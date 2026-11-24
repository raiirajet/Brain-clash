import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../audio/audio.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';
import 'play.dart';
import '../widgets/character.dart';
import 'cosmetics.dart';
import '../widgets/arcade.dart';

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
  final colors=[const Color(0xff2879e7),const Color(0xffbf4b12),const Color(0xff16856b),const Color(0xff7546bb)];
  final icons=[Icons.bolt_rounded,Icons.sports_esports_rounded,Icons.psychology_rounded,Icons.groups_rounded];
  return Scaffold(body:ArcadeBackdrop(child:SafeArea(child:LayoutBuilder(builder:(context,box){
    final compact=box.maxHeight<510;
    return Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:780),child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:Column(children:[
      Row(children:[
       ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset('assets/branding/brain_clash.webp',width:48,height:48)),
       const SizedBox(width:8),
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('BRAIN CLASH',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900,letterSpacing:.5)),const Text('PLAY. THINK. WIN.',style:TextStyle(fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.w700))])),
       ActionChip(avatar:AvatarArt(index:p.current['avatar'] as int,size:24),label:Text(p.active),onPressed:()=>open(Profiles(progress:p))),
      ]),
      const SizedBox(height:10),
      if(!compact)Container(height:105,padding:const EdgeInsets.all(12),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xff193e7f),Color(0xff161a33),Color(0xff63351f)]),border:Border.all(color:arcadeBlue.withAlpha(85))),child:Row(children:[
       AvatarArt(index:p.current['avatar'] as int,size:76),
       Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${p.current['xp']} XP',style:const TextStyle(fontSize:27,color:Colors.white,fontWeight:FontWeight.w900)),
        const SizedBox(height:6),
        LinearProgressIndicator(value:((p.current['xp'] as int)%100)/100,backgroundColor:Colors.white24,color:arcadeGreen,borderRadius:BorderRadius.circular(8)),
        const SizedBox(height:5),
        Text('Lv ${1+(p.current['xp'] as int)~/100}',style:const TextStyle(color:Colors.white70,fontSize:12)),
       ])),const SizedBox(width:10),const Icon(Icons.bolt_rounded,color:arcadeOrange,size:36),
      ])),
      const SizedBox(height:10),
      Expanded(child:LayoutBuilder(builder:(context,grid){
        final wide=grid.maxWidth>=640&&compact;
        final cols=wide?4:2;
        final rows=(4/cols).ceil();
        return GridView.builder(padding:EdgeInsets.zero,itemCount:4,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,mainAxisSpacing:10,crossAxisSpacing:10,mainAxisExtent:((grid.maxHeight-(rows-1)*10)/rows).clamp(76.0,230.0).toDouble()),itemBuilder:(c,i)=>ArcadeTile(label:modeNames[i],icon:icons[i],color:colors[i],onTap:()=>open(Setup(progress:p,mode:Mode.values[i]))));
      })),
      const SizedBox(height:7),
      Container(decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface.withAlpha(215),borderRadius:BorderRadius.circular(18),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant.withAlpha(100))),child:Row(children:[
       nav(Icons.insights,'Fortschritt',()=>open(Stats(progress:p))),
       nav(Icons.face,'Sammlung',()=>open(CollectionPage(progress:p))),
       nav(Icons.emoji_events,'Erfolge',()=>open(Stats(progress:p,achievements:true))),
       nav(Icons.settings,'Einstellungen',()=>open(Settings(progress:p,themeChanged:widget.themeChanged,intro:intro))),
      ])),
    ]))));
  }))));
 }
 Widget nav(IconData icon,String label,VoidCallback tap)=>Expanded(child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(children:[Icon(icon,size:26),Text(label,style:const TextStyle(fontSize:10),textAlign:TextAlign.center)]))));
}

class Setup extends StatefulWidget{
 final Progress progress;final Mode mode;
 const Setup({super.key,required this.progress,required this.mode});
 @override State<Setup> createState()=>_SetupState();
}
class _SetupState extends State<Setup>{
 World world=World.math;int level=1,opponent=1,duration=60;bool automatic=false,numberEntry=false;String age='Individuell';String secondProfile='';
 @override void initState(){super.initState();level=widget.progress.prefs.getInt('difficulty')??1;duration=widget.progress.prefs.getInt('duration')??60;}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(modeNames[widget.mode.index])),body:SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
  Text('Lernwelt',style:Theme.of(context).textTheme.titleLarge),
  const SizedBox(height:8),
  GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,childAspectRatio:1.25,mainAxisSpacing:7,crossAxisSpacing:7,children:World.values.map((w)=>ArcadeTile(label:w.label,icon:worldIcons[w.index],color:[const Color(0xff276fe5),const Color(0xff7044bf),const Color(0xffa743ab),const Color(0xffb95518),const Color(0xff187b65),const Color(0xff3b629b)][w.index],selected:w==world,onTap:()=>setState(()=>world=w))).toList()),
  const SizedBox(height:20),
  DropdownButtonFormField<String>(value:age,decoration:InputDecoration(labelText:L.text('Altersgruppe (freiwillig)')),items:['8–9 Jahre','10–11 Jahre','12–14 Jahre','15 Jahre und älter','Individuell','Automatisch'].map((a)=>DropdownMenuItem(value:a,child:Text(a))).toList(),onChanged:(v)=>setState((){age=v!;final ages=['8–9 Jahre','10–11 Jahre','12–14 Jahre','15 Jahre und älter'];if(ages.contains(age)){level=ages.indexOf(age);automatic=false;}if(age=='Automatisch')automatic=true;})),
  DropdownButtonFormField<int>(value:level,decoration:InputDecoration(labelText:L.text('Deine Schwierigkeit')),items:levels(),onChanged:(v)=>setState(()=>level=v!)),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Automatische Anpassung'),value:automatic,onChanged:(v)=>setState(()=>automatic=v)),
  if(widget.mode!=Mode.training)DropdownButtonFormField<int>(value:opponent,decoration:InputDecoration(labelText:L.text(widget.mode==Mode.solo?'Virtueller Gegner':'Spieler 2')),items:levels(),onChanged:(v)=>setState(()=>opponent=v!)),
  if(widget.mode==Mode.duel||widget.mode==Mode.team)DropdownButtonFormField<String>(value:secondProfile,decoration:InputDecoration(labelText:L.text('Profil für Spieler 2')),items:[const DropdownMenuItem(value:'',child:Text('Ohne Profil')),for(final name in widget.progress.profiles.keys.where((n)=>n!=widget.progress.active))DropdownMenuItem(value:name,child:Text(name))],onChanged:(v)=>setState(()=>secondProfile=v??'')),
  if(widget.mode==Mode.training&&world==World.math)SwitchListTile(title:const Text('Zahlentastatur statt Antwortvorgaben'),contentPadding:EdgeInsets.zero,value:numberEntry,onChanged:(v)=>setState(()=>numberEntry=v)),
  const SizedBox(height:18),const Text('Rundendauer'),
  Wrap(spacing:8,children:[30,60,90,120,if(widget.mode==Mode.training)0].map((t)=>ChoiceChip(label:Text(t==0?'Ohne Limit':'$t s'),selected:duration==t,onSelected:(_)=>setState(()=>duration=t))).toList()),
  const SizedBox(height:24),
  FilledButton(onPressed:(){final actual=automatic?widget.progress.levelFor(world.name,level):level;Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Play(progress:widget.progress,mode:widget.mode,world:world,duration:duration,level:actual,opponent:opponent,numberEntry:numberEntry,secondProfile:secondProfile)));},child:const Padding(padding:EdgeInsets.all(14),child:Text('BATTLE STARTEN'))),
 ])));
 List<DropdownMenuItem<int>> levels()=>List.generate(4,(i)=>DropdownMenuItem(value:i,child:Text(['Einfach','Normal','Schwer','Experte'][i])));
}

class Stats extends StatelessWidget{
 final Progress progress;final bool achievements;
 const Stats({super.key,required this.progress,this.achievements=false});
 @override Widget build(BuildContext context){
  final p=progress.current;final right=p['right'] as int,wrong=p['wrong'] as int,xp=p['xp'] as int;
  return Scaffold(appBar:AppBar(title:Text(achievements?'Erfolge':'Mein Fortschritt')),body:ListView(padding:const EdgeInsets.all(20),children:[
   if(achievements)...[for(final a in [('Erste Runde',p['rounds'] as int,1),('Rechenkünstler',right,100),('Duellmeister',p['wins'] as int,10),('Ausdauer',p['rounds'] as int,25),('Brain Clash Champion',xp,1000)])ListTile(leading:Icon(a.$2>=a.$3?Icons.emoji_events:Icons.lock_outline),title:Text(a.$1),subtitle:Text('${a.$2} / ${a.$3}'))]
   else ...[
    Row(children:[Expanded(child:MetricTile(label:'XP',value:'$xp',icon:Icons.bolt,color:arcadeOrange)),const SizedBox(width:12),AccuracyRing(value:right+wrong==0?0:right/(right+wrong),reduced:progress.prefs.getBool('reduced')??false)]),
    const SizedBox(height:12),
    ListTile(title:const Text('Runden'),trailing:Text('${p['rounds']}')),
    ListTile(title:const Text('Siege'),trailing:Text('${p['wins']}')),
    ListTile(title:const Text('Richtige Antworten'),trailing:Text('$right')),
    ListTile(title:const Text('Rundenrekord'),trailing:Text('${p['best']??0}')),
    ListTile(title:const Text('Fällige Wiederholungen'),trailing:Text('${progress.dueQuestions(World.mixed).length}')),
    ListTile(title:const Text('Trefferquote'),trailing:Text(right+wrong==0?'–':'${(100*right/(right+wrong)).round()} %')),
    for(final w in World.values.where((w)=>w!=World.mixed))Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:4),child:category(w,p))),
   ]
  ]));
 }
 Widget category(World w,Map p){final c=(p['categories'] as Map)[w.name] as Map?;final r=c?['right'] as int? ??0;final f=c?['wrong'] as int? ??0;return ListTile(leading:Icon(worldIcons[w.index],color:arcadeBlue),title:Text(w.label),subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[LinearProgressIndicator(value:r+f==0?0:r/(r+f)),if(r+f>0)Text('Ø ${((c!['ms'] as int)/(r+f)/1000).toStringAsFixed(1)} s · Lv ${(c['level'] as int)+1}')]),trailing:Text('$r / ${r+f}'));}
}
class CollectionPage extends StatefulWidget{
 final Progress progress;
 const CollectionPage({super.key,required this.progress});
 @override State<CollectionPage> createState()=>_CollectionPageState();
}
class _CollectionPageState extends State<CollectionPage>{
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Sammlung'),actions:[IconButton(tooltip:L.text('Arena & Effekte'),icon:const Icon(Icons.palette),onPressed:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Cosmetics(progress:widget.progress))))]),body:GridView.builder(padding:const EdgeInsets.all(16),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.15,crossAxisSpacing:8,mainAxisSpacing:8),itemCount:6,itemBuilder:(c,i){final p=widget.progress.current;final unlocked=(p['xp'] as int)>=thresholds[i];return Card(child:InkWell(onTap:unlocked?()async{setState(()=>p['avatar']=i);await widget.progress.save();}:null,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[palette[i].withAlpha(90),Colors.transparent])),child:AvatarArt(index:i,size:80)),Text(names[i]),Text(unlocked?(p['avatar']==i?'Ausgewählt':'Auswählen'):'🔒 ${thresholds[i]} XP')])));}));
}
class Profiles extends StatefulWidget{
 final Progress progress;
 const Profiles({super.key,required this.progress});
 @override State<Profiles> createState()=>_ProfilesState();
}
class _ProfilesState extends State<Profiles>{
 Progress get p=>widget.progress;
 Future<void> add()async{
  var name='';final result=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Neues Profil'),content:TextField(maxLength:24,onChanged:(v)=>name=v,decoration:InputDecoration(labelText:L.text('Spitzname'))),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Erstellen'))]));
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
  ListTile(title:const Text('Sprache'),trailing:DropdownButton<String>(value:p.prefs.getString('language')??'de',items:const [DropdownMenuItem(value:'de',child:Text('Deutsch')),DropdownMenuItem(value:'en',child:Text('English'))],onChanged:(v)async{if(v==null)return;L.language=v;await p.prefs.setString('language',v);if(mounted)setState((){});widget.themeChanged();})),
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
  AboutListTile(applicationName:'Brain Clash',applicationVersion:'0.3.0 – Testversion',applicationLegalese:'Play. Think. Win.'),
 ]));
}
