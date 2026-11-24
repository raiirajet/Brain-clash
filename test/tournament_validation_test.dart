import 'package:flutter_test/flutter_test.dart';
import 'package:brain_clash/game_engine/tournament_validation.dart';
void main(){
 test('valid bracket with bye and incomplete second match',(){
  expect(validTournament(['A','B','C'],[[0,1],[2,-1],[0,2]],[0,2],roundRobin:false),true);
 });
 test('corrupt or impossible stored match indexes are rejected',(){
  expect(validTournament(['A','B'],[[0,8]],[],roundRobin:false),false);
  expect(validTournament(['A','B'],[[0,1]],[2],roundRobin:false),false);
  expect(validTournament(['A','a'],[[0,1]],[],roundRobin:false),false);
  expect(validTournament(['A','B'],[[0,-1]],[],roundRobin:true),false);
 });
}
