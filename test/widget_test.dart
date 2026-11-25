import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_clash/main.dart';
import 'package:brain_clash/learning/progress.dart';
void main(){
 testWidgets('home contains four game modes and navigation',(tester)async{
  SharedPreferences.setMockInitialValues({'intro':true});
  final p=Progress(await SharedPreferences.getInstance());
  await tester.pumpWidget(BrainClash(progress:p));
  expect(find.text('Solo Battle'),findsOneWidget);
  expect(find.text('1 VS 1'),findsOneWidget);
  expect(find.text('Training'),findsOneWidget);
  expect(find.text('Team Battle'),findsOneWidget);
 });
}
