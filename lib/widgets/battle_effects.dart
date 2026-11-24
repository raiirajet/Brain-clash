import 'dart:math' as math;
import 'package:flutter/material.dart';

// Draw distinct attack silhouettes using the character's identity, no raster assets or timers.
void drawAttack(Canvas canvas,Offset from,Offset to,double progress,Color color,int variant,double radius){
 final t=progress.clamp(0.0,1.0).toDouble();
 final impact=(t/.76).clamp(0.0,1.0).toDouble();
 final fade=1-t;
 final tip=Offset.lerp(from,to,impact)!;
 final vector=to-from;
 final angle=math.atan2(vector.dy,vector.dx);
 final normal=Offset(-math.sin(angle),math.cos(angle));
 final width=(radius*.22).clamp(2.0,8.0).toDouble();
 final strength=(fade*200).round();
 final trail=Path()..moveTo(from.dx,from.dy);
 for(var i=1;i<=9;i++){
  final f=i/9;final p=Offset.lerp(from,tip,f)!+normal*math.sin(f*math.pi*5)*width*(1-f);
  trail.lineTo(p.dx,p.dy);
 }
 canvas.drawPath(trail,Paint()..color=color.withAlpha(strength)..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..strokeWidth=width*2.2);
 canvas.drawPath(trail,Paint()..color=Colors.white.withAlpha((fade*245).round())..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=width*.55);
 canvas.save();canvas.translate(tip.dx,tip.dy);canvas.rotate(angle);
 final fill=Paint()..color=color.withAlpha((fade*255).round());
 final core=Paint()..color=Colors.white.withAlpha((fade*255).round());
 switch(variant%12){
  case 0: // robot: electric bolt
   final p=Path()..addPolygon([Offset(-width,-width),Offset(width*.5,-width),Offset(0,0),Offset(width*1.5,0),Offset(-width*.6,width*1.8),Offset(0,width*.5),Offset(-width*1.5,width*.5)],true);canvas.drawPath(p,core);break;
  case 1: // astronaut: comet
   canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:width*3.5,height:width*1.8),fill);canvas.drawCircle(Offset(width*.6,0),width*.75,core);break;
  case 2: // ninja: spinning shuriken
   canvas.rotate(t*math.pi*5);final p=Path();for(var j=0;j<8;j++){final a=j*math.pi/4;final rr=j.isEven?width*2:width*.55;final o=Offset(math.cos(a)*rr,math.sin(a)*rr);if(j==0){p.moveTo(o.dx,o.dy);}else{p.lineTo(o.dx,o.dy);}}p.close();canvas.drawPath(p,core);break;
  case 3: // fox: flame
   final p=Path()..moveTo(width*2,0)..quadraticBezierTo(-width,-width*2,-width*2,0)..quadraticBezierTo(-width,width*2,width*2,0);canvas.drawPath(p,fill);canvas.drawCircle(Offset(width*.45,0),width*.65,core);break;
  case 4: // dragon: emerald orb
   canvas.drawCircle(Offset.zero,width*1.8,fill);canvas.drawCircle(Offset.zero,width,core);canvas.drawCircle(Offset.zero,width*2.2,Paint()..color=color.withAlpha(strength)..style=PaintingStyle.stroke..strokeWidth=1.3);break;
  case 5: // alien: plasma ring
   canvas.drawCircle(Offset.zero,width*1.65,Paint()..color=color.withAlpha(strength)..style=PaintingStyle.stroke..strokeWidth=width*.6);canvas.drawCircle(Offset.zero,width*.6,core);break;
  case 6: // Frost crystal
   canvas.drawPath(Path()..addPolygon([Offset(width*2,0),Offset(0,-width),Offset(-width*2,0),Offset(0,width)],true),fill);canvas.drawLine(Offset(-width,0),Offset(width,0),core..strokeWidth=2);break;
  case 7: // Ember sparks
   for(var i=0;i<5;i++){final a=i*math.pi*2/5;canvas.drawCircle(Offset(math.cos(a)*width,math.sin(a)*width),width*.7,fill);}canvas.drawCircle(Offset.zero,width*.6,core);break;
  case 8: // Titan shield
   canvas.drawPath(Path()..addPolygon([Offset(-width,-width),Offset(width,-width),Offset(width,width*.2),Offset(0,width*1.6),Offset(-width,width*.2)],true),fill);canvas.drawCircle(Offset.zero,width*.45,core);break;
  case 9: // Luna crescent
   canvas.drawArc(Rect.fromCircle(center:Offset.zero,radius:width*1.6),-.7,4.0,false,fill..style=PaintingStyle.stroke..strokeWidth=width*.7);break;
  case 10: // Orion laser
   canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-width*3,-width*.4,width*5,width*.8),Radius.circular(width*.4)),fill);canvas.drawLine(Offset(-width*2,0),Offset(width,0),core..strokeWidth=width*.3);break;
  default: // Sol solar flare
   for(var i=0;i<12;i++){final a=i*math.pi/6;canvas.drawLine(Offset(math.cos(a)*width,math.sin(a)*width),Offset(math.cos(a)*width*2.2,math.sin(a)*width*2.2),fill..strokeWidth=2);}canvas.drawCircle(Offset.zero,width,core);break;
 }
 canvas.restore();
 if(t>.48){
  final u=(t-.48)/.52;
  canvas.drawCircle(to,width+u*radius*.85,Paint()..color=color.withAlpha(((1-u)*210).round())..style=PaintingStyle.stroke..strokeWidth=2.2);
  for(var j=0;j<12;j++){
   final a=j*math.pi/6+variant*.2;final p=to+Offset(math.cos(a),math.sin(a))*u*radius*1.45;
   canvas.drawCircle(p,1.1+(1-u)*width*.45,Paint()..color=color.withAlpha(((1-u)*255).round()));
  }
 }
}

void drawStage(Canvas canvas,Size size,int skin,double clock,bool reduced){
 final w=size.width,h=size.height;
 final horizon=h*.63;
 final colors=[const Color(0xff478fff),const Color(0xff63d9a7),const Color(0xffbc8aff),const Color(0xffff743e),const Color(0xff9de8ff),const Color(0xffffcf54)];
 final accent=colors[skin.clamp(0,5).toInt()];
 final floor=Paint()..color=const Color(0x55050a18);
 canvas.drawRect(Rect.fromLTWH(0,horizon,w,h-horizon),floor);
 if(skin==0){
  for(var i=0;i<15;i++){
   final x=i*w/14;final bh=h*(.12+(i*7%5)*.045);
   canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w/42,horizon-bh,w/23,bh),const Radius.circular(2)),Paint()..color=const Color(0x55060d22));
   for(var j=0;j<3;j++){canvas.drawRect(Rect.fromLTWH(x-1,horizon-bh+3+j*4,2,1.8),Paint()..color=accent.withAlpha(70));}
  }
 }else if(skin==1){
  for(var i=0;i<9;i++){
   final x=i*w/8;
   final path=Path()..moveTo(x,horizon)..quadraticBezierTo(x-w*.07,h*.25,x-w*.035,h*.1)..quadraticBezierTo(x+w*.04,h*.3,x,horizon);
   canvas.drawPath(path,Paint()..color=accent.withAlpha(45));
  }
 }else if(skin==2){
  canvas.drawCircle(Offset(w*.78,h*.25),h*.18,Paint()..shader=RadialGradient(colors:[accent.withAlpha(100),const Color(0x11234080)]).createShader(Rect.fromCircle(center:Offset(w*.78,h*.25),radius:h*.18)));
  for(var i=0;i<30;i++){final x=(i*79.0)%w,y=(i*31.0)%(h*.62);canvas.drawCircle(Offset(x,y),i%4==0?1.8:.8,Paint()..color=Colors.white.withAlpha(80+i%4*25));}
 }else if(skin==3){
  for(var i=0;i<6;i++){final x=w*i/5;final path=Path()..moveTo(x-w*.15,horizon)..lineTo(x,h*.14)..lineTo(x+w*.15,horizon)..close();canvas.drawPath(path,Paint()..color=accent.withAlpha(45));}
  for(var i=0;i<20;i++){final y=(i*17.0+(reduced?0:clock*8))%(h*.58);canvas.drawCircle(Offset((i*53.0)%w,h*.58-y),1.5,Paint()..color=accent.withAlpha(170));}
 }else if(skin==4){
  for(var i=0;i<9;i++){final x=i*w/8;final p=Path()..moveTo(x-w*.045,horizon)..lineTo(x,h*.12+(i%3)*h*.08)..lineTo(x+w*.055,horizon)..close();canvas.drawPath(p,Paint()..color=accent.withAlpha(75));}
 }else{
  for(var i=0;i<7;i++){final x=i*w/6;canvas.drawRect(Rect.fromLTWH(x-5,h*.12,10,horizon-h*.12),Paint()..color=accent.withAlpha(70));canvas.drawRect(Rect.fromLTWH(x-8,h*.11,16,4),Paint()..color=accent.withAlpha(140));}
  canvas.drawCircle(Offset(w*.5,h*.24),h*.13,Paint()..color=accent.withAlpha(150));
 }
 canvas.drawLine(Offset(0,horizon),Offset(w,horizon),Paint()..color=accent.withAlpha(110)..strokeWidth=1);
 for(var i=0;i<11;i++){canvas.drawLine(Offset(w/2+(i-5)*w*.035,horizon),Offset(i*w/10,h),Paint()..color=accent.withAlpha(45)..strokeWidth=.7);}
 for(var i=1;i<=4;i++){
  final phase=reduced?0.0:(clock*.18)%1;
  final f=(i+phase)/5;final y=horizon+(h-horizon)*f*f;
  canvas.drawLine(Offset(0,y),Offset(w,y),Paint()..color=accent.withAlpha(45)..strokeWidth=.7);
 }
}
