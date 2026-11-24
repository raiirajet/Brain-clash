import 'dart:math';
import '../question_generators/questions.dart';
enum Mode { solo, duel, training, team }
enum BattleRule { tug, race, sprint, hearts, race10, perfect, speed }
extension RuleInfo on BattleRule {
 String get label=>const ['Energie-Duell','5er-Rennen','Punkte-Sprint','3 Herzen','First to 10','Perfect Battle','Speed Battle'][index];
 String get description=>const ['Ziehe die Energie auf deine Seite.','Wer zuerst 5 Punkte hat, gewinnt.','Die meisten Punkte vor Ablauf der Zeit gewinnen.','Drei Fehler kosten das Duell.','Wer zuerst zehn Punkte erreicht, gewinnt.','Der erste Fehler entscheidet.','Schnellste richtige Antwort gewinnt; Gleichstand innerhalb 100 ms.'][index];
}
enum Phase { countdown, playing, paused, ended }
class Attempt {
  final Question question;
  final int player, ms;
  final bool correct;
  Attempt(this.question,this.player,this.ms,this.correct);
}
class Battle {
  final Mode mode;
  final World world;
  final int duration, level, opponentLevel;
  final Questions questions;
  final Questions? opponentQuestions;
  final BattleRule rule;
  final bool sameQuestions;
  final bool numberEntry;
  final Random rng;
  Phase phase=Phase.countdown, previous=Phase.countdown;
  int time=0, countdown=3000, energy=50, elapsed=0, serial=0;
  int? winner;
  final points=[0,0], misses=[0,0], locks=[0,0], shown=[0,0], ready=[0,0];
  final List<Attempt> attempts=[];
  final partial=[<String>[],<String>[]];
  final matched=[<int>{},<int>{}];
  final selected=[-1,-1];
  final mismatched=[<int>{},<int>{}];
  late List<Question> tasks;
  int? pendingPlayer;
  int pendingAt=0, botAt=0;
  bool get shared=>mode==Mode.duel&&sameQuestions&&level==opponentLevel;
  Battle({required this.mode,required this.world,required this.duration,required this.level,required this.opponentLevel,Questions? questions,this.opponentQuestions,this.rule=BattleRule.tug,this.sameQuestions=true,this.numberEntry=false,Random? random}):questions=questions??Questions(),rng=random??Random() {
    final first=this.questions.make(world,level);
    tasks=[first,mode==Mode.training||shared?first:(opponentQuestions??this.questions).make(world,opponentLevel)];
    if(shared) tasks[1]=tasks[0];
  }
  int get remaining=>max(0,duration*1000-time);
  bool get unlimited=>duration==0;
  bool visible(int p)=>elapsed>=ready[p];
  bool canAnswer(int p)=>phase==Phase.playing&&visible(p)&&elapsed>=locks[p]&&!(shared&&pendingPlayer==p);
  void setTask(int p,Question q) {
    tasks[p]=q;partial[p].clear();matched[p].clear();mismatched[p].clear();selected[p]=-1;shown[p]=elapsed;ready[p]=elapsed+q.previewMs;locks[p]=ready[p];
  }
  void start() {
    phase=Phase.playing;
    for(var p=0;p<2;p++){setTask(p,tasks[p]);}
    scheduleBot();
  }
  void scheduleBot() {botAt=ready[1]+(tasks[1].interaction==Interaction.pairs?tasks[1].board.length*400:tasks[1].interaction==Interaction.sequence?tasks[1].board.length*260:0)+[3500,2500,1500,850][opponentLevel]+rng.nextInt(900);}
  void tick(int ms) {
    if(phase==Phase.countdown) {countdown-=ms;if(countdown<=0) start();return;}
    if(phase!=Phase.playing)return;
    elapsed+=ms;time+=ms;
    if(pendingPlayer!=null&&elapsed-pendingAt>100) resolvePending();
    if(phase!=Phase.playing)return;
    if(mode==Mode.solo&&elapsed>=botAt&&canAnswer(1)) {
      final q=tasks[1];
      final good=rng.nextDouble()<[.60,.76,.88,.97][opponentLevel];
      answer(1,good?q.answer:q.options.firstWhere((x)=>x!=q.answer));
    }
    if(!unlimited&&remaining==0) {if(pendingPlayer!=null)resolvePending();finish();}
  }
  void pause(){if(phase==Phase.playing||phase==Phase.countdown){previous=phase;phase=Phase.paused;}}
  void resume(){if(phase==Phase.paused)phase=previous;}
  bool? tapCell(int p,int cell){
    if(p<0||p>1||!canAnswer(p))return null;
    final q=tasks[p];
    if(q.interaction==Interaction.sequence){
      if(cell<0||cell>8)return null;
      final v=cell.toString();
      if(v!=q.board[partial[p].length]){
        partial[p].clear();
        final result=answer(p,q.options.firstWhere((s)=>s!=q.answer));
        shown[p]=elapsed;ready[p]=elapsed+q.previewMs;locks[p]=ready[p];
        return result;
      }
      partial[p].add(v);
      if(partial[p].length==q.board.length)return answer(p,q.answer);
      return null;
    }
    if(q.interaction==Interaction.pairs){
      if(cell<0||cell>=q.board.length||matched[p].contains(cell)||selected[p]==cell)return null;
      if(selected[p]<0){selected[p]=cell;return null;}
      final first=selected[p];selected[p]=-1;
      if(q.board[first]!=q.board[cell]){mismatched[p].clear();mismatched[p].addAll([first,cell]);return answer(p,q.options.firstWhere((s)=>s!=q.answer));}
      mismatched[p].clear();
      matched[p].addAll([first,cell]);
      if(matched[p].length==q.board.length)return answer(p,q.answer);
    }
    return null;
  }
  bool? answer(int p,String value) {
    if(p<0||p>1||phase!=Phase.playing)return null;
    final q=tasks[p];
    if(q.interaction==Interaction.signal&&!visible(p)&&locks[p]==ready[p]){misses[p]++;attempts.add(Attempt(q,p,0,false));locks[p]=ready[p]+850;if(rule==BattleRule.perfect||rule==BattleRule.hearts&&misses[p]>=3)finish(forcedWinner:1-p);return false;}
    if(!canAnswer(p))return null;
    if(!q.options.contains(value)&&!((numberEntry||mode==Mode.training&&p==0)&&q.world==World.math&&double.tryParse(value)?.isFinite==true))return null;
    final good=value==q.answer||((numberEntry||mode==Mode.training)&&q.world==World.math&&double.tryParse(value)?.isFinite==true&&double.tryParse(value)==double.tryParse(q.answer));
    if(mode!=Mode.solo||p==0)attempts.add(Attempt(q,p,elapsed-ready[p],good));
    if(!good){misses[p]++;locks[p]=elapsed+850;if(rule==BattleRule.perfect&&(mode==Mode.duel||mode==Mode.solo)){finish(forcedWinner:1-p);return false;}if(rule==BattleRule.hearts&&(mode==Mode.duel||mode==Mode.solo)){updateRuleEnergy();if(misses[p]>=3){finish(forcedWinner:1-p);return false;}}if(p==1&&mode==Mode.solo)botAt=locks[p]+700;return false;}
    if(shared) {
      if(pendingPlayer!=null) {
        if(pendingPlayer!=p&&elapsed-pendingAt<=100){pendingPlayer=null;advanceShared();return true;}
        return null;
      }
      pendingPlayer=p;pendingAt=elapsed;
    } else {score(p);if(phase==Phase.playing){setTask(p,(p==0?questions:opponentQuestions??questions).make(world,p==0?level:opponentLevel));if(p==1)scheduleBot();}}
    return true;
  }
  void resolvePending(){final p=pendingPlayer;if(p==null)return;pendingPlayer=null;score(p);if(phase==Phase.playing)advanceShared();}
  void advanceShared(){final q=questions.make(world,level);setTask(0,q);setTask(1,q);serial++;}
  void score(int p){
    points[p]++;
    if(mode==Mode.training)return;
    if((mode==Mode.duel||mode==Mode.solo)&&rule!=BattleRule.tug){updateRuleEnergy();if((rule==BattleRule.race&&points[p]>=5)||(rule==BattleRule.race10&&points[p]>=10)||(rule==BattleRule.speed&&points[p]>=1))finish(forcedWinner:p);return;}
    energy=(energy+((mode==Mode.team||p==0)?5:-5)).clamp(0,100).toInt();
    if(energy==0||energy==100)finish();
  }
  void updateRuleEnergy(){
    if(rule==BattleRule.hearts){energy=(50+(misses[1]-misses[0])*16).clamp(0,100).toInt();}
    else if(rule==BattleRule.race||rule==BattleRule.race10){energy=(50+(points[0]-points[1])*10).clamp(0,100).toInt();}
    else{final total=points[0]+points[1];energy=total==0?50:(100*points[0]/total).round();}
  }
  void finish({int? forcedWinner}){
    if(phase==Phase.ended)return;
    phase=Phase.ended;
    if(forcedWinner!=null){winner=forcedWinner;return;}
    if((mode==Mode.duel||mode==Mode.solo)&&rule!=BattleRule.tug){
      if(rule==BattleRule.hearts&&misses[0]!=misses[1]){winner=misses[0]<misses[1]?0:1;return;}
      winner=points[0]==points[1]?null:points[0]>points[1]?0:1;return;
    }
    winner=mode==Mode.training?null:mode==Mode.team?(energy==100?0:1):energy==50?null:energy>50?0:1;
  }
}
