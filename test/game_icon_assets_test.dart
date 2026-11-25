import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/widgets/challenge_card.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('all 44 games have real bundled WebP assets',()async{
  expect(Challenge.values.length,44);
  for(final game in Challenge.values){
   final data=await rootBundle.load(ChallengeArt.path(game));
   expect(data.lengthInBytes,greaterThan(1000),reason:game.name);
   expect(String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes,4)),'RIFF');
   expect(String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes+8,4)),'WEBP');
  }
 });
}
