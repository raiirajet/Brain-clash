import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/questions.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 test('each question has four unique options and one answer',(){
  final gen=Questions(Random(7));
  for(final w in World.values){for(var level=0;level<4;level++){for(var i=0;i<200;i++){
   final q=gen.make(w,level);expect(q.options.toSet().length,4);expect(q.options.where((x)=>x==q.answer).length,1);
  }}}
 });
 test('shared tie, cooldown, pause, victory',(){
  final b=Battle(mode:Mode.duel,world:World.math,duration:60,level:0,opponentLevel:0);
  b.tick(3000);
  b.answer(0,b.tasks[0].answer);b.tick(90);b.answer(1,b.tasks[1].answer);expect(b.energy,50);
  b.answer(0,b.tasks[0].options.firstWhere((s)=>s!=b.tasks[0].answer));expect(b.answer(0,b.tasks[0].answer),isNull);
  b.tick(900);b.pause();final t=b.time;b.tick(2000);expect(b.time,t);b.resume();
  for(var i=0;i<10;i++){b.answer(0,b.tasks[0].answer);b.tick(101);}
  expect(b.energy,100);expect(b.phase,Phase.ended);expect(b.winner,0);
 });
 test('adapt only after sufficient sample',(){expect(Progress.adapt(1,19,19),1);expect(Progress.adapt(1,18,20),2);expect(Progress.adapt(1,12,20),0);});
}
