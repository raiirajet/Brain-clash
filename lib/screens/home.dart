import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';
import 'play.dart';
import '../widgets/character.dart';

const avatars=['🤖','👨‍🚀','🥷','🦊','🐉','👽'];
const names=['Roboter','Astronaut','Ninja','Fuchs','Drache','Alien'];
const thresholds=[0,50,150,300,600,1000];
const modeNames=['Solo Battle','2 Spieler','Training','Team Battle'];
const worldIcons=[Icons.calculate,Icons.extension,Icons.psychology,Icons.track_changes,Icons.translate,Icons.shuffle];
class Home extends StatefulWidget{
 final Progress progress;final VoidCallback themeChanged;
 const Home({super.key,required this.progress,required this.themeChanged});
 @override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home>{
 Progress get p=>widget.progress;
 @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&!(p.prefs.getBool('intro')??false))intro();});}
 Future<void> intro()async{
  await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Willkommen in der Arena!'),content:const Text('Wähle eine Lernwelt. Jede richtige Antwort verschiebt die Energie um 5 %. Falsche Antworten sperren das Feld kurz. Im Training lernst du ohne Druck.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Überspringen')),FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Los geht’s'))]));
  await p.prefs.setBool('intro',true);
 }
 Future<void> open(Widget screen)async{unawaited(GameAudio(p.prefs).effect('menu'));await Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>screen));if(mounted)setState((){});}
 @override Widget build(BuildContext context){
  final colors=[const Color(0xff2359c5),const Color(0xffb44818),const Color(0xff187768),const Color(0xff7144ba)];
  final icons=[Icons.bolt,Icons.sports_esports,Icons.psychology,Icons.groups];
  return Scaffold(body:SafeArea(child:LayoutBuilder(builder:(context,box){
    return Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      Row(children:[const Icon(Icons.bolt_rounded,color:Color(0xff4d9cff),size:35),const Spacer(),ActionChip(avatar:AvatarArt(index:p.current['avatar'] as int,size:24),label:Text(p.active),onPressed:()=>open(Profiles(progress:p))) ]),
      const SizedBox(height:10),
      Text('BRAIN CLASH',style:Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight:FontWeight.w900,letterSpacing:1.5)),
      const Text('PLAY. THINK. WIN.',style:TextStyle(letterSpacing:3,fontWeight:FontWeight.w600)),
      const SizedBox(height:20),
      Expanded(child:GridView.builder(itemCount:4,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,mainAxisExtent:((box.maxHeight-250)/2).clamp(85.0,220.0).toDouble()),itemBuilder:(c,i)=>Material(color:colors[i],borderRadius:BorderRadius.circular(24),child:InkWell(borderRadius:BorderRadius.circular(24),onTap:()=>open(Setup(progress:p,mode:Mode.values[i])),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icons[i],size:box.maxHeight<500?27:45,color:Colors.white),const SizedBox(height:8),Text(modeNames[i],style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:17))]))))),
      Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
       nav(Icons.insights,'Fortschritt',()=>open(Stats(progress:p))),
       nav(Icons.face,'Sammlung',()=>open(CollectionPage(progress:p))),
       nav(Icons.emoji_events,'Erfolge',()=>open(Stats(progress:p,achievements:true))),
       nav(Icons.settings,'Einstellungen',()=>open(Settings(progress:p,themeChanged:widget.themeChanged,intro:intro))),
      ]),
    ]))));
  })));
 }
 Widget nav(IconData icon,String label,VoidCallback tap)=>Expanded(child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(children:[Icon(icon,size:26),Text(label,style:const TextStyle(fontSize:10),textAlign:TextAlign.center)]))));
}

class Setup extends StatefulWidget{
 final Progress progress;final Mode mode;
 const Setup({super.key,required this.progress,required this.mode});
 @override State<Setup> createState()=>_SetupState();
}
class _SetupState extends State<Setup>{
 World world=World.math;int level=1,opponent=1,duration=60;bool automatic=false;
 @override void initState(){super.initState();level=widget.progress.prefs.getInt('difficulty')??1;duration=widget.progress.prefs.getInt('duration')??60;}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(modeNames[widget.mode.index])),body:SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
  Text('Lernwelt',style:Theme.of(context).textTheme.titleLarge),
  const SizedBox(height:8),
  Wrap(spacing:8,runSpacing:8,children:World.values.map((w)=>ChoiceChip(avatar:Icon(worldIcons[w.index],size:18),label:Text(w.label),selected:w==world,onSelected:(_)=>setState(()=>world=w))).toList()),
  const SizedBox(height:20),
  DropdownButtonFormField<int>(value:level,decoration:const InputDecoration(labelText:'Deine Schwierigkeit'),items:levels(),onChanged:(v)=>setState(()=>level=v!)),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Automatische Anpassung'),value:automatic,onChanged:(v)=>setState(()=>automatic=v)),
  if(widget.mode!=Mode.training)DropdownButtonFormField<int>(value:opponent,decoration:InputDecoration(labelText:widget.mode==Mode.solo?'Virtueller Gegner':'Spieler 2'),items:levels(),onChanged:(v)=>setState(()=>opponent=v!)),
  const SizedBox(height:18),const Text('Rundendauer'),
  Wrap(spacing:8,children:[30,60,90,120,if(widget.mode==Mode.training)0].map((t)=>ChoiceChip(label:Text(t==0?'Ohne Limit':'$t s'),selected:duration==t,onSelected:(_)=>setState(()=>duration=t))).toList()),
  const SizedBox(height:24),
  FilledButton(onPressed:(){final actual=automatic?widget.progress.levelFor(world.name,level):level;Navigator.pushReplacement<void,void>(context,MaterialPageRoute(builder:(_)=>Play(progress:widget.progress,mode:widget.mode,world:world,duration:duration,level:actual,opponent:opponent)));},child:const Padding(padding:EdgeInsets.all(14),child:Text('BATTLE STARTEN'))),
 ])));
 List<DropdownMenuItem<int>> levels()=>List.generate(4,(i)=>DropdownMenuItem(value:i,child:Text(['Einfach','Normal','Schwer','Experte'][i])));
}

class Stats extends StatelessWidget{
 final Progress progress;final bool achievements;
 const Stats({super.key,required this.progress,this.achievements=false});
 @override Widget build(BuildContext context){
  final p=progress.current;final right=p['right'] as int,wrong=p['wrong'] as int,xp=p['xp'] as int;
  return Scaffold(appBar:AppBar(title:Text(achievements?'Erfolge':'Mein Fortschritt')),body:ListView(padding:const EdgeInsets.all(20),children:[
   if(achievements)...List.generate(thresholds.length,(i)=>ListTile(leading:Icon(xp>=thresholds[i]?Icons.emoji_events:Icons.lock_outline),title:Text(names[i]),subtitle:Text('${thresholds[i]} XP')) )
   else ...[
    Text('$xp XP',style:Theme.of(context).textTheme.displaySmall),
    ListTile(title:const Text('Runden'),trailing:Text('${p['rounds']}')),
    ListTile(title:const Text('Siege'),trailing:Text('${p['wins']}')),
    ListTile(title:const Text('Richtige Antworten'),trailing:Text('$right')),
    ListTile(title:const Text('Rundenrekord'),trailing:Text('${p['best']??0}')),
    ListTile(title:const Text('Fällige Wiederholungen'),trailing:Text('${progress.dueQuestions(World.mixed).length}')),
    ListTile(title:const Text('Trefferquote'),trailing:Text(right+wrong==0?'–':'${(100*right/(right+wrong)).round()} %')),
    for(final w in World.values.where((w)=>w!=World.mixed))category(w,p),
   ]
  ]));
 }
 Widget category(World w,Map p){final c=(p['categories'] as Map)[w.name] as Map?;final r=c?['right'] as int? ??0;final f=c?['wrong'] as int? ??0;return ListTile(title:Text(w.label),subtitle:LinearProgressIndicator(value:r+f==0?0:r/(r+f)),trailing:Text('$r / ${r+f}'));}
}
class CollectionPage extends StatefulWidget{
 final Progress progress;
 const CollectionPage({super.key,required this.progress});
 @override State<CollectionPage> createState()=>_CollectionPageState();
}
class _CollectionPageState extends State<CollectionPage>{
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Meine Spielfiguren')),body:GridView.builder(padding:const EdgeInsets.all(16),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.15,crossAxisSpacing:8,mainAxisSpacing:8),itemCount:6,itemBuilder:(c,i){final p=widget.progress.current;final unlocked=(p['xp'] as int)>=thresholds[i];return Card(child:InkWell(onTap:unlocked?()async{setState(()=>p['avatar']=i);await widget.progress.save();}:null,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[AvatarArt(index:i,size:66),Text(names[i]),Text(unlocked?(p['avatar']==i?'Ausgewählt':'Auswählen'):'🔒 ${thresholds[i]} XP')])));}));
}
class Profiles extends StatefulWidget{
 final Progress progress;
 const Profiles({super.key,required this.progress});
 @override State<Profiles> createState()=>_ProfilesState();
}
class _ProfilesState extends State<Profiles>{
 Progress get p=>widget.progress;
 Future<void> add()async{
  var name='';final result=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Neues Profil'),content:TextField(maxLength:24,onChanged:(v)=>name=v,decoration:const InputDecoration(labelText:'Spitzname')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Erstellen'))]));
  name=name.trim();if(!mounted||result!=true||name.isEmpty)return;
  if(p.profiles.containsKey(name)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dieser Name existiert bereits.')));return;}
  setState((){p.profiles[name]=p.fresh();p.active=name;});await p.save();
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Spielerprofile')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('Profil')),body:ListView(children:p.profiles.keys.map((name)=>ListTile(title:Text(name),leading:Icon(p.active==name?Icons.check_circle:Icons.person_outline),onTap:()async{setState(()=>p.active=name);await p.save();},trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('$name löschen?'),content:const Text('Der lokale Lernfortschritt wird entfernt.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Löschen'))]));if(yes!=true||!mounted)return;setState((){p.profiles.remove(name);p.profiles.putIfAbsent('Gast',()=>p.fresh());if(p.active==name)p.active='Gast';});await p.save();}))).toList()));
}
class Settings extends StatefulWidget{
 final Progress progress;final VoidCallback themeChanged;final Future<void> Function() intro;
 const Settings({super.key,required this.progress,required this.themeChanged,required this.intro});
 @override State<Settings> createState()=>_SettingsState();
}
class _SettingsState extends State<Settings>{
 Progress get p=>widget.progress;
 Widget toggle(String key,String title,bool fallback)=>SwitchListTile(title:Text(title),value:p.prefs.getBool(key)??fallback,onChanged:(v)async{await p.prefs.setBool(key,v);if(mounted)setState((){});});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Einstellungen')),body:ListView(children:[
  ListTile(title:const Text('Design'),trailing:DropdownButton<int>(value:p.prefs.getInt('theme')??2,items:const [DropdownMenuItem(value:0,child:Text('System')),DropdownMenuItem(value:1,child:Text('Hell')),DropdownMenuItem(value:2,child:Text('Dunkel'))],onChanged:(v)async{await p.prefs.setInt('theme',v!);if(mounted)setState((){});widget.themeChanged();})),
  ListTile(title:const Text('Standard-Schwierigkeit'),trailing:DropdownButton<int>(value:p.prefs.getInt('difficulty')??1,items:List.generate(4,(i)=>DropdownMenuItem(value:i,child:Text(['Einfach','Normal','Schwer','Experte'][i]))),onChanged:(v)async{await p.prefs.setInt('difficulty',v!);if(mounted)setState((){});})),
  toggle('sound','Soundeffekte',true),
  SwitchListTile(title:const Text('Hintergrundmusik'),value:p.prefs.getBool('music')??false,onChanged:(v)async{await p.prefs.setBool('music',v);await GameAudio(p.prefs).music();if(mounted)setState((){});}),
  ListTile(title:const Text('Lautstärke'),subtitle:Slider(value:p.prefs.getDouble('volume')??.65,onChanged:(v){setState(()=>p.prefs.setDouble('volume',v));},onChangeEnd:(v)async{await p.prefs.setDouble('volume',v);await GameAudio(p.prefs).music();await GameAudio(p.prefs).effect('menu');})),toggle('haptics','Vibration',true),toggle('reduced','Reduzierte Animationen',false),
  ListTile(title:const Text('Standard-Spielzeit'),trailing:DropdownButton<int>(value:p.prefs.getInt('duration')??60,items:[30,60,90,120].map((v)=>DropdownMenuItem(value:v,child:Text('$v s'))).toList(),onChanged:(v)async{await p.prefs.setInt('duration',v!);if(mounted)setState((){});})),
  ListTile(title:const Text('Spielerprofile'),onTap:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Profiles(progress:p)))),
  ListTile(title:const Text('Einführung erneut anzeigen'),onTap:widget.intro),
  ListTile(title:const Text('Lernfortschritt zurücksetzen'),onTap:()async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Fortschritt zurücksetzen?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Zurücksetzen'))]));if(yes==true){p.profiles[p.active]=p.fresh();await p.save();if(mounted)setState((){});}}),
  ListTile(title:const Text('Datenschutz'),onTap:()=>showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Deine Daten'),content:const Text('Profile und Lernfortschritt werden auf diesem Gerät gespeichert. Kein Konto, keine Werbung, kein Tracking. Lösche Profile in der Profilverwaltung oder alle Daten in den Android-App-Einstellungen.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]))),
  AboutListTile(applicationName:'Brain Clash',applicationVersion:'0.1.0 – Entwicklung',applicationLegalese:'Play. Think. Win.'),
 ]));
}
