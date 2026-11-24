import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import 'package:flutter/services.dart';
import '../game_engine/arena.dart';
import '../audio/audio.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';
import '../question_generators/challenges.dart';
import '../widgets/memory_board.dart';
import '../widgets/character.dart';
import '../widgets/arcade.dart';
import '../widgets/arcade_stage.dart';

class Play extends StatefulWidget{
 final Progress progress;final Mode mode;final World world;final int duration,level,opponent;final bool numberEntry;final String secondProfile;
 final Challenge? challenge;final int digits,opponentDigits;final BattleRule rule;final MathOptions mathConfig;
 const Play({super.key,required this.progress,required this.mode,required this.world,required this.duration,required this.level,required this.opponent,this.numberEntry=false,this.secondProfile='',this.challenge,this.digits=1,this.opponentDigits=1,this.rule=BattleRule.tug,this.mathConfig=const MathOptions()});
 @override State<Play> createState()=>_PlayState();
}
class _PlayState extends State<Play> with WidgetsBindingObserver{
 late Battle b;late Timer timer;final arena=Arena();final watch=Stopwatch();
 int last=0,streak=0;int lastCountdown=3;bool saved=false,leaving=false,dialogOpen=false;final feedback=['',''];final typed=['',''];int earnedXp=0;
 final feedbackUntil=[0,0],feedbackEvent=[0,0],combo=[0,0];
 final feedbackCorrect=[true,true];
 final selectedAnswer=['',''];
 final lastSolution=['',''];
 bool get reduced=>widget.progress.prefs.getBool('reduced')??false;
 void showFeedback(int p,String message,bool correct){feedback[p]=message;feedbackCorrect[p]=correct;feedbackUntil[p]=b.elapsed+(correct?850:1200);feedbackEvent[p]++;}
 void syncArena(List<int> before){arena.energy=b.energy/100;arena.score=b.points[0]+b.points[1];for(var p=0;p<2;p++){if(b.points[p]>before[p]){arena.hit(p);combo[p]++;showFeedback(p,combo[p]>=3?'COMBO ×${combo[p]} · +1':'+1 · Richtig!',true);}}}
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);reset();watch.start();timer=Timer.periodic(const Duration(milliseconds:32),(_){
  if(!mounted)return;final now=watch.elapsedMilliseconds;final delta=now-last;last=now;
  if(b.phase==Phase.paused||b.phase==Phase.ended)return;
  final before=b.phase;final oldScore=b.points[0]+b.points[1];final beforePoints=List<int>.of(b.points);
  setState((){b.tick(delta);syncArena(beforePoints);});
  if(before==Phase.countdown&&b.phase==Phase.playing){unawaited(GameAudio(widget.progress.prefs).effect('start'));}
  if(b.phase==Phase.countdown){final count=(b.countdown/1000).ceil();if(count!=lastCountdown){lastCountdown=count;unawaited(GameAudio(widget.progress.prefs).effect('countdown'));}}
  if(b.points[0]+b.points[1]>oldScore&&b.phase==Phase.playing)unawaited(GameAudio(widget.progress.prefs).effect('energy'));
  if(b.phase==Phase.ended)persist();
 });}
 void reset(){b=Battle(mode:widget.mode,world:widget.world,duration:widget.duration,level:widget.level,opponentLevel:widget.opponent,questions:widget.challenge==null?(widget.mode==Mode.training?ReviewQuestions(widget.progress.dueQuestions(widget.world)):null):ChallengeQuestions(widget.challenge!,widget.digits,config:widget.mathConfig,reviews:widget.mode==Mode.training?widget.progress.dueQuestions(widget.world):const []),opponentQuestions:widget.challenge!=null&&widget.opponentDigits!=widget.digits?ChallengeQuestions(widget.challenge!,widget.opponentDigits,config:widget.mathConfig):null,sameQuestions:widget.digits==widget.opponentDigits&&widget.challenge!=Challenge.pairs&&widget.challenge?.arcadeStage!=true,rule:widget.rule,numberEntry:widget.numberEntry);arena.energy=.5;arena.leftAvatar=widget.progress.current['avatar'] as int;arena.rightAvatar=(widget.progress.profiles[widget.secondProfile] as Map?)?['avatar'] as int? ??5;arena.training=widget.mode==Mode.training;arena.team=widget.mode==Mode.team;arena.reduced=widget.progress.prefs.getBool('reduced')??false;saved=false;typed[0]='';typed[1]='';earnedXp=0;streak=0;lastCountdown=3;arena.score=0;arena.clearEffects();for(var i=0;i<2;i++){feedbackUntil[i]=0;feedbackEvent[i]++;combo[i]=0;selectedAnswer[i]='';lastSolution[i]='';}arena.skin=widget.progress.current['arena'] as int? ?? 0;arena.effect=widget.progress.current['effect'] as int? ?? 0;arena.tint=widget.progress.current['color'] as int? ?? 0;arena.background=widget.progress.current['background'] as int? ?? 0;arena.victor=null;arena.failed=-1;feedback[0]='';feedback[1]='';}
 void persist(){arena.victor=b.winner;if(saved)return;saved=true;final before=widget.progress.current['xp'] as int;widget.progress.record(b);if(two&&widget.secondProfile.isNotEmpty&&widget.secondProfile!=widget.progress.active){widget.progress.record(b,player:1,profile:widget.secondProfile);}final after=widget.progress.current['xp'] as int;earnedXp=after-before;unawaited(widget.progress.save());final audio=GameAudio(widget.progress.prefs);unawaited(audio.effect(widget.mode==Mode.training?'right':b.winner==null?'draw':b.winner==0?'win':'loss'));if([50,150,300,600,1000].any((n)=>before<n&&after>=n))unawaited(audio.effect('unlock'));}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed&&mounted){setState(()=>b.pause());}}
 @override void dispose(){timer.cancel();watch.stop();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 void answer(int p,String v,Question expected,{int? cell}){
  // Synchronise the monotonic clock at the input, not just the display frame.
  final now=watch.elapsedMilliseconds;
  setState((){final beforePoints=List<int>.of(b.points);b.tick(now-last);last=now;final result=identical(b.tasks[p],expected)?(cell==null?b.answer(p,v):b.tapCell(p,cell)):null;if(result!=null){
    typed[p]='';
    if(!result){arena.failed=p;combo[p]=0;selectedAnswer[p]=v;lastSolution[p]='';}
    else{lastSolution[p]=expected.world==World.math&&expected.prompt.contains('?')?expected.prompt.replaceFirst('?',expected.answer):expected.answer;}
    showFeedback(p,result?'Richtig!':widget.mode==Mode.training?'Richtig: ${expected.answer}':'Noch einmal versuchen',result);
    final audio=GameAudio(widget.progress.prefs);
    if(p==0){streak=result?streak+1:0;}
    unawaited(audio.effect(result?(p==0&&streak%5==0?'streak':'right'):'wrong'));
    if(widget.progress.prefs.getBool('haptics')??true)unawaited(result?HapticFeedback.selectionClick():HapticFeedback.lightImpact());
  }syncArena(beforePoints);});
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
  appBar:AppBar(title:Text(widget.challenge?.label??widget.world.label),leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:leave),actions:[if(b.phase!=Phase.ended)IconButton(icon:Icon(b.phase==Phase.paused?Icons.play_arrow:Icons.pause),onPressed:()=>setState((){if(b.phase==Phase.paused){last=watch.elapsedMilliseconds;b.resume();}else{b.pause();}}))]),
  body:ArcadeBackdrop(child:SafeArea(child:b.phase==Phase.ended?result():LayoutBuilder(builder:(context,space)=>Column(children:[
   if(two)Expanded(child:RotatedBox(quarterTurns:2,child:panel(1))),
   Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:3),child:Row(children:[
    Expanded(child:scoreChip(0)),
    const SizedBox(width:7),
    Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),decoration:BoxDecoration(color:const Color(0xff101b32),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white24)),child:Column(mainAxisSize:MainAxisSize.min,children:[
     Text(b.phase==Phase.countdown?'${(b.countdown/1000).ceil()}':b.phase==Phase.paused?'PAUSE':b.unlimited?'∞':'${(b.remaining/1000).ceil()} s',style:TextStyle(color:b.remaining<10000&&!b.unlimited?arcadeOrange:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
     if(!b.unlimited)SizedBox(width:60,child:LinearProgressIndicator(value:(b.remaining/(widget.duration*1000)).clamp(0.0,1.0),color:arcadeOrange,backgroundColor:Colors.white24,minHeight:3)),
    ])),
    const SizedBox(width:7),
    Expanded(child:scoreChip(1)),
   ])),
   Padding(padding:const EdgeInsets.symmetric(horizontal:10),child:ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(height:two?(space.maxHeight*.12).clamp(42.0,78.0).toDouble():(space.maxHeight*.29).clamp(68.0,220.0).toDouble(),child:Stack(fit:StackFit.expand,children:[
    if(widget.challenge?.arcadeStage==true)ArcadeStage(challenge:widget.challenge!,points:b.points,remaining:b.remaining,reduced:reduced)else GameWidget(game:arena),
    if(b.phase==Phase.countdown||b.phase==Phase.paused)IgnorePointer(child:ColoredBox(color:Colors.black38,child:Center(child:Text(b.phase==Phase.paused?'PAUSE':'${(b.countdown/1000).ceil()}',style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w900))))),
   ])))),
   if(widget.mode==Mode.team)Padding(padding:const EdgeInsets.only(top:3),child:Text('Monster-Energie: ${(100-b.energy)*2} %',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))),
   Expanded(child:panel(0)),
   if(widget.mode==Mode.training)TextButton(onPressed:()=>setState((){b.finish();persist();}),child:const Text('Training beenden')),
  ]))))));
 Widget scoreChip(int p){
  final color=p==0?arcadeBlue:arcadeOrange;
  final label=p==0?'P1':widget.mode==Mode.solo?'BOT':widget.mode==Mode.training?'XP':'P2';
  final score=p==1&&widget.mode==Mode.training?b.points[0]*10:b.points[p];
  if(widget.rule==BattleRule.hearts&&(widget.mode==Mode.duel||widget.mode==Mode.solo))return Container(padding:const EdgeInsets.symmetric(vertical:8),decoration:BoxDecoration(color:color.withAlpha(25),borderRadius:BorderRadius.circular(13),border:Border.all(color:color.withAlpha(100))),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(width:3),for(var i=0;i<3;i++)Icon(i<3-b.misses[p]?Icons.favorite:Icons.favorite_border,color:color,size:15),const SizedBox(width:3),Text('$score',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800))]));
  return Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:color.withAlpha(25),border:Border.all(color:color.withAlpha(120)),borderRadius:BorderRadius.circular(13)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(p==0?Icons.bolt:widget.mode==Mode.training?Icons.star:Icons.shield,color:color,size:17),const SizedBox(width:4),Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(width:5),Text(widget.rule==BattleRule.race?'$score/5':'$score',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))]));
 }

 Widget panel(int p){
  final q=b.tasks[p],visible=b.visible(p);
  final running=b.phase==Phase.playing;
  final color=p==0?const Color(0xff2359c5):const Color(0xffb44818);
  final activeFeedback=running&&b.elapsed<feedbackUntil[p];
  final isMemory=q.interaction==Interaction.sequence||q.interaction==Interaction.pairs;
  return Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),child:LayoutBuilder(builder:(context,box){
   final small=box.maxHeight<220;
   final feedbackHeight=small?23.0:36.0;
   final prompt=!running?(b.phase==Phase.paused?'Pausiert':'Bereit?'):!visible?(isMemory?'Merke dir die Felder':q.preview):q.prompt;
   return Column(children:[
    SizedBox(height:small?18:25,child:Row(children:[Icon([Icons.calculate,Icons.extension,Icons.psychology,Icons.track_changes,Icons.translate,Icons.shuffle][q.world.index],color:p==0?arcadeBlue:arcadeOrange,size:16),const SizedBox(width:5),Expanded(child:Text('${p==0?widget.progress.active:widget.secondProfile.isEmpty?'P2':widget.secondProfile} · ${q.world.label}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))),if(combo[p]>=3)Text('🔥 ×${combo[p]}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))])),
    Expanded(child:Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface.withAlpha(220),borderRadius:BorderRadius.circular(15),border:Border.all(color:activeFeedback?(feedbackCorrect[p]?arcadeGreen:arcadeRed).withAlpha(160):color.withAlpha(95))),child:Center(child:FittedBox(fit:BoxFit.scaleDown,child:Text(prompt,style:TextStyle(fontSize:small?23:34,fontWeight:FontWeight.w900),textAlign:TextAlign.center))))),
    const SizedBox(height:4),
    if(running&&isMemory)Expanded(flex:3,child:MemoryBoard(question:q,battle:b,player:p,onTap:(i)=>answer(p,'',q,cell:i)))
    else if(running&&q.interaction==Interaction.signal&&!visible)Expanded(flex:2,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:arcadeRed),onPressed:()=>answer(p,q.answer,q),child:const Text('WARTEN!')))
    else if(running&&visible&&widget.numberEntry&&q.world==World.math&&double.tryParse(q.answer)!=null)numberPad(p,q,box.maxHeight,color)
    else if(running&&visible)Expanded(flex:2,child:LayoutBuilder(builder:(context,grid)=>GridView.builder(padding:EdgeInsets.zero,physics:const NeverScrollableScrollPhysics(),itemCount:q.options.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisExtent:((grid.maxHeight-(q.options.length>2?5:0))/(q.options.length>2?2:1)).clamp(12.0,100.0).toDouble(),mainAxisSpacing:5,crossAxisSpacing:6),itemBuilder:(context,i){
      final v=q.options[i];final wrong=activeFeedback&&!feedbackCorrect[p]&&selectedAnswer[p]==v&&b.locks[p]>b.elapsed;
      return FilledButton(style:FilledButton.styleFrom(backgroundColor:color,disabledBackgroundColor:wrong?const Color(0xffa42d49):color.withAlpha(100),disabledForegroundColor:Colors.white70,padding:const EdgeInsets.symmetric(horizontal:5),minimumSize:Size.zero,tapTargetSize:MaterialTapTargetSize.shrinkWrap,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13),side:BorderSide(color:wrong?arcadeRed:Colors.white24))),onPressed:b.canAnswer(p)?()=>answer(p,v,q):null,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[if(wrong)const Icon(Icons.close,size:16),Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:Text(v,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800))))]));
    }))),
    SizedBox(height:feedbackHeight,child:Center(child:activeFeedback?AnswerFeedback(message:feedbackCorrect[p]&&lastSolution[p].isNotEmpty&&(!b.shared||b.pendingPlayer==null)?'${feedback[p]} · ${lastSolution[p]}':feedback[p],correct:feedbackCorrect[p],reduced:reduced,event:feedbackEvent[p]):b.pendingPlayer==p?const Text('Warte …',style:TextStyle(fontSize:12)):const SizedBox.shrink())),
   ]);
  }));
 }
 Widget numberPad(int p,Question q,double available,Color color){
  final enabled=b.canAnswer(p);
  return Expanded(flex:3,child:Column(children:[
    Text(typed[p].isEmpty?'?':typed[p],style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
    Expanded(child:LayoutBuilder(builder:(context,space)=>GridView(physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,mainAxisExtent:((space.maxHeight-9)/4).clamp(15.0,100.0).toDouble(),mainAxisSpacing:3,crossAxisSpacing:4),children:['1','2','3','4','5','6','7','8','9','⌫','0','-','.','OK'].map((key)=>FilledButton(style:FilledButton.styleFrom(backgroundColor:color,padding:EdgeInsets.zero),onPressed:!enabled?null:(){
      if(key=='OK'){if(typed[p].isNotEmpty)answer(p,typed[p],q);return;}
      setState((){if(key=='⌫'){if(typed[p].isNotEmpty)typed[p]=typed[p].substring(0,typed[p].length-1);}else if(typed[p].length<10){typed[p]+=key;}});
    },child:Text(key))).toList()))),
  ]));
 }
 Widget result(){
  final a=b.attempts.where((a)=>a.player==0).toList(),correct=a.where((a)=>a.correct).length;
  final title=widget.mode==Mode.training?'Training abgeschlossen':widget.mode==Mode.team?(b.winner==0?'Gemeinsam gewonnen!':'Gut gekämpft!'):b.winner==null?'Unentschieden':b.winner==0?'Spieler 1 gewinnt!':widget.mode==Mode.solo?'Der Gegner gewinnt':'Spieler 2 gewinnt!';
  return ListView(padding:const EdgeInsets.all(24),children:[
   Center(child:VictoryAvatar(index:b.winner==1?5:widget.progress.current['avatar'] as int,animate:!(widget.progress.prefs.getBool('reduced')??false))),Text(title,textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineSmall),
   const SizedBox(height:12),if(two)Text('${b.points[0]}  VS  ${b.points[1]}',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineLarge),if(two)Text('Spieler 2: ${b.points[1]} Punkte · ${b.misses[1]} Fehler',textAlign:TextAlign.center),
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[AccuracyRing(value:a.isEmpty?0:correct/a.length,reduced:reduced),const SizedBox(width:16),Flexible(child:Column(children:[MetricTile(label:'Richtige Antworten',value:'$correct',icon:Icons.check_circle,color:arcadeGreen),const SizedBox(height:7),MetricTile(label:'XP',value:'+$earnedXp',icon:Icons.bolt,color:arcadeOrange)]))]),
   if(a.any((a)=>!a.correct))ExpansionTile(title:const Text('Fehler ansehen'),children:a.where((a)=>!a.correct).map((a)=>ListTile(title:Text(a.question.prompt),subtitle:Text(a.question.explanation))).toList()),
   const SizedBox(height:18),FilledButton(onPressed:()=>setState(reset),child:const Text('Revanche')),
   OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Neues Spiel')),
   TextButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Hauptmenü')),
  ]);
 }
}
