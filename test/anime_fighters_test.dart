import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/core/fighters.dart';
import 'package:brain_clash/learning/progress.dart';
import 'package:brain_clash/widgets/character.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('all nine real atlases are present and decode at 960x640',() async{
  expect(fighterIds.toSet().length,9);
  expect(await preloadCharacterArt(),isTrue);
 });
 test('legacy profiles keep progress and switch to a valid anime character',() async{
  SharedPreferences.setMockInitialValues({'profiles':'{"Gast":{"xp":1234,"avatar":11,"costume":4}}'});
  final prefs=await SharedPreferences.getInstance();
  final p=Progress(prefs);
  expect(p.current['xp'],1234);
  expect(p.current['avatar'],0);
  p.current['avatar']=8;
  await p.save();
  expect(Progress(prefs).current['avatar'],8);
 });
}
