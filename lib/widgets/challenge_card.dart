import 'package:flutter/material.dart';
import '../question_generators/challenges.dart';
import '../localization/strings.dart' show L;
class ChallengeCard extends StatelessWidget{
 final Challenge challenge;final bool selected;final VoidCallback onTap;
 const ChallengeCard({super.key,required this.challenge,required this.selected,required this.onTap});
 @override Widget build(BuildContext context){
  final color=const [Color(0xff3577db),Color(0xffb85c20),Color(0xff14866f),Color(0xff8052c6)][challenge.index%4];
  return Material(color:Colors.transparent,borderRadius:BorderRadius.circular(15),clipBehavior:Clip.antiAlias,child:Ink(
   decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),gradient:LinearGradient(colors:[Color.lerp(color,Colors.black,.18)!,const Color(0xff142039)]),border:Border.all(color:selected?Colors.white:color.withAlpha(160),width:selected?2:1)),
   child:InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.all(7),child:Row(children:[
    Container(width:43,height:43,alignment:Alignment.center,decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.3)!,color]),boxShadow:[BoxShadow(color:color.withAlpha(110),blurRadius:7,offset:const Offset(0,3))]),child:FittedBox(fit:BoxFit.scaleDown,child:Text(challenge.symbol,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)))),
    const SizedBox(width:7),Expanded(child:Text(L.text(challenge.label),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:13))),
    if(selected)const Icon(Icons.check_circle,color:Colors.white,size:15),
   ]))),
  ));
 }
}
