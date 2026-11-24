import 'package:flutter/material.dart';
import 'character.dart';
import 'arcade.dart';
class ModeArt extends StatelessWidget{
 final int mode,avatar;
 const ModeArt({super.key,required this.mode,required this.avatar});
 @override Widget build(BuildContext context)=>CustomPaint(size:const Size(160,85),painter:_ModePainter(mode,avatar));
}
class _ModePainter extends CustomPainter{
 final int mode,avatar;
 _ModePainter(this.mode,this.avatar);
 @override void paint(Canvas c,Size s){
  final w=s.width,h=s.height,r=h*.39;
  final y=h*.48;
  final blue=arcadeBlue,orange=arcadeOrange;
  final center=Offset(w*.5,y);
  c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.83),width:w*.81,height:h*.17),Paint()..color=Colors.black26);
  if(mode==0||mode==1){
   drawAvatar(c,Offset(w*.26,y),r,avatar);drawAvatar(c,Offset(w*.74,y),r,mode==0?5:3);
   final p=Path()..addPolygon([center+const Offset(3,-16),center+const Offset(-9,2),center+const Offset(-1,2),center+const Offset(-5,16),center+const Offset(10,-5),center+const Offset(1,-5)],true);
   c.drawPath(p,Paint()..color=const Color(0xffffdf76));
  }else if(mode==2){
   drawAvatar(c,Offset(w*.29,y),r,avatar);
   for(var i=3;i>=1;i--){c.drawCircle(Offset(w*.73,y),r*i*.26,Paint()..color=i==2?blue:Colors.white70..style=PaintingStyle.stroke..strokeWidth=2.7);}
   c.drawLine(Offset(w*.46,y),Offset(w*.7,y),Paint()..color=Colors.white..strokeWidth=2.7..strokeCap=StrokeCap.round);
  }else{
   drawAvatar(c,Offset(w*.18,y),r*.8,avatar);drawAvatar(c,Offset(w*.43,y),r*.8,3);drawAvatar(c,Offset(w*.8,y),r,4);
   c.drawLine(Offset(w*.32,y),Offset(w*.7,y),Paint()..color=blue..strokeWidth=2.5);
   c.drawLine(Offset(w*.53,y+7),Offset(w*.7,y),Paint()..color=orange..strokeWidth=2.5);
  }
 }
 @override bool shouldRepaint(covariant _ModePainter oldDelegate)=>oldDelegate.mode!=mode||oldDelegate.avatar!=avatar;
}
