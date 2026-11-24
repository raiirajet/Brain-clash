import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/main.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 testWidgets('game selection exposes arithmetic and arcade categories',(tester)async{
  SharedPreferences.setMockInitialValues({'intro':true});
  await tester.pumpWidget(BrainClash(progress:Progress(await SharedPreferences.getInstance())));
  await tester.tap(find.text('1 VS 1'));await tester.pumpAndSettle();
  expect(find.text('Addition'),findsWidgets);
  expect(find.text('Einmaleins'),findsOneWidget);
  await tester.tap(find.text('Arcade-Battles'));await tester.pumpAndSettle();
  expect(find.text('Signal Sprint'),findsWidgets);
  expect(find.text('Paare-Duell'),findsOneWidget);
  expect(find.text('Weiter'),findsOneWidget);
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();
  expect(find.text('BATTLE STARTEN'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
}
