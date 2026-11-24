import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import 'arcade.dart';

class AccuracyHistory extends StatelessWidget {
 final List history;
 const AccuracyHistory({super.key,required this.history});
 @override Widget build(BuildContext context){
  final recent=history.reversed.take(20).toList().reversed.toList();
  final values=recent.map((row){final total=(row['total'] as num? ??0);return total==0?0.0:(row['right'] as num)/total;}).toList();
  return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Trefferquote · letzte Runden',style:TextStyle(fontWeight:FontWeight.w800)),
   const SizedBox(height:12),
   SizedBox(height:110,width:double.infinity,child:CustomPaint(painter:_AccuracyPainter(values,Theme.of(context).colorScheme.onSurface))),
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('${recent.first['date']}'),Text('${recent.last['date']}')]),
  ])));
 }
}
class _AccuracyPainter extends CustomPainter{
 final List<double> values;
 final Color textColor;
 _AccuracyPainter(this.values,this.textColor);
 @override void paint(Canvas c,Size s){
  final w=s.width-28,h=s.height-12;
  if(w<=0||h<=0||values.length<2)return;
  for(var i=0;i<=4;i++){
   final y=6+h*i/4;
   c.drawLine(Offset(28,y),Offset(s.width,y),Paint()..color=textColor.withAlpha(35));
   final tp=TextPainter(text:TextSpan(text:'${100-i*25}%',style:TextStyle(color:textColor,fontSize:9)),textDirection:TextDirection.ltr)..layout();tp.paint(c,Offset(0,y-5));tp.dispose();
  }
  final path=Path();
  for(var i=0;i<values.length;i++){
   final point=Offset(28+w*i/(values.length-1),6+h*(1-values[i].clamp(0.0,1.0)));
   if(i==0){path.moveTo(point.dx,point.dy);}else{path.lineTo(point.dx,point.dy);}
   c.drawCircle(point,2.8,Paint()..color=arcadeGreen);
  }
  c.drawPath(path,Paint()..color=arcadeGreen..style=PaintingStyle.stroke..strokeWidth=2.5..strokeJoin=StrokeJoin.round);
 }
 @override bool shouldRepaint(covariant _AccuracyPainter old)=>old.values!=values||old.textColor!=textColor;
}
