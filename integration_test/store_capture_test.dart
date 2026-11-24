
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/main.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 final binding=IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('capture real app screens',(tester)async{
  final prefs=await SharedPreferences.getInstance();
  await prefs.clear();await prefs.setBool('intro',true);await prefs.setBool('reduced',true);await prefs.setBool('sound',false);
  final progress=Progress(prefs);
  await tester.pumpWidget(BrainClash(progress:progress));await tester.pumpAndSettle();
  await binding.convertFlutterSurfaceToImage();await tester.pumpAndSettle();await binding.takeScreenshot('01-home');
  await tester.tap(find.text('1 VS 1'));await tester.pumpAndSettle();await binding.takeScreenshot('02-game-selection');
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();await binding.takeScreenshot('03-math-settings');
  await tester.tap(find.text('Weiter'));await tester.pumpAndSettle();
  await tester.tap(find.text('BATTLE STARTEN'));await tester.pump(const Duration(milliseconds:400));
  // Real time is used by the battle stopwatch. Wait through the countdown.
  await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:4)));
  await tester.pump(const Duration(milliseconds:100));await binding.takeScreenshot('04-duel');
 });
}
