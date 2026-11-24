import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_engine/arena.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';

class Play extends StatefulWidget{
 final Progress progress;final Mode mode;final World world;final int duration,level,opponent;
 const Play({super.key,required this.progress,required this.mode,required this.world,required this.duration,required this.level,required this.opponent});
 @override State<Play> createState()=>_PlayState();
}
class _PlayState extends State<Play> with WidgetsBindingObserver{
 late Battle b;late Timer timer;final arena=Arena();final watch=Stopwatch();
 int last=0;bool saved=false,leaving=false;final feedback=['',''];
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);reset();watch.start();timer=Timer.periodic(const Duration(milliseconds:32),(_){
  if(!mounted)return;final now=watch.elapsedMilliseconds;final delta=now-last;last=now;
  if(b.phase==Phase.paused||b.phase==Phase.ended)return;
  setState((){b.tick(delta);arena.energy=b.energy/100;});
  if(b.phase==Phase.ended)persist();
 });}
 void reset(){b=Battle(mode:widget.mode,world:widget.world,duration:widget.duration,level:widget.level,opponentLevel:widget.opponent);arena.energy=.5;arena.reduced=widget.progress.prefs.getBool('reduced')??false;saved=false;feedback[0]='';feedback[1]='';}
 void persist(){if(saved)return;saved=true;widget.progress.record(b);unawaited(widget.progress.save());}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed&&mounted){setState(()=>b.pause());}}
 @override void dispose(){timer.cancel();watch.stop();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 void answer(int p,String v){
  // Synchronise the monotonic clock at the input, not just the display frame.
  final now=watch.elapsedMilliseconds;
  setState((){b.tick(now-last);last=now;final result=b.answer(p,v);if(result!=null){
    feedback[p]=result?'Richtig!':'Richtig: ${b.tasks[p].answer}';
    if(widget.progress.prefs.getBool('sound')??true)unawaited(SystemSound.play(result?SystemSoundType.click:SystemSoundType.alert));
    if(widget.progress.prefs.getBool('haptics')??true)unawaited(result?HapticFeedback.selectionClick():HapticFeedback.lightImpact());
  }arena.energy=b.energy/100;});
  if(b.phase==Phase.ended)persist();
 }
 Future<void> leave()async{
  if(b.phase==Phase.ended){Navigator.pop(context);return;}
  setState(()=>b.pause());
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Runde verlassen?'),content:const Text('Diese Runde wird nicht gespeichert.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Weiterspielen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Verlassen'))]));
  if(!mounted)return;
  if(yes==true){setState(()=>leaving=true);WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)Navigator.pop(context);});}else{setState(()=>b.resume());}
 }
 bool get two=>widget.mode==Mode.duel||widget.mode==Mode.team;
 @override Widget build(BuildContext context)=>PopScope(canPop:leaving||b.phase==Phase.ended,onPopInvokedWithResult:(didPop,result){if(!didPop)unawaited(leave());},child:Scaffold(
  appBar:AppBar(title:Text(widget.world.label),leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:leave),actions:[if(b.phase!=Phase.ended)IconButton(icon:Icon(b.phase==Phase.paused?Icons.play_arrow:Icons.pause),onPressed:()=>setState((){if(b.phase==Phase.paused){b.resume();}else{b.pause();}}))]),
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
   Expanded(child:Center(child:Text(!running?(b.phase==Phase.paused?'Pausiert':'Bereit?'):!visible?q.preview:q.prompt,style:TextStyle(fontSize:box.maxHeight<230?18:25,fontWeight:FontWeight.w800),textAlign:TextAlign.center))),
   if(running&&visible)SizedBox(height:((box.maxHeight-80)*.62).clamp(62.0,145.0).toDouble(),child:GridView.count(physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:(box.maxWidth/2)/(((box.maxHeight-80)*.62).clamp(62.0,145.0)/2),mainAxisSpacing:3,crossAxisSpacing:5,children:q.options.map((v)=>FilledButton(style:FilledButton.styleFrom(backgroundColor:color,padding:const EdgeInsets.symmetric(horizontal:4)),onPressed:b.canAnswer(p)?()=>answer(p,v):null,child:FittedBox(fit:BoxFit.scaleDown,child:Text(v,style:const TextStyle(fontSize:19))))).toList())),
   SizedBox(height:21,child:Text(!running?'':b.locks[p]>b.elapsed?feedback[p]:b.pendingPlayer==p?'Warte …':'',style:const TextStyle(fontSize:13))),
  ])));
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
