import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../question_generators/challenges.dart';
import '../game_engine/arcade_rules.dart';

class ArcadeStage extends StatelessWidget {
 final Challenge challenge;
 final List<int> points;
 final int remaining;
 final bool reduced;
 final ArcadeRules? rules;
 const ArcadeStage({super.key,required this.challenge,required this.points,required this.remaining,required this.reduced,this.rules});
 @override Widget build(BuildContext context)=>Semantics(label:'${challenge.label}: ${points[0]} zu ${points[1]}',child:CustomPaint(painter:_StagePainter(challenge,List<int>.of(points),remaining,rules),size:Size.infinite));
}
class _StagePainter extends CustomPainter{
 final Challenge challenge;final List<int> points;final int remaining;
 final ArcadeRules? rules;
 _StagePainter(this.challenge,this.points,this.remaining,this.rules);
 @override void paint(Canvas c,Size s){
  final w=s.width,h=s.height;
  if(w<=0||h<=0)return;
  final rect=Offset.zero&s;
  c.drawRect(rect,Paint()..shader=const LinearGradient(colors:[Color(0xff162c50),Color(0xff080b15),Color(0xff493023)]).createShader(rect));
  if(rules?.boss==true){final a=rules!;final center=Offset(w*.5,h*.42);final r=math.min(h*.25,w*.11);c.drawCircle(center,r,Paint()..color=Colors.deepPurpleAccent);for(final dx in [-r*.35,r*.35])c.drawCircle(center+Offset(dx,-r*.1),r*.16,Paint()..color=Colors.white);c.drawRect(Rect.fromLTWH(w*.12,h*.79,w*.76,5),Paint()..color=Colors.white24);c.drawRect(Rect.fromLTWH(w*.12,h*.79,w*.76*a.bossHp/120,5),Paint()..color=Colors.redAccent);for(var i=0;i<a.teamHp;i++)c.drawCircle(Offset(w*.1+i*9,h*.2),3,Paint()..color=Colors.greenAccent);return;}
  final colors=[const Color(0xff318bff),const Color(0xffff943c)];
  for(var p=0;p<2;p++){
   final color=colors[p],n=points[p],x0=p*w/2,half=w/2;
   final lane=rules?.lanes[p];
   final paint=Paint()..color=color;
   switch(challenge){
    case Challenge.mathTower:
     final step=math.min(h/12,10.0),width=half*.38;
     for(var i=0;i<math.min(lane?.blocks??n,10);i++){
      final r=RRect.fromRectAndRadius(Rect.fromLTWH(x0+half*.31,h-4-(i+1)*step,width,step-1),const Radius.circular(2));
      c.drawRRect(r,paint);c.drawLine(r.outerRect.topLeft,r.outerRect.topRight,Paint()..color=Colors.white54..strokeWidth=1);
     }
     break;
    case Challenge.mathRace:
    case Challenge.rocketRace:
     final y=h*.55;
     c.drawLine(Offset(x0+8,y),Offset(x0+half-8,y),Paint()..color=Colors.white24..strokeWidth=4);
     for(var i=0;i<10;i++)c.drawCircle(Offset(x0+8+i*(half-16)/9,y),1.3,Paint()..color=Colors.white54);
     final x=x0+8+(half-16)*(lane==null?n.clamp(0,10)/10:lane.position/100);
     final r=math.min(h*.24,12.0);
     if(challenge==Challenge.rocketRace){
      final ship=Path()..moveTo(x+r,y)..lineTo(x-r,y-r*.65)..lineTo(x-r,y+r*.65)..close();
      c.drawPath(ship,paint);c.drawCircle(Offset(x-r-3,y),3,Paint()..color=Colors.amber);
     }else{
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:r*2,height:r),const Radius.circular(4)),paint);
      for(final dx in [-r*.6,r*.6])c.drawCircle(Offset(x+dx,y+r*.5),r*.25,Paint()..color=Colors.black);
     }
     break;
    case Challenge.treasureRush:
     for(var i=0;i<6;i++){
      final x=x0+half*(i+.5)/6,r=math.min(half/12,h*.22);
      final box=RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,h*.55),width:r*2,height:r*1.4),const Radius.circular(3));
      c.drawRRect(box,Paint()..color=(lane?.opened.contains(i)??(i<n.clamp(0,5)))?Colors.amber:color.withAlpha(90));
      c.drawCircle(Offset(x,h*.55),2,Paint()..color=Colors.white);
     }
     break;
    case Challenge.numberBomb:
     final center=Offset(x0+half*.5,h*.55),r=math.min(half*.21,h*.32);
     c.drawCircle(center,r,Paint()..color=color.withAlpha(80));
     c.drawArc(Rect.fromCircle(center:center,radius:r),-math.pi/2,math.pi*2*(remaining/10000).clamp(0.0,1.0).toDouble(),false,Paint()..color=(remaining<3000?Colors.redAccent:color)..style=PaintingStyle.stroke..strokeWidth=4);
     c.drawCircle(center,math.min(n.toDouble()+2,r*.8),paint);
     break;
    case Challenge.mazeBattle:
     final maze=rules?.maze;
     final cell=math.min(half/6,h/5),ox=x0+(half-cell*5)/2,oy=(h-cell*4)/2;
     if(maze!=null){
       for(var i=0;i<20;i++){
        final x=ox+(i%5)*cell,y=oy+(i~/5)*cell;
        final wall=Paint()..color=Colors.white54..strokeWidth=1.2;
        if(maze.move(i,Direction.up)==null)c.drawLine(Offset(x,y),Offset(x+cell,y),wall);
        if(maze.move(i,Direction.left)==null)c.drawLine(Offset(x,y),Offset(x,y+cell),wall);
        if(maze.move(i,Direction.right)==null)c.drawLine(Offset(x+cell,y),Offset(x+cell,y+cell),wall);
        if(maze.move(i,Direction.down)==null)c.drawLine(Offset(x,y+cell),Offset(x+cell,y+cell),wall);
       }
       c.drawCircle(Offset(ox+4.5*cell,oy+3.5*cell),cell*.23,Paint()..color=Colors.amber);
       final pos=lane?.cell??0;c.drawCircle(Offset(ox+(pos%5+.5)*cell,oy+(pos~/5+.5)*cell),cell*.32,paint);
     }
     break;
    case Challenge.logicEscape:
     for(var i=0;i<6;i++){final x=x0+half*(i+.5)/6,y=h*.53;final r=math.min(h*.19,half/14);c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:r*1.6,height:r*1.5),const Radius.circular(3)),Paint()..color=i<(lane?.locks??0)?Colors.greenAccent:color);c.drawArc(Rect.fromCenter(center:Offset(x,y-r*.8),width:r,height:r),math.pi,math.pi,false,Paint()..color=Colors.white70..style=PaintingStyle.stroke..strokeWidth=2);}
     break;
    default:break;
   }
  }
  c.drawLine(Offset(w/2,0),Offset(w/2,h),Paint()..color=Colors.white24);
 }
 @override bool shouldRepaint(covariant _StagePainter old)=>rules!=null||old.challenge!=challenge||old.remaining!=remaining||old.points[0]!=points[0]||old.points[1]!=points[1];
}
