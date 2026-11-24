import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../audio/audio.dart';
import '../game_engine/battle.dart';
import '../learning/progress.dart';
import '../question_generators/questions.dart';
import '../question_generators/challenges.dart';
import '../widgets/challenge_card.dart';
import 'play.dart';
import '../widgets/character.dart';
import 'cosmetics.dart';
import '../widgets/arcade.dart';
import '../widgets/mode_art.dart';
import '../learning/engagement.dart';
import 'tournament.dart';
import '../widgets/accuracy_history.dart';

const avatars=['🤖','👨‍🚀','🥷','🦊','🐉','👽'];
const names=['Volt','Cosmo','Shadow','Blaze','Drako','Nova','Frost','Ember','Titan','Luna','Orion','Sol'];
const thresholds=[0,50,150,300,600,1000,1500,2500,3500,7000,15000,30000];
const modeNames=['Solo Battle','1 VS 1','Training','Team Battle'];
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
    final compact=box.maxHeight<580;
    return Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:780),child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:Column(children:[
      Row(children:[
       ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset('assets/branding/brain_clash.webp',width:48,height:48)),
       const SizedBox(width:8),
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('BRAIN CLASH',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900,letterSpacing:.5)),const Text('PLAY. THINK. WIN.',style:TextStyle(fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.w700))])),
       ActionChip(avatar:AvatarArt(index:p.current['avatar'] as int,size:24,costume:p.current['costume'] as int? ??0),label:Text(p.active),onPressed:()=>open(Profiles(progress:p))),
      ]),
      const SizedBox(height:10),
      if(!compact)Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xff193e7f),Color(0xff161a33),Color(0xff63351f)]),border:Border.all(color:arcadeBlue.withAlpha(85))),child:Row(children:[
       AvatarArt(index:p.current['avatar'] as int,size:76,costume:p.current['costume'] as int? ??0),
       Expanded(child:Column(mainAxisSize:MainAxisSize.min,mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
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
        return GridView.builder(padding:EdgeInsets.zero,itemCount:4,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,mainAxisSpacing:10,crossAxisSpacing:10,mainAxisExtent:((grid.maxHeight-(rows-1)*10)/rows).clamp(76.0,230.0).toDouble()),itemBuilder:(c,index){final i=[1,0,2,3][index];return ArcadeTile(label:modeNames[i],icon:icons[i],color:colors[i],art:FittedBox(fit:BoxFit.contain,child:ModeArt(mode:i,avatar:p.current['avatar'] as int)),onTap:()=>open(Setup(progress:p,mode:Mode.values[i])));});
      })),
      const SizedBox(height:7),
      Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>open(Setup(progress:p,mode:Mode.training,daily:true)),icon:const Icon(Icons.calendar_today,size:17),label:Text('${DailyProgress.count(p.current)}/10 · Tages-Challenge',maxLines:1,overflow:TextOverflow.ellipsis))),const SizedBox(width:6),IconButton(tooltip:L.text('Schnellstart'),onPressed:p.prefs.containsKey('lastGame')?()=>open(Setup(progress:p,mode:Mode.values[(p.prefs.getInt('lastMode')??1).clamp(0,3).toInt()],quick:true)):null,icon:const Icon(Icons.flash_on))]),
      Container(decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface.withAlpha(215),borderRadius:BorderRadius.circular(18),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant.withAlpha(100))),child:Row(children:[
       nav(Icons.insights,'Fortschritt',()=>open(Stats(progress:p))),
       nav(Icons.account_tree,'Turnier',()=>open(TournamentPage(progress:p))),
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
 final Progress progress;final Mode mode;final bool quick,daily;
 const Setup({super.key,required this.progress,required this.mode,this.quick=false,this.daily=false});
 @override State<Setup> createState()=>_SetupState();
}
class _SetupState extends State<Setup>{
 Challenge challenge=Challenge.addition;
 BattleRule rule=BattleRule.tug;
 int level=1,opponent=1,duration=60,digits=1,otherDigits=1;
 bool automatic=false,numberEntry=false,customDigits=false;
 String age='Individuell',secondProfile='';
 int tab=0,step=0,range=0,table=0,factorDigits=0,choiceCount=4,seriesLength=1;
 int? avatar1,avatar2;
 bool negative=false,noCarry=false;
 DivisionStyle division=DivisionStyle.exact;
 MathOptions get config=>MathOptions(range:range,table:table,factorDigits:factorDigits,choiceCount:choiceCount,negative:negative,noCarry:noCarry,division:division);
 bool get competitive=>widget.mode==Mode.duel||widget.mode==Mode.solo;
 static const mathGames=[Challenge.addition,Challenge.subtraction,Challenge.timesTable,Challenge.division,Challenge.multiplication,Challenge.arithmeticMix,Challenge.compare,Challenge.missing,Challenge.targetNumber,Challenge.mathClassic,Challenge.bigTable,Challenge.numberSeries,Challenge.fractions,Challenge.percent,Challenge.decimals,Challenge.precedence,Challenge.estimate];
 static const arcadeGames=[Challenge.reaction,Challenge.odd,Challenge.sequence,Challenge.pairs,Challenge.trueFalse,Challenge.logic,Challenge.memory,Challenge.focus,Challenge.words,Challenge.mixed,Challenge.mathTower,Challenge.mathRace,Challenge.rocketRace,Challenge.treasureRush,Challenge.numberBomb,Challenge.mazeBattle,Challenge.colorConfusion,Challenge.numberRecall,Challenge.shapeClash,Challenge.patternMaster,Challenge.spellingDuel,Challenge.targetHunt,Challenge.tapBattle,Challenge.numberSort,Challenge.wordSprint,Challenge.logicEscape,Challenge.bossBattle];
 @override void initState(){super.initState();level=widget.progress.prefs.getInt('difficulty')??1;opponent=level;duration=widget.progress.prefs.getInt('duration')??60;if(widget.daily){challenge=Challenge.addition;duration=60;level=0;step=1;}if(widget.quick){final prefs=widget.progress.prefs;challenge=Challenge.values.byName(prefs.getString('lastGame')??'addition');digits=prefs.getInt('lastDigits')??1;duration=prefs.getInt('lastDuration')??60;rule=BattleRule.values.byName(prefs.getString('lastRule')??'tug');seriesLength=prefs.getInt('lastSeries')??1;otherDigits=prefs.getInt('lastOtherDigits')??digits;level=prefs.getInt('lastLevel')??1;opponent=prefs.getInt('lastOpponent')??level;range=prefs.getInt('lastRange')??0;table=prefs.getInt('lastTable')??0;factorDigits=prefs.getInt('lastFactorDigits')??0;choiceCount=prefs.getInt('lastChoices')??4;division=DivisionStyle.values[(prefs.getInt('lastDivision')??0).clamp(0,2).toInt()];negative=prefs.getBool('lastNegative')??false;noCarry=prefs.getBool('lastNoCarry')??false;numberEntry=prefs.getBool('lastNumberEntry')??false;customDigits=prefs.getBool('lastCustomDigits')??false;automatic=prefs.getBool('lastAutomatic')??false;final stored=prefs.getString('lastSecondProfile')??'';secondProfile=widget.progress.profiles.containsKey(stored)&&stored!=widget.progress.active?stored:'';tab=mathGames.contains(challenge)?0:1;step=2;WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)start();});}}
 void start(){
  final prefs=widget.progress.prefs;unawaited(prefs.setString('lastGame',challenge.name));unawaited(prefs.setInt('lastSeries',seriesLength));unawaited(prefs.setInt('lastOtherDigits',otherDigits));unawaited(prefs.setInt('lastLevel',level));unawaited(prefs.setInt('lastOpponent',opponent));unawaited(prefs.setInt('lastRange',range));unawaited(prefs.setInt('lastTable',table));unawaited(prefs.setInt('lastFactorDigits',factorDigits));unawaited(prefs.setInt('lastChoices',choiceCount));unawaited(prefs.setInt('lastDivision',division.index));unawaited(prefs.setBool('lastNegative',negative));unawaited(prefs.setBool('lastNoCarry',noCarry));unawaited(prefs.setBool('lastNumberEntry',numberEntry));unawaited(prefs.setBool('lastCustomDigits',customDigits));unawaited(prefs.setBool('lastAutomatic',automatic));unawaited(prefs.setString('lastSecondProfile',secondProfile));unawaited(prefs.setInt('lastDigits',digits));unawaited(prefs.setInt('lastDuration',duration));unawaited(prefs.setString('lastRule',rule.name));unawaited(prefs.setInt('lastMode',widget.mode.index));
  final actual=automatic?widget.progress.levelFor(challenge.world.name,level):level;
  final chosenDigits=automatic&&challenge.usesDigits&&range==0?widget.progress.digitsFor(challenge.name,digits):digits;
  Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Play(progress:widget.progress,mode:widget.mode,world:challenge.world,duration:duration,level:actual,opponent:opponent,numberEntry:numberEntry&&challenge.canType&&!(challenge==Challenge.division&&division==DivisionStyle.remainder),seriesLength:seriesLength,avatars:[avatar1??widget.progress.current['avatar'] as int,avatar2??(widget.progress.profiles[secondProfile] as Map?)?['avatar'] as int? ??5],mathConfig:customDigits?config.withDigitsOnly():config,secondProfile:secondProfile,challenge:challenge,digits:chosenDigits,opponentDigits:customDigits&&challenge.usesDigits?otherDigits:chosenDigits,rule:competitive?rule:BattleRule.tug)));
 }
 String arcadeInstructions(Challenge c)=>switch(c){Challenge.mathTower=>'Baue 10 Blöcke. Fehler kosten einen Block.',Challenge.mathRace=>'Erreiche die Ziellinie. Fehler bremsen dich.',Challenge.rocketRace=>'Tanke mit richtigen Antworten. Die Rakete fliegt selbständig.',Challenge.treasureRush=>'Sammle Schlüssel und öffne Truhen mit sichtbaren Belohnungen.',Challenge.mazeBattle=>'Löse eine Aufgabe und wähle dann einen freien Weg.',Challenge.logicEscape=>'Öffne sechs Schlösser. Fehler schliessen ein Schloss.',Challenge.bossBattle=>'Besiege den Boss und schütze das Team vor seinen Angriffen.',_=>''};
 Widget section(String text)=>Padding(padding:const EdgeInsets.only(top:16,bottom:8),child:Text(text,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)));
 Widget digitRow(int value,ValueChanged<int> set)=>Wrap(spacing:6,children:[for(var i=1;i<=4;i++)ChoiceChip(label:Text(i==1?'1 Ziffer':'$i Ziffern'),selected:value==i,onSelected:(_)=>set(i))]);
 @override Widget build(BuildContext context){
  final games=tab==0?mathGames:arcadeGames.where((g)=>g==Challenge.bossBattle?widget.mode==Mode.team||widget.mode==Mode.training:widget.mode!=Mode.team||!g.specialRules).toList();
  return Scaffold(appBar:AppBar(title:Text(modeNames[widget.mode.index])),body:ArcadeBackdrop(child:SafeArea(child:Column(children:[
   Padding(padding:const EdgeInsets.all(12),child:Row(children:[for(var i=0;i<3;i++)Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(label:Text(['Spiel','Regeln','Kämpfer'][i]),selected:step==i,onSelected:(_)=>setState(()=>step=i))))])),
   Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(14,0,14,12),children:[
    if(competitive)Container(height:64,padding:const EdgeInsets.all(8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xff173c7a),Color(0xff16172c),Color(0xff70381d)])),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[AvatarArt(index:widget.progress.current['avatar'] as int,size:58),const Text('1  VS  1',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),const AvatarArt(index:5,size:58)])),
    if(step==0)...[
    section('Wähle dein Spiel'),
    Row(children:[for(var i=0;i<2;i++)Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:FilledButton.tonalIcon(onPressed:()=>setState((){tab=i;final list=i==0?mathGames:arcadeGames;if(!list.contains(challenge))challenge=list.first;}),icon:Icon(i==0?Icons.calculate_rounded:Icons.sports_esports_rounded),label:Text(i==0?'Rechen-Battles':'Arcade-Battles'),style:FilledButton.styleFrom(backgroundColor:tab==i?const Color(0xff2359c5):null,foregroundColor:tab==i?Colors.white:null,padding:const EdgeInsets.symmetric(horizontal:4)))))]),
    const SizedBox(height:8),
    LayoutBuilder(builder:(context,box)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:games.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:box.maxWidth>=650?4:2,mainAxisExtent:67,mainAxisSpacing:7,crossAxisSpacing:7),itemBuilder:(context,i)=>ChallengeCard(challenge:games[i],selected:challenge==games[i],onTap:()=>setState((){challenge=games[i];if(challenge.arcadeStage&&competitive)rule=challenge==Challenge.numberBomb?BattleRule.hearts:BattleRule.race10;})))),
    ],
    if(step==1)...[
    if(challenge.usesDigits)...[
     section('Zahlenbereich'),digitRow(digits,(v)=>setState(()=>digits=v)),
     Text(challenge==Challenge.division?'Die erste Zahl hat die gewählte Ziffernzahl. Divisionsart unten wählen.':challenge==Challenge.targetNumber||challenge==Challenge.missing?'Ziffernzahl der erzeugten Zahlen.':'Ziffernzahl der Ausgangszahlen.',style:const TextStyle(fontSize:11)),
     if(widget.mode==Mode.duel||widget.mode==Mode.team)...[
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Eigene Ziffernstufe für Spieler 2'),value:customDigits,onChanged:(v)=>setState(()=>customDigits=v)),
      if(customDigits)digitRow(otherDigits,(v)=>setState(()=>otherDigits=v)),
     ],
    ],
    if(challenge.usesDigits&&!customDigits)Wrap(spacing:6,children:[for(final n in [0,10,20,100,1000])ChoiceChip(label:Text(n==0?'Ziffern':'Bis $n'),selected:range==n,onSelected:(_)=>setState(()=>range=n))]),
    if(challenge==Challenge.addition)SwitchListTile(title:const Text('Ohne Zehnerübergang'),value:noCarry,onChanged:(v)=>setState(()=>noCarry=v)),
    if(challenge==Challenge.subtraction)SwitchListTile(title:const Text('Negative Ergebnisse erlauben'),value:negative,onChanged:(v)=>setState(()=>negative=v)),
    if(challenge==Challenge.multiplication&&!customDigits)DropdownButtonFormField<int>(value:factorDigits,decoration:InputDecoration(labelText:L.text('Ziffern zweiter Faktor')),items:[for(final n in [0,1,2,3,4])DropdownMenuItem(value:n,child:Text(n==0?'Gleich': '$n'))],onChanged:(v)=>setState(()=>factorDigits=v!)),
    if(challenge==Challenge.timesTable||challenge==Challenge.bigTable)DropdownButtonFormField<int>(value:table,decoration:InputDecoration(labelText:L.text('Einmaleins-Reihe')),items:[for(var n=0;n<=20;n++)DropdownMenuItem(value:n,child:Text(n==0?'Alle':'$n'))],onChanged:(v)=>setState(()=>table=v!)),
    if(challenge==Challenge.division)DropdownButtonFormField<DivisionStyle>(value:division,decoration:InputDecoration(labelText:L.text('Division')),items:[for(final style in DivisionStyle.values)DropdownMenuItem(value:style,child:Text(['Ganzzahlig','Mit Rest','Dezimal'][style.index]))],onChanged:(v)=>setState(()=>division=v!)),
    if(challenge.specialRules)Card(child:ListTile(leading:const Icon(Icons.sports_esports),title:const Text('Eigene Spielregeln'),subtitle:Text(arcadeInstructions(challenge))))
    else if(competitive)...[
     section('Spielregeln'),
     GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:7,crossAxisSpacing:7,childAspectRatio:1.65,children:BattleRule.values.map((r)=>ArcadeTile(label:r.label,icon:[Icons.bolt,Icons.flag,Icons.timer,Icons.favorite,Icons.flag_circle,Icons.verified,Icons.speed,Icons.bolt_rounded][r.index],color:[const Color(0xff2464bc),const Color(0xffa95a22),const Color(0xff187b65),const Color(0xffa74468),const Color(0xff2464bc),const Color(0xff8052c6),const Color(0xff187b65),const Color(0xffa95a22)][r.index],selected:r==rule,onTap:()=>setState((){rule=r;if(r==BattleRule.sprint)duration=30;}))).toList()),
     Padding(padding:const EdgeInsets.only(top:7),child:Text(rule.description,style:const TextStyle(fontSize:12))),
    ],
    if(competitive)Wrap(spacing:8,children:[for(final n in [1,3,5])ChoiceChip(label:Text(n==1?'Einzelrunde':'Best of $n'),selected:seriesLength==n,onSelected:(_)=>setState(()=>seriesLength=n))]),
    section('Rundendauer'),
    Wrap(spacing:8,children:[30,60,90,120,if(widget.mode==Mode.training)0].map((t)=>ChoiceChip(label:Text(t==0?'Ohne Limit':'$t s'),selected:duration==t,onSelected:(_)=>setState(()=>duration=t))).toList()),
    if(challenge.canType&&!(challenge==Challenge.division&&division==DivisionStyle.remainder))SwitchListTile(title:const Text('Zahlentastatur statt Antwortvorgaben'),contentPadding:EdgeInsets.zero,value:numberEntry,onChanged:(v)=>setState(()=>numberEntry=v)),
    Wrap(spacing:8,children:[for(final n in [2,4])ChoiceChip(label:Text('$n Antworten'),selected:choiceCount==n,onSelected:(_)=>setState(()=>choiceCount=n))]),
    ],
    if(step==2)...[
    section('Kämpfer auswählen'),
    fighterPicker(0),
    if(widget.mode!=Mode.training)fighterPicker(1),
    Card(child:ExpansionTile(initiallyExpanded:true,leading:const Icon(Icons.tune),title:const Text('Spieler & Schwierigkeit'),childrenPadding:const EdgeInsets.all(12),children:[
     DropdownButtonFormField<String>(value:age,decoration:InputDecoration(labelText:L.text('Altersgruppe (freiwillig)')),items:['8–9 Jahre','10–11 Jahre','12–14 Jahre','15 Jahre und älter','Individuell','Automatisch'].map((a)=>DropdownMenuItem(value:a,child:Text(a))).toList(),onChanged:(v)=>setState((){age=v!;final ages=['8–9 Jahre','10–11 Jahre','12–14 Jahre','15 Jahre und älter'];if(ages.contains(age)){level=ages.indexOf(age);automatic=false;}if(age=='Automatisch')automatic=true;})),
     const SizedBox(height:8),
     DropdownButtonFormField<int>(value:level,decoration:InputDecoration(labelText:L.text('Deine Schwierigkeit')),items:levels(),onChanged:(v)=>setState(()=>level=v!)),
     SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Automatische Anpassung'),value:automatic,onChanged:(v)=>setState(()=>automatic=v)),
     if(widget.mode!=Mode.training)DropdownButtonFormField<int>(value:opponent,decoration:InputDecoration(labelText:L.text(widget.mode==Mode.solo?'Virtueller Gegner':'Spieler 2')),items:levels(),onChanged:(v)=>setState(()=>opponent=v!)),
     if(widget.mode==Mode.duel||widget.mode==Mode.team)DropdownButtonFormField<String>(value:secondProfile,decoration:InputDecoration(labelText:L.text('Profil für Spieler 2')),items:[const DropdownMenuItem(value:'',child:Text('Ohne Profil')),for(final name in widget.progress.profiles.keys.where((n)=>n!=widget.progress.active))DropdownMenuItem(value:name,child:Text(name))],onChanged:(v)=>setState((){secondProfile=v??'';avatar2=null;})),
    ])),
    ],
   ])),
   Padding(padding:const EdgeInsets.fromLTRB(14,5,14,10),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('${L.text(challenge.label)} · ${challenge.usesDigits?digits==1?L.text('1 Ziffer'):L.text('$digits Ziffern'):L.text(competitive?rule.label:modeNames[widget.mode.index])}',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
    const SizedBox(height:5),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:step==2?start:()=>setState(()=>step++),icon:Icon(step==2?Icons.play_arrow_rounded:Icons.arrow_forward),label:Text(step==2?'BATTLE STARTEN':'Weiter'))),
   ])),
  ]))));
 }
 Widget fighterPicker(int player){final profile=player==0?widget.progress.current:(widget.progress.profiles[secondProfile] as Map? ??widget.progress.current);final current=player==0?avatar1??profile['avatar'] as int:avatar2??(profile['avatar'] as int);return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(player==0?'Spieler 1':'Spieler 2'),SizedBox(height:96,child:ListView(scrollDirection:Axis.horizontal,children:[for(var i=0;i<names.length;i++)if((profile['xp'] as int)>=thresholds[i])Padding(padding:const EdgeInsets.all(4),child:ChoiceChip(label:Column(mainAxisSize:MainAxisSize.min,children:[AvatarArt(index:i,size:44),Text(names[i])]),selected:current==i,onSelected:(_)=>setState((){if(player==0){avatar1=i;}else{avatar2=i;}})))]))]);}
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
    ListTile(title:const Text('Rang'),trailing:Text(rankFor(xp))),
    ListTile(title:const Text('Tages-Challenge'),trailing:Text('${DailyProgress.count(p)}/10')),
    ListTile(title:const Text('Wochen-Challenge'),subtitle:Text('${WeeklyProgress.worlds(p).length}/3 Lernwelten'),trailing:Text('${WeeklyProgress.count(p)}/50')),
    ListTile(title:const Text('Beste Serie'),trailing:Text('${p['bestSeries']??0}')),
    if((p['history'] as List? ?? []).length>=2)AccuracyHistory(history:p['history'] as List),
    ListTile(title:const Text('Runden'),trailing:Text('${p['rounds']}')),
    ListTile(title:const Text('Siege'),trailing:Text('${p['wins']}')),
    ListTile(title:const Text('Richtige Antworten'),trailing:Text('$right')),
    ListTile(title:const Text('Rundenrekord'),trailing:Text('${p['best']??0}')),
    ListTile(title:const Text('Fällige Wiederholungen'),trailing:Text('${progress.dueQuestions(World.mixed).length}')),
    if(progress.dueQuestions(World.mixed).isNotEmpty)FilledButton.icon(onPressed:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Play(progress:progress,mode:Mode.training,world:World.mixed,duration:60,level:1,opponent:1))),icon:const Icon(Icons.replay),label:const Text('Fehlertraining starten')),
    ListTile(title:const Text('Trefferquote'),trailing:Text(right+wrong==0?'–':'${(100*right/(right+wrong)).round()} %')),
    if((p['history'] as List? ?? []).isNotEmpty)ExpansionTile(title:const Text('Letzte Spiele'),children:[for(final entry in (p['history'] as List).reversed.take(10))ListTile(title:Text('${entry['world']} · ${entry['points']} Punkte'),subtitle:Text('${entry['date']} · ${entry['right']}/${entry['total']} richtig'))]),
    if((p['skills'] as Map? ?? {}).isNotEmpty)ExpansionTile(title:const Text('Kompetenz je Spiel'),children:[for(final e in (p['skills'] as Map).entries)ListTile(title:Text(Challenge.values.where((c)=>c.name==e.key).firstOrNull?.label??e.key.toString()),subtitle:Text('${e.value['right']} richtig · ${e.value['wrong']} Fehler'),trailing:Text('${e.value['digits']} Ziffern'))]),
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
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Sammlung'),actions:[IconButton(tooltip:L.text('Arena & Effekte'),icon:const Icon(Icons.palette),onPressed:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Cosmetics(progress:widget.progress))))]),body:GridView.builder(padding:const EdgeInsets.all(16),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisExtent:180,crossAxisSpacing:8,mainAxisSpacing:8),itemCount:names.length,itemBuilder:(c,i){final p=widget.progress.current;final unlocked=(p['xp'] as int)>=thresholds[i];return Card(child:InkWell(onTap:unlocked?()async{setState(()=>p['avatar']=i);await widget.progress.save();}:null,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[palette[i].withAlpha(90),Colors.transparent])),child:AvatarArt(index:i,size:80,costume:p['costume'] as int? ??0)),Text(names[i],style:const TextStyle(fontWeight:FontWeight.w900)),Text(['Standard','Standard','Selten','Selten','Episch','Episch','Episch','Episch','Legendär','Legendär','Meister','Meister'][i],style:TextStyle(color:palette[i],fontSize:11)),Text(unlocked?(p['avatar']==i?'Ausgewählt':'Auswählen'):'🔒 ${thresholds[i]} XP')])));}));
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
  const Padding(padding:EdgeInsets.fromLTRB(16,16,16,4),child:Text('Design',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900))),
  ListTile(leading:const Icon(Icons.language),title:const Text('Sprache'),trailing:DropdownButton<String>(value:p.prefs.getString('language')??'de',items:const [DropdownMenuItem(value:'de',child:Text('Deutsch')),DropdownMenuItem(value:'en',child:Text('English'))],onChanged:(v)async{if(v==null)return;L.language=v;await p.prefs.setString('language',v);if(mounted)setState((){});widget.themeChanged();})),
  ListTile(leading:const Icon(Icons.dark_mode_outlined),title:const Text('Design'),trailing:DropdownButton<int>(value:p.prefs.getInt('theme')??2,items:const [DropdownMenuItem(value:0,child:Text('System')),DropdownMenuItem(value:1,child:Text('Hell')),DropdownMenuItem(value:2,child:Text('Dunkel'))],onChanged:(v)async{await p.prefs.setInt('theme',v!);if(mounted)setState((){});widget.themeChanged();})),
  const Divider(),
  ListTile(leading:const Icon(Icons.tune),title:const Text('Standard-Schwierigkeit'),trailing:DropdownButton<int>(value:p.prefs.getInt('difficulty')??1,items:List.generate(4,(i)=>DropdownMenuItem(value:i,child:Text(['Einfach','Normal','Schwer','Experte'][i]))),onChanged:(v)async{await p.prefs.setInt('difficulty',v!);if(mounted)setState((){});})),
  toggle('sound','Soundeffekte',true),
  SwitchListTile(secondary:const Icon(Icons.music_note),title:const Text('Hintergrundmusik'),value:p.prefs.getBool('music')??false,onChanged:(v)async{await p.prefs.setBool('music',v);await GameAudio(p.prefs).music();if(mounted)setState((){});}),
  ListTile(leading:const Icon(Icons.volume_up),title:const Text('Lautstärke'),subtitle:Slider(value:p.prefs.getDouble('volume')??.65,onChanged:(v){setState(()=>p.prefs.setDouble('volume',v));},onChangeEnd:(v)async{await p.prefs.setDouble('volume',v);await GameAudio(p.prefs).music();await GameAudio(p.prefs).effect('menu');})),toggle('haptics','Vibration',true),toggle('reduced','Reduzierte Animationen',false),
  ListTile(leading:const Icon(Icons.timer_outlined),title:const Text('Standard-Spielzeit'),trailing:DropdownButton<int>(value:p.prefs.getInt('duration')??60,items:[30,60,90,120].map((v)=>DropdownMenuItem(value:v,child:Text('$v s'))).toList(),onChanged:(v)async{await p.prefs.setInt('duration',v!);if(mounted)setState((){});})),
  const Divider(),
  ListTile(leading:const Icon(Icons.people_outline),title:const Text('Spielerprofile'),onTap:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Profiles(progress:p)))),
  ListTile(leading:const Icon(Icons.help_outline),title:const Text('Einführung erneut anzeigen'),onTap:widget.intro),
  ListTile(leading:const Icon(Icons.restart_alt),title:const Text('Lernfortschritt zurücksetzen'),onTap:()async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Fortschritt zurücksetzen?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Abbrechen')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Zurücksetzen'))]));if(yes==true){p.profiles[p.active]=p.fresh();await p.save();if(mounted)setState((){});}}),
  ListTile(leading:const Icon(Icons.storage),title:const Text('Lokale Datenspeicherung'),subtitle:Text(p.storageName)),
  ListTile(leading:const Icon(Icons.privacy_tip_outlined),title:const Text('Datenschutz'),onTap:()=>showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Deine Daten'),content:const Text('Profile und Lernfortschritt werden auf diesem Gerät gespeichert. Kein Konto, keine Werbung, kein Tracking. Lösche Profile in der Profilverwaltung oder alle Daten in den Android-App-Einstellungen.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]))),
  AboutListTile(applicationName:'Brain Clash',applicationVersion:'0.9.5 – Release Candidate',applicationLegalese:'Play. Think. Win.'),
 ]));
}
