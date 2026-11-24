import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/game_engine/battle.dart';
import 'package:brain_clash/game_engine/arcade_rules.dart';
import 'package:brain_clash/question_generators/challenges.dart';
import 'round_contract_test.dart' show match,solve;

void main(){
 for(final game in Challenge.values){
  test('supported competition contracts: ${game.name}',(){
   for(final mode in [Mode.duel,Mode.solo,Mode.team]){
    if(game==Challenge.bossBattle&&mode!=Mode.team)continue;
    if(game.specialRules&&game!=Challenge.bossBattle&&mode==Mode.team)continue;
    final rules=game.specialRules||mode==Mode.team?[BattleRule.tug]:BattleRule.values;
    for(final rule in rules){
     final b=match(game,mode:mode,rule:rule,seconds:30,shared:false);
     b.tick(3000);
     for(var n=0;n<200&&b.phase==Phase.playing;n++){
      solve(b,0);if(mode!=Mode.solo)solve(b,1);
      b.tick(101);
     }
     if(b.phase==Phase.playing)b.tick(60000);
     if(b.phase==Phase.playing)b.tick(30000);
     expect(b.phase,Phase.ended,reason:'${game.name}/${mode.name}/${rule.name}');
     expect(b.winner==null||b.winner==0||b.winner==1,true);
    }
   }
  });
 }
 test('higher maze tiers are connected and larger',(){
  for(var tier=0;tier<4;tier++){
   final a=ArcadeRules(ArcadeKind.maze,difficulty:tier);
   expect(a.maze.links.length,(5+tier)*(4+tier));
   for(var i=0;i<a.maze.links.length;i++)expect(a.maze.distance(i),greaterThanOrEqualTo(0));
  }
 });
}
