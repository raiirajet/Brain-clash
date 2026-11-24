import 'package:flutter/material.dart';
import '../game_engine/arcade_rules.dart';
import '../localization/strings.dart' show L;
class ArcadeControls extends StatelessWidget{
 final ArcadeRules rules;final int player;final ValueChanged<Direction> onMove;final ValueChanged<int> onChest;
 const ArcadeControls({super.key,required this.rules,required this.player,required this.onMove,required this.onChest});
 @override Widget build(BuildContext context){
  final lane=rules.lanes[player];
  return LayoutBuilder(builder:(context,box){
   if(rules.kind==ArcadeKind.maze){
    const icons=[Icons.arrow_upward,Icons.arrow_forward,Icons.arrow_downward,Icons.arrow_back];
    const labels=['Oben','Rechts','Unten','Links'];
    return Row(children:[for(final dir in Direction.values)Expanded(child:Padding(padding:const EdgeInsets.all(2),child:Semantics(label:L.text(labels[dir.index]),child:FilledButton(style:FilledButton.styleFrom(padding:EdgeInsets.zero,minimumSize:Size.zero),onPressed:rules.maze.move(lane.cell,dir)==null?null:()=>onMove(dir),child:Icon(icons[dir.index])))))]);
   }
   return GridView.builder(padding:EdgeInsets.zero,physics:const NeverScrollableScrollPhysics(),itemCount:ArcadeRules.chestValues.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisSpacing:4,crossAxisSpacing:4,mainAxisExtent:((box.maxHeight-4)/2).clamp(12.0,72.0).toDouble()),itemBuilder:(context,i)=>FilledButton.tonal(onPressed:lane.opened.contains(i)?null:()=>onChest(i),style:FilledButton.styleFrom(padding:EdgeInsets.zero),child:FittedBox(child:Row(children:[Icon(lane.opened.contains(i)?Icons.check:Icons.diamond_outlined,size:17),Text(' ${ArcadeRules.chestValues[i]}')]))));
  });
 }
}
