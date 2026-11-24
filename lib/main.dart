import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning/progress.dart';
import 'screens/home.dart';
import 'audio/audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs=await SharedPreferences.getInstance();
  runApp(BrainClash(progress:Progress(prefs)));
  await GameAudio(prefs).music();
}
class BrainClash extends StatefulWidget {
  final Progress progress;
  const BrainClash({super.key,required this.progress});
  @override State<BrainClash> createState()=>_BrainClashState();
}
class _BrainClashState extends State<BrainClash>{
  ThemeMode get mode=>ThemeMode.values[widget.progress.prefs.getInt('theme')??2];
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'Brain Clash',debugShowCheckedModeBanner:false,themeMode:mode,
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff2563eb)),useMaterial3:true),
    darkTheme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff4d9cff),brightness:Brightness.dark),scaffoldBackgroundColor:const Color(0xff080b13),useMaterial3:true),
    home:Home(progress:widget.progress,themeChanged:()=>setState((){})),
  );
}
