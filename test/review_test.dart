import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/learning/progress.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/question_generators/questions.dart';
void main(){
 test('incorrect answer becomes due and correct retrieval schedules next day',() async {
  SharedPreferences.setMockInitialValues({});
  final p=Progress(await SharedPreferences.getInstance());
  final now=DateTime(2026,1,1);
  final b=Battle(mode:Mode.training,world:World.math,duration:0,level:0,opponentLevel:0);
  b.tick(3000);
  final q=b.tasks[0];
  b.answer(0,q.options.firstWhere((v)=>v!=q.answer));
  p.updateReviews(b,at:now);
  expect(p.dueQuestions(World.math,at:now).single.key,q.key);
  final r=Battle(mode:Mode.training,world:World.math,duration:0,level:0,opponentLevel:0,questions:ReviewQuestions([q]));
  r.tick(3000);
  r.answer(0,q.answer);
  p.updateReviews(r,at:now);
  expect(p.dueQuestions(World.math,at:now),isEmpty);
  expect(p.dueQuestions(World.math,at:now.add(const Duration(days:1))).single.key,q.key);
 });
}
