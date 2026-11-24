import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_engine/battle.dart';
class Progress {
  final SharedPreferences prefs;
  String active='Gast';
  Map<String,dynamic> profiles={};
  Progress(this.prefs){
    try{profiles=Map<String,dynamic>.from(jsonDecode(prefs.getString('profiles')??'{}') as Map);active=prefs.getString('active')??'Gast';}catch(_){profiles={};}
    profiles.putIfAbsent('Gast',()=>fresh());
    if(!profiles.containsKey(active))active='Gast';
  }
  Map<String,dynamic> fresh()=>{'rounds':0,'wins':0,'right':0,'wrong':0,'xp':0,'avatar':0,'categories':<String,dynamic>{}};
  Map<String,dynamic> get current=>profiles[active] as Map<String,dynamic>;
  Future<void> save()async{await prefs.setString('profiles',jsonEncode(profiles));await prefs.setString('active',active);}
  int levelFor(String world,int fallback){final c=(current['categories'] as Map)[world] as Map?;return (c?['level'] as int?)??fallback;}
  static int adapt(int level,int right,int total){
    if(total<20)return level;
    final rate=right/total;
    return (level+(rate>=.9?1:rate<.7?-1:0)).clamp(0,3).toInt();
  }
  void record(Battle b){
    final p=current;
    p['rounds']=(p['rounds'] as int)+1;
    if(b.winner==0)p['wins']=(p['wins'] as int)+1;
    for(final a in b.attempts.where((a)=>a.player==0)){
      final key=a.correct?'right':'wrong';p[key]=(p[key] as int)+1;
      final cats=p['categories'] as Map;
      final c=cats.putIfAbsent(a.question.world.name,()=>{'right':0,'wrong':0,'ms':0,'level':b.level,'windowRight':0,'windowTotal':0}) as Map;
      c[key]=(c[key] as int)+1;c['ms']=(c['ms'] as int)+a.ms;
      c['windowTotal']=(c['windowTotal'] as int)+1;
      if(a.correct)c['windowRight']=(c['windowRight'] as int)+1;
    }
    for(final c in (p['categories'] as Map).values.cast<Map>()){
      if((c['windowTotal'] as int)>=20){c['level']=adapt(c['level'] as int,c['windowRight'] as int,c['windowTotal'] as int);c['windowTotal']=0;c['windowRight']=0;}
    }
    p['xp']=(p['xp'] as int)+b.points[0]*10;
  }
}
