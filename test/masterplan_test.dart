import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/learning/engagement.dart';
void main(){
 test('expanded maths generators have distinct answers',(){
  for(final game in Challenge.values){
   final g=ChallengeQuestions(game,4,random:Random(42));
   for(var i=0;i<200;i++){final q=g.make(game.world,2);expect(q.options.toSet().length,q.options.length);expect(q.options.where((v)=>v==q.answer).length,1);}
  }
 });
 test('signed arithmetic, selected table, division styles and two choices',(){
  for(final style in DivisionStyle.values){
   final g=ChallengeQuestions(Challenge.division,3,config:MathOptions(division:style,choiceCount:2),random:Random(4));
   for(var i=0;i<100;i++){final q=g.make(Challenge.division.world,1);expect(q.options.length,2);expect(q.options,contains(q.answer));}
  }
  final table=ChallengeQuestions(Challenge.bigTable,1,config:const MathOptions(table:17));
  expect(table.make(Challenge.bigTable.world,1).prompt,startsWith('17 × '));
  final signed=ChallengeQuestions(Challenge.subtraction,1,config:const MathOptions(negative:true),random:Random(8));
  expect(List.generate(100,(_)=>signed.make(Challenge.subtraction.world,1)).any((q)=>int.parse(q.answer)<0),isTrue);
 });
 test('daily rewards only once per day and ranks are transparent',(){
  final p=<String,dynamic>{};final date=DateTime(2026,1,1);
  expect(DailyProgress.add(p,7,at:date),0);expect(DailyProgress.add(p,3,at:date),75);
  expect(DailyProgress.add(p,10,at:date),0);expect(DailyProgress.count(p,at:date),10);
  expect(DailyProgress.count(p,at:date.add(const Duration(days:1))),0);
  expect(rankFor(1500),'Gold');
 });
 test('premature reaction incurs a single miss',(){
  final b=Battle(mode:Mode.duel,world:Challenge.reaction.world,duration:60,level:0,opponentLevel:0,questions:ChallengeQuestions(Challenge.reaction,1));
  b.tick(3000);expect(b.answer(0,b.tasks[0].answer),isFalse);expect(b.answer(0,b.tasks[0].answer),isNull);expect(b.misses[0],1);
 });
 test('sort and target games require the correct interaction',(){
  final b=Battle(mode:Mode.training,world:Challenge.numberSort.world,duration:0,level:0,opponentLevel:0,questions:ChallengeQuestions(Challenge.numberSort,1,random:Random(9)));
  b.tick(3000);expect(b.sorted[0].join(' '),isNot(b.tasks[0].answer));
  final desired=b.tasks[0].answer.split(' ');
  for(var i=0;i<desired.length;i++){final old=b.sorted[0].indexOf(desired[i]);if(old!=i)b.moveCell(0,old,i);}
  expect(b.submitSort(0),true);expect(b.points[0],1);
  final target=Battle(mode:Mode.training,world:Challenge.targetHunt.world,duration:0,level:0,opponentLevel:0,questions:ChallengeQuestions(Challenge.targetHunt,1));
  target.tick(3000);expect(target.tapCell(0,target.tasks[0].board.indexOf(target.tasks[0].answer)),true);
 });
 test('perfect battle ends on the first wrong answer',(){
  final b=Battle(mode:Mode.duel,world:Challenge.addition.world,duration:60,level:0,opponentLevel:0,rule:BattleRule.perfect,questions:ChallengeQuestions(Challenge.addition,1));
  b.tick(3000);b.answer(0,b.tasks[0].options.firstWhere((s)=>s!=b.tasks[0].answer));expect(b.winner,1);expect(b.phase,Phase.ended);
 });
}
