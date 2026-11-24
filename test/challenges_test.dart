import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/question_generators/questions.dart';
import 'package:brain_clash/game_engine/battle.dart';
void main(){
 test('arithmetic operations use selected digits and produce exact answers',(){
  for(var digits=1;digits<=3;digits++){
   for(final type in [Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division]){
    final g=ChallengeQuestions(type,digits,random:Random(42));
    for(var i=0;i<300;i++){
     final q=g.make(World.math,1);
     final m=RegExp(r'^(\d+) ([+−×÷]) (\d+) = \?$').firstMatch(q.prompt)!;
     final a=int.parse(m[1]!),b=int.parse(m[3]!);
     expect(a.toString().length,digits);
     if(type!=Challenge.division)expect(b.toString().length,digits);
     final answer=switch(type){Challenge.addition=>a+b,Challenge.subtraction=>a-b,Challenge.multiplication=>a*b,_=>a~/b};
     if(type==Challenge.division)expect(a%b,0);
     expect(q.answer,'$answer');expect(q.options.toSet().length,4);
    }
   }
  }
 });
 test('all games generate unique selectable answers',(){
  for(final type in Challenge.values){final g=ChallengeQuestions(type,3,random:Random(11));for(var i=0;i<100;i++){final q=g.make(type.world,1);expect(q.options.toSet().length,q.options.length);expect(q.options.where((v)=>v==q.answer).length,1);}}
 });
 test('independent digit levels do not share a question',(){
  final b=Battle(mode:Mode.duel,world:World.math,duration:60,level:1,opponentLevel:1,questions:ChallengeQuestions(Challenge.addition,1),opponentQuestions:ChallengeQuestions(Challenge.addition,3),sameQuestions:false);
  expect(b.shared,isFalse);expect(b.tasks[0].prompt.split(' ').first.length,1);expect(b.tasks[1].prompt.split(' ').first.length,3);
 });
 Battle make(BattleRule rule)=>Battle(mode:Mode.duel,world:World.math,duration:30,level:1,opponentLevel:1,rule:rule,questions:ChallengeQuestions(Challenge.addition,1));
 test('race ends at five awarded points, not before',(){
  final b=make(BattleRule.race);b.tick(3000);
  for(var i=0;i<5;i++){b.answer(0,b.tasks[0].answer);b.tick(101);if(i<4)expect(b.phase,Phase.playing);}
  expect(b.winner,0);expect(b.points[0],5);expect(b.phase,Phase.ended);
 });
 test('sprint does not end early at ten points',(){
  final b=make(BattleRule.sprint);b.tick(3000);for(var i=0;i<11;i++){b.answer(0,b.tasks[0].answer);b.tick(101);}
  expect(b.phase,Phase.playing);b.tick(30000);expect(b.winner,0);
 });
 test('three mistakes lose hearts duel and cooldown prevents spam',(){
  final b=make(BattleRule.hearts);b.tick(3000);for(var i=0;i<3;i++){final wrong=b.tasks[0].options.firstWhere((v)=>v!=b.tasks[0].answer);b.answer(0,wrong);expect(b.answer(0,wrong),isNull);b.tick(900);}
  expect(b.phase,Phase.ended);expect(b.winner,1);expect(b.misses[0],3);
 });
}
