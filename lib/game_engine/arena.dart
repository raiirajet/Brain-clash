import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/character.dart';

class Arena extends FlameGame {
 double energy=.5,display=.5,clock=0;
 bool reduced=false;
 int leftAvatar=0,rightAvatar=5,score=0;
 double shake=0;
 int skin=0,effect=0,tint=0,background=0,failed=-1;
 int? victor;
 final pulses=[0.0,0.0];
 static const skins=[[Color(0xff102c60),Color(0xff141329),Color(0xff662c13)],[Color(0xff073b3a),Color(0xff0d6653),Color(0xff102943)],[Color(0xff240e4b),Color(0xff632c73),Color(0xff173773)]];
 static const tints=[Color(0xff4d9cff),Color(0xff38d6c4),Color(0xffa78bfa)];
 void hit(int player){pulses[player]=.65;}
 void clearEffects(){pulses[0]=0;pulses[1]=0;display=.5;shake=0;}
 @override void update(double dt){
  super.update(dt);clock+=dt;
  if(failed>=0&&shake==0)shake=.32;
  if(shake>0){shake=max(0.0,shake-dt);if(shake==0)failed=-1;}
  for(var p=0;p<2;p++){pulses[p]=max(0.0,pulses[p]-dt);}
  display=reduced?energy:display+(energy-display)*min(1.0,dt*10);
 }
 @override void render(Canvas canvas){
  super.render(canvas);
  final w=size.x,h=size.y;if(w<45||h<1)return;
  final rect=Rect.fromLTWH(0,0,w,h);
  final blue=tints[tint.clamp(0,2).toInt()],orange=const Color(0xffffa04d);
  canvas.drawRect(rect,Paint()..shader=LinearGradient(colors:skins[skin.clamp(0,2).toInt()]).createShader(rect));
  final y=h*.55,x=w*display;
  final radius=min(h*.32,w*.13);
  // Distinct coloured territories, a luminous front line and a perspective floor.
  canvas.drawRect(Rect.fromLTWH(0,0,x,h),Paint()..color=blue.withAlpha(26));
  canvas.drawRect(Rect.fromLTWH(x,0,w-x,h),Paint()..color=orange.withAlpha(24));
  for(var i=0;i<9;i++){
   canvas.drawLine(Offset(w/2+(i-4)*w*.045,h*.63),Offset(i*w/8,h),Paint()..color=Colors.white12..strokeWidth=.7);
  }
  for(var i=0;i<4;i++){final fy=h*(.67+i*.10);canvas.drawLine(Offset(0,fy),Offset(w,fy),Paint()..color=Colors.white12..strokeWidth=.7);}
  if(background>0){for(var i=0;i<18;i++){canvas.drawCircle(Offset((i*67.0)%w,(i*23.0)%h),background==1?1.4:2.6,Paint()..color=Colors.white24);}}
  final barY=h*.84,bar=RRect.fromRectAndRadius(Rect.fromLTWH(12,barY,w-24,7),const Radius.circular(5));
  canvas.drawRRect(bar,Paint()..color=orange);
  final front=12+(w-24)*display;
  canvas.save();canvas.clipRRect(bar);canvas.drawRect(Rect.fromLTWH(12,barY,max(0.0,front-12),7),Paint()..color=blue);canvas.restore();
  canvas.drawLine(Offset(x,7),Offset(x,h-5),Paint()..color=Colors.white.withAlpha(65)..strokeWidth=8);
  canvas.drawLine(Offset(x,7),Offset(x,h-5),Paint()..color=Colors.white..strokeWidth=1.5);
  canvas.drawCircle(Offset(front,barY+3.5),5,Paint()..color=Colors.white);
  for(var p=0;p<2;p++){
   final base=p==0?blue:orange;
   final avatar=p==0?leftAvatar:rightAvatar;
   final progress=1-pulses[p]/.65;
   final pulse=reduced?0.0:sin(progress*pi)*min(20.0,w*.05);
   final bob=reduced?0.0:sin(clock*3+p)*2;
   final offset=Offset(p==0?w*.18+pulse:w*.82-pulse,y+bob+(failed==p&&!reduced?sin(clock*60)*3:0));
   canvas.drawOval(Rect.fromCenter(center:Offset(offset.dx,y+radius*.82),width:radius*2.7,height:radius*.58),Paint()..color=base.withAlpha(75));
   canvas.drawCircle(offset,radius*1.16,Paint()..color=base.withAlpha(30));
   drawAvatar(canvas,offset,radius*(pulses[p]>0&&!reduced?1.08:1),avatar);
   if(pulses[p]>0&&!reduced){
    final c=effect==0?palette[avatar.clamp(0,5).toInt()]:effect==1?Colors.amber:Colors.cyanAccent;
    final target=Offset(offset.dx+(x-offset.dx)*progress,y);
    canvas.drawLine(offset,target,Paint()..color=c.withAlpha(90)..strokeWidth=9..strokeCap=StrokeCap.round);
    canvas.drawLine(offset,target,Paint()..color=Colors.white..strokeWidth=2..strokeCap=StrokeCap.round);
    canvas.drawCircle(target,5+sin(progress*pi)*6,Paint()..color=c);
    for(var i=0;i<10;i++){
     final a=i*pi/5;final distance=progress*min(45.0,h*.36);
     canvas.drawCircle(target+Offset(cos(a)*distance,sin(a)*distance),2.8*(1-progress)+.5,Paint()..color=c.withAlpha(((1-progress)*255).round()));
    }
    canvas.drawCircle(Offset(x,y),6+progress*min(30.0,h*.28),Paint()..color=c.withAlpha(((1-progress)*220).round())..style=PaintingStyle.stroke..strokeWidth=2);
   }
  }
  void label(String value,Offset center,Color color){
   final tp=TextPainter(text:TextSpan(text:value,style:TextStyle(color:color,fontSize:h<70?11:16,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();
   tp.paint(canvas,center-Offset(tp.width/2,tp.height/2));
  }
  label('${(display*100).round()}%',Offset(w*.18,h*.13),blue);
  label('${(100-display*100).round()}%',Offset(w*.82,h*.13),orange);
 }
}
