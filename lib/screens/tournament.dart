import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../learning/progress.dart';
import '../game_engine/battle.dart';
import '../question_generators/challenges.dart';
import '../game_engine/tournament_validation.dart';
import 'play.dart';
class TournamentPage extends StatefulWidget{
 final Progress progress;
 const TournamentPage({super.key,required this.progress});
 @override State<TournamentPage> createState()=>_TournamentPageState();
}
class _TournamentPageState extends State<TournamentPage>{
 final names=TextEditingController();
 List<String> players=[];
 List<List<int>> matches=[];
 List<int> winners=[];
 bool roundRobin=false;
 int digits=1,duration=60,level=1;
 Challenge game=Challenge.addition;
 BattleRule rule=BattleRule.race;
 bool playing=false;
 static final games=Challenge.values.where((g)=>!g.specialRules).toList();
 bool get active=>players.isNotEmpty;
 @override void initState(){
  super.initState();
  try{
   final data=jsonDecode(widget.progress.prefs.getString('tournamentV1')??'{}') as Map;
   players=List<String>.from(data['players']??[]);
   matches=(data['matches'] as List? ?? []).map((m)=>List<int>.from(m as List)).toList();
   winners=List<int>.from(data['winners']??[]);
   roundRobin=data['roundRobin']==true;digits=(data['digits'] as int? ??1).clamp(1,4).toInt();
   game=games.where((g)=>g.name==data['game']).firstOrNull??Challenge.addition;
   rule=BattleRule.values.where((r)=>r.name==data['rule']).firstOrNull??BattleRule.race;
   duration=[30,60,90,120].contains(data['duration'])?data['duration'] as int:60;level=(data['level'] as int? ??1).clamp(0,3).toInt();
   if(!validTournament(players,matches,winners,roundRobin:roundRobin))throw const FormatException('Invalid tournament');
  }catch(_){players=[];matches=[];winners=[];}
 }
 @override void dispose(){names.dispose();super.dispose();}
 Future<void> save()async{await widget.progress.prefs.setString('tournamentV1',jsonEncode({'players':players,'matches':matches,'winners':winners,'roundRobin':roundRobin,'digits':digits,'duration':duration,'level':level,'game':game.name,'rule':rule.name}));}
 void begin(){
  final list=names.text.split(RegExp(r'[,\n]')).map((n)=>n.trim()).where((n)=>n.isNotEmpty).toList();
  if(list.length<2||list.length>8||list.map((n)=>n.toLowerCase()).toSet().length!=list.length||list.any((n)=>n.length>40)){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bitte 2 bis 8 unterschiedliche Namen eingeben.')));return;
  }
  setState((){
   players=list;matches=[];winners=[];
   if(roundRobin){for(var i=0;i<players.length;i++){for(var j=i+1;j<players.length;j++){matches.add([i,j]);}}}
   else{final pool=List.generate(players.length,(i)=>i);while(pool.length>1){matches.add([pool.removeAt(0),pool.removeAt(0)]);}if(pool.isNotEmpty)matches.add([pool.first,-1]);advanceByes();}
  });save();
 }
 void advanceByes(){
  while(!roundRobin&&winners.length<matches.length&&matches[winners.length][1]==-1)winners.add(matches[winners.length][0]);
 }
 void complete(int? winner){
  if(!mounted||winner==null||winner<0||winner>1||winners.length>=matches.length)return;
  setState((){
   final pair=matches[winners.length];winners.add(pair[winner]);advanceByes();
   if(!roundRobin&&winners.length==matches.length){
    // The current survivors are all participants that have never lost.
    final eliminated=<int>{};
    for(var i=0;i<matches.length;i++){final m=matches[i];if(m[1]>=0)eliminated.add(m.first==winners[i]?m[1]:m.first);}
    final alive=List.generate(players.length,(i)=>i).where((p)=>!eliminated.contains(p)).toList();
    if(alive.length>1){while(alive.length>1){matches.add([alive.removeAt(0),alive.removeAt(0)]);}if(alive.isNotEmpty)matches.add([alive.first,-1]);advanceByes();}
   }
  });save();
 }
 Future<void> play()async{
  if(playing||winners.length>=matches.length)return;
  setState(()=>playing=true);
  final index=winners.length,pair=matches[index];
  await Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Play(progress:widget.progress,mode:Mode.duel,world:game.world,duration:duration,level:level,opponent:level,challenge:game,digits:digits,opponentDigits:digits,rule:rule,playerNames:[players[pair[0]],players[pair[1]]],recordProgress:false,onMatchEnd:(winner){if(winners.length==index)complete(winner);}))); 
  if(mounted)setState(()=>playing=false);
 }
 @override Widget build(BuildContext context){
  final done=active&&winners.length==matches.length;
  final standings=List.generate(players.length,(i)=>i)..sort((a,b)=>winners.where((w)=>w==b).length.compareTo(winners.where((w)=>w==a).length));
  return Scaffold(appBar:AppBar(title:const Text('Lokales Turnier')),body:ListView(padding:const EdgeInsets.all(16),children:[
   if(!active)...[
    const Text('2–8 Teilnehmer · Unentschieden wird wiederholt'),
    DropdownButtonFormField<Challenge>(value:game,decoration:const InputDecoration(labelText:'Spiel'),items:[for(final g in games)DropdownMenuItem(value:g,child:Text(g.label))],onChanged:(g)=>setState(()=>game=g!)),
    DropdownButtonFormField<BattleRule>(value:rule,decoration:const InputDecoration(labelText:'Spielregeln'),items:[for(final r in BattleRule.values)DropdownMenuItem(value:r,child:Text(r.label))],onChanged:(r)=>setState(()=>rule=r!)),
    Wrap(spacing:8,children:[for(final t in [30,60,90,120])ChoiceChip(label:Text('$t s'),selected:duration==t,onSelected:(_)=>setState(()=>duration=t))]),
    DropdownButtonFormField<int>(value:level,items:[for(var i=0;i<4;i++)DropdownMenuItem(value:i,child:Text(['Einfach','Normal','Schwer','Experte'][i]))],onChanged:(v)=>setState(()=>level=v!)),
    TextField(controller:names,maxLines:4,decoration:InputDecoration(labelText:L.text('Namen, getrennt durch Komma oder Zeilenumbruch'))),
    SwitchListTile(title:const Text('Jeder gegen jeden'),subtitle:const Text('Aus: K.-o.-System'),value:roundRobin,onChanged:(v)=>setState(()=>roundRobin=v)),
    Wrap(spacing:8,children:[for(var n=1;n<=4;n++)ChoiceChip(label:Text('$n Ziffern'),selected:digits==n,onSelected:(_)=>setState(()=>digits=n))]),
    FilledButton(onPressed:begin,child:const Text('Turnier starten')),
   ]else...[
    Text(roundRobin?'Jeder gegen jeden':'K.-o.-Turnier',style:Theme.of(context).textTheme.headlineSmall),
    if(done)Text(roundRobin?'Turnier abgeschlossen':'Sieger: ${players[winners.last]}',style:Theme.of(context).textTheme.titleLarge)
    else FilledButton.icon(onPressed:playing?null:play,icon:const Icon(Icons.play_arrow),label:Text('${players[matches[winners.length][0]]} VS ${players[matches[winners.length][1]]}')),
    for(var i=0;i<matches.length;i++)ListTile(leading:Icon(i<winners.length?Icons.check_circle:i==winners.length?Icons.play_circle:Icons.schedule),title:Text('${players[matches[i][0]]} – ${matches[i][1]<0?'Freilos':players[matches[i][1]]}'),subtitle:i<winners.length?Text('Weiter: ${players[winners[i]]}'):null),
    if(roundRobin)...[const Divider(),const Text('Rangliste · Gleiche Siege = gleicher Rang'),for(final i in standings)ListTile(title:Text(players[i]),trailing:Text('${winners.where((w)=>w==i).length} Siege'))],
    TextButton(onPressed:()async{final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Turnier zurücksetzen?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Zurücksetzen'))]));if(confirmed==true&&mounted){setState((){players=[];matches=[];winners=[];});save();}},child:const Text('Neues Turnier')),
   ]
  ]));
 }
}
