/// Validates saved tournament data before it can reach any UI list indexing.
bool validTournament(List<String> players,List<List<int>> matches,List<int> winners,{required bool roundRobin}){
 if(players.isEmpty)return matches.isEmpty&&winners.isEmpty;
 if(players.length<2||players.length>8||players.any((n)=>n.trim().isEmpty||n.length>40)||players.map((n)=>n.toLowerCase()).toSet().length!=players.length)return false;
 if(matches.isEmpty||matches.length>56||winners.length>matches.length)return false;
 for(var i=0;i<matches.length;i++){
  final m=matches[i];if(m.length!=2||m[0]<0||m[0]>=players.length||m[1]<-1||m[1]>=players.length||m[0]==m[1]||roundRobin&&m[1]<0)return false;
  if(i<winners.length&&(!m.contains(winners[i])||winners[i]<0))return false;
  if(i==winners.length&&m[1]==-1)return false;
 }
 return true;
}
