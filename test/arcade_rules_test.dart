import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/game_engine/arcade_rules.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/question_generators/challenges.dart';
void main(){
 test('tower and race have different error penalties',(){
  final t=ArcadeRules(ArcadeKind.tower);t.correct(0);t.correct(0);t.wrong(0);expect(t.lanes[0].blocks,1);
  for(var i=0;i<9;i++)t.correct(0);expect(t.ended,true);expect(t.winner,0);
  final r=ArcadeRules(ArcadeKind.race);r.correct(1);r.wrong(1);expect(r.lanes[1].position,7);
 });
 test('rocket advances with elapsed time and consumes fuel',(){
  final r=ArcadeRules(ArcadeKind.rocket);r.correct(0);expect(r.lanes[0].position,0);
  r.tick(1000);expect(r.lanes[0].position,greaterThan(0));final fuel=r.lanes[0].fuel;r.wrong(0);expect(r.lanes[0].fuel,lessThan(fuel));
 });
 test('maze is connected and requires one key per step',(){
  for(var seed=0;seed<20;seed++){
   final r=ArcadeRules(ArcadeKind.maze,seed:seed);for(var i=0;i<20;i++)expect(r.maze.distance(i),inInclusiveRange(0,19));
   expect(r.move(0,Direction.right),false);
   for(var i=0;i<20&&!r.ended;i++){r.correct(0);r.autoAction(0);}expect(r.winner,0);
  }
 });
 test('chests require keys and cannot be reopened',(){
  final r=ArcadeRules(ArcadeKind.treasure);expect(r.openChest(0,2),false);r.correct(0);expect(r.openChest(0,2),true);expect(r.lanes[0].gems,3);expect(r.openChest(0,1),false);r.correct(0);expect(r.openChest(0,2),false);
 });
 test('boss retaliates unless team charges a shield',(){
  final r=ArcadeRules(ArcadeKind.boss,cooperative:true);r.correct(0);r.correct(1);r.tick(12000);expect(r.teamHp,5);r.tick(12000);expect(r.teamHp,4);while(!r.ended)r.correct(0);expect(r.bossHp,0);expect(r.winner,0);
 });
 test('word sprint requires unused letter tiles in the correct order',(){
  final b=Battle(mode:Mode.training,world:Challenge.wordSprint.world,duration:60,level:0,opponentLevel:0,questions:ChallengeQuestions(Challenge.wordSprint,1));
  b.tick(3000);final q=b.tasks[0];final used=<int>{};
  for(final letter in q.answer.split('')){final i=List.generate(q.board.length,(i)=>i).firstWhere((i)=>q.board[i]==letter&&!used.contains(i));used.add(i);b.tapCell(0,i);}
  expect(b.points[0],1);
 });
 test('battle waits for movement and respects pause',(){
  final b=Battle(mode:Mode.duel,world:Challenge.mazeBattle.world,duration:60,level:0,opponentLevel:0,skillName:'mazeBattle',questions:ChallengeQuestions(Challenge.mazeBattle,1));
  b.tick(3000);expect(b.answer(0,b.tasks[0].answer),true);expect(b.canAnswer(0),false);
  final dir=Direction.values.firstWhere((d)=>b.arcade!.maze.move(0,d)!=null);b.pause();expect(b.arcadeMove(0,dir),false);b.resume();expect(b.arcadeMove(0,dir),true);expect(b.canAnswer(0),true);
 });
}
