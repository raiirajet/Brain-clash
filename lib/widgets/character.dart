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
void drawAvatar(Canvas c,Offset center,double r,int index){
 final i=index.clamp(0,5).toInt(),base=palette[index.clamp(0,5).toInt()];
 c.save();c.translate(center.dx,center.dy);c.scale(r/50);
 final shadow=Paint()..color=const Color(0x66000000);
 c.drawOval(const Rect.fromLTWH(-42,37,84,13),shadow);
 final body=Paint()..shader=RadialGradient(center:const Alignment(-.5,-.65),colors:[Color.lerp(base,Colors.white,.55)!,base,Color.lerp(base,Colors.black,.45)!],stops:const [0,.52,1]).createShader(const Rect.fromLTWH(-50,-50,100,100));
 final dark=Paint()..color=const Color(0xff162337);
 final light=Paint()..color=const Color(0xfff4fbff);
 void ear(double x,double y){final p=Path()..moveTo(x-15,y+22)..lineTo(x,y-12)..lineTo(x+18,y+24)..close();c.drawPath(p,body);}
 if(i==3||i==4){ear(-27,-35);ear(27,-35);}
 if(i==0){
   c.drawLine(const Offset(0,-34),const Offset(0,-46),Paint()..color=base..strokeWidth=5..strokeCap=StrokeCap.round);
   c.drawCircle(const Offset(0,-47),6,body);
   c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-43,-34,86,72),const Radius.circular(24)),body);
   c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-32,-18,64,36),const Radius.circular(14)),dark);
 }else if(i==1){
   c.drawCircle(const Offset(0,-1),43,body);
   c.drawOval(const Rect.fromLTWH(-33,-25,66,48),dark);
 }else if(i==2){
   c.drawCircle(Offset.zero,43,body);
   c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-36,-16,72,29),const Radius.circular(12)),Paint()..color=const Color(0xffe2b78d));
   c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-38,14,76,25),const Radius.circular(15)),dark);
 }else{
   c.drawOval(const Rect.fromLTWH(-44,-36,88,76),body);
   if(i==3)c.drawOval(const Rect.fromLTWH(-31,8,62,29),light);
   if(i==4){c.drawOval(const Rect.fromLTWH(-25,7,50,25),Paint()..color=const Color(0xffb2f5d2));}
   if(i==5){c.drawLine(const Offset(15,-30),const Offset(27,-44),Paint()..color=base..strokeWidth=5);c.drawCircle(const Offset(29,-45),6,body);}
 }
 for(final x in [-16.0,16.0]){
   c.drawOval(Rect.fromCenter(center:Offset(x,-4),width:i==5?18:12,height:i==5?21:15),i==0||i==1?light:dark);
   c.drawCircle(Offset(x-2,-7),2,Paint()..color=i==0||i==1?const Color(0xff76dfff):Colors.white);
 }
 if(i!=2&&i!=0&&i!=1){c.drawArc(const Rect.fromLTWH(-8,7,16,13),0,pi,false,Paint()..color=dark.color..style=PaintingStyle.stroke..strokeWidth=2.5..strokeCap=StrokeCap.round);}
 c.restore();
}
