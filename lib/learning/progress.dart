import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_engine/battle.dart';
import '../question_generators/questions.dart';
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
  Map<String,dynamic> get current=>profiles[active] as Map<String,dynamic>;
  static Future<Progress> open(SharedPreferences prefs)async{
    final progress=Progress(prefs);
    try{
      final store=await ProfileStore.open();
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
      await prefs.setString('profileSnapshotV1',jsonEncode(snapshot.toJson()));
      await prefs.setString('profiles',jsonEncode(snapshot.profiles));
      await prefs.setString('active',snapshot.active);
      await prefs.setInt('profilesRevision',snapshot.revision);
      if(_store!=null){try{await _store!.write(snapshot);storageFallback=false;}catch(_){storageFallback=true;}}
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
  Map get reviews=>current.putIfAbsent('review',()=> <String,dynamic>{}) as Map;
  List<Question> dueQuestions(World world,{DateTime? at}){
    final now=(at??DateTime.now()).millisecondsSinceEpoch;
    final result=<Question>[];
    for(final v in reviews.values){
      try {
        final item=v as Map;
        if((item['due'] as int)>now)continue;
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
      grouped.putIfAbsent(a.question.key,()=>[]).add(a);
    }
    for(final entry in grouped.entries){
      final a=entry.value.last;
      if(entry.value.any((a)=>!a.correct)){
        reviews[entry.key]={'question':a.question.toJson(),'due':now.millisecondsSinceEpoch,'stage':0};
      }else if(b.mode==Mode.training&&reviews.containsKey(entry.key)){
        final old=reviews[entry.key] as Map;
        if((old['due'] as int)>now.millisecondsSinceEpoch)continue;
        final stage=old['stage'] as int;
        if(stage>=3){reviews.remove(entry.key);}else{
          reviews[entry.key]={'question':a.question.toJson(),'due':now.add(Duration(days:[1,3,7][stage])).millisecondsSinceEpoch,'stage':stage+1};
        }
      }
    }
  }
  void record(Battle b,{int player=0,String? profile}){
    final previous=active;
    if(profile!=null&&profiles.containsKey(profile))active=profile;
    final p=current;
    final previousDue=dueQuestions(World.mixed).map((q)=>q.key).toSet();
    updateReviews(b,player:player);
    final newRecord=b.points[player]>(p['best'] as int? ??0);
    if(newRecord)p['best']=b.points[player];
    p['rounds']=(p['rounds'] as int)+1;
    if(b.winner==player||(b.mode==Mode.team&&b.winner==0))p['wins']=(p['wins'] as int)+1;
    for(final a in b.attempts.where((a)=>a.player==player)){
      final key=a.correct?'right':'wrong';p[key]=(p[key] as int)+1;
      final cats=p['categories'] as Map;
      final c=cats.putIfAbsent(a.question.world.name,()=>{'right':0,'wrong':0,'ms':0,'level':player==0?b.level:b.opponentLevel,'windowRight':0,'windowTotal':0}) as Map;
      c[key]=(c[key] as int)+1;c['ms']=(c['ms'] as int)+a.ms;c['last']=a.question.prompt;if(a.correct&&(c['bestMs']==null||a.ms<(c['bestMs'] as int)))c['bestMs']=a.ms;
      c['windowTotal']=(c['windowTotal'] as int)+1;
      if(a.correct)c['windowRight']=(c['windowRight'] as int)+1;
    }
    for(final c in (p['categories'] as Map).values.cast<Map>()){
      if((c['windowTotal'] as int)>=20){c['level']=adapt(c['level'] as int,c['windowRight'] as int,c['windowTotal'] as int);c['windowTotal']=0;c['windowRight']=0;}
    }
    final own=b.attempts.where((a)=>a.player==player).toList();
    final right=own.where((a)=>a.correct).length;
    final dayBonus=DailyProgress.add(p,right);
    final weekBonus=WeeklyProgress.add(p,own.where((a)=>a.correct).map((a)=>a.question.world.name));
    final learned=b.mode==Mode.training?own.where((a)=>a.correct&&previousDue.contains(a.question.key)).map((a)=>a.question.key).toSet().length:0;
    final reward=own.isEmpty?0:right*10+15+(b.mode!=Mode.training&&b.winner==player?25:0)+(right>=5&&right==own.length?50:0)+dayBonus+weekBonus+(newRecord?30:0)+learned*15;
    final skillMap=p.putIfAbsent('skills',()=> <String,dynamic>{}) as Map;
    final digit=player==0?b.digits:b.opponentDigits;
    final skill=skillMap.putIfAbsent(b.skillName,()=>{'right':0,'wrong':0,'digits':digit,'sampleDigits':digit,'windowRight':0,'windowTotal':0,'windowMs':0}) as Map;
    if(skill['sampleDigits']!=digit){skill['sampleDigits']=digit;skill['windowRight']=0;skill['windowTotal']=0;skill['windowMs']=0;}
    skill['right']=(skill['right'] as int)+right;skill['wrong']=(skill['wrong'] as int)+own.length-right;
    skill['windowRight']=(skill['windowRight'] as int)+right;skill['windowTotal']=(skill['windowTotal'] as int)+own.length;
    skill['windowMs']=(skill['windowMs'] as int)+own.fold<int>(0,(sum,a)=>sum+a.ms);
    if((skill['windowTotal'] as int)>=20){
     final rate=(skill['windowRight'] as int)/(skill['windowTotal'] as int),avg=(skill['windowMs'] as int)/(skill['windowTotal'] as int);
     skill['digits']=(digit+(rate<.6?-1:rate>=.9&&avg<=4500?1:0)).clamp(1,4).toInt();
     skill['windowRight']=0;skill['windowTotal']=0;skill['windowMs']=0;
    }
    p['xp']=(p['xp'] as int)+reward;
    final history=p.putIfAbsent('history',()=> <dynamic>[]) as List;
    if(own.isNotEmpty){
      var best=0,series=0;
      for(final a in own){series=a.correct?series+1:0;if(series>best)best=series;}
      if(best>(p['bestSeries'] as int? ??0))p['bestSeries']=best;
      history.add({'date':DateTime.now().toIso8601String().substring(0,10),'world':b.world.name,'game':b.skillName,'points':b.points[player],'right':right,'total':own.length,'ms':own.fold<int>(0,(sum,a)=>sum+a.ms),'attempts':[for(final a in own.take(30)){'prompt':a.question.prompt,'solution':a.question.answer,'response':a.response,'correct':a.correct,'ms':a.ms}]});
    }
    if(history.length>100)history.removeRange(0,history.length-100);
    active=previous;
  }
}
