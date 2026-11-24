import 'dart:math';
import 'arcade_rules.dart';
import '../question_generators/questions.dart';
enum Mode { solo, duel, training, team }
enum BattleRule { tug, race, sprint, hearts, race10, perfect, speed, finalClash }
extension RuleInfo on BattleRule {
 String get label=>const ['Energie-Duell','5er-Rennen','Punkte-Sprint','3 Herzen','First to 10','Perfect Battle','Speed Battle','Final Clash'][index];
 String get description=>const ['Ziehe die Energie auf deine Seite.','Wer zuerst 5 Punkte hat, gewinnt.','Die meisten Punkte vor Ablauf der Zeit gewinnen.','Drei Fehler kosten das Duell.','Wer zuerst zehn Punkte erreicht, gewinnt.','Der erste Fehler entscheidet.','Schnellste richtige Antwort gewinnt; Gleichstand innerhalb 100 ms.','Bei Gleichstand entscheidet eine letzte Aufgabe.'][index];
}
enum Phase { countdown, playing, paused, ended }
enum FinishReason { time, goal, defeat, hearts, mistake, speed, finalClash, manual }
class Attempt {
  final Question question;
  final int player, ms;
  final bool correct;
  final String? response;
  Attempt(this.question,this.player,this.ms,this.correct,{this.response});
}
class Battle {
  final Mode mode;
  final World world;
  final int duration, level, opponentLevel;
  final Questions questions;
  final Questions? opponentQuestions;
  final BattleRule rule;
  final bool sameQuestions;
  final bool numberEntry,timedArcade;
  final int fuseMs,digits,opponentDigits;
  final String skillName;
  late final ArcadeRules? arcade;
  final sorted=[<String>[],<String>[]];
  final Random rng;
  Phase phase=Phase.countdown, previous=Phase.countdown;
  int time=0, countdown=3000, energy=50, elapsed=0, serial=0;
  int? winner;
  FinishReason? finishReason;
  final points=[0,0], misses=[0,0], locks=[0,0], shown=[0,0], ready=[0,0];
  final List<Attempt> attempts=[];
  final partial=[<String>[],<String>[]];
  final matched=[<int>{},<int>{}];
  final selected=[-1,-1];
  final mismatched=[<int>{},<int>{}];
  late List<Question> tasks;
  int? pendingPlayer;
  int pendingAt=0, botAt=0;
  bool finalRound=false;
  int finalDeadline=0;
  int get finalRemaining=>max(0,finalDeadline-elapsed);
  bool get shared=>mode==Mode.duel&&sameQuestions&&level==opponentLevel&&fuseMs==0&&ArcadeRules.kindFor(skillName)==null;
  bool get speedContest=>arcade==null&&rule==BattleRule.speed&&(mode==Mode.duel||mode==Mode.solo);
  bool get arbitrate=>shared||speedContest;
  Battle({required this.mode,required this.world,required this.duration,required this.level,required this.opponentLevel,Questions? questions,this.opponentQuestions,this.rule=BattleRule.tug,this.sameQuestions=true,this.numberEntry=false,this.timedArcade=false,this.fuseMs=0,this.digits=1,this.opponentDigits=1,this.skillName='mixed',Random? random}):questions=questions??Questions(),rng=random??Random() {
    final kind=ArcadeRules.kindFor(skillName);
    arcade=kind==null?null:ArcadeRules(kind,seed:rng.nextInt(1<<30),cooperative:mode==Mode.team,repeatObjectives:mode==Mode.training||timedArcade&&kind!=ArcadeKind.boss);
    final first=this.questions.make(world,level);
    tasks=[first,mode==Mode.training||shared?first:(opponentQuestions??this.questions).make(world,opponentLevel)];
    if(shared) tasks[1]=tasks[0];
  }
  int get remaining=>max(0,duration*1000-time);
  bool get unlimited=>duration==0||finalRound;
  bool visible(int p)=>elapsed>=ready[p];
  bool activePlayer(int p)=>p>=0&&p<(mode==Mode.training?1:2);
  bool canAnswer(int p)=>activePlayer(p)&&phase==Phase.playing&&arcade?.waiting(p)!=true&&visible(p)&&elapsed>=locks[p]&&!(arbitrate&&pendingPlayer==p);
  void setTask(int p,Question q) {
    tasks[p]=q;sorted[p]=List.of(q.board);partial[p].clear();matched[p].clear();mismatched[p].clear();selected[p]=-1;shown[p]=elapsed;ready[p]=elapsed+q.previewMs;locks[p]=ready[p];
  }
  void start() {
    phase=Phase.playing;
    for(var p=0;p<2;p++){setTask(p,tasks[p]);}
    scheduleBot();
  }
  void scheduleBot() {botAt=ready[1]+(tasks[1].interaction==Interaction.pairs?tasks[1].board.length*400:tasks[1].interaction==Interaction.sequence?tasks[1].board.length*260:0)+[3500,2500,1500,850][opponentLevel]+rng.nextInt(900);}
  void tick(int ms) {
    if(ms<=0)return;
    if(phase==Phase.countdown){
      final used=min(ms,countdown);countdown-=used;ms-=used;
      if(countdown==0)start();
      if(ms==0)return;
    }
    if(phase!=Phase.playing)return;
    final step=finalRound?min(ms,finalRemaining):unlimited?ms:min(ms,remaining);
    elapsed+=step;
    if(!finalRound)time+=step;
    if(finalRound&&finalRemaining==0){if(pendingPlayer!=null)resolvePending();if(phase==Phase.playing)finish(reason:FinishReason.time);return;}
    arcade?.tick(step,players:mode==Mode.training?1:2);
    checkArcade();if(phase==Phase.ended)return;
    // The deadline is authoritative: no new bot answer or fuse penalty after it.
    if(!unlimited&&remaining==0){
      if(pendingPlayer!=null)resolvePending();
      if(phase!=Phase.playing)return;
      if(mode!=Mode.training&&arcade==null&&rule==BattleRule.finalClash&&points[0]==points[1]){
        finalRound=true;finalDeadline=elapsed+30000;
        if(shared){advanceShared();}else{
          setTask(0,questions.make(world,level));setTask(1,(opponentQuestions??questions).make(world,opponentLevel));scheduleBot();
        }
      }else{finish(reason:FinishReason.time);}
      return;
    }
    if(mode==Mode.solo&&arcade?.waiting(1)==true){
      arcade!.autoAction(1);if(!arcade!.waiting(1)){restartArcadeQuestion(1);scheduleBot();}
      checkArcade();if(phase==Phase.ended)return;
    }
    if(pendingPlayer!=null&&elapsed-pendingAt>100)resolvePending();
    if(phase!=Phase.playing)return;
    if(fuseMs>0){
      for(var p=0;p<(mode==Mode.training?1:2);p++){
        if(phase!=Phase.playing)break;
        if(canAnswer(p)&&elapsed-ready[p]>=fuseMs){
          final q=tasks[p];answer(p,q.options.firstWhere((x)=>x!=q.answer));
        }
      }
    }
    if(phase!=Phase.playing)return;
    if(mode==Mode.solo&&elapsed>=botAt&&canAnswer(1)){
      final q=tasks[1],good=rng.nextDouble()<[.60,.76,.88,.97][opponentLevel];
      answer(1,good?q.answer:q.options.firstWhere((x)=>x!=q.answer));
    }
  }
  void checkArcade(){if(arcade?.ended==true&&phase==Phase.playing)finish(reason:arcade!.boss&&arcade!.winner==1?FinishReason.defeat:FinishReason.goal);}
  void restartArcadeQuestion(int p){shown[p]=elapsed;ready[p]=elapsed+tasks[p].previewMs;locks[p]=ready[p];}
  bool arcadeMove(int p,Direction d){if(phase!=Phase.playing||!activePlayer(p))return false;final ok=arcade?.move(p,d)??false;if(ok)restartArcadeQuestion(p);checkArcade();return ok;}
  bool arcadeChest(int p,int index){if(phase!=Phase.playing||!activePlayer(p))return false;final ok=arcade?.openChest(p,index)??false;if(ok)restartArcadeQuestion(p);checkArcade();return ok;}
  void pause(){if(phase==Phase.playing||phase==Phase.countdown){previous=phase;phase=Phase.paused;}}
  void resume(){if(phase==Phase.paused)phase=previous;}
  bool? tapCell(int p,int cell){
    if(p<0||p>1||!canAnswer(p))return null;
    final q=tasks[p];
    if(q.interaction==Interaction.word){
      if(cell<0||cell>=q.board.length||matched[p].contains(cell))return null;
      if(partial[p].length>=q.answer.length)return null;
      if(q.board[cell]!=q.answer[partial[p].length]){partial[p].clear();matched[p].clear();return answer(p,q.options.firstWhere((v)=>v!=q.answer));}
      matched[p].add(cell);partial[p].add(q.board[cell]);
      return partial[p].length==q.answer.length?answer(p,q.answer):null;
    }
    if(q.interaction==Interaction.target){
      if(cell<0||cell>=q.board.length)return null;
      return answer(p,q.board[cell]==q.answer?q.answer:q.options.firstWhere((s)=>s!=q.answer));
    }
    if(q.interaction==Interaction.tap){
      partial[p].add('tap');
      return partial[p].length>=int.parse(q.answer)?answer(p,q.answer):null;
    }
    if(q.interaction==Interaction.sequence){
      if(cell<0||cell>8)return null;
      final v=cell.toString();
      if(partial[p].length>=q.board.length)return null;
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
  void moveCell(int p,int oldIndex,int newIndex){
    if(p<0||p>1||!canAnswer(p)||tasks[p].interaction!=Interaction.sort)return;
    final order=sorted[p];if(oldIndex<0||oldIndex>=order.length||newIndex<0||newIndex>order.length)return;
    if(newIndex>oldIndex)newIndex--;
    order.insert(newIndex,order.removeAt(oldIndex));
  }
  bool? submitSort(int p){
    if(p<0||p>1||!canAnswer(p)||tasks[p].interaction!=Interaction.sort)return null;
    final q=tasks[p];
    return answer(p,sorted[p].join(' ')==q.answer?q.answer:q.options.firstWhere((s)=>s!=q.answer));
  }
  bool? answer(int p,String value) {
    if(!activePlayer(p)||phase!=Phase.playing)return null;
    final q=tasks[p];
    if(q.interaction==Interaction.signal&&!visible(p)&&locks[p]==ready[p]){misses[p]++;attempts.add(Attempt(q,p,0,false,response:'false start'));locks[p]=ready[p]+850;if(mode!=Mode.training&&mode!=Mode.team&&rule==BattleRule.perfect)finish(forcedWinner:1-p,reason:FinishReason.mistake);else if(mode!=Mode.training&&mode!=Mode.team&&rule==BattleRule.hearts&&misses[p]>=3)finish(forcedWinner:1-p,reason:FinishReason.hearts);return false;}
    if(!canAnswer(p))return null;
    if(!q.options.contains(value)&&!(q.interaction==Interaction.recall&&RegExp(r'^\d+$').hasMatch(value))&&!((numberEntry||mode==Mode.training&&p==0)&&q.world==World.math&&double.tryParse(value)?.isFinite==true))return null;
    final good=value==q.answer||((numberEntry||mode==Mode.training)&&q.world==World.math&&double.tryParse(value)?.isFinite==true&&double.tryParse(value)==double.tryParse(q.answer));
    if(mode!=Mode.solo||p==0)attempts.add(Attempt(q,p,elapsed-ready[p],good,response:value));
    if(!good){misses[p]++;locks[p]=elapsed+850;if(arcade!=null){arcade!.wrong(p);checkArcade();if(p==1&&mode==Mode.solo)botAt=locks[p]+700;return false;}if(rule==BattleRule.perfect&&(mode==Mode.duel||mode==Mode.solo)){finish(forcedWinner:1-p,reason:FinishReason.mistake);return false;}if(rule==BattleRule.hearts&&(mode==Mode.duel||mode==Mode.solo)){updateRuleEnergy();if(misses[p]>=3){finish(forcedWinner:1-p,reason:FinishReason.hearts);return false;}}if(fuseMs>0&&!shared){setTask(p,(p==0?questions:opponentQuestions??questions).make(world,p==0?level:opponentLevel));ready[p]+=850;locks[p]=ready[p];if(p==1)scheduleBot();}else if(p==1&&mode==Mode.solo)botAt=locks[p]+700;return false;}
    if(arbitrate) {
      if(pendingPlayer!=null) {
        if(pendingPlayer!=p&&elapsed-pendingAt<=100){pendingPlayer=null;if(shared){advanceShared();}else{advanceIndependent();}return true;}
        return null;
      }
      pendingPlayer=p;pendingAt=elapsed;
    } else {score(p);if(phase==Phase.playing){setTask(p,(p==0?questions:opponentQuestions??questions).make(world,p==0?level:opponentLevel));if(p==1)scheduleBot();}}
    return true;
  }
  void resolvePending(){final p=pendingPlayer;if(p==null)return;pendingPlayer=null;score(p);if(phase==Phase.playing){if(shared){advanceShared();}else{advanceIndependent();}}}
  void advanceIndependent(){setTask(0,questions.make(world,level));setTask(1,(opponentQuestions??questions).make(world,opponentLevel));scheduleBot();serial++;}
  void advanceShared(){final q=questions.make(world,level);setTask(0,q);setTask(1,q);serial++;}
  void score(int p){
    points[p]++;
    if(arcade!=null){arcade!.correct(p);checkArcade();return;}
    if(finalRound){finish(forcedWinner:p,reason:FinishReason.finalClash);return;}
    if(mode==Mode.training)return;
    if((mode==Mode.duel||mode==Mode.solo)&&rule!=BattleRule.tug){updateRuleEnergy();if((rule==BattleRule.race&&points[p]>=5)||(rule==BattleRule.race10&&points[p]>=10)||(rule==BattleRule.speed&&points[p]>=1))finish(forcedWinner:p,reason:rule==BattleRule.speed?FinishReason.speed:FinishReason.goal);return;}
    energy=(energy+((mode==Mode.team||p==0)?5:-5)).clamp(0,100).toInt();
    if(energy==0||energy==100)finish(reason:FinishReason.goal);
  }
  void updateRuleEnergy(){
    if(rule==BattleRule.hearts){energy=(50+(misses[1]-misses[0])*16).clamp(0,100).toInt();}
    else if(rule==BattleRule.race||rule==BattleRule.race10){energy=(50+(points[0]-points[1])*10).clamp(0,100).toInt();}
    else{final total=points[0]+points[1];energy=total==0?50:(100*points[0]/total).round();}
  }
  void finish({int? forcedWinner,FinishReason reason=FinishReason.manual}){
    if(phase==Phase.ended)return;
    phase=Phase.ended;finishReason=reason;
    if(mode==Mode.training){winner=null;return;}
    if(forcedWinner!=null){winner=forcedWinner;return;}
    if(arcade!=null){winner=mode==Mode.training?null:arcade!.ended?arcade!.winner:arcade!.timeWinner();return;}
    if((mode==Mode.duel||mode==Mode.solo)&&rule!=BattleRule.tug){
      if(rule==BattleRule.hearts&&misses[0]!=misses[1]){winner=misses[0]<misses[1]?0:1;return;}
      winner=points[0]==points[1]?null:points[0]>points[1]?0:1;return;
    }
    winner=mode==Mode.training?null:mode==Mode.team?(energy==100?0:1):energy==50?null:energy>50?0:1;
  }
}
