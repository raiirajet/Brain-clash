import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../question_generators/challenges.dart';

class ArcadeStage extends StatelessWidget {
 final Challenge challenge;
 final List<int> points;
 final int remaining;
 final bool reduced;
 const ArcadeStage({super.key,required this.challenge,required this.points,required this.remaining,required this.reduced});
 @override Widget build(BuildContext context)=>Semantics(label:'${challenge.label}: ${points[0]} zu ${points[1]}',child:CustomPaint(painter:_StagePainter(challenge,List<int>.of(points),remaining),size:Size.infinite));
}
class _StagePainter extends CustomPainter{
 final Challenge challenge;final List<int> points;final int remaining;
 _StagePainter(this.challenge,this.points,this.remaining);
 @override void paint(Canvas c,Size s){
  final w=s.width,h=s.height;
  if(w<=0||h<=0)return;
  final rect=Offset.zero&s;
  c.drawRect(rect,Paint()..shader=const LinearGradient(colors:[Color(0xff162c50),Color(0xff080b15),Color(0xff493023)]).createShader(rect));
  final colors=[const Color(0xff318bff),const Color(0xffff943c)];
  for(var p=0;p<2;p++){
   final color=colors[p],n=points[p],x0=p*w/2,half=w/2;
   final paint=Paint()..color=color;
   switch(challenge){
    case Challenge.mathTower:
     final step=math.min(h/12,10.0),width=half*.38;
     for(var i=0;i<math.min(n,10);i++){
      final r=RRect.fromRectAndRadius(Rect.fromLTWH(x0+half*.31,h-4-(i+1)*step,width,step-1),const Radius.circular(2));
      c.drawRRect(r,paint);c.drawLine(r.outerRect.topLeft,r.outerRect.topRight,Paint()..color=Colors.white54..strokeWidth=1);
     }
     break;
    case Challenge.mathRace:
    case Challenge.rocketRace:
     final y=h*.55;
     c.drawLine(Offset(x0+8,y),Offset(x0+half-8,y),Paint()..color=Colors.white24..strokeWidth=4);
     for(var i=0;i<10;i++)c.drawCircle(Offset(x0+8+i*(half-16)/9,y),1.3,Paint()..color=Colors.white54);
     final x=x0+8+(half-16)*n.clamp(0,10)/10;
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
     for(var i=0;i<5;i++){
      final x=x0+half*(i+.5)/5,r=math.min(half/12,h*.22);
      final box=RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(x,h*.55),width:r*2,height:r*1.4),const Radius.circular(3));
      c.drawRRect(box,Paint()..color=i<n.clamp(0,5)?Colors.amber:color.withAlpha(90));
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
     final cell=math.min(half/7,h/4);
     final ox=x0+(half-cell*6)/2,oy=(h-cell*3)/2;
     for(var i=0;i<7;i++)c.drawLine(Offset(ox+i*cell,oy),Offset(ox+i*cell,oy+cell*3),Paint()..color=Colors.white24);
     for(var i=0;i<4;i++)c.drawLine(Offset(ox,oy+i*cell),Offset(ox+cell*6,oy+i*cell),Paint()..color=Colors.white24);
     final index=n.clamp(0,17).toInt(),row=index~/6,col=row.isEven?index%6:5-index%6;
     c.drawCircle(Offset(ox+(col+.5)*cell,oy+(row+.5)*cell),cell*.32,paint);
     break;
    default:break;
   }
  }
  c.drawLine(Offset(w/2,0),Offset(w/2,h),Paint()..color=Colors.white24);
 }
 @override bool shouldRepaint(covariant _StagePainter old)=>old.challenge!=challenge||old.remaining!=remaining||old.points[0]!=points[0]||old.points[1]!=points[1];
}
