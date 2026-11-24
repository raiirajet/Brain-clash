import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/widgets/arcade.dart';
void main(){
 testWidgets('correct feedback shows a check and point text without animation in reduced mode',(tester)async{
  await tester.pumpWidget(const MaterialApp(home:Scaffold(body:AnswerFeedback(message:'+1 · Richtig!',correct:true,reduced:true,event:1))));
  expect(find.byIcon(Icons.check_circle),findsOneWidget);
  expect(find.text('+1 · Richtig!'),findsOneWidget);
 });
 testWidgets('error feedback uses a distinct icon',(tester)async{
  await tester.pumpWidget(const MaterialApp(home:Scaffold(body:AnswerFeedback(message:'Noch einmal versuchen',correct:false,reduced:true,event:2))));
  expect(find.byIcon(Icons.info_outline),findsOneWidget);
 });
 testWidgets('arcade tile remains tappable',(tester)async{
  var tapped=false;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:SizedBox(width:180,height:120,child:ArcadeTile(label:'Training',icon:Icons.psychology,color:arcadeBlue,onTap:()=>tapped=true)))));
  await tester.tap(find.text('Training'));
  expect(tapped,isTrue);
 });
}
