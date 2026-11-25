import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/learning/progress.dart';
import 'package:brain_clash/question_generators/challenges.dart';
void main(){
 test('hidden settings cannot affect unrelated games',(){
  final config=const MathOptions(negative:true,noCarry:true,division:DivisionStyle.remainder,table:20,factorDigits:4);
  final g=ChallengeQuestions(Challenge.arithmeticMix,2,config:config,random:Random(8));
  expect(g.config.negative,false);expect(g.config.noCarry,false);expect(g.config.division,DivisionStyle.exact);expect(g.config.factorDigits,0);
 });
 test('final clash has bounded overtime',(){
  final b=Battle(mode:Mode.duel,world:Challenge.addition.world,duration:30,level:0,opponentLevel:0,rule:BattleRule.finalClash);
  b.tick(33000);expect(b.finalRound,true);b.tick(30000);expect(b.phase,Phase.ended);expect(b.winner,isNull);
 });
 test('zero activity and wrong-only training cannot farm XP',()async{
  SharedPreferences.setMockInitialValues({});final p=Progress(await SharedPreferences.getInstance());
  final b=Battle(mode:Mode.training,world:Challenge.addition.world,duration:60,level:0,opponentLevel:0);
  b.tick(3000);b.finish();p.record(b);expect(p.current['rounds'],0);expect(p.current['xp'],0);
  final c=Battle(mode:Mode.training,world:Challenge.addition.world,duration:60,level:0,opponentLevel:0);
  c.tick(3000);c.answer(0,c.tasks[0].options.firstWhere((v)=>v!=c.tasks[0].answer));c.finish();p.record(c);expect(p.current['xp'],0);
 });
 test('a corrected retry is not a first attempt mastery success',()async{
  SharedPreferences.setMockInitialValues({});final p=Progress(await SharedPreferences.getInstance());
  final b=Battle(mode:Mode.training,world:Challenge.addition.world,duration:0,level:0,opponentLevel:0,skillName:'addition');
  b.tick(3000);final q=b.tasks[0];b.answer(0,q.options.firstWhere((v)=>v!=q.answer));b.tick(850);b.answer(0,q.answer);b.finish();p.record(b);
  final skill=(p.current['skills'] as Map)['addition'] as Map;
  expect((skill['sampleWindow'] as List).length,1);expect((skill['sampleWindow'] as List).first['ok'],false);
  expect(p.current['xp'],5);expect(p.current['dailyRight']??0,0);
 });

 test('deleted profile cannot inherit quick start or second-player checkpoint',()async{
  SharedPreferences.setMockInitialValues({});final prefs=await SharedPreferences.getInstance();final p=Progress(prefs);
  p.profiles['A']=p.fresh();p.profiles['B']=p.fresh();p.active='A';
  await prefs.setString(p.quickKey('lastGame'),'division');
  await prefs.setString(p.quickKey('lastSecondProfile'),'B');
  p.current['series']={'A|B|addition':[1,0,0]};
  p.active='B';await prefs.setString(p.quickKey('lastGame'),'addition');
  await p.deleteProfile('B');p.profiles['B']=p.fresh();p.active='B';
  expect(prefs.containsKey(p.quickKey('lastGame')),false);expect(p.current['xp'],0);
  p.active='A';expect(prefs.getString(p.quickKey('lastGame')),'division');
  expect(prefs.containsKey(p.quickKey('lastSecondProfile')),false);expect(p.current['series'],isEmpty);
  await p.save();final restored=Progress(prefs);expect(restored.active,'A');expect(restored.profiles.containsKey('B'),true);
 });
 test('solo victories never modify human duel rating',()async{
  SharedPreferences.setMockInitialValues({});final p=Progress(await SharedPreferences.getInstance());
  for(final mode in [Mode.solo,Mode.duel]){
   final b=Battle(mode:mode,world:Challenge.addition.world,duration:60,level:0,opponentLevel:0,rule:BattleRule.sprint);
   b.tick(3000);b.answer(0,b.tasks[0].answer);b.tick(101);b.finish(forcedWinner:0);p.record(b);
   if(mode==Mode.solo){expect(p.current['competitive'],isNull);expect((p.current['soloRating'] as Map)['rating'],1020);}
  }
  expect((p.current['competitive'] as Map)['rating'],1020);
  expect((p.current['soloRating'] as Map)['rating'],1020);
 });
}
