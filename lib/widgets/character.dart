import 'dart:math';
import 'package:flutter/material.dart';

const palette=[Color(0xff478de4),Color(0xffdbeafe),Color(0xff5e527c),Color(0xffff944e),Color(0xff30b89a),Color(0xffa28cf4)];
class AvatarArt extends StatelessWidget {
 final int index;final double size;
 const AvatarArt({super.key,required this.index,required this.size});
 @override Widget build(BuildContext context)=>CustomPaint(size:Size.square(size),painter:AvatarPainter(index));
}
class AvatarPainter extends CustomPainter{
 final int index;
 AvatarPainter(this.index);
 @override void paint(Canvas canvas,Size size)=>drawAvatar(canvas,size.center(Offset.zero),min(size.width,size.height)*.47,index);
 @override bool shouldRepaint(covariant AvatarPainter oldDelegate)=>oldDelegate.index!=index;
}
// Original vector sprites. Each has a silhouette, body, material highlights and equipment.
void drawAvatar(Canvas c,Offset center,double r,int index,{double action=0,bool hurt=false}){
 final i=index.clamp(0,5).toInt(),base=palette[i];
 final dark=const Color(0xff122034),white=const Color(0xfff4fbff);
 c.save();c.translate(center.dx,center.dy);c.scale(r/50);
 c.drawOval(const Rect.fromLTWH(-35,40,70,9),Paint()..color=Colors.black38);
 Paint material(Color color,Rect rect)=>Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.53)!,color,Color.lerp(color,Colors.black,.47)!],stops:const [0,.45,1]).createShader(rect);
 void rounded(Rect rect,double radius,Color color,{bool outline=true}){
  final rr=RRect.fromRectAndRadius(rect,Radius.circular(radius));
  c.drawRRect(rr,material(color,rect));
  if(outline)c.drawRRect(rr,Paint()..color=dark.withAlpha(150)..style=PaintingStyle.stroke..strokeWidth=1.5);
 }
 void oval(Rect rect,Color color,{bool outline=true}){
  c.drawOval(rect,material(color,rect));
  if(outline)c.drawOval(rect,Paint()..color=dark.withAlpha(140)..style=PaintingStyle.stroke..strokeWidth=1.5);
 }
 void polygon(List<Offset> pts,Color color){
  final path=Path()..addPolygon(pts,true);
  c.drawPath(path,material(color,path.getBounds()));
  c.drawPath(path,Paint()..color=dark.withAlpha(155)..style=PaintingStyle.stroke..strokeWidth=1.4..strokeJoin=StrokeJoin.round);
 }
 void dot(Offset p,double radius,Color color)=>c.drawCircle(p,radius,Paint()..color=color);
 // Feet, torso and articulated arms; head is deliberately large for small screens.
 for(final x in [-16.0,16.0])rounded(Rect.fromCenter(center:Offset(x,35),width:19,height:17),7,i==1?white:base);
 if(i==4){
  polygon([const Offset(-15,8),const Offset(-43,-8),const Offset(-48,20),const Offset(-22,15)],const Color(0xff387eac));
  polygon([const Offset(15,8),const Offset(43,-8),const Offset(48,20),const Offset(22,15)],const Color(0xff387eac));
 }else if(i==3){
  c.save();c.translate(27,24);c.rotate(-.48);oval(const Rect.fromLTWH(-4,-5,24,19),base);oval(const Rect.fromLTWH(10,-5,12,16),white);c.restore();
 }
 rounded(const Rect.fromLTWH(-23,5,46,32),13,base);
 for(final x in [-29.0,29.0]){
  c.save();c.translate(x,16);c.rotate((x<0?-1:1)*(.25+action*.5));rounded(const Rect.fromLTWH(-7,-8,14,24),6,base);oval(const Rect.fromLTWH(-8,9,16,12),i==1?white:base);c.restore();
 }
 if(i==0){rounded(const Rect.fromLTWH(-11,14,22,12),4,dark);dot(const Offset(0,20),4,const Color(0xff62f3ff));}
 if(i==1){rounded(const Rect.fromLTWH(-12,13,24,13),3,dark);for(var k=0;k<3;k++)dot(Offset(-6+k*6,19),2,k==1?Colors.orange:Colors.cyanAccent);}
 if(i==2){polygon([const Offset(-22,9),const Offset(-5,29),const Offset(9,35),const Offset(17,28),const Offset(-9,8)],const Color(0xffb04e76));}
 if(i==3||i==4)oval(const Rect.fromLTWH(-13,12,26,20),i==3?white:const Color(0xffa6edc5),outline:false);
 if(i==5){dot(const Offset(0,20),7,const Color(0xffe4bdff));dot(const Offset(0,20),3,white);}
 // Character-specific silhouette and face.
 if(i==0){
  c.drawLine(const Offset(0,-40),const Offset(0,-48),Paint()..color=base..strokeWidth=4);
  dot(const Offset(0,-47),4,const Color(0xff78f3ff));
  rounded(const Rect.fromLTWH(-39,-33,13,25),6,dark);
  rounded(const Rect.fromLTWH(26,-33,13,25),6,dark);
  rounded(const Rect.fromLTWH(-33,-43,66,57),17,base);
  rounded(const Rect.fromLTWH(-26,-32,52,28),10,dark);
  for(final x in [-12.0,12.0]){rounded(Rect.fromCenter(center:Offset(x,-18),width:10,height:hurt?3:13),4,const Color(0xff77f5ff),outline:false);}
  for(var k=0;k<3;k++)dot(Offset(-5+k*5,6),1.5,dark);
 }else if(i==1){
  rounded(const Rect.fromLTWH(-37,-26,10,22),5,white);
  rounded(const Rect.fromLTWH(27,-26,10,22),5,white);
  oval(const Rect.fromLTWH(-34,-47,68,64),white);
  oval(const Rect.fromLTWH(-27,-38,54,43),const Color(0xff193650));
  c.drawArc(const Rect.fromLTWH(-22,-34,44,35),3.4,1.2,false,Paint()..color=const Color(0xff86dfff)..style=PaintingStyle.stroke..strokeWidth=4..strokeCap=StrokeCap.round);
  for(final x in [-11.0,11.0])dot(Offset(x,-17),hurt?2:4,const Color(0xffd3f7ff));
  c.drawLine(const Offset(-5,12),const Offset(5,12),Paint()..color=Colors.orange..strokeWidth=3..strokeCap=StrokeCap.round);
 }else if(i==2){
  polygon([const Offset(20,-28),const Offset(47,-36),const Offset(41,-16),const Offset(24,-18)],const Color(0xffb04e76));
  oval(const Rect.fromLTWH(-33,-45,66,61),base);
  rounded(const Rect.fromLTWH(-28,-27,56,20),7,const Color(0xffe9b88d));
  rounded(const Rect.fromLTWH(-29,-35,58,9),4,const Color(0xffb04e76));
  for(final x in [-12.0,12.0])dot(Offset(x,-17),hurt?1.5:4,dark);
  rounded(const Rect.fromLTWH(-28,-5,56,18),9,dark);
 }else if(i==3){
  for(final x in [-23.0,23.0]){
   polygon([Offset(x-14,-21),Offset(x,-47),Offset(x+13,-23)],base);
   polygon([Offset(x-7,-24),Offset(x,-38),Offset(x+7,-24)],const Color(0xfff7bfad));
  }
  oval(const Rect.fromLTWH(-34,-36,68,52),base);
  oval(const Rect.fromLTWH(-27,-4,54,20),white,outline:false);
  dot(const Offset(0,2),5,dark);
  for(final x in [-13.0,13.0]){dot(Offset(x,-15),hurt?2:5,dark);dot(Offset(x-1,-17),1.8,white);}
 }else if(i==4){
  for(final x in [-21.0,21.0])polygon([Offset(x-9,-28),Offset(x,-47),Offset(x+8,-28)],const Color(0xfff6dca3));
  oval(const Rect.fromLTWH(-33,-38,66,54),base);
  oval(const Rect.fromLTWH(-22,-3,44,19),const Color(0xffa6edc5));
  for(final x in [-13.0,13.0]){oval(Rect.fromCenter(center:Offset(x,-17),width:14,height:16),const Color(0xffe8ffb0),outline:false);dot(Offset(x,-16),hurt?2:4,dark);}
  for(final x in [-6.0,6.0])dot(Offset(x,3),2.5,dark);
 }else{
  for(final x in [-16.0,16.0]){c.drawLine(Offset(x,-30),Offset(x*1.5,-45),Paint()..color=base..strokeWidth=4);dot(Offset(x*1.5,-45),5,const Color(0xffe5c4ff));}
  oval(const Rect.fromLTWH(-34,-40,68,54),base);
  for(final x in [-14.0,14.0]){oval(Rect.fromCenter(center:Offset(x,-18),width:19,height:hurt?5:22),dark,outline:false);dot(Offset(x-3,-22),3,white);}
  c.drawArc(const Rect.fromLTWH(-8,-3,16,10),0,pi,false,Paint()..color=dark..strokeWidth=2.2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
 }
 c.restore();
}

class VictoryAvatar extends StatelessWidget {
 final int index;final bool animate;
 const VictoryAvatar({super.key,required this.index,required this.animate});
 @override Widget build(BuildContext context)=>TweenAnimationBuilder<double>(
  tween:Tween(begin:animate ? 0.55 : 1.0,end:1.0),duration:Duration(milliseconds:animate?650:0),curve:Curves.easeOutBack,
  builder:(context,scale,child)=>Transform.scale(scale:scale,child:child),
  child:AvatarArt(index:index,size:100));
}
