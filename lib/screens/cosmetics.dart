import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../learning/progress.dart';
import '../widgets/arcade.dart';
import '../widgets/character.dart';
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
  const SizedBox(height:12),const Text('Kostüme'),
  Wrap(spacing:8,runSpacing:8,children:[for(var i=0;i<5;i++)ChoiceChip(label:Column(mainAxisSize:MainAxisSize.min,children:[AvatarArt(index:p['avatar'] as int,size:52,costume:i),Text(['Original','Eis','Feuer','Gold','Kosmisch'][i]),Text('${[0,500,1500,3500,7000][i]} XP')]),selected:(p['costume']??0)==i,onSelected:xp<[0,500,1500,3500,7000][i]?null:(_)async{setState(()=>p['costume']=i);await widget.progress.save();})]),
  for(final category in [('arena','Arenen',['Cyber City','Mystic Forest','Space Station','Volcano Clash','Ice Kingdom','Golden Temple']),('color','Energiefarben',['Blau','Türkis','Violett']),('background','Hintergründe',['Clean','Sterne','Partikel']),('effect','Energieeffekte',['Figurenfarbe','Gold','Plasma'])])...[
   const SizedBox(height:16),Text(category.$2,style:Theme.of(context).textTheme.titleLarge),
   for(var i=0;i<category.$3.length;i++) Card(child:ListTile(leading:Icon(xp>=[0,150,450,1000,2500,5000][i]?Icons.auto_awesome:Icons.lock_outline,color:xp>=[0,150,450,1000,2500,5000][i]?arcadeOrange:null),title:Text(category.$3[i]),subtitle:Text('${[0,150,450,1000,2500,5000][i]} XP'),trailing:Icon((p[category.$1]??0)==i?Icons.check_circle:Icons.circle_outlined),enabled:xp>=[0,150,450,1000,2500,5000][i],onTap:()async{if(xp<[0,150,450,1000,2500,5000][i])return;setState(()=>p[category.$1]=i);await widget.progress.save();})),
  ]
 ]));
 }
}
