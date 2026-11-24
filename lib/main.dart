import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning/progress.dart';
import 'screens/home.dart';
import 'widgets/arcade.dart';
import 'audio/audio.dart';
import 'localization/strings.dart' show L;
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs=await SharedPreferences.getInstance();
  runApp(BrainClash(progress:await Progress.open(prefs)));
  await GameAudio(prefs).music();
}
class BrainClash extends StatefulWidget {
  final Progress progress;
  const BrainClash({super.key,required this.progress});
  @override State<BrainClash> createState()=>_BrainClashState();
}
class _BrainClashState extends State<BrainClash>{
  ThemeMode get mode=>ThemeMode.values[widget.progress.prefs.getInt('theme')??2];
  @override Widget build(BuildContext context){L.language=widget.progress.prefs.getString('language')??'de';return MaterialApp(
    locale:Locale(L.language),supportedLocales:const [Locale('de'),Locale('en')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
    title:'Brain Clash',debugShowCheckedModeBanner:false,themeMode:mode,
    theme:arcadeTheme(Brightness.light),
    darkTheme:arcadeTheme(Brightness.dark),
    home:Home(progress:widget.progress,themeChanged:()=>setState((){})),
  );}
}
