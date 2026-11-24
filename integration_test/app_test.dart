import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/main.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('offline home, setup and training start', (tester) async {
  final prefs=await SharedPreferences.getInstance();
  await prefs.clear();await prefs.setBool('intro',true);
  await tester.pumpWidget(BrainClash(progress:Progress(prefs)));
  await tester.pumpAndSettle();
  for(final name in ['Solo Battle','1 VS 1','Training','Team Battle']){
   expect(find.text(name),findsOneWidget);
  }
  await tester.tap(find.text('Training'));await tester.pumpAndSettle();
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();
  await tester.tap(find.text('BATTLE STARTEN'));await tester.pump(const Duration(milliseconds:500));
  await tester.pump(const Duration(seconds:4));
  expect(find.text('Training beenden'),findsOneWidget);
  await tester.tap(find.text('Training beenden'));await tester.pump(const Duration(milliseconds:500));
  expect(find.text('Training abgeschlossen'),findsOneWidget);
 });
}
