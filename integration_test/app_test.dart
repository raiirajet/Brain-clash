import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/main.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('SQLite migration preserves legacy XP, and profile deletion is durable',(tester) async {
  final prefs=await SharedPreferences.getInstance();await prefs.clear();
  final legacy=Progress(prefs);legacy.profiles['Migration']=legacy.fresh()..['xp']=777;legacy.active='Migration';
  await prefs.setString('profiles',jsonEncode(legacy.profiles));await prefs.setString('active','Migration');
  final path='${await getDatabasesPath()}/migration_test.db';await deleteDatabase(path);
  final migrated=await Progress.open(prefs,databasePath:path);expect(migrated.storageName,'SQLite');expect(migrated.active,'Migration');expect(migrated.current['xp'],777);
  migrated.current['xp']=900;await migrated.save();
  final reopened=await Progress.open(prefs,databasePath:path);expect(reopened.current['xp'],900);
  reopened.profiles.remove('Migration');reopened.active='Gast';await reopened.save();
  final after=await Progress.open(prefs,databasePath:path);expect(after.profiles.containsKey('Migration'),false);
 });
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
