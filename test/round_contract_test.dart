import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/question_generators/questions.dart';

Battle match(Challenge game,{Mode mode=Mode.training,BattleRule rule=BattleRule.tug,int seconds=90,bool timed=false,bool shared=true})=>Battle(
 mode:mode,world:game.world,duration:seconds,level:0,opponentLevel:0,rule:rule,skillName:game.name,
 questions:ChallengeQuestions(game,1,random:Random(33)),sameQuestions:shared,timedArcade:timed,
 fuseMs:game==Challenge.numberBomb?8000:0,random:Random(22));

void solve(Battle b,int p){
 if(b.phase!=Phase.playing)return;
 final a=b.arcade;
 if(a?.waiting(p)==true){a!.autoAction(p);b.checkArcade();return;}
 if(!b.visible(p))b.tick(b.ready[p]-b.elapsed);
 if(!b.canAnswer(p))return;
 final q=b.tasks[p];
 switch(q.interaction){
  case Interaction.target:b.tapCell(p,q.board.indexOf(q.answer));break;
  case Interaction.tap:for(var i=0;i<int.parse(q.answer);i++)b.tapCell(p,0);break;
  case Interaction.sequence:for(final v in q.board)b.tapCell(p,int.parse(v));break;
  case Interaction.pairs:
   final used=<int>{};
   for(var i=0;i<q.board.length;i++){if(used.contains(i))continue;final j=List.generate(q.board.length,(j)=>j).firstWhere((j)=>j!=i&&q.board[j]==q.board[i]);used.add(i);used.add(j);b.tapCell(p,i);b.tapCell(p,j);}
   break;
  case Interaction.word:
   final used=<int>{};
   for(final v in q.answer.split('')){final i=List.generate(q.board.length,(i)=>i).firstWhere((i)=>q.board[i]==v&&!used.contains(i));used.add(i);b.tapCell(p,i);}
   break;
  case Interaction.sort:
   final target=q.answer.split(' ');
   for(var i=0;i<target.length;i++){final old=b.sorted[p].indexOf(target[i]);if(old!=i)b.moveCell(p,old,i);}
   b.submitSort(p);break;
  default:b.answer(p,q.answer);break;
 }
}
void main(){
 for(final game in Challenge.values){
  test('90 second training remains playable: '+game.name,(){
   final b=match(game);b.tick(3000);expect(b.remaining,90000);
   expect(b.canAnswer(1),false);expect(b.answer(1,b.tasks[1].answer),isNull);
   for(var i=0;i<22&&b.remaining>7000;i++){solve(b,0);b.tick(110);expect(b.phase,Phase.playing,reason:game.name);}
   expect(b.points[0],greaterThan(0));b.tick(b.remaining-1);expect(b.phase,Phase.playing);
   b.tick(1);expect(b.phase,Phase.ended);expect(b.finishReason,FinishReason.time);expect(b.time,90000);expect(b.winner,isNull);
  });
 }
 for(final seconds in [30,60,90,120]){
  test('sprint preserves selected duration '+seconds.toString(),(){
   final b=match(Challenge.addition,mode:Mode.duel,rule:BattleRule.sprint,seconds:seconds);
   b.tick(3000);for(var i=0;i<12;i++){solve(b,0);b.tick(101);}
   expect(b.phase,Phase.playing);b.tick(b.remaining);expect(b.time,seconds*1000);expect(b.winner,0);expect(b.finishReason,FinishReason.time);
  });
 }
 test('countdown overshoot, pause, no late answers',(){
  final b=match(Challenge.addition);b.tick(3100);expect(b.time,100);
  b.pause();b.tick(10000);expect(b.time,100);b.resume();b.tick(100000);expect(b.time,90000);expect(b.answer(0,b.tasks[0].answer),isNull);
 });
 test('rocket, tower, race, treasure, maze and escape can loop in training',(){
  for(final game in [Challenge.mathTower,Challenge.mathRace,Challenge.rocketRace,Challenge.treasureRush,Challenge.mazeBattle,Challenge.logicEscape]){
   final b=match(game,seconds:0);b.tick(3000);
   for(var i=0;i<60&&b.arcade!.completed[0]==0;i++){solve(b,0);b.tick(game==Challenge.rocketRace?1000:100);}
   expect(b.phase,Phase.playing);expect(b.arcade!.completed[0],greaterThan(0),reason:game.name);
  }
 });
 test('boss training continues after defeat and victory',(){
  final b=match(Challenge.bossBattle,seconds:0);b.tick(3000);
  for(var i=0;i<5;i++)b.arcade!.wrong(0);
  expect(b.arcade!.teamHp,5);expect(b.phase,Phase.playing);
  for(var i=0;i<15;i++)b.arcade!.correct(0);
  expect(b.arcade!.completed[0],greaterThan(0));expect(b.phase,Phase.playing);
 });
 test('objective race can finish early or use full duration',(){
  final early=match(Challenge.mathRace,mode:Mode.duel);early.tick(3000);
  for(var i=0;i<9;i++)solve(early,0);expect(early.phase,Phase.ended);expect(early.finishReason,FinishReason.goal);
  final timed=match(Challenge.mathRace,mode:Mode.duel,timed:true);timed.tick(3000);
  for(var i=0;i<18;i++)solve(timed,0);expect(timed.phase,Phase.playing);expect(timed.arcade!.completed[0],2);
  timed.tick(90000);expect(timed.finishReason,FinishReason.time);expect(timed.winner,0);
 });
 test('number bomb errors start fresh fuses; no phantom player',(){
  final b=match(Challenge.numberBomb);b.tick(3000);b.tick(8000);expect(b.misses,[1,0]);
  b.tick(849);expect(b.canAnswer(0),false);b.tick(1);expect(b.canAnswer(0),true);
  b.tick(7999);expect(b.misses,[1,0]);b.tick(1);expect(b.misses,[2,0]);expect(b.phase,Phase.playing);
 });
 test('all competitive rules have explicit end conditions',(){
  for(final rule in BattleRule.values){
   final b=match(Challenge.addition,mode:Mode.duel,rule:rule);b.tick(3000);
   if(rule==BattleRule.hearts||rule==BattleRule.perfect){
    for(var i=0;i<(rule==BattleRule.hearts?3:1);i++){b.answer(0,b.tasks[0].options.firstWhere((v)=>v!=b.tasks[0].answer));b.tick(851);}
    expect(b.winner,1);expect(b.finishReason,rule==BattleRule.hearts?FinishReason.hearts:FinishReason.mistake);
   }else if(rule==BattleRule.finalClash){
    b.tick(90000);expect(b.finalRound,true);solve(b,1);b.tick(101);expect(b.winner,1);expect(b.finishReason,FinishReason.finalClash);
   }else{
    final target=switch(rule){BattleRule.race=>5,BattleRule.race10||BattleRule.tug=>10,BattleRule.speed=>1,_=>15};
    for(var i=0;i<target;i++){solve(b,0);b.tick(101);}
    if(rule==BattleRule.sprint){expect(b.phase,Phase.playing);b.tick(b.remaining);}
    expect(b.winner,0);expect(b.phase,Phase.ended);
   }
  }
 });
 test('speed ties replay even with independent boards',(){
  final b=match(Challenge.tapBattle,mode:Mode.duel,rule:BattleRule.speed,shared:false);b.tick(3000);
  solve(b,0);b.tick(50);solve(b,1);expect(b.phase,Phase.playing);expect(b.points,[0,0]);
  solve(b,1);b.tick(101);expect(b.winner,1);
 });
 test('all generators across four digit levels and difficulty tiers',(){
  for(final game in Challenge.values){for(var digits=1;digits<=4;digits++){for(var level=0;level<4;level++){
   final g=ChallengeQuestions(game,digits,random:Random(digits*10+level));
   for(var n=0;n<10;n++){final q=g.make(game.world,level);expect(q.options.toSet().length,q.options.length,reason:game.name);expect(q.options.where((v)=>v==q.answer).length,1);}
  }}}
 });
}
