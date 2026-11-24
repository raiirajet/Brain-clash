import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/widgets/character.dart';
import 'package:brain_clash/widgets/mode_art.dart';
import 'package:brain_clash/widgets/battle_effects.dart';
import 'dart:ui' as ui;
void main(){
 testWidgets('all character and mode artwork paints at compact sizes',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Wrap(children:[for(var i=0;i<6;i++) AvatarArt(index:i,size:48),for(var i=0;i<4;i++) ModeArt(mode:i,avatar:i)]))));
  expect(tester.takeException(),isNull);
 });
 test('all six effects and three stages paint without throwing',(){
  final recorder=ui.PictureRecorder();final canvas=Canvas(recorder);
  for(var skin=0;skin<3;skin++)drawStage(canvas,const Size(340,90),skin,0,false);
  for(var i=0;i<6;i++){for(final t in [0.0,.4,.8,1.0])drawAttack(canvas,const Offset(20,40),const Offset(200,40),t,Colors.cyan,i,24);}
  recorder.endRecording().dispose();
 });
}
