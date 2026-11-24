import 'dart:math';
import '../question_generators/questions.dart';
enum Mode { solo, duel, training, team }
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
  final Random rng;
  Phase phase=Phase.countdown, previous=Phase.countdown;
  int time=0, countdown=3000, energy=50, elapsed=0, serial=0;
  int? winner;
  final points=[0,0], misses=[0,0], locks=[0,0], shown=[0,0], ready=[0,0];
  final List<Attempt> attempts=[];
  late List<Question> tasks;
  int? pendingPlayer;
  int pendingAt=0, botAt=0;
  bool get shared=>mode==Mode.duel&&level==opponentLevel;
  Battle({required this.mode,required this.world,required this.duration,required this.level,required this.opponentLevel,Questions? questions,Random? random}):questions=questions??Questions(),rng=random??Random() {
    tasks=[this.questions.make(world,level),this.questions.make(world,opponentLevel)];
    if(shared) tasks[1]=tasks[0];
  }
  int get remaining=>max(0,duration*1000-time);
  bool get unlimited=>duration==0;
  bool visible(int p)=>elapsed>=ready[p];
  bool canAnswer(int p)=>phase==Phase.playing&&visible(p)&&elapsed>=locks[p]&&!(shared&&pendingPlayer==p);
  void setTask(int p,Question q) {
    tasks[p]=q;shown[p]=elapsed;ready[p]=elapsed+(q.preview.isEmpty?0:2200);locks[p]=ready[p];
  }
  void start() {
    phase=Phase.playing;
    for(var p=0;p<2;p++) setTask(p,tasks[p]);
    scheduleBot();
  }
  void scheduleBot() {botAt=ready[1]+[3500,2500,1500,850][opponentLevel]+rng.nextInt(900);}
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
  bool? answer(int p,String value) {
    if(!canAnswer(p))return null;
    final q=tasks[p], good=value==tasks[p].answer;
    if(mode!=Mode.solo||p==0)attempts.add(Attempt(q,p,elapsed-ready[p],good));
    if(!good){misses[p]++;locks[p]=elapsed+850;if(p==1&&mode==Mode.solo)botAt=locks[p]+700;return false;}
    if(shared) {
      if(pendingPlayer!=null) {
        if(pendingPlayer!=p&&elapsed-pendingAt<=100){pendingPlayer=null;advanceShared();return true;}
        return null;
      }
      pendingPlayer=p;pendingAt=elapsed;
    } else {score(p);if(phase==Phase.playing){setTask(p,questions.make(world,p==0?level:opponentLevel));if(p==1)scheduleBot();}}
    return true;
  }
  void resolvePending(){final p=pendingPlayer;if(p==null)return;pendingPlayer=null;score(p);if(phase==Phase.playing)advanceShared();}
  void advanceShared(){final q=questions.make(world,level);setTask(0,q);setTask(1,q);serial++;}
  void score(int p){
    points[p]++;
    if(mode==Mode.training)return;
    energy=(energy+((mode==Mode.team||p==0)?5:-5)).clamp(0,100).toInt();
    if(energy==0||energy==100)finish();
  }
  void finish(){
    if(phase==Phase.ended)return;
    phase=Phase.ended;
    winner=mode==Mode.training?null:mode==Mode.team?(energy==100?0:1):energy==50?null:energy>50?0:1;
  }
}
