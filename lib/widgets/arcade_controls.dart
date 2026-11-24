import 'package:flutter/material.dart';
import '../game_engine/arcade_rules.dart';
import '../localization/strings.dart' show L;

class ArcadeControls extends StatelessWidget{
 final ArcadeRules rules;
 final int player;
 final ValueChanged<Direction> onMove;
 final ValueChanged<int> onChest;
 const ArcadeControls({super.key,required this.rules,required this.player,required this.onMove,required this.onChest});
 @override Widget build(BuildContext context){
  final lane=rules.lanes[player];
  return LayoutBuilder(builder:(context,box){
   if(rules.kind==ArcadeKind.maze){
    return Center(child:AspectRatio(aspectRatio:5/4,child:LayoutBuilder(builder:(context,grid){
     final width=grid.maxWidth/5,height=grid.maxHeight/4;
     final neighbors=<int,Direction>{for(final dir in Direction.values)if(rules.mazeFor(player).move(lane.cell,dir)!=null)rules.mazeFor(player).move(lane.cell,dir)!:dir};
     return Stack(children:[
      Positioned.fill(child:CustomPaint(painter:_MazePainter(rules.mazeFor(player),lane.cell,neighbors.keys.toSet(),player))),
      for(final entry in neighbors.entries)Positioned(left:entry.key%5*width,top:entry.key~/5*height,width:width,height:height,child:Semantics(button:true,label:L.text(['Oben','Rechts','Unten','Links'][entry.value.index]),child:Material(color:Colors.transparent,child:InkWell(onTap:()=>onMove(entry.value),child:const Center(child:Icon(Icons.arrow_circle_right,color:Colors.white,size:17)))))),
     ]);
    })));
   }
   return GridView.builder(padding:EdgeInsets.zero,physics:const NeverScrollableScrollPhysics(),itemCount:ArcadeRules.chestValues.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisSpacing:4,crossAxisSpacing:4,mainAxisExtent:((box.maxHeight-4)/2).clamp(12.0,72.0).toDouble()),itemBuilder:(context,i)=>FilledButton.tonal(onPressed:lane.opened.contains(i)?null:()=>onChest(i),style:FilledButton.styleFrom(padding:EdgeInsets.zero,minimumSize:Size.zero),child:FittedBox(child:Row(children:[Icon(lane.opened.contains(i)?Icons.check:Icons.diamond_outlined,size:17),Text(' ${ArcadeRules.chestValues[i]}')]))));
  });
 }
}
class _MazePainter extends CustomPainter{
 final Maze maze;final int cell,player;final Set<int> neighbors;
 _MazePainter(this.maze,this.cell,this.neighbors,this.player);
 @override void paint(Canvas c,Size s){
  final width=s.width/5,height=s.height/4;
  c.drawRect(Offset.zero&s,Paint()..color=const Color(0xff101b32));
  for(var i=0;i<20;i++){
   final r=Rect.fromLTWH(i%5*width,i~/5*height,width,height);
   if(neighbors.contains(i))c.drawRect(r.deflate(2),Paint()..color=const Color(0xff2359c5));
   if(i==19)c.drawCircle(r.center,width*.21,Paint()..color=Colors.amber);
   if(i==cell)c.drawCircle(r.center,width*.26,Paint()..color=player==0?const Color(0xff318bff):const Color(0xffff943c));
   final wall=Paint()..color=Colors.white70..strokeWidth=2;
   if(maze.move(i,Direction.up)==null)c.drawLine(r.topLeft,r.topRight,wall);
   if(maze.move(i,Direction.right)==null)c.drawLine(r.topRight,r.bottomRight,wall);
   if(maze.move(i,Direction.down)==null)c.drawLine(r.bottomLeft,r.bottomRight,wall);
   if(maze.move(i,Direction.left)==null)c.drawLine(r.topLeft,r.bottomLeft,wall);
  }
 }
 @override bool shouldRepaint(covariant _MazePainter old)=>old.maze!=maze||old.cell!=cell||old.player!=player;
}
