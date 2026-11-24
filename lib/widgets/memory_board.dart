import 'package:flutter/material.dart' hide Text;
import '../localization/strings.dart';
import '../question_generators/questions.dart';
import '../game_engine/battle.dart';
class MemoryBoard extends StatelessWidget {
 final Question question;
 final Battle battle;
 final int player;
 final ValueChanged<int> onTap;
 const MemoryBoard({super.key,required this.question,required this.battle,required this.player,required this.onTap});
 @override Widget build(BuildContext context){
   final sequence=question.interaction==Interaction.sequence;
   final preview=!battle.visible(player);
   final index=((battle.elapsed-battle.shown[player])/480).floor();
   final highlight=preview&&sequence&&index>=0&&index<question.board.length&&((battle.elapsed-battle.shown[player])%480)<370?int.parse(question.board[index]):-1;
   final count=sequence?9:question.board.length;
   final cols=sequence?3:count<=6?3:4;
   return LayoutBuilder(builder:(context,box){
     final rows=(count/cols).ceil();
     final cell=((box.maxHeight-(rows-1)*4)/rows).clamp(18.0,85.0).toDouble();
     return GridView.builder(physics:const NeverScrollableScrollPhysics(),padding:EdgeInsets.zero,itemCount:count,
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,mainAxisSpacing:4,crossAxisSpacing:4,mainAxisExtent:cell),
      itemBuilder:(context,i){
        final paired=battle.matched[player].contains(i),chosen=battle.selected[player]==i;
        final mismatch=battle.elapsed<battle.locks[player]&&battle.mismatched[player].contains(i);
        final lit=highlight==i||paired||chosen;
        final revealed=!sequence&&(preview||paired||chosen||mismatch);
        return Semantics(label:L.text(sequence?'Feld ${i+1}':revealed?question.board[i]:'Verdeckte Karte ${i+1}'),button:true,
          child:FilledButton(style:FilledButton.styleFrom(backgroundColor:mismatch?const Color(0xffab3548):lit?const Color(0xff139b8d):const Color(0xff304d90),disabledBackgroundColor:mismatch?const Color(0xffab3548):lit?const Color(0xff139b8d):const Color(0xff304d90),disabledForegroundColor:Colors.white,padding:EdgeInsets.zero),
          onPressed:!preview&&battle.canAnswer(player)&&!paired?()=>onTap(i):null,
          child:Text(sequence?(lit?'●':'${i+1}'):revealed?question.board[i]:'?',style:TextStyle(fontSize:cell*.48,color:Colors.white))));
      });
   });
 }
}
