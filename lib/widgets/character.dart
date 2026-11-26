import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/fighters.dart';

const palette = [Color(0xffa78bfa),Color(0xff478de4),Color(0xffee4aab),Color(0xff8958ec),Color(0xffff944e),Color(0xfff25c45),Color(0xffdb3c35),Color(0xff9867d9),Color(0xff41d4e8)];
final Map<int,ui.Image> _art = {};
// A single atlas is decoded once per fighter; nothing is loaded during painting.
Future<bool> preloadCharacterArt() async {
  var complete = true;
  for (var i=0;i<fighterIds.length;i++) {
    if (_art.containsKey(i)) continue;
    try {
      final data=await rootBundle.load('assets/characters/${fighterIds[i]}.webp');
      final codec=await ui.instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes));
      try {
        final frame=await codec.getNextFrame();
        if(frame.image.width!=960 || frame.image.height!=640){
          frame.image.dispose();
          complete=false;
        } else {
          _art[i]=frame.image;
        }
      } finally {codec.dispose();}
    } catch (_) {complete=false;}
  }
  return complete;
}

class AvatarArt extends StatelessWidget {
 final int index,costume,pose;final double size;
 const AvatarArt({super.key,required this.index,required this.size,this.costume=0,this.pose=0});
 @override Widget build(BuildContext context)=>CustomPaint(size:Size.square(size),painter:AvatarPainter(index,costume:costume,pose:pose));
}
class AvatarPainter extends CustomPainter{
 final int index,costume,pose;
 AvatarPainter(this.index,{this.costume=0,this.pose=0});
 @override void paint(Canvas canvas,Size size)=>drawAvatar(canvas,size.center(Offset.zero),min(size.width,size.height)*.47,index,costume:costume,pose:pose);
 @override bool shouldRepaint(covariant AvatarPainter oldDelegate)=>oldDelegate.index!=index||oldDelegate.costume!=costume||oldDelegate.pose!=pose;
}
// Poses: 0 idle, 1 charge, 2 attack, 3 error, 4 victory, 5 recover.
void drawAvatar(Canvas c,Offset center,double r,int index,{double action=0,bool hurt=false,int costume=0,int? pose,bool faceLeft=false}){
 final i=validFighter(index);
 final image=_art[i];
 final frame=(pose??(hurt?3:action>.55?2:action>.06?1:0)).clamp(0,5).toInt();
 c.save();c.translate(center.dx,center.dy);
 if(faceLeft)c.scale(-1,1);
 if(image!=null){
  final src=Rect.fromLTWH((frame%3)*320.0,(frame~/3)*320.0,320,320);
  c.drawImageRect(image,src,Rect.fromLTWH(-r,-r,2*r,2*r),Paint()..filterQuality=FilterQuality.medium);
 }else{
  // Neutral fallback for tests and missing assets, never an old character.
  c.drawCircle(Offset.zero,r*.55,Paint()..color=palette[i].withAlpha(70));
  c.drawCircle(Offset(0,-r*.18),r*.18,Paint()..color=palette[i]);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(0,r*.23),width:r*.7,height:r*.45),Radius.circular(r*.2)),Paint()..color=palette[i]);
 }
 c.restore();
}
class VictoryAvatar extends StatelessWidget {
 final int index,costume;final bool animate,celebrate;
 const VictoryAvatar({super.key,required this.index,required this.animate,this.costume=0,this.celebrate=true});
 @override Widget build(BuildContext context)=>SizedBox(width:180,height:136,child:TweenAnimationBuilder<double>(
  tween:Tween(begin:animate?0.0:1.0,end:1.0),duration:Duration(milliseconds:animate?1200:0),curve:Curves.easeOutCubic,
  builder:(context,t,child)=>Stack(alignment:Alignment.center,children:[
   if(celebrate&&animate)CustomPaint(size:const Size(180,136),painter:_VictoryParticles(t)),
   Transform.scale(scale:animate ? .68+.32*t : 1.0,child:Transform.translate(offset:Offset(0,celebrate&&animate?-12*sin(t*pi):0),child:child)),
  ]),child:AvatarArt(index:index,size:100,costume:costume,pose:celebrate?4:0)));
}
class _VictoryParticles extends CustomPainter{
 final double t;_VictoryParticles(this.t);
 @override void paint(Canvas c,Size s){
  final colors=[const Color(0xff318bff),const Color(0xffff943c),const Color(0xff31d9a0),const Color(0xffffcf54)];
  for(var i=0;i<22;i++){final a=i*2*pi/22;final r=12+t*(40+i%4*5);final center=s.center(Offset.zero)+Offset(cos(a)*r,sin(a)*r+t*t*14);c.save();c.translate(center.dx,center.dy);c.rotate(a+t*3);c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2,-4,4,8),const Radius.circular(1)),Paint()..color=colors[i%4].withAlpha(((1-t)*240).round()));c.restore();}
 }
 @override bool shouldRepaint(covariant _VictoryParticles old)=>old.t!=t;
}
