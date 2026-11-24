import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/character.dart';
class Arena extends FlameGame {
  double energy=.5, display=.5, clock=0;
  bool reduced=false;
  int leftAvatar=0,rightAvatar=5,score=0,seenScore=0;
  double burst=0,shake=0;
  int skin=0,effect=0,tint=0,background=0,failed=-1;
  int? victor;
  static const skins=[[Color(0xff112c69),Color(0xff24183d),Color(0xff6b3014)],[Color(0xff073b3a),Color(0xff0d6653),Color(0xff102943)],[Color(0xff240e4b),Color(0xff632c73),Color(0xff173773)]];
  static const tints=[Color(0xff4d9cff),Color(0xff38d6c4),Color(0xffa78bfa)];
  @override void update(double dt){super.update(dt);clock+=dt;if(failed>=0&&shake==0)shake=.32; if(shake>0){shake=max(0.0,shake-dt);if(shake==0)failed=-1;}if(score!=seenScore){seenScore=score;burst=.35;}burst=max(0.0,burst-dt);display=reduced?energy:display+(energy-display)*min(1.0,dt*9);}
  @override void render(Canvas canvas){
    super.render(canvas);
    final w=size.x,h=size.y;
    if(w<45||h<1)return;
    final rect=Rect.fromLTWH(0,0,w,h);
    canvas.drawRect(rect,Paint()..shader=LinearGradient(colors:skins[skin.clamp(0,2).toInt()]).createShader(rect));
    if(background>0){for(var i=0;i<12;i++){final px=(i*67.0)%w;canvas.drawCircle(Offset(px,(i*23.0)%h),background==1?1.8:3.0,Paint()..color=Colors.white24);}}
    final y=h/2,x=w*display;
    canvas.drawLine(Offset(22,y),Offset(w-22,y),Paint()..color=Colors.white24..strokeWidth=14..strokeCap=StrokeCap.round);
    canvas.drawLine(Offset(22,y),Offset(x.clamp(22,w-22).toDouble(),y),Paint()..color=tints[tint.clamp(0,2).toInt()]..strokeWidth=12..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(x,y),reduced?9:10+sin(clock*5)*2,Paint()..color=Colors.white);
    final radius=min(h*.42,w*.13);
    final bob=reduced?0.0:sin(clock*3)*2;
    drawAvatar(canvas,Offset(radius+5+(failed==0&&!reduced?sin(clock*65)*4:0),y+bob),radius*(victor==0&&!reduced?1.1:1),leftAvatar);
    drawAvatar(canvas,Offset(w-radius-5+(failed==1&&!reduced?sin(clock*65)*4:0),y-bob),radius*(victor==1&&!reduced?1.1:1),rightAvatar);
    if(!reduced&&burst>0){canvas.drawCircle(Offset(x,y),18+(1-burst/.35)*22,Paint()..color=(effect==0?palette[leftAvatar.clamp(0,5).toInt()]:effect==1?Colors.amber:Colors.cyanAccent).withAlpha((burst/.35*200).round())..style=PaintingStyle.stroke..strokeWidth=3);}
  }
}
