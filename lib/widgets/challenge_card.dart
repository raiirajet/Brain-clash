import 'package:flutter/material.dart';
import '../question_generators/challenges.dart';
import '../localization/strings.dart' show L;

class ChallengeArt extends StatelessWidget {
 final Challenge challenge;
 final double size;
 const ChallengeArt({super.key,required this.challenge,this.size=88});
 static String path(Challenge challenge)=>'assets/games/${challenge.name}.webp';
 @override Widget build(BuildContext context)=>Image.asset(path(challenge),
  width:size,height:size,fit:BoxFit.contain,cacheWidth:256,excludeFromSemantics:true,
  errorBuilder:(context,error,stack)=>SizedBox.square(dimension:size,child:Center(child:Text(challenge.symbol,style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w800)))),
 );
}
class ChallengeCard extends StatelessWidget{
 final Challenge challenge;final bool selected;final VoidCallback onTap;
 const ChallengeCard({super.key,required this.challenge,required this.selected,required this.onTap});
 @override Widget build(BuildContext context){
  final border=selected?const Color(0xffffb052):const Color(0xff344b77);
  return Semantics(button:true,selected:selected,label:L.text(challenge.label),child:Material(
   color:const Color(0xff10192e),borderRadius:BorderRadius.circular(17),clipBehavior:Clip.antiAlias,
   child:Ink(decoration:BoxDecoration(
    borderRadius:BorderRadius.circular(17),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xff152541),Color(0xff0b1026)]),
    border:Border.all(color:border,width:selected?2:1)),
    child:InkWell(onTap:onTap,child:Stack(children:[
     Positioned.fill(child:Padding(padding:const EdgeInsets.fromLTRB(8,8,8,7),child:Column(children:[
      Expanded(child:Center(child:ChallengeArt(challenge:challenge,size:94))),
      const SizedBox(height:4),SizedBox(height:32,child:Center(child:Text(L.text(challenge.label),maxLines:2,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontFamily:'Inter',fontWeight:FontWeight.w700,fontSize:13,height:1.1)))),
     ]))),
     if(selected)const Positioned(top:8,right:8,child:Icon(Icons.check_circle,color:Color(0xffffb052),size:20)),
    ]))),
  ));
 }
}
