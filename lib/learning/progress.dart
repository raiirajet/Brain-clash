import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_engine/battle.dart';
import '../question_generators/questions.dart';
import '../question_generators/challenges.dart';
import 'engagement.dart';
import '../core/storage/profile_store.dart';
class Progress {
  final SharedPreferences prefs;
  String active='Gast';
  ProfileStore? _store;
  int _revision=0;
  Future<void> _writes=Future.value();
  bool storageFallback=false;
  String get storageName=>_store==null||storageFallback?'SharedPreferences (Sicherung)':'SQLite';
  Map<String,dynamic> profiles={};
  Progress(this.prefs){
    try{profiles=Map<String,dynamic>.from(jsonDecode(prefs.getString('profiles')??'{}') as Map);active=prefs.getString('active')??'Gast';}catch(_){profiles={};}
    _revision=prefs.getInt('profilesRevision')??0;
    try{final raw=prefs.getString('profileSnapshotV1');if(raw!=null){final snapshot=ProfileSnapshot.fromJson(jsonDecode(raw) as Map);if(snapshot.revision>=_revision){profiles=snapshot.profiles;active=snapshot.active;_revision=snapshot.revision;}}}catch(_){/* Use legacy backup. */}
    profiles.putIfAbsent('Gast',()=>fresh());
    if(!profiles.containsKey(active))active='Gast';
  }
  Map<String,dynamic> fresh()=>{'rounds':0,'wins':0,'right':0,'wrong':0,'xp':0,'avatar':0,'categories':<String,dynamic>{},'review':<String,dynamic>{},'best':0};
  String quickKey(String key)=>'profile:${Uri.encodeComponent(active)}:$key';
  Map<String,dynamic> get current=>profiles[active] as Map<String,dynamic>;
  static Future<Progress> open(SharedPreferences prefs,{String? databasePath})async{
    final progress=Progress(prefs);
    try{
      final store=await ProfileStore.open(databasePath:databasePath);
      final stored=await store.read();
      if(stored!=null&&stored.revision>=progress._revision){
        progress.profiles=stored.profiles;progress.active=stored.active;progress._revision=stored.revision;
        progress.profiles.putIfAbsent('Gast',()=>progress.fresh());
        if(!progress.profiles.containsKey(progress.active))progress.active='Gast';
      }
      progress._store=store;
      if(stored==null||stored.revision<progress._revision)await progress.save();
    }catch(_){progress.storageFallback=true;}
    return progress;
  }
  Future<void> save(){
    final snapshot=ProfileSnapshot(++_revision,active,Map<String,dynamic>.from(jsonDecode(jsonEncode(profiles)) as Map));
    final previous=_writes;
    _writes=()async{
      try{await previous;}catch(_){/* A later snapshot can still be saved. */}
      final backupOk=await prefs.setString('profileSnapshotV1',jsonEncode(snapshot.toJson()));
      await prefs.setString('profiles',jsonEncode(snapshot.profiles));
      await prefs.setString('active',snapshot.active);
      await prefs.setInt('profilesRevision',snapshot.revision);
      if(_store!=null){try{await _store!.write(snapshot);storageFallback=false;}catch(_){storageFallback=true;}}
      if(!backupOk&&(_store==null||storageFallback))throw StateError('Profile snapshot could not be saved');
    }();
    return _writes;
  }
  int digitsFor(String game,int fallback,{String? profile}){
    final p=profiles[profile??active] as Map? ??current;
    return (((p['skills'] as Map?)?[game] as Map?)?['digits'] as int? ??fallback).clamp(1,4).toInt();
  }
  int levelFor(String world,int fallback){if(world=='mixed'){final values=(current['categories'] as Map).values.map((v)=>(v as Map)['level'] as int).toList();return values.isEmpty?fallback:(values.reduce((a,b)=>a+b)/values.length).round();}final c=(current['categories'] as Map)[world] as Map?;return (c?['level'] as int?)??fallback;}
  static int adapt(int level,int right,int total){
    if(total<20)return level;
    final rate=right/total;
    return (level+(rate>=.9?1:rate<.6?-1:0)).clamp(0,3).toInt();
  }
  int masteryLevel(String game,int fallback,{String? profile}){final p=profiles[profile??active] as Map? ??current;return (((p['skills'] as Map?)?[game] as Map?)?['level'] as int? ??fallback).clamp(0,3).toInt();}
  Map get reviews=>current.putIfAbsent('review',()=> <String,dynamic>{}) as Map;
  List<Question> dueQuestions(World world,{DateTime? at,String? game}){
    final now=(at??DateTime.now()).millisecondsSinceEpoch;
    final result=<Question>[];
    for(final v in reviews.values){
      try {
        final item=v as Map;
        if((item['due'] as int)>now)continue;
        if(game!=null&&item['game']!=game)continue;
        final q=Question.fromJson(item['question'] as Map);
        if(world==World.mixed||q.world==world)result.add(q);
      }catch(_){continue;}
    }
    return result;
  }
  void updateReviews(Battle b,{DateTime? at,int player=0}){
    final now=at??DateTime.now();
    final grouped=<String,List<Attempt>>{};
    for(final a in b.attempts.where((a)=>a.player==player)){
      if(a.question.interaction==Interaction.tap||a.question.interaction==Interaction.signal)continue;
      grouped.putIfAbsent(a.question.key,()=>[]).add(a);
    }
    for(final entry in grouped.entries){
      final a=entry.value.last;
      if(entry.value.any((a)=>!a.correct)){
        reviews[entry.key]={'question':a.question.toJson(),'game':b.skillName,'due':now.millisecondsSinceEpoch,'stage':0};
      }else if(b.mode==Mode.training&&reviews.containsKey(entry.key)){
        final old=reviews[entry.key] as Map;
        if((old['due'] as int)>now.millisecondsSinceEpoch)continue;
        final stage=old['stage'] as int;
        if(stage>=3){reviews.remove(entry.key);}else{
          reviews[entry.key]={'question':a.question.toJson(),'game':b.skillName,'due':now.add(Duration(days:[1,3,7][stage])).millisecondsSinceEpoch,'stage':stage+1};
        }
      }
    }
  }
  void record(Battle b,{int player=0,String? profile}){
    final previous=active;
    if(profile!=null&&profiles.containsKey(profile))active=profile;
    final p=current;
    final own=b.attempts.where((a)=>a.player==player).toList();
    if(own.isEmpty){active=previous;return;}
    final first=<int,Attempt>{};for(final a in own){first.putIfAbsent(a.taskId,()=>a);}
    final samples=first.values.toList();
    final previousDue=dueQuestions(World.mixed).map((q)=>q.key).toSet();
    updateReviews(b,player:player);
    final digit=player==0?b.digits:b.opponentDigits,level=player==0?b.level:b.opponentLevel;
    final recordKey='${b.skillName}|${b.mode.name}|${b.rule.name}|${b.duration}|$digit|$level|${b.settingsKey}';
    final records=p.putIfAbsent('records',()=> <String,dynamic>{}) as Map;
    final newRecord=b.points[player]>(records[recordKey] as int? ??0);
    if(newRecord)records[recordKey]=b.points[player];
    if(records.length>300)records.remove(records.keys.first);
    if(b.points[player]>(p['best'] as int? ??0))p['best']=b.points[player];
    p['rounds']=(p['rounds'] as int)+1;
    if(b.winner==player||(b.mode==Mode.team&&b.winner==0))p['wins']=(p['wins'] as int)+1;
    for(final a in b.attempts.where((a)=>a.player==player)){
      final key=a.correct?'right':'wrong';p[key]=(p[key] as int)+1;
      final cats=p['categories'] as Map;
      final c=cats.putIfAbsent(a.question.world.name,()=>{'right':0,'wrong':0,'ms':0,'level':player==0?b.level:b.opponentLevel,'windowRight':0,'windowTotal':0}) as Map;
      c[key]=(c[key] as int)+1;c['ms']=(c['ms'] as int)+a.ms;c['last']=a.question.prompt;if(a.correct&&(c['bestMs']==null||a.ms<(c['bestMs'] as int)))c['bestMs']=a.ms;
      // Category totals are descriptive; mastery uses first attempts per game.
    }
    final right=own.where((a)=>a.correct).length;
    final firstRight=samples.where((a)=>a.correct).length;
    final dayBonus=DailyProgress.add(p,right);
    final weekBonus=WeeklyProgress.add(p,own.where((a)=>a.correct).map((a)=>a.question.world.name));
    final learned=b.mode==Mode.training?samples.where((a)=>a.correct&&previousDue.contains(a.question.key)).map((a)=>a.question.key).toSet().length:0;
    final qualified=samples.length>=5&&right>=3&&(b.elapsed>=10000||b.finishReason==FinishReason.goal);
    final breakdown=<String,int>{
     'Richtige Antworten':right*10,'Teilnahme':qualified?15:0,'Sieg':right>0&&b.mode!=Mode.training&&(b.mode==Mode.team?b.winner==0:b.winner==player)?25:0,
     'Fehlerfrei':qualified&&firstRight==samples.length?50:0,'Tagesziel':dayBonus,'Wochenziel':weekBonus,'Rekord':qualified&&newRecord?30:0,'Fehlertraining':learned*15};
    breakdown.removeWhere((k,v)=>v==0);
    final reward=breakdown.values.fold<int>(0,(sum,n)=>sum+n);
    final skillMap=p.putIfAbsent('skills',()=> <String,dynamic>{}) as Map;
    final skill=skillMap.putIfAbsent(b.skillName,()=>{'right':0,'wrong':0,'digits':digit,'level':level}) as Map;
    skill['right']=(skill['right'] as int? ??0)+right;skill['wrong']=(skill['wrong'] as int? ??0)+own.length-right;
    final numeric=Challenge.values.where((c)=>c.name==b.skillName).firstOrNull?.usesDigits??false;
    final signature='$digit|$level|${b.settingsKey}';
    if(b.mode==Mode.training&&skill['sampleKey']!=signature){skill['sampleKey']=signature;skill['sampleWindow']=<dynamic>[];}
    final window=skill.putIfAbsent('sampleWindow',()=> <dynamic>[]) as List;
    if(b.mode==Mode.training){
     for(final a in samples){window.add({'ok':a.correct,'ms':a.ms});}
     while(window.length>=20){
      final group=window.take(20).cast<Map>().toList();
      final correct=group.where((a)=>a['ok']==true).length;
      final avg=group.fold<int>(0,(sum,a)=>sum+(a['ms'] as int))/20;
      final next=adapt(level,correct,20);
      final digitNext=correct<12?-1:correct>=18&&avg<=4500?1:0;
      skill['level']=next;
      if(numeric){skill['digits']=(digit+digitNext).clamp(1,4).toInt();}
      skill['masteryAccuracy']=correct/20;
      window.removeRange(0,20);
     }
    }
    if(b.mode==Mode.duel||b.mode==Mode.solo){
      final competitive=p.putIfAbsent('competitive',()=>{'played':0,'wins':0,'draws':0,'rating':1000}) as Map;
      competitive['played']=(competitive['played'] as int)+1;
      competitive['wins']=(competitive['wins'] as int)+(b.winner==player?1:0);
      competitive['draws']=(competitive['draws'] as int)+(b.winner==null?1:0);
      competitive['rating']=((competitive['rating'] as int)+(b.winner==null?0:b.winner==player?20:-20)).clamp(0,100000).toInt();
    }
    p['xp']=(p['xp'] as int)+reward;
    final history=p.putIfAbsent('history',()=> <dynamic>[]) as List;
    if(own.isNotEmpty){
      var best=0,series=0;
      for(final a in own){series=a.correct?series+1:0;if(series>best)best=series;}
      if(best>(p['bestSeries'] as int? ??0))p['bestSeries']=best;
      history.add({'date':DateTime.now().toIso8601String().substring(0,10),'world':b.world.name,'game':b.skillName,'points':b.points[player],'level':level,'digits':digit,'duration':b.duration,'mode':b.mode.name,'rule':b.rule.name,'firstRight':firstRight,'firstTotal':samples.length,'xp':reward,'xpBreakdown':breakdown,'right':right,'total':own.length,'ms':own.fold<int>(0,(sum,a)=>sum+a.ms),'attempts':[for(final a in own.take(30)){'prompt':a.question.prompt,'solution':a.question.answer,'response':a.response,'correct':a.correct,'ms':a.ms}]});
    }
    if(history.length>100)history.removeRange(0,history.length-100);
    active=previous;
  }
}
