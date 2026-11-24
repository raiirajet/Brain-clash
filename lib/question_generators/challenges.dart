import 'dart:math';
import 'questions.dart';

enum Challenge { mathClassic, addition, subtraction, multiplication, division, timesTable, arithmeticMix, compare, missing, logic, memory, focus, words, mixed, reaction, odd, sequence, pairs, trueFalse, targetNumber, bigTable, numberSeries, fractions, percent, decimals, precedence, estimate, mathTower, mathRace, rocketRace, treasureRush, numberBomb, mazeBattle, colorConfusion, numberRecall, shapeClash, patternMaster, spellingDuel, targetHunt, tapBattle, numberSort, wordSprint, logicEscape, bossBattle }
extension ChallengeInfo on Challenge {
 String get label=>const ['Mathematik Mix (klassisch)','Addition','Subtraktion','Multiplikation','Division','Einmaleins','Rechen-Mix','Zahlen-Duell','Zahlenlücke','Logic Clash','Memory Arena','Focus Rush','Word Battle','Mixed Battle','Signal Sprint','Symbol-Jagd','Licht-Memory','Paare-Duell','Wahr oder falsch','Zahlen-Ziel','Grosses Einmaleins','Zahlenfolgen','Bruchrechnen','Prozentrechnen','Dezimalzahlen','Punkt vor Strich','Schätzrechnen','Math Tower','Math Race','Rocket Race','Treasure Rush','Number Bomb','Maze Battle','Color Confusion','Number Recall','Shape Clash','Pattern Master','Spelling Duel','Target Hunt','Tap Battle','Number Sort','Word Sprint','Logic Escape','Boss Battle'][index];
 String get symbol=>const ['±','+','−','×','÷','1×1','±×','>','?','◆','◉','◎','ABC','⚡','!','★','▦','◫','✓','◎','20×20','1…','½','%','0.5','×+','≈','▥','»','↑','◇','◷','▦','◉','123','↻','▧','ABC','⊕','⚡','↕','ABC','▣','◆'][index];
 World get world=>switch(this){
  Challenge.logic||Challenge.trueFalse||Challenge.shapeClash||Challenge.patternMaster||Challenge.logicEscape=>World.logic,
  Challenge.memory||Challenge.sequence||Challenge.pairs||Challenge.numberRecall=>World.memory,
  Challenge.focus||Challenge.reaction||Challenge.odd||Challenge.colorConfusion||Challenge.targetHunt||Challenge.tapBattle=>World.focus,
  Challenge.words||Challenge.spellingDuel||Challenge.wordSprint=>World.words,Challenge.mixed||Challenge.bossBattle=>World.mixed,_=>World.math,
 };
 bool get usesDigits=>const [Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division,Challenge.arithmeticMix,Challenge.compare,Challenge.missing,Challenge.targetNumber,Challenge.trueFalse,Challenge.mathTower,Challenge.mathRace,Challenge.rocketRace,Challenge.treasureRush,Challenge.numberBomb,Challenge.mazeBattle].contains(this);
 bool get standard=>const [Challenge.mathClassic,Challenge.logic,Challenge.memory,Challenge.focus,Challenge.words,Challenge.mixed].contains(this);
 bool get numeric=>world==World.math;
 bool get arcadeStage=>const [Challenge.mathTower,Challenge.mathRace,Challenge.rocketRace,Challenge.treasureRush,Challenge.numberBomb,Challenge.mazeBattle,Challenge.logicEscape,Challenge.bossBattle].contains(this);
 bool get specialRules=>arcadeStage&&this!=Challenge.numberBomb;
 bool get canType=>numeric&&!const [Challenge.targetNumber,Challenge.fractions,Challenge.estimate,Challenge.numberSort].contains(this);
}
enum DivisionStyle { exact, remainder, decimal }
class MathOptions {
 final int range, table, factorDigits, choiceCount;
 final bool negative, noCarry;
 final DivisionStyle division;
 const MathOptions({this.range=0,this.table=0,this.factorDigits=0,this.choiceCount=4,this.negative=false,this.noCarry=false,this.division=DivisionStyle.exact});
 MathOptions withDigitsOnly()=>MathOptions(table:table,choiceCount:choiceCount,negative:negative,noCarry:noCarry,division:division);
}
class ChallengeQuestions extends Questions{
 final Challenge challenge;
 final int digits;
 final MathOptions config;
 final List<Question> due;
 ChallengeQuestions(this.challenge,this.digits,{Random? random,Iterable<Question> reviews=const [],this.config=const MathOptions()}):due=List.of(reviews),super(random);
 int get minDigit=>config.range>0?1:[1,10,100,1000][digits.clamp(1,4).toInt()-1];
 int get maxDigit=>config.range>0?config.range:[9,99,999,9999][digits.clamp(1,4).toInt()-1];
 int operand()=>minDigit+random.nextInt(maxDigit-minDigit+1);
 @override Question make(World world,int level){
  final q=generate(world,level);
  if(config.choiceCount!=2||q.interaction!=Interaction.choices||q.options.length<=2)return q;
  final wrong=q.options.where((s)=>s!=q.answer).toList()..shuffle(random);
  final choices=[q.answer,wrong.first]..shuffle(random);
  return Question(q.world,q.prompt,q.answer,choices,q.explanation,preview:q.preview,interaction:q.interaction,board:q.board);
 }
 String decimal(int n)=>n%10==0?'${n~/10}':'${n~/10}.${n%10}';
 Question generate(World world,int level){
  if(challenge.standard){
   final i=due.indexWhere((q)=>world==World.mixed||q.world==world);
   if(i>=0)return due.removeAt(i);
   return super.make(world,level);
  }
  final a=operand();
  var b=operand();
  if(config.factorDigits>0&&challenge==Challenge.multiplication){
   final i=config.factorDigits.clamp(1,4).toInt()-1;
   final lo=[1,10,100,1000][i],hi=[9,99,999,9999][i];
   b=lo+random.nextInt(hi-lo+1);
  }
  final type=challenge==Challenge.arithmeticMix||(challenge.arcadeStage&&challenge!=Challenge.logicEscape&&challenge!=Challenge.bossBattle)?[Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division][random.nextInt(4)]:challenge;
  switch(type){
   case Challenge.addition:
    if(config.noCarry){
     var x=a,y=b,m=1,total=0;
     while(x>0||y>0){total+=min(y%10,9-x%10)*m;x~/=10;y~/=10;m*=10;}
     b=total;
    }
    return number(World.math,'$a + $b = ?',a+b);
   case Challenge.subtraction:return config.negative?number(World.math,'$a − $b = ?',a-b):number(World.math,'${max(a,b)} − ${min(a,b)} = ?', (a-b).abs());
   case Challenge.multiplication:return number(World.math,'$a × $b = ?',a*b);
   case Challenge.division:
    if(config.division==DivisionStyle.remainder){
     final divisor=2+random.nextInt(min(12,maxDigit)-1);
     final answer='${a~/divisor} R ${a%divisor}';
     return pick(World.math,'$a ÷ $divisor (Rest)',answer,List.generate(3,(i)=>'${a~/divisor+i+1} R ${a%divisor}'));
    }
    if(config.division==DivisionStyle.decimal){
     final divisor=[2,4,5,8][random.nextInt(4)];
     final answer=(a/divisor).toString();
     return pick(World.math,'$a ÷ $divisor = ?',answer,List.generate(3,(i)=>(a/divisor+i+1).toString()));
    }
    // Dividend has exactly the selected digits; the divisor is nonzero and the quotient integral.
    final divisor=2+random.nextInt(min(12,maxDigit)-1);
    final lo=max(1,(minDigit+divisor-1)~/divisor),hi=maxDigit~/divisor;
    final quotient=lo+random.nextInt(hi-lo+1);
    return number(World.math,'${quotient*divisor} ÷ $divisor = ?',quotient);
   case Challenge.bigTable:
   case Challenge.timesTable:
    final limit=challenge==Challenge.bigTable?20:10;
    final x=config.table>0?config.table.clamp(1,limit).toInt():1+random.nextInt(limit),y=1+random.nextInt(limit);
    return number(World.math,'$x × $y = ?',x*y);
   case Challenge.numberSeries:
    final step=1+random.nextInt(12),start=1+random.nextInt(30);
    return number(World.math,'$start, ${start+step}, ${start+2*step}, ?',start+3*step);
   case Challenge.fractions:
    final denominator=[4,6,8,10,12][random.nextInt(5)];
    final x=1+random.nextInt(denominator-2),y=1+random.nextInt(denominator-x);
    String fraction(int n){final gcd=n.gcd(denominator);return gcd==denominator?'${n~/gcd}':'${n~/gcd}/${denominator~/gcd}';}
    return pick(World.math,'$x/$denominator + $y/$denominator = ?',fraction(x+y),List.generate(3,(i)=>fraction(x+y+i+1)));
   case Challenge.percent:
    final rate=[5,10,20,25,50,75][random.nextInt(6)],amount=(1+random.nextInt(20))*100;
    return number(World.math,'$rate % von $amount',rate*amount~/100);
   case Challenge.decimals:
    final x=1+random.nextInt(99),y=1+random.nextInt(99);
    return pick(World.math,'${decimal(x)} + ${decimal(y)} = ?',decimal(x+y),List.generate(3,(i)=>decimal(x+y+i+1)));
   case Challenge.precedence:
    return number(World.math,'$a + $b × 2 = ?',a+b*2);
   case Challenge.estimate:
    final x=11+random.nextInt(89),y=11+random.nextInt(89);
    final estimate=((x*y)/100).round()*100;
    return pick(World.math,'$x × $y ≈ ? (auf 100)', '$estimate',List.generate(3,(i)=>'${estimate+100*(i+1)}'));
   case Challenge.wordSprint:
    const bank=['APFEL','LAMPE','WOLKE','TIGER','BLUME','STERN','FISCH','KARTE','HAFEN','MAUER','PFERD','STEIN'];
    final word=bank[random.nextInt(bank.length)],letters=word.split('')..shuffle(random);
    if(letters.join()==word){final first=letters.removeAt(0);letters.add(first);}
    final wrong=<String>{};while(wrong.length<3){final copy=word.split('')..shuffle(random);if(copy.join()!=word)wrong.add(copy.join());}
    return Question(World.words,'Ordne die Buchstaben',word,[word,...wrong],'Richtig: '+word,interaction:Interaction.word,board:letters);
   case Challenge.logicEscape:return super.make(World.logic,level);
   case Challenge.bossBattle:return super.make(World.mixed,level);
   case Challenge.numberRecall:
    final s=List.generate(3+level.clamp(0,3).toInt(),(_)=>random.nextInt(10)).join();
    final wrong=List.generate(3,(i)=>'${(int.parse(s[0])+i+1)%10}${s.substring(1)}');
    return Question(World.memory,'Gib die gemerkte Zahl ein',s,[s,...wrong],'Zahl: $s',preview:s,interaction:Interaction.recall);
   case Challenge.shapeClash:
    final arrows=['↑','→','↓','←'];final i=random.nextInt(4);
    return pick(World.logic,'Drehe ${arrows[i]} um 90° nach rechts',arrows[(i+1)%4],arrows.where((s)=>s!=arrows[(i+1)%4]).toList());
   case Challenge.patternMaster:
    final signs=['●','▲','■','◆','★']..shuffle(random);
    final pattern=[signs[0],signs[1],signs[1],signs[0],signs[1]];
    return pick(World.logic,'${pattern.join(' ')} ?',signs[1],[signs[0],signs[2],signs[3]]);
   case Challenge.colorConfusion:
    final words=['Rot','Blau','Grün','Gelb'];
    final i=random.nextInt(4),j=(i+1+random.nextInt(3))%4;
    final options=[...words]..shuffle(random);
    return Question(World.focus,words[j].toUpperCase(),words[i],options,'Farbe: ${words[i]}',interaction:Interaction.stroop,board:['$i']);
   case Challenge.spellingDuel:
    const bank=[['Fahrrad','Farad','Fahrad','Farrad'],['Rhythmus','Rytmus','Rhytmus','Rythmuss'],['Bibliothek','Biblioteck','Bibliohthek','Biblothek'],['Schokolade','Schokollade','Schokolate','Schokoladde']];
    final row=bank[random.nextInt(bank.length)];
    return pick(World.words,'Wie schreibt man es?',row.first,row.sublist(1));
   case Challenge.targetHunt:
    final symbols=['●','▲','■','◆','★','✚']..shuffle(random);
    final target=symbols.first,board=List.generate(9,(_)=>symbols[1+random.nextInt(5)]);
    board[random.nextInt(board.length)]=target;
    return Question(World.focus,'Finde $target',target,[target,...symbols.skip(1).take(3)],'Tippe nur das Ziel.',interaction:Interaction.target,board:board);
   case Challenge.tapBattle:
    return const Question(World.focus,'5 schnelle Treffer!','5',['5','0','1','2'],'Fünf Treffer ergeben einen Punkt.',interaction:Interaction.tap);
   case Challenge.numberSort:
    final set=<int>{};while(set.length<4){set.add(1+random.nextInt(99));}
    final board=set.toList()..shuffle(random);
    final sorted=set.toList()..sort();
    if(board.join(' ')==sorted.join(' ')){final first=board[0];board[0]=board[1];board[1]=first;}
    final answer=sorted.join(' ');
    final wrong=List.generate(3,(i){final v=[...sorted];final a=v[i];v[i]=v[i+1];v[i+1]=a;return v.join(' ');});
    return Question(World.math,'Klein nach gross',answer,[answer,...wrong],'Reihenfolge: $answer',interaction:Interaction.sort,board:board.map((n)=>n.toString()).toList());
   case Challenge.compare:
    final numbers=<int>{a,b};while(numbers.length<4){numbers.add(operand());}
    final largest=random.nextBool();
    final answer=largest?numbers.reduce(max):numbers.reduce(min);
    return pick(World.math,largest?'Welche Zahl ist am grössten?':'Welche Zahl ist am kleinsten?',answer.toString(),numbers.where((n)=>n!=answer).map((n)=>n.toString()).toList());
   case Challenge.missing:return number(World.math,'$a + ? = ${a+b}',b);
   case Challenge.targetNumber:
    final target=a+b;
    final correct='$a + $b';
    final alternatives=<int>{};while(alternatives.length<3){final n=operand();if(n!=b)alternatives.add(n);}
    final wrong=alternatives.map((n)=>'$a + $n').toList();
    return pick(World.math,'Erreiche die Zahl $target',correct,wrong);
   case Challenge.trueFalse:
    final correct=random.nextBool();
    final result=a+b+(correct?0:1+random.nextInt(5));
    final answer=correct?'Richtig':'Falsch';
    return Question(World.logic,'$a + $b = $result',answer,const ['Richtig','Falsch'],'$a + $b = ${a+b}');
   case Challenge.reaction:
    return Question(World.focus,'JETZT!','LOS',const ['LOS','Zu früh','Falsch','Warten'],'Reagiere erst auf das Signal.',preview:'Warte auf das Signal …',interaction:Interaction.signal,board:[(900+random.nextInt(1900)).toString()]);
   case Challenge.odd:
    final signs=['●','▲','■','◆','★','✚']..shuffle(random);
    final row=List.filled(8+level.clamp(0,3).toInt()*3,signs[0]);row[random.nextInt(row.length)]=signs[1];
    return pick(World.focus,'Welches Symbol ist anders?\n${row.join(' ')}',signs[1],[signs[0],signs[2],signs[3]]);
   case Challenge.sequence:
    final cells=List.generate(3+level.clamp(0,3).toInt(),(_)=>random.nextInt(9).toString());
    final answer=cells.join(' ');
    final wrong=List.generate(3,(i){final copy=[...cells];copy[i]=((int.parse(copy[i])+1)%9).toString();return copy.join(' ');});
    return Question(World.memory,'Tippe die Felder in derselben Reihenfolge',answer,[answer,...wrong],'Reihenfolge: $answer',preview:answer,interaction:Interaction.sequence,board:cells);
   case Challenge.pairs:
    final faces=['🐱','🐶','🦊','🐼','🐸','🐯']..shuffle(random);
    final cards=faces.take(2+level.clamp(0,3).toInt()).expand((f)=>[f,f]).toList()..shuffle(random);
    return Question(World.memory,'Finde alle Bildpaare','Paare gefunden',const ['Paare gefunden','Nicht gleich','Falsch','Noch nicht'],'Gleiche Bilder bilden ein Paar.',preview:'Merke die Karten',interaction:Interaction.pairs,board:cards);
   default:return super.make(world,level);
  }
 }
}
