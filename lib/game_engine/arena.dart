import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/character.dart';
class Arena extends FlameGame {
  double energy=.5, display=.5, clock=0;
  bool reduced=false;
  int leftAvatar=0,rightAvatar=5,score=0,seenScore=0;
  double burst=0;
  @override void update(double dt){super.update(dt);clock+=dt;if(score!=seenScore){seenScore=score;burst=.35;}burst=max(0.0,burst-dt);display=reduced?energy:display+(energy-display)*min(1.0,dt*9);}
  @override void render(Canvas canvas){
    super.render(canvas);
    final w=size.x,h=size.y;
    if(w<45||h<1)return;
    final rect=Rect.fromLTWH(0,0,w,h);
    canvas.drawRect(rect,Paint()..shader=const LinearGradient(colors:[Color(0xff112c69),Color(0xff24183d),Color(0xff6b3014)]).createShader(rect));
    final y=h/2,x=w*display;
    canvas.drawLine(Offset(22,y),Offset(w-22,y),Paint()..color=Colors.white24..strokeWidth=14..strokeCap=StrokeCap.round);
    canvas.drawLine(Offset(22,y),Offset(x.clamp(22,w-22).toDouble(),y),Paint()..color=const Color(0xff4d9cff)..strokeWidth=12..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(x,y),reduced?9:10+sin(clock*5)*2,Paint()..color=Colors.white);
    final radius=min(h*.42,w*.13);
    final bob=reduced?0.0:sin(clock*3)*2;
    drawAvatar(canvas,Offset(radius+5,y+bob),radius,leftAvatar);
    drawAvatar(canvas,Offset(w-radius-5,y-bob),radius,rightAvatar);
    if(!reduced&&burst>0){canvas.drawCircle(Offset(x,y),18+(1-burst/.35)*22,Paint()..color=Colors.white.withAlpha((burst/.35*150).round())..style=PaintingStyle.stroke..strokeWidth=3);}
  }
}
