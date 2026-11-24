String rankFor(int xp){
 const labels=['Bronze','Silber','Gold','Platin','Diamant','Master','Brain Legend'];
 const limits=[0,500,1500,3500,7000,15000,30000];
 for(var i=limits.length-1;i>=0;i--){if(xp>=limits[i])return labels[i];}
 return labels.first;
}
class DailyProgress {
 static String day(DateTime? at)=>(at??DateTime.now()).toIso8601String().substring(0,10);
 static int count(Map profile,{DateTime? at})=>profile['dailyDate']==day(at)?(profile['dailyRight'] as int? ?? 0):0;
 static int add(Map profile,int correct,{DateTime? at}){
  if(correct<=0)return 0;
  final old=count(profile,at:at);
  profile['dailyDate']=day(at);
  profile['dailyRight']=(old+correct).clamp(0,10).toInt();
  return old<10&&old+correct>=10?75:0;
 }
}
