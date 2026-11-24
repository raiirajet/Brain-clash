import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_engine/arena.dart';
import '../audio/audio.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';
import '../widgets/memory_board.dart';

class Play extends StatefulWidget{
 final Progress progress;final Mode mode;final World world;final int duration,level,opponent;final bool numberEntry;
 const Play({super.key,required this.progress,required this.mode,required this.world,required this.duration,required this.level,required this.opponent,this.numberEntry=false});
 @override State<Play> createState()=>_PlayState();
}
class _PlayState extends State<Play> with WidgetsBindingObserver{
 late Battle b;late Timer timer;final arena=Arena();final watch=Stopwatch();
 int last=0,streak=0;int lastCountdown=3;bool saved=false,leaving=false,dialogOpen=false;final feedback=['',''];String typed='';
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);reset();watch.start();timer=Timer.periodic(const Duration(milliseconds:32),(_){
  if(!mounted)return;final now=watch.elapsedMilliseconds;final delta=now-last;last=now;
  if(b.phase==Phase.paused||b.phase==Phase.ended)return;
  final before=b.phase;final oldScore=b.points[0]+b.points[1];
  setState((){b.tick(delta);arena.energy=b.energy/100;arena.score=b.points[0]+b.points[1];});
  if(before==Phase.countdown&&b.phase==Phase.playing){unawaited(GameAudio(widget.progress.prefs).effect('start'));}
  if(b.phase==Phase.countdown){final count=(b.countdown/1000).ceil();if(count!=lastCountdown){lastCountdown=count;unawaited(GameAudio(widget.progress.prefs).effect('countdown'));}}
  if(b.points[0]+b.points[1]>oldScore&&b.phase==Phase.playing)unawaited(GameAudio(widget.progress.prefs).effect('energy'));
  if(b.phase==Phase.ended)persist();
 });}
 void reset(){b=Battle(mode:widget.mode,world:widget.world,duration:widget.duration,level:widget.level,opponentLevel:widget.opponent,questions:widget.mode==Mode.training?ReviewQuestions(widget.progress.dueQuestions(widget.world)):null);arena.energy=.5;arena.leftAvatar=widget.progress.current['avatar'] as int;arena.rightAvatar=widget.mode==Mode.team?4:5;arena.reduced=widget.progress.prefs.getBool('reduced')??false;saved=false;typed='';streak=0;lastCountdown=3;arena.score=0;feedback[0]='';feedback[1]='';}
 void persist(){if(saved)return;saved=true;final before=widget.progress.current['xp'] as int;widget.progress.record(b);final after=widget.progress.current['xp'] as int;unawaited(widget.progress.save());final audio=GameAudio(widget.progress.prefs);unawaited(audio.effect(widget.mode==Mode.training?'right':b.winner==null?'draw':b.winner==0?'win':'loss'));if([50,150,300,600,1000].any((n)=>before<n&&after>=n))unawaited(audio.effect('unlock'));}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed&&mounted){setState(()=>b.pause());}}
 @override void dispose(){timer.cancel();watch.stop();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 void answer(int p,String v,Question expected,{int? cell}){
  // Synchronise the monotonic clock at the input, not just the display frame.
  final now=watch.elapsedMilliseconds;
  setState((){b.tick(now-last);last=now;final result=identical(b.tasks[p],expected)?(cell==null?b.answer(p,v):b.tapCell(p,cell)):null;if(result!=null){
    if(p==0)typed='';
    feedback[p]=result?'Richtig!':widget.mode==Mode.training?'Richtig: ${expected.answer}':'Noch einmal versuchen';
    final audio=GameAudio(widget.progress.prefs);
    if(p==0){streak=result?streak+1:0;}
    unawaited(audio.effect(result?(p==0&&streak%5==0?'streak':'right'):'wrong'));
    if(widget.progress.prefs.getBool('haptics')??true)unawaited(result?HapticFeedback.selectionClick():HapticFeedback.lightImpact());
  }arena.energy=b.energy/100;arena.score=b.points[0]+b.points[1];});
  if(b.phase==Phase.ended)persist();
 }
 Future<void> leave()async{
  if(dialogOpen)return;
  if(b.phase==Phase.ended){Navigator.pop(context);return;}
  dialogOpen=true;
  final wasPaused=b.phase==Phase.paused;
  setState(()=>b.pause());
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Runde verlassen?'),content:const Text('Diese Runde wird nicht gespeichert.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Weiterspielen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Verlassen'))]));
  dialogOpen=false;
  if(!mounted)return;
  if(yes==true){setState(()=>leaving=true);WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)Navigator.pop(context);});}else if(!wasPaused){setState((){last=watch.elapsedMilliseconds;b.resume();});}
 }
 bool get two=>widget.mode==Mode.duel||widget.mode==Mode.team;
 @override Widget build(BuildContext context)=>PopScope(canPop:leaving||b.phase==Phase.ended,onPopInvokedWithResult:(didPop,result){if(!didPop&&!leaving)unawaited(leave());},child:Scaffold(
  appBar:AppBar(title:Text(widget.world.label),leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:leave),actions:[if(b.phase!=Phase.ended)IconButton(icon:Icon(b.phase==Phase.paused?Icons.play_arrow:Icons.pause),onPressed:()=>setState((){if(b.phase==Phase.paused){last=watch.elapsedMilliseconds;b.resume();}else{b.pause();}}))]),
  body:SafeArea(child:b.phase==Phase.ended?result():Column(children:[
   if(two)Expanded(child:RotatedBox(quarterTurns:2,child:panel(1))),
   if(!two)const SizedBox(height:8),
   Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('🔵 ${b.points[0]}'),Text(b.phase==Phase.countdown?'Start in ${(b.countdown/1000).ceil()}':b.phase==Phase.paused?'PAUSE':b.unlimited?'∞':'${(b.remaining/1000).ceil()} s',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text('${b.points[1]} 🟠')])),
   SizedBox(height:two?48:100,child:GameWidget(game:arena)),
   if(widget.mode==Mode.team)Text('Monster-Energie: ${(100-b.energy)*2} %'),
   if(!two&&widget.mode==Mode.solo)const Padding(padding:EdgeInsets.all(8),child:Text('🤖 Virtueller Gegner')),
   Expanded(child:panel(0)),
   if(widget.mode==Mode.training)TextButton(onPressed:()=>setState((){b.finish();persist();}),child:const Text('Training beenden')),
  ]))));
 Widget panel(int p){
  final q=b.tasks[p],visible=b.visible(p);
  final running=b.phase==Phase.playing;
  final color=p==0?const Color(0xff2359c5):const Color(0xffb44818);
  return Padding(padding:const EdgeInsets.all(8),child:LayoutBuilder(builder:(c,box)=>Column(children:[
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(p==0?'🔵 Spieler 1':'🟠 Spieler 2'),Text('${b.points[p]} ✓')]),
   Expanded(child:Center(child:Text(!running?(b.phase==Phase.paused?'Pausiert':'Bereit?'):!visible?(q.interaction==Interaction.sequence||q.interaction==Interaction.pairs?'Merke dir die Felder':q.preview):q.prompt,style:TextStyle(fontSize:box.maxHeight<230?18:25,fontWeight:FontWeight.w800),textAlign:TextAlign.center))),
   if(running&&(q.interaction==Interaction.sequence||q.interaction==Interaction.pairs))Expanded(flex:3,child:MemoryBoard(question:q,battle:b,player:p,onTap:(i)=>answer(p,'',q,cell:i)))
   else if(running&&visible&&widget.numberEntry&&p==0&&q.world==World.math)numberPad(q,box.maxHeight,color)
   else if(running&&visible)SizedBox(height:((box.maxHeight-80)*.62).clamp(62.0,145.0).toDouble(),child:GridView.count(physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:(box.maxWidth/2)/(((box.maxHeight-80)*.62).clamp(62.0,145.0)/2),mainAxisSpacing:3,crossAxisSpacing:5,children:q.options.map((v)=>FilledButton(style:FilledButton.styleFrom(backgroundColor:color,padding:const EdgeInsets.symmetric(horizontal:4)),onPressed:b.canAnswer(p)?()=>answer(p,v,q):null,child:FittedBox(fit:BoxFit.scaleDown,child:Text(v,style:const TextStyle(fontSize:19))))).toList())),
   SizedBox(height:21,child:Text(!running?'':b.locks[p]>b.elapsed?feedback[p]:b.pendingPlayer==p?'Warte …':'',style:const TextStyle(fontSize:13))),
  ])));
 }
 Widget numberPad(Question q,double available,Color color){
  final enabled=b.canAnswer(0);
  return SizedBox(height:((available-60)*.68).clamp(115.0,285.0).toDouble(),child:Column(children:[
    Text(typed.isEmpty?'?':typed,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
    Expanded(child:LayoutBuilder(builder:(context,space)=>GridView(physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisExtent:((space.maxHeight-9)/4).clamp(15.0,100.0).toDouble(),mainAxisSpacing:3,crossAxisSpacing:4),children:['1','2','3','4','5','6','7','8','9','⌫','0','OK'].map((key)=>FilledButton(style:FilledButton.styleFrom(backgroundColor:color,padding:EdgeInsets.zero),onPressed:!enabled?null:(){
      if(key=='OK'){if(typed.isNotEmpty)answer(0,typed,q);return;}
      setState((){if(key=='⌫'){if(typed.isNotEmpty)typed=typed.substring(0,typed.length-1);}else if(typed.length<7){typed+=key;}});
    },child:Text(key))).toList()))),
  ]));
 }
 Widget result(){
  final a=b.attempts.where((a)=>a.player==0).toList(),correct=a.where((a)=>a.correct).length;
  final title=widget.mode==Mode.training?'Training abgeschlossen':widget.mode==Mode.team?(b.winner==0?'Gemeinsam gewonnen!':'Gut gekämpft!'):b.winner==null?'Unentschieden':b.winner==0?'Spieler 1 gewinnt!':widget.mode==Mode.solo?'Der Gegner gewinnt':'Spieler 2 gewinnt!';
  return ListView(padding:const EdgeInsets.all(24),children:[
   const Icon(Icons.emoji_events,size:66,color:Colors.amber),Text(title,textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineSmall),
   const SizedBox(height:18),Text('Richtig: $correct · Trefferquote: ${a.isEmpty?0:(100*correct/a.length).round()} % · +${b.points[0]*10} XP',textAlign:TextAlign.center),
   if(a.any((a)=>!a.correct))ExpansionTile(title:const Text('Fehler ansehen'),children:a.where((a)=>!a.correct).map((a)=>ListTile(title:Text(a.question.prompt),subtitle:Text(a.question.explanation))).toList()),
   const SizedBox(height:18),FilledButton(onPressed:()=>setState(reset),child:const Text('Revanche')),
   OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Neues Spiel')),
   TextButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Hauptmenü')),
  ]);
 }
}
