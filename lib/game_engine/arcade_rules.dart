
import 'dart:math' as math;
enum ArcadeKind { tower, race, rocket, treasure, maze, escape, boss }
enum Direction { up, right, down, left }

/// A seeded perfect maze. Both sides have the same layout.
class Maze {
 static const width=5,height=4;
 final links=List.generate(width*height,(_)=><int>{});
 Maze(int seed){
  final rng=math.Random(seed),seen=<int>{0},stack=<int>[0];
  while(stack.isNotEmpty){
   final cell=stack.last;
   final next=Direction.values.map((d)=>neighbor(cell,d)).whereType<int>().where((n)=>!seen.contains(n)).toList();
   if(next.isEmpty){stack.removeLast();continue;}
   final n=next[rng.nextInt(next.length)];links[cell].add(n);links[n].add(cell);seen.add(n);stack.add(n);
  }
 }
 static int? neighbor(int cell,Direction d){
  final x=cell%width,y=cell~/width;
  return switch(d){Direction.up=>y>0?cell-width:null,Direction.right=>x<width-1?cell+1:null,Direction.down=>y<height-1?cell+width:null,Direction.left=>x>0?cell-1:null};
 }
 int? move(int cell,Direction d){final n=neighbor(cell,d);return links[cell].contains(n)?n:null;}
 int distance(int start){
  final queue=<int>[start],depth=<int,int>{start:0};
  for(var i=0;i<queue.length;i++){final c=queue[i];if(c==width*height-1)return depth[c]!;for(final n in links[c]){if(!depth.containsKey(n)){depth[n]=depth[c]!+1;queue.add(n);}}}
  throw StateError('Disconnected maze');
 }
}
class ArcadeLane {
 int blocks=0,keys=0,gems=0,cell=0,locks=0,charge=0;
 double position=0,velocity=0,fuel=0;
 final opened=<int>{};
}
/// Deterministic, elapsed-time-only simulation; cosmetic choices never affect it.
class ArcadeRules {
 static ArcadeKind? kindFor(String skill)=>switch(skill){
 'mathTower'=>ArcadeKind.tower,'mathRace'=>ArcadeKind.race,'rocketRace'=>ArcadeKind.rocket,'treasureRush'=>ArcadeKind.treasure,'mazeBattle'=>ArcadeKind.maze,'logicEscape'=>ArcadeKind.escape,'bossBattle'=>ArcadeKind.boss,_=>null};
 final ArcadeKind kind;
 final Maze maze;
 final lanes=[ArcadeLane(),ArcadeLane()];
 final bool cooperative;
 int bossHp=120,teamHp=5,elapsed=0,nextStrike=12000;
 int? winner;
 bool ended=false;
 ArcadeRules(this.kind,{int seed=42,this.cooperative=false}):maze=Maze(seed);
 bool get boss=>kind==ArcadeKind.boss;
 int get bossPhase=>bossHp>80?1:bossHp>40?2:3;
 bool waiting(int p)=>(kind==ArcadeKind.maze||kind==ArcadeKind.treasure)&&lanes[p].keys>0;
 void correct(int p){
  if(ended)return;final l=lanes[p];
  switch(kind){
   case ArcadeKind.tower:l.blocks++;break;
   case ArcadeKind.race:l.position=math.min(100.0,l.position+12);break;
   case ArcadeKind.rocket:l.fuel=math.min(6.0,l.fuel+2.5);l.velocity=math.min(24.0,l.velocity+5);break;
   case ArcadeKind.treasure:case ArcadeKind.maze:l.keys=1;break;
   case ArcadeKind.escape:l.locks++;break;
   case ArcadeKind.boss:l.charge++;bossHp=math.max(0,bossHp-(bossPhase==2?10:15));if(bossHp==0){ended=true;winner=0;}break;
  }
  check();
 }
 void wrong(int p){
  if(ended)return;final l=lanes[p];
  switch(kind){
   case ArcadeKind.tower:l.blocks=math.max(0,l.blocks-1);break;
   case ArcadeKind.race:l.position=math.max(0.0,l.position-5);break;
   case ArcadeKind.rocket:l.fuel=math.max(0.0,l.fuel-1.5);l.velocity*=.55;break;
   case ArcadeKind.escape:l.locks=math.max(0,l.locks-1);break;
   case ArcadeKind.boss:teamHp--;if(teamHp<=0){ended=true;winner=1;}break;
   default:break;
  }
 }
 bool move(int p,Direction d){
  if(ended||kind!=ArcadeKind.maze||lanes[p].keys==0)return false;
  final l=lanes[p],n=maze.move(lanes[p].cell,d);if(n==null)return false;
  l.cell=n;l.keys=0;check();return true;
 }
 static const chestValues=[2,1,3,2,1,3];
 bool openChest(int p,int index){
  if(ended||kind!=ArcadeKind.treasure||index<0||index>=chestValues.length)return false;
  final l=lanes[p];if(l.keys==0||l.opened.contains(index))return false;
  l.keys=0;l.opened.add(index);l.gems+=chestValues[index];check();return true;
 }
 void autoAction(int p){
  if(!waiting(p))return;
  if(kind==ArcadeKind.maze){
   final l=lanes[p],old=maze.distance(lanes[p].cell);
   for(final d in Direction.values){final n=maze.move(l.cell,d);if(n!=null&&maze.distance(n)<old){move(p,d);return;}}
  }else{
   final available=List.generate(chestValues.length,(i)=>i).where((i)=>!lanes[p].opened.contains(i)).toList()..sort((a,b)=>chestValues[b].compareTo(chestValues[a]));
   if(available.isNotEmpty)openChest(p,available.first);
  }
 }
 void tick(int ms,{int players=2}){
  if(ended||ms<=0)return;elapsed+=ms;
  if(kind==ArcadeKind.rocket){
   // Bounded substeps keep integration stable across dropped frames.
   for(var left=ms;left>0;){final step=math.min(left,20);left-=step;final dt=step/1000;
    for(var p=0;p<players;p++){final l=lanes[p],powered=math.min(dt,lanes[p].fuel);
     l.fuel=math.max(0.0,l.fuel-powered);l.velocity=(l.velocity+powered*5-(dt-powered)*9).clamp(0.0,24.0).toDouble();
     l.position=math.min(100.0,l.position+l.velocity*dt);
    }
    check(players:players);if(ended)return;
   }
  }
  if(boss&&elapsed>=nextStrike){
   final charged=lanes.fold<int>(0,(sum,l)=>sum+l.charge);
   if(charged<(cooperative?2:1))teamHp--;
   for(final l in lanes){l.charge=0;}
   nextStrike=elapsed+(bossPhase==3?6500:12000);
   if(teamHp<=0){ended=true;winner=1;}
  }
  check(players:players);
 }
 double progress(int p){
  final l=lanes[p];return switch(kind){ArcadeKind.tower=>l.blocks/10,ArcadeKind.race||ArcadeKind.rocket=>l.position/100,ArcadeKind.treasure=>l.gems/12,ArcadeKind.maze=>1-maze.distance(l.cell)/math.max(1,maze.distance(0)),ArcadeKind.escape=>l.locks/6,ArcadeKind.boss=>1-bossHp/120};
 }
 void check({int players=2}){
  if(ended||boss)return;final a=progress(0)>=1,b=players>1&&progress(1)>=1;
  if(a||b){ended=true;winner=a&&b?null:a?0:1;}
 }
 int? timeWinner(){if(boss)return bossHp==0?0:1;final a=progress(0),b=progress(1);return (a-b).abs()<.000001?null:a>b?0:1;}
}
