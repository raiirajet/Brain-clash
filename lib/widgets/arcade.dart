import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../localization/strings.dart' show L;

const arcadeBlue=Color(0xff318bff);
const arcadeOrange=Color(0xffff943c);
const arcadeGreen=Color(0xff31d9a0);
const arcadeRed=Color(0xffff5277);

ThemeData arcadeTheme(Brightness brightness) {
 final dark=brightness==Brightness.dark;
 final scheme=ColorScheme.fromSeed(seedColor:const Color(0xff377cf7),brightness:brightness);
 final surface=dark?const Color(0xff182338):const Color(0xfff4f7ff);
 final shape=RoundedRectangleBorder(borderRadius:BorderRadius.circular(16));
 return ThemeData(
  useMaterial3:true,fontFamily:'Inter',colorScheme:scheme.copyWith(surface:surface),textTheme:Typography.material2021().black.apply(fontFamily:'Inter',bodyColor:scheme.onSurface,displayColor:scheme.onSurface).copyWith(headlineLarge:TextStyle(fontFamily:'Outfit',fontSize:32,fontWeight:FontWeight.w800,color:scheme.onSurface),headlineSmall:TextStyle(fontFamily:'Outfit',fontSize:24,fontWeight:FontWeight.w800,color:scheme.onSurface),titleLarge:TextStyle(fontFamily:'Outfit',fontSize:22,fontWeight:FontWeight.w800,color:scheme.onSurface),titleMedium:TextStyle(fontFamily:'Outfit',fontSize:16,fontWeight:FontWeight.w700,color:scheme.onSurface)),scaffoldBackgroundColor:dark?const Color(0xff080b15):const Color(0xffeaf0fa),
  appBarTheme:AppBarTheme(backgroundColor:Colors.transparent,elevation:0,centerTitle:true,titleTextStyle:TextStyle(fontFamily:'Outfit',color:scheme.onSurface,fontSize:20,fontWeight:FontWeight.w800)),
  filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(shape:shape,minimumSize:const Size(44,48),textStyle:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),
  outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(shape:shape,minimumSize:const Size(44,48),textStyle:const TextStyle(fontWeight:FontWeight.w700))),
  inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:surface,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14)),
  dividerTheme:DividerThemeData(color:scheme.outlineVariant.withAlpha(100)),
  chipTheme:ChipThemeData(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),padding:const EdgeInsets.all(6)),
  progressIndicatorTheme:const ProgressIndicatorThemeData(color:arcadeBlue,linearMinHeight:7),
 );
}

class ArcadeBackdrop extends StatelessWidget {
 final Widget child;
 const ArcadeBackdrop({super.key,required this.child});
 @override Widget build(BuildContext context){
  final dark=Theme.of(context).brightness==Brightness.dark;
  return DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:dark?const [Color(0xff101d36),Color(0xff080b15),Color(0xff20142a)]:const [Color(0xffd9e9ff),Color(0xfff3f7ff),Color(0xffffe9db)])),child:child);
 }
}

class ArcadeTile extends StatelessWidget {
 final String label;final IconData icon;final Color color;final VoidCallback onTap;final bool selected;final Widget? art;
 const ArcadeTile({super.key,required this.label,required this.icon,required this.color,required this.onTap,this.selected=false,this.art});
 @override Widget build(BuildContext context)=>Semantics(button:true,selected:selected,child:Material(
  color:Colors.transparent,borderRadius:BorderRadius.circular(20),clipBehavior:Clip.antiAlias,
  child:Ink(decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.12)!,Color.lerp(color,const Color(0xff081124),.72)!]),border:Border.all(color:color.withAlpha(selected?255:145),width:selected?2:1),boxShadow:[BoxShadow(color:color.withAlpha(45),blurRadius:14,offset:const Offset(0,5))]),
   child:InkWell(onTap:onTap,child:Stack(fit:StackFit.expand,children:[
    Positioned(right:-18,top:-18,child:Icon(icon,size:110,color:Colors.white.withAlpha(25))),
    Padding(padding:const EdgeInsets.all(9),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
     Flexible(child:art??FittedBox(fit:BoxFit.scaleDown,child:Icon(icon,size:48,color:Colors.white,shadows:[Shadow(color:color,blurRadius:14),const Shadow(color:Colors.black38,offset:Offset(0,3),blurRadius:4)]))),
     const SizedBox(height:5),Text(L.text(label),maxLines:2,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:14)),
    ])),
    if(selected)const Positioned(top:7,right:7,child:Icon(Icons.check_circle,color:Colors.white,size:18)),
   ])),
  ),
 ));
}

class MetricTile extends StatelessWidget{
 final String label,value;final IconData icon;final Color color;
 const MetricTile({super.key,required this.label,required this.value,required this.icon,required this.color});
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:13),decoration:BoxDecoration(color:color.withAlpha(22),border:Border.all(color:color.withAlpha(100)),borderRadius:BorderRadius.circular(16)),child:Column(children:[Icon(icon,color:color,size:23),const SizedBox(height:6),FittedBox(fit:BoxFit.scaleDown,child:Text(value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900))),Text(L.text(label),maxLines:2,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]));
}

class AnswerFeedback extends StatelessWidget{
 final String message;final bool correct,reduced;final int event;
 const AnswerFeedback({super.key,required this.message,required this.correct,required this.reduced,required this.event});
 @override Widget build(BuildContext context){
  final color=correct?arcadeGreen:arcadeRed;
  if(message.isEmpty)return const SizedBox.shrink();
  return TweenAnimationBuilder<double>(key:ValueKey(event),tween:Tween(begin:reduced?1.0:0.0,end:1.0),duration:Duration(milliseconds:reduced?0:300),curve:Curves.easeOutBack,
   builder:(context,value,child)=>Transform.scale(scale:.78+.22*value.clamp(0.0,1.2),child:child),
   child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),decoration:BoxDecoration(color:color.withAlpha(32),borderRadius:BorderRadius.circular(20),border:Border.all(color:color.withAlpha(145))),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(correct?Icons.check_circle:Icons.info_outline,color:color,size:16),const SizedBox(width:5),Flexible(child:Text(L.text(message),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:Theme.of(context).brightness==Brightness.dark?color:Color.lerp(color,Colors.black,.45),fontSize:12,fontWeight:FontWeight.w800)))])),
  );
 }
}

class AccuracyRing extends StatelessWidget{
 final double value;final bool reduced;
 const AccuracyRing({super.key,required this.value,this.reduced=false});
 @override Widget build(BuildContext context)=>TweenAnimationBuilder<double>(tween:Tween(begin:reduced?value:0,end:value),duration:Duration(milliseconds:reduced?0:550),curve:Curves.easeOutCubic,builder:(context,v,_)=>SizedBox(width:108,height:108,child:Stack(alignment:Alignment.center,children:[
  CustomPaint(size:const Size.square(108),painter:_RingPainter(v,Theme.of(context).colorScheme.outlineVariant)),
  Column(mainAxisSize:MainAxisSize.min,children:[Text('${(v*100).round()}%',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(L.text('Trefferquote'),style:const TextStyle(fontSize:10))]),
 ])));
}
class _RingPainter extends CustomPainter{
 final double value;final Color track;
 _RingPainter(this.value,this.track);
 @override void paint(Canvas canvas,Size size){
  final rect=Offset.zero&size;final circle=rect.deflate(7);
  canvas.drawCircle(rect.center,circle.width/2,Paint()..color=track..style=PaintingStyle.stroke..strokeWidth=8);
  canvas.drawArc(circle,-math.pi/2,math.pi*2*value.clamp(0.0,1.0),false,Paint()..shader=const SweepGradient(colors:[arcadeBlue,arcadeGreen,arcadeBlue]).createShader(rect)..style=PaintingStyle.stroke..strokeWidth=8..strokeCap=StrokeCap.round);
 }
 @override bool shouldRepaint(covariant _RingPainter oldDelegate)=>oldDelegate.value!=value||oldDelegate.track!=track;
}
