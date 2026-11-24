import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
class GameAudio {
  static const channel=MethodChannel('brainclash/audio');
  final SharedPreferences prefs;
  const GameAudio(this.prefs);
  double get volume=>(prefs.getDouble('volume')??.65).clamp(0.0,1.0).toDouble();
  Future<void> effect(String name)async{
    if(!(prefs.getBool('sound')??true))return;
    try{await channel.invokeMethod<void>('effect',{'name':name,'volume':volume});}
    on MissingPluginException{if(name=='right'||name=='wrong')await SystemSound.play(name=='right'?SystemSoundType.click:SystemSoundType.alert);}
    on PlatformException{if(name=='right'||name=='wrong')await SystemSound.play(name=='right'?SystemSoundType.click:SystemSoundType.alert);}
  }
  Future<void> music()async{
    try{await channel.invokeMethod<void>('music',{'enabled':prefs.getBool('music')??false,'volume':volume*.35});}
    on MissingPluginException{/* Non-Android audio adapter not yet implemented. */}
    on PlatformException{/* Device audio unavailable; gameplay remains usable. */}
  }
}
