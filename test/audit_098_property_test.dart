import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'package:brain_clash/question_generators/questions.dart';
import 'package:brain_clash/game_engine/arcade_rules.dart';
import 'package:brain_clash/game_engine/battle.dart';

List<int> integers(String s)=>RegExp(r'\d+').allMatches(s).map((m)=>int.parse(m.group(0)!)).toList();
double rational(String s){final v=s.split('/').map(int.parse).toList();return v.length==1?v[0].toDouble():v[0]/v[1];}

void main(){
 for(var digits=1;digits<=4;digits++){
  for(var level=0;level<4;level++){
   test('arithmetic truth and operand contracts $digits digits / tier $level',(){
    final rng=Random(8900+digits*10+level);
    final lo=[1,10,100,1000][digits-1],hi=[9,99,999,9999][digits-1];
    for(final game in [Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division]){
     final options=game==Challenge.division?DivisionStyle.values:[DivisionStyle.exact];
     for(final style in options){
      final g=ChallengeQuestions(game,digits,random:rng,config:MathOptions(division:style,noCarry:game==Challenge.addition));
      for(var i=0;i<256;i++){
       final q=g.make(game.world,level),v=integers(q.prompt),a=v[0],b=v[1];
       expect(a,inInclusiveRange(lo,hi));
       if(game!=Challenge.division)expect(b,inInclusiveRange(lo,hi));
       switch(game){
        case Challenge.addition:
         expect(int.parse(q.answer),a+b);
         var x=a,y=b;while(x>0||y>0){expect(x%10+y%10,lessThan(10));x~/=10;y~/=10;}break;
        case Challenge.subtraction:expect(a,greaterThanOrEqualTo(b));expect(int.parse(q.answer),a-b);break;
        case Challenge.multiplication:expect(int.parse(q.answer),a*b);break;
        case Challenge.division:
         expect(b,greaterThan(0));
         switch(style){
          case DivisionStyle.exact:expect(a%b,0);expect(int.parse(q.answer),a~/b);break;
          case DivisionStyle.remainder:
           final result=integers(q.answer);
           expect(result[1],greaterThan(0));expect(result[1],lessThan(b));expect(a,result[0]*b+result[1]);break;
          case DivisionStyle.decimal:expect(double.parse(q.answer),closeTo(a/b,1e-10));break;
         }break;
        default:fail('Unexpected operation');
       }
      }
     }
    }
   });
  }
 }
 for(var level=0;level<4;level++){
  test('fraction, decimal, percent and precedence truth at tier $level',(){
   for(final game in [Challenge.fractions,Challenge.decimals,Challenge.percent,Challenge.precedence]){
    final g=ChallengeQuestions(game,2,random:Random(320+level));
    for(var i=0;i<1024;i++){
     final q=g.make(game.world,level),v=integers(q.prompt);
     switch(game){
      case Challenge.fractions:
       expect(rational(q.answer),closeTo(v[0]/v[1]+v[2]/v[3],1e-10));if(level>=2)expect(v[1],isNot(v[3]));break;
      case Challenge.decimals:
       final operands=q.prompt.split(' = ').first.split(' + ').map(double.parse).toList();
       expect(double.parse(q.answer),closeTo(operands[0]+operands[1],1e-9));break;
      case Challenge.percent:
       final answer=int.parse(q.answer);
       if(q.prompt.startsWith('?')){expect(answer*v[0],100*v[1]);}
       else if(q.prompt.contains('von ?')){expect(v[0]*answer,100*v[1]);}
       else{expect(100*answer,v[0]*v[1]);}break;
      case Challenge.precedence:
       final result=level<2?v[0]+v[1]*v[2]:level==2?(v[0]+v[1])*v[2]+v[3]*v[4]:v[0]+(v[1]+v[2])*v[3]-v[4];
       expect(int.parse(q.answer),result);break;
      default:fail('Unexpected operation');
     }
    }
   }
  });
 }
 test('rest division with range 1 and 2 terminates with positive remainder',(){
  for(final range in [1,2]){
   final g=ChallengeQuestions(Challenge.division,1,random:Random(range),config:MathOptions(range:range,division:DivisionStyle.remainder));
   for(var i=0;i<100;i++){final q=g.make(World.math,3),v=integers(q.prompt),a=integers(q.answer);expect(v[0],inInclusiveRange(1,range));expect(a[1],greaterThan(0));expect(a[1],lessThan(v[1]));expect(v[0],a[0]*v[1]+a[1]);}
  }
 });
 test('boss strikes are invariant under frame partition including repeated defeat',(){
  for(final repeat in [true,false]){
   for(var tier=0;tier<4;tier++){
    List<Object?> run(int step){
     final a=ArcadeRules(ArcadeKind.boss,difficulty:tier,repeatObjectives:repeat);
     a.correct(0);
     for(var t=0;t<120000;t+=step){a.tick(step,players:1);}
     return [a.bossHp,a.teamHp,a.nextStrike,a.elapsed,a.ended,a.winner,...a.completed];
    }
    expect(run(100),run(120000));expect(run(1000),run(120000));
   }
  }
 });
 test('arcade lanes use their own targets and maze dimensions',(){
  final tower=ArcadeRules(ArcadeKind.tower,difficulty:0,opponentDifficulty:3);
  expect(tower.towerGoalFor(0),10);expect(tower.towerGoalFor(1),16);
  for(var i=0;i<10;i++)tower.correct(1);
  expect(tower.ended,false);for(var i=0;i<6;i++)tower.correct(1);expect(tower.winner,1);
  final maze=ArcadeRules(ArcadeKind.maze,difficulty:0,opponentDifficulty:3);
  expect(maze.mazeFor(0).columns,5);expect(maze.mazeFor(1).columns,8);
  final treasure=ArcadeRules(ArcadeKind.treasure,difficulty:0,opponentDifficulty:3);
  expect(treasure.treasureGoalFor(0),9);expect(treasure.treasureGoalFor(1),12);
 });
 test('number bomb has independent fuse deadlines',(){
  final b=Battle(mode:Mode.duel,world:World.math,duration:90,level:0,opponentLevel:3,skillName:'numberBomb',fuseMs:12000,opponentFuseMs:5000);
  b.tick(3000);expect(b.fuseRemainingFor(0),12000);expect(b.fuseRemainingFor(1),5000);
  b.tick(4999);expect(b.misses,[0,0]);b.tick(1);expect(b.misses,[0,1]);
  expect(b.fuseRemainingFor(0),7000);b.tick(7000);expect(b.misses[0],1);
 });
 for(final delta in [99,100,101]){
  test('speed arbitration boundary $delta ms',(){
   final b=Battle(mode:Mode.duel,world:World.math,duration:30,level:0,opponentLevel:0,rule:BattleRule.speed);
   b.tick(3000);expect(b.tasks[0],same(b.tasks[1]));expect(b.ready[0],b.ready[1]);
   b.answer(0,b.tasks[0].answer);b.tick(delta);
   if(delta<=100){b.answer(1,b.tasks[1].answer);expect(b.points,[0,0]);expect(b.phase,Phase.playing);}
   else{expect(b.phase,Phase.ended);expect(b.winner,0);}
  });
 }
}
