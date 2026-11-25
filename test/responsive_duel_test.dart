
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/screens/play.dart';
import 'package:brain_clash/learning/progress.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/question_generators/questions.dart';
void main(){
 for(final size in [const Size(390,844),const Size(844,390),const Size(1024,768)]){
  testWidgets('two pointer taps work at '+size.toString(),(tester)async{
   tester.view.physicalSize=size;tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   SharedPreferences.setMockInitialValues({'reduced':true,'sound':false,'haptics':false});
   final progress=Progress(await SharedPreferences.getInstance());
   var now=0;
   await tester.pumpWidget(MaterialApp(home:Play(progress:progress,mode:Mode.duel,world:World.focus,duration:60,level:0,opponent:0,challenge:Challenge.tapBattle,rule:BattleRule.sprint,clockMs:()=>now)));
   now=3100;await tester.pump(const Duration(milliseconds:40));
   final a=find.byKey(const ValueKey('tap-player-0')),b=find.byKey(const ValueKey('tap-player-1'));
   expect(a,findsOneWidget);expect(b,findsOneWidget);
   for(var i=0;i<5;i++){
    now+=100;final first=await tester.startGesture(tester.getCenter(a),pointer:1);final second=await tester.startGesture(tester.getCenter(b),pointer:2);
    await first.up();await second.up();await tester.pump(const Duration(milliseconds:40));
   }
   expect(find.text('1'),findsAtLeastNWidgets(2));expect(tester.takeException(),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
}
