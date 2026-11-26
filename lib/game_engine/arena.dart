import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/character.dart';
import '../widgets/battle_effects.dart';

class Arena extends FlameGame {
 double energy=.5,display=.5,clock=0;
 bool reduced=false,training=false,team=false;
 int leftAvatar=0,rightAvatar=5,score=0,leftCostume=0,rightCostume=0;
 double shake=0;
 int skin=0,effect=0,tint=0,background=0,failed=-1;
 int? victor;
 final pulses=[0.0,0.0];
 static const skins=[[Color(0xff102c60),Color(0xff141329),Color(0xff662c13)],[Color(0xff073b3a),Color(0xff0d6653),Color(0xff102943)],[Color(0xff240e4b),Color(0xff632c73),Color(0xff173773)],[Color(0xff4e160c),Color(0xff281117),Color(0xffb5481e)],[Color(0xff133955),Color(0xff104d68),Color(0xff629ec4)],[Color(0xff543d15),Color(0xff292112),Color(0xff967329)]];
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
  canvas.drawRect(rect,Paint()..shader=LinearGradient(colors:skins[skin.clamp(0,5).toInt()]).createShader(rect));
  drawStage(canvas,Size(w,h),skin,clock,reduced);
  final y=h*.55,x=w*display;
  if(training||team){renderCooperative(canvas,w,h,blue,orange);return;}
  final radius=min(h*.39,w*.15);
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
   drawAvatar(canvas,offset,radius*(pulses[p]>0&&!reduced?1.08:1),avatar,action:0,hurt:failed==p,faceLeft:p==1,pose:reduced?0:failed==p?3:pulses[p]>0?(progress<.25?1:progress<.73?2:5):0,costume:p==0?leftCostume:rightCostume);
   if(pulses[p]>0&&!reduced){
    final c=effect==0?palette[avatar.clamp(0,palette.length-1).toInt()]:effect==1?Colors.amber:Colors.cyanAccent;
    drawAttack(canvas,offset,Offset(x,y),progress,c,avatar,radius);
   }
  }
  void label(String value,Offset center,Color color){
   final tp=TextPainter(text:TextSpan(text:value,style:TextStyle(color:color,fontSize:h<70?11:16,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();
   tp.paint(canvas,center-Offset(tp.width/2,tp.height/2));tp.dispose();
  }
  label('${(display*100).round()}%',Offset(w*.18,h*.13),blue);
  label('${(100-display*100).round()}%',Offset(w*.82,h*.13),orange);
 }
 void renderCooperative(Canvas canvas,double w,double h,Color blue,Color orange){
  final y=h*.49;
  final radius=min(h*.36,w*.12);
  final anchor=Offset(team?w*.78:w*.64,y);
  // A clear target for practice; a distinct monster for cooperative play.
  for(var i=0;i<7;i++){
   final xx=i*w/6;
   canvas.drawLine(Offset(w*.5+(i-3)*w*.035,h*.65),Offset(xx,h),Paint()..color=Colors.white12..strokeWidth=.7);
  }
  if(team){
   canvas.drawCircle(anchor,radius,Paint()..color=orange.withAlpha(75));
   canvas.drawCircle(anchor,radius*.72,Paint()..color=orange..style=PaintingStyle.stroke..strokeWidth=3);
   canvas.drawCircle(anchor,radius*.25,Paint()..color=Colors.white);
  }else{
   for(var i=3;i>=1;i--){
    canvas.drawCircle(anchor,radius*i/3,Paint()..color=blue.withAlpha(30+i*25)..style=PaintingStyle.stroke..strokeWidth=3);
   }
   canvas.drawCircle(anchor,radius*.24,Paint()..color=Colors.white);
  }
  for(var p=0;p<(team?2:1);p++){
   final base=p==0?blue:orange,avatar=p==0?leftAvatar:rightAvatar;
   final t=1-pulses[p]/.65;
   final jump=reduced?0.0:sin(t*pi)*8;
   final center=Offset(w*(team?(p==0 ? .14 : .37):.28)+jump,y+(reduced?0.0:sin(clock*3+p)*2));
   canvas.drawOval(Rect.fromCenter(center:Offset(center.dx,y+radius*.75),width:radius*2.4,height:radius*.52),Paint()..color=base.withAlpha(80));
   drawAvatar(canvas,center,radius*(pulses[p]>0&&!reduced?1.08:1),avatar,action:0,hurt:failed==p,pose:reduced?0:failed==p?3:pulses[p]>0?(t<.25?1:t<.73?2:5):0,costume:p==0?leftCostume:rightCostume);
   if(pulses[p]>0&&!reduced){
    final c=effect==0?palette[avatar.clamp(0,palette.length-1).toInt()]:effect==1?Colors.amber:Colors.cyanAccent;
    drawAttack(canvas,center,anchor,t,c,avatar,radius);
   }
  }
  final bar=RRect.fromRectAndRadius(Rect.fromLTWH(15,h*.82,w-30,7),const Radius.circular(5));
  canvas.drawRRect(bar,Paint()..color=Colors.white24);
  final portion=team?((1-display)*2).clamp(0.0,1.0):(score%10)/10;
  canvas.save();canvas.clipRRect(bar);canvas.drawRect(Rect.fromLTWH(15,h*.82,(w-30)*portion,7),Paint()..color=team?orange:blue);canvas.restore();
  final text=team?'${(portion*100).round()}%':'$score ✓';
  final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:Colors.white,fontSize:h<70?11:17,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();
  tp.paint(canvas,Offset(w*.5-tp.width/2,2));tp.dispose();
 }

}
