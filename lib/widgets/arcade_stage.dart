import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../question_generators/challenges.dart';
import '../game_engine/arcade_rules.dart';
import 'character.dart';

class ArcadeStage extends StatelessWidget {
 final Challenge challenge;
 final List<int> points;
 final int remaining;
 final bool reduced;
 final ArcadeRules? rules;
 final List<int>? fuseRemaining,avatars,fuseDurations;
 final int players,fuseDuration;
 const ArcadeStage({super.key,required this.challenge,required this.points,required this.remaining,required this.reduced,this.rules,this.fuseRemaining,this.avatars,this.players=2,this.fuseDuration=8000,this.fuseDurations});
 @override Widget build(BuildContext context)=>Semantics(label:players==1?'${challenge.label}: ${points[0]}':'${challenge.label}: ${points[0]} zu ${points[1]}',child:CustomPaint(painter:_StagePainter(challenge,List<int>.of(points),remaining,rules,fuseRemaining,avatars,players,fuseDuration,fuseDurations),size:Size.infinite));
}
class _StagePainter extends CustomPainter{
 final Challenge challenge;final List<int> points;final int remaining;
 final ArcadeRules? rules;
 final List<int>? fuseRemaining,avatars,fuseDurations;
 final int players,fuseDuration;
 _StagePainter(this.challenge,this.points,this.remaining,this.rules,this.fuseRemaining,this.avatars,this.players,this.fuseDuration,this.fuseDurations);
 @override void paint(Canvas c,Size s){
  final w=s.width,h=s.height;
  if(w<=0||h<=0)return;
  final rect=Offset.zero&s;
  c.drawRect(rect,Paint()..shader=const LinearGradient(colors:[Color(0xff162c50),Color(0xff080b15),Color(0xff493023)]).createShader(rect));
  if(rules?.boss==true){final a=rules!;final center=Offset(w*.5,h*.42);final r=math.min(h*.25,w*.11);c.drawCircle(center,r,Paint()..color=Colors.deepPurpleAccent);for(final dx in [-r*.35,r*.35])c.drawCircle(center+Offset(dx,-r*.1),r*.16,Paint()..color=Colors.white);c.drawRect(Rect.fromLTWH(w*.12,h*.79,w*.76,5),Paint()..color=Colors.white24);c.drawRect(Rect.fromLTWH(w*.12,h*.79,w*.76*a.bossHp/a.bossMaxHp,5),Paint()..color=Colors.redAccent);for(var i=0;i<a.teamHp;i++)c.drawCircle(Offset(w*.1+i*9,h*.2),3,Paint()..color=Colors.greenAccent);return;}
  final colors=[const Color(0xff318bff),const Color(0xffff943c)];
  for(var p=0;p<players;p++){
   final color=colors[p],n=points[p],x0=p*w/players,half=w/players;
   final lane=rules?.lanes[p];
   final paint=Paint()..color=color;
   switch(challenge){
    case Challenge.mathTower:
     final goal=rules?.towerGoalFor(p)??10,step=math.min(h/((rules?.towerGoalFor(p)??10)+2),10.0),width=half*.38;
     for(var i=0;i<math.min(lane?.blocks??n,goal);i++){
      final r=RRect.fromRectAndRadius(Rect.fromLTWH(x0+half*.31,h-4-(i+1)*step,width,step-1),const Radius.circular(2));
      c.drawRRect(r,paint);c.drawLine(r.outerRect.topLeft,r.outerRect.topRight,Paint()..color=Colors.white54..strokeWidth=1);
     }
     break;
    case Challenge.mathRace:
    case Challenge.rocketRace:
     final y=h*.55;
     c.drawLine(Offset(x0+8,y),Offset(x0+half-8,y),Paint()..color=Colors.white24..strokeWidth=4);
     for(var i=0;i<10;i++)c.drawCircle(Offset(x0+8+i*(half-16)/9,y),1.3,Paint()..color=Colors.white54);
     final r=math.min(h*.18,players==1?25.0:14.0);
     final margin=r+8;
     final x=x0+margin+math.max(0.0,half-2*margin)*(lane==null?n.clamp(0,10)/10:lane.position/100);
     if(challenge==Challenge.rocketRace){
      final active=(lane?.fuel??0)>0;
      for(var i=0;i<18;i++){final sx=x0+half*((i*37%101)/101),sy=h*((i*19%83)/83);c.drawCircle(Offset(sx,sy),i%4==0?1.6:.7,Paint()..color=Colors.white.withAlpha(90));}
      if(active){final flame=Path()..moveTo(x-r*.65,y-r*.27)..quadraticBezierTo(x-r*1.75,y,x-r*.65,y+r*.27)..close();c.drawPath(flame,Paint()..shader=LinearGradient(colors:[Colors.transparent,color,Colors.white]).createShader(Rect.fromLTWH(x-r*1.75,y-r*.3,r*1.1,r*.6)));}
      final fin=Path()..addPolygon([Offset(x-r*.5,y-r*.32),Offset(x-r*.95,y-r*.87),Offset(x+r*.12,y-r*.35),Offset(x+r*.12,y+r*.35),Offset(x-r*.95,y+r*.87),Offset(x-r*.5,y+r*.32)],true);
      c.drawPath(fin,paint);
      final body=Path()..moveTo(x-r*.65,y-r*.42)..quadraticBezierTo(x+r*.38,y-r*.53,x+r,y)..quadraticBezierTo(x+r*.38,y+r*.53,x-r*.65,y+r*.42)..close();
      c.drawPath(body,Paint()..shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.white,Color(0xffb4d9fb),Color(0xff4c73a2)]).createShader(Rect.fromLTWH(x-r,y-r*.5,r*2,r)));
      c.drawCircle(Offset(x+r*.28,y),r*.22,Paint()..color=color);
      c.drawCircle(Offset(x+r*.32,y-r*.07),r*.07,Paint()..color=Colors.white);
      final bar=Rect.fromLTWH(x0+margin,h*.82,math.max(1.0,half-2*margin),4);
      c.drawRRect(RRect.fromRectAndRadius(bar,const Radius.circular(3)),Paint()..color=Colors.white24);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left,bar.top,bar.width*((lane?.fuel??0)/6).clamp(0.0,1.0).toDouble(),4),const Radius.circular(3)),paint);
     }else{
      drawAvatar(c,Offset(x,y),r*1.25,avatars?[p]??p);
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
     final fuse=fuseRemaining?[p]??remaining;
     c.drawCircle(center,r,Paint()..color=color.withAlpha(80));
     c.drawArc(Rect.fromCircle(center:center,radius:r),-math.pi/2,math.pi*2*(fuse/math.max(1,fuseDurations?[p]??fuseDuration)).clamp(0.0,1.0).toDouble(),false,Paint()..color=(fuse<3000?Colors.redAccent:color)..style=PaintingStyle.stroke..strokeWidth=4);
     c.drawCircle(center,math.min(n.toDouble()+2,r*.8),paint);
     break;
    case Challenge.mazeBattle:
     final maze=rules?.mazeFor(p);
     if(maze!=null){
       final cell=math.min(half/(maze.columns+1),h/(maze.rows+1)),ox=x0+(half-cell*maze.columns)/2,oy=(h-cell*maze.rows)/2;
       for(var i=0;i<=maze.end;i++){
        final x=ox+(i%maze.columns)*cell,y=oy+(i~/maze.columns)*cell;
        final wall=Paint()..color=Colors.white54..strokeWidth=1.2;
        if(maze.move(i,Direction.up)==null)c.drawLine(Offset(x,y),Offset(x+cell,y),wall);
        if(maze.move(i,Direction.left)==null)c.drawLine(Offset(x,y),Offset(x,y+cell),wall);
        if(maze.move(i,Direction.right)==null)c.drawLine(Offset(x+cell,y),Offset(x+cell,y+cell),wall);
        if(maze.move(i,Direction.down)==null)c.drawLine(Offset(x,y+cell),Offset(x+cell,y+cell),wall);
       }
       c.drawCircle(Offset(ox+(maze.columns-.5)*cell,oy+(maze.rows-.5)*cell),cell*.23,Paint()..color=Colors.amber);
       final pos=lane?.cell??0;c.drawCircle(Offset(ox+(pos%maze.columns+.5)*cell,oy+(pos~/maze.columns+.5)*cell),cell*.32,paint);
     }
     break;
    case Challenge.logicEscape:
     for(var i=0;i<(rules?.escapeGoalFor(p)??6);i++){final x=x0+half*(i+.5)/(rules?.escapeGoalFor(p)??6),y=h*.53;final r=math.min(h*.19,half/14);c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,y),width:r*1.6,height:r*1.5),const Radius.circular(3)),Paint()..color=i<(lane?.locks??0)?Colors.greenAccent:color);c.drawArc(Rect.fromCenter(center:Offset(x,y-r*.8),width:r,height:r),math.pi,math.pi,false,Paint()..color=Colors.white70..style=PaintingStyle.stroke..strokeWidth=2);}
     break;
    default:break;
   }
  }
  if(players==2)c.drawLine(Offset(w/2,0),Offset(w/2,h),Paint()..color=Colors.white24);
 }
 @override bool shouldRepaint(covariant _StagePainter old)=>rules!=null||fuseRemaining!=null||old.players!=players||old.challenge!=challenge||old.remaining!=remaining||old.points[0]!=points[0]||old.points[1]!=points[1];
}
