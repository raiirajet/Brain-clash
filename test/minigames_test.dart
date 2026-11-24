import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/questions.dart';
import 'package:brain_clash/game_engine/battle.dart';
class Fixed extends Questions {
 final Question q;
 Fixed(this.q);
 @override Question make(World world,int level)=>q;
}
void main(){
 test('memory sequence awards exactly one point after full sequence',(){
  const q=Question(World.memory,'sequence','0 2 1',['0 2 1','bad','x','y'],'sequence',preview:'0 2 1',interaction:Interaction.sequence,board:['0','2','1']);
  final b=Battle(mode:Mode.training,world:World.memory,duration:0,level:0,opponentLevel:0,questions:Fixed(q));
  b.tick(3000);expect(b.tapCell(0,0),isNull);b.tick(q.previewMs);
  expect(b.tapCell(0,0),isNull);expect(b.tapCell(0,2),isNull);expect(b.points[0],0);
  expect(b.tapCell(0,1),isTrue);expect(b.points[0],1);
 });
 test('all pairs must be matched',(){
  const q=Question(World.memory,'pairs','ok',['ok','no','x','y'],'pairs',preview:'cards',interaction:Interaction.pairs,board:['A','B','B','A']);
  final b=Battle(mode:Mode.training,world:World.memory,duration:0,level:0,opponentLevel:0,questions:Fixed(q));
  b.tick(3000);b.tick(q.previewMs);
  b.tapCell(0,0);b.tapCell(0,3);expect(b.points[0],0);
  b.tapCell(0,1);expect(b.tapCell(0,2),isTrue);expect(b.points[0],1);
 });
}
