import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../learning/progress.dart';
import '../widgets/arcade.dart';
class Cosmetics extends StatefulWidget {
 final Progress progress;
 const Cosmetics({super.key,required this.progress});
 @override State<Cosmetics> createState()=>_CosmeticsState();
}
class _CosmeticsState extends State<Cosmetics>{
 @override Widget build(BuildContext context){
 final p=widget.progress.current;
 final xp=p['xp'] as int;
 return Scaffold(appBar:AppBar(title:const Text('Arena & Effekte')),body:ListView(padding:const EdgeInsets.all(16),children:[
  Text('$xp XP',style:Theme.of(context).textTheme.headlineSmall),
  for(final category in [('arena','Arenen',['Neon Arena','Dschungel','Galaxie']),('color','Energiefarben',['Blau','Türkis','Violett']),('background','Hintergründe',['Clean','Sterne','Partikel']),('effect','Energieeffekte',['Figurenfarbe','Gold','Plasma'])])...[
   const SizedBox(height:16),Text(category.$2,style:Theme.of(context).textTheme.titleLarge),
   for(var i=0;i<3;i++) Card(child:ListTile(leading:Icon(xp>=[0,150,450][i]?Icons.auto_awesome:Icons.lock_outline),title:Text(category.$3[i]),subtitle:Text('${[0,150,450][i]} XP'),trailing:Icon((p[category.$1]??0)==i?Icons.check_circle:Icons.circle_outlined),enabled:xp>=[0,150,450][i],onTap:()async{if(xp<[0,150,450][i])return;setState(()=>p[category.$1]=i);await widget.progress.save();})),
  ]
 ]));
 }
}
