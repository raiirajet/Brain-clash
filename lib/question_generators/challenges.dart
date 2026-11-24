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
 MathOptions forGame(Challenge game)=>MathOptions(
  range:game.usesDigits?range.clamp(0,9999).toInt():0,
  table:game==Challenge.timesTable||game==Challenge.bigTable?table:0,
  factorDigits:game==Challenge.multiplication?factorDigits:0,
  choiceCount:choiceCount==2?2:4,
  negative:game==Challenge.subtraction&&negative,
  noCarry:game==Challenge.addition&&noCarry,
  division:game==Challenge.division?division:DivisionStyle.exact);
 MathOptions withDigitsOnly()=>MathOptions(table:table,choiceCount:choiceCount,negative:negative,noCarry:noCarry,division:division);
}
class ChallengeQuestions extends Questions{
 final Challenge challenge;
 final int digits;
 final MathOptions config;
 final List<Question> due;
 ChallengeQuestions(this.challenge,this.digits,{Random? random,Iterable<Question> reviews=const [],MathOptions config=const MathOptions()}):config=config.forGame(challenge),due=List.of(reviews),super(random);
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
 static const wordClues={'HAUS':'Gebäude zum Wohnen','MAUS':'Kleines Nagetier','BAUM':'Hat Stamm und Blätter','FROSCH':'Quakendes Tier','APFEL':'Runde Frucht','LAMPE':'Macht Licht','WOLKE':'Am Himmel','TIGER':'Gestreifte Raubkatze','BLUME':'Blüht im Garten','STERN':'Leuchtet nachts','FISCH':'Schwimmt im Wasser','PFERD':'Tier zum Reiten','BANANE':'Gelbe Frucht','GARTEN':'Ort für Pflanzen','PIRAT':'Seeräuber','KAMERA':'Macht Fotos','RAKETE':'Fliegt ins All','PLANET':'Umkreist einen Stern','ELEFANT':'Tier mit Rüssel','SCHULE':'Ort zum Lernen','GIRAFFE':'Tier mit langem Hals','VULKAN':'Berg mit Lava','KROKUS':'Frühlingsblume','KOMPASS':'Zeigt die Himmelsrichtung'};
 String decimal(int n)=>n%10==0?'${n~/10}':'${n~/10}.${n%10}';
 Question generate(World world,int level){
  level=level.clamp(0,3).toInt();
  final review=due.indexWhere((q)=>world==World.mixed||q.world==world);
  if(review>=0)return due.removeAt(review);
  if(challenge.standard)return super.make(world,level);
  var a=operand();
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
     // Keep the requested operand width, including at the most significant digit.
     final minValue=minDigit;
     if(a.toString()[0]=='9'||config.range>0&&a%10==9)a=minValue;
     var x=a,y=b,m=1,total=0;
     while(x>0||y>0){total+=min(y%10,9-x%10)*m;x~/=10;y~/=10;m*=10;}
     b=max(minValue,total);
     if(b>maxDigit)b=minValue;
    }
    return number(World.math,'$a + $b = ?',a+b);
   case Challenge.subtraction:return config.negative?number(World.math,'$a − $b = ?',a-b):number(World.math,'${max(a,b)} − ${min(a,b)} = ?', (a-b).abs());
   case Challenge.multiplication:return number(World.math,'$a × $b = ?',a*b);
   case Challenge.division:
    if(config.division==DivisionStyle.remainder){
     final divisor=maxDigit<2?1:2+random.nextInt(min([5,8,10,12][level],maxDigit)-1);
     final answer='${a~/divisor} R ${a%divisor}';
     return pick(World.math,'$a ÷ $divisor (Rest)',answer,List.generate(3,(i)=>'${a~/divisor+i+1} R ${a%divisor}'));
    }
    if(config.division==DivisionStyle.decimal){
     final divisor=[2,4,5,8][random.nextInt(4)];
     final answer=(a/divisor).toString();
     return pick(World.math,'$a ÷ $divisor = ?',answer,List.generate(3,(i)=>(a/divisor+i+1).toString()));
    }
    // Dividend has exactly the selected digits; the divisor is nonzero and the quotient integral.
    final divisor=maxDigit<2?1:2+random.nextInt(min([5,8,10,12][level],maxDigit)-1);
    final lo=max(1,(minDigit+divisor-1)~/divisor),hi=maxDigit~/divisor;
    final quotient=lo+random.nextInt(hi-lo+1);
    return number(World.math,'${quotient*divisor} ÷ $divisor = ?',quotient);
   case Challenge.bigTable:
   case Challenge.timesTable:
    final limit=challenge==Challenge.bigTable?20:10;
    final x=config.table>0?config.table.clamp(1,limit).toInt():1+random.nextInt(limit),y=1+random.nextInt(min(limit,challenge==Challenge.bigTable?[10,12,16,20][level]:[5,7,9,10][level]));
    return number(World.math,'$x × $y = ?',x*y);
   case Challenge.numberSeries:
    final step=1+random.nextInt([4,12,25,50][level]),start=1+random.nextInt([10,30,100,300][level]);
    return number(World.math,'$start, ${start+step}, ${start+2*step}, ?',start+3*step);
   case Challenge.fractions:
    final denominator=[4,6,8,10,12,16,20,24][random.nextInt(2+level*2>8?8:2+level*2)];
    final x=1+random.nextInt(denominator-2),y=1+random.nextInt(denominator-x);
    String fraction(int n){final gcd=n.gcd(denominator);return gcd==denominator?'${n~/gcd}':'${n~/gcd}/${denominator~/gcd}';}
    return pick(World.math,'$x/$denominator + $y/$denominator = ?',fraction(x+y),List.generate(3,(i)=>fraction(x+y+i+1)));
   case Challenge.percent:
    final rate=[5,10,20,25,50,75][random.nextInt(6)],amount=(1+random.nextInt([5,20,60,100][level]))*100;
    return number(World.math,'$rate % von $amount',rate*amount~/100);
   case Challenge.decimals:
    final x=1+random.nextInt([19,99,999,9999][level]),y=1+random.nextInt([19,99,999,9999][level]);
    return pick(World.math,'${decimal(x)} + ${decimal(y)} = ?',decimal(x+y),List.generate(3,(i)=>decimal(x+y+i+1)));
   case Challenge.precedence:
    return level<2?number(World.math,'$a + $b × ${level+2} = ?',a+b*(level+2)):number(World.math,'($a + $b) × ${level+2} = ?',(a+b)*(level+2));
   case Challenge.estimate:
    final x=11+random.nextInt([19,89,189,389][level]),y=11+random.nextInt([19,89,189,389][level]);
    final estimate=((x*y)/100).round()*100;
    return pick(World.math,'$x × $y ≈ ? (auf 100)', '$estimate',List.generate(3,(i)=>'${estimate+100*(i+1)}'));
   case Challenge.wordSprint:
    const banks=[
     ['HAUS','MAUS','BAUM','FROSCH'],
     ['APFEL','LAMPE','WOLKE','TIGER','BLUME','STERN','FISCH','PFERD'],
     ['BANANE','GARTEN','PIRAT','KAMERA','RAKETE','PLANET'],
     ['ELEFANT','SCHULE','GIRAFFE','VULKAN','KROKUS','KOMPASS']
    ];
    final bank=banks[level],word=bank[random.nextInt(bank.length)],letters=word.split('')..shuffle(random);
    if(letters.join()==word){final first=letters.removeAt(0);letters.add(first);}
    final wrong=<String>{};while(wrong.length<3){final copy=word.split('')..shuffle(random);if(copy.join()!=word)wrong.add(copy.join());}
    return Question(World.words,'Ordne die Buchstaben · ${wordClues[word]}',word,[word,...wrong],'Richtig: '+word,interaction:Interaction.word,board:letters);
   case Challenge.logicEscape:return super.make(World.logic,level);
   case Challenge.bossBattle:return super.make(World.mixed,level);
   case Challenge.numberRecall:
    final s=List.generate(3+level.clamp(0,3).toInt(),(_)=>random.nextInt(10)).join();
    final wrong=List.generate(3,(i)=>'${(int.parse(s[0])+i+1)%10}${s.substring(1)}');
    return Question(World.memory,'Gib die gemerkte Zahl ein',s,[s,...wrong],'Zahl: $s',preview:s,interaction:Interaction.recall);
   case Challenge.shapeClash:
    final arrows=['↑','→','↓','←'];final i=random.nextInt(4),turn=level==0?1:1+random.nextInt(3);
    final right=level<2||random.nextBool(),answer=arrows[(i+(right?turn:4-turn))%4];
    return pick(World.logic,'Drehe ${arrows[i]} um ${90*turn}° nach ${right?'rechts':'links'}',answer,arrows.where((s)=>s!=answer).toList());
   case Challenge.patternMaster:
    final signs=['●','▲','■','◆','★']..shuffle(random);
    final cycle=List.generate(level+2,(i)=>signs[i%signs.length]);
    final pattern=[...cycle,...cycle,...cycle.take(level+1)];
    final answer=cycle[level+1];
    return pick(World.logic,'${pattern.join(' ')} ?',answer,signs.where((s)=>s!=answer).take(3).toList());
   case Challenge.colorConfusion:
    final words=['Rot','Blau','Grün','Gelb'];
    final i=random.nextInt(4),j=(i+1+random.nextInt(3))%4;
    final options=[...words]..shuffle(random);
    return Question(World.focus,words[j].toUpperCase(),words[i],options,'Farbe: ${words[i]}',interaction:Interaction.stroop,board:['$i']);
   case Challenge.spellingDuel:
    const bank=[['Fahrrad','Farad','Fahrad','Farrad'],['Rhythmus','Rytmus','Rhytmus','Rythmuss'],['Bibliothek','Biblioteck','Bibliohthek','Biblothek'],['Schokolade','Schokollade','Schokolate','Schokoladde']];
    final row=bank[random.nextInt(min(bank.length,level+1))];
    return pick(World.words,'Wie schreibt man es?',row.first,row.sublist(1));
   case Challenge.targetHunt:
    final symbols=['●','▲','■','◆','★','✚']..shuffle(random);
    final target=symbols.first,board=List.generate([9,9,12,16][level],(_)=>symbols[1+random.nextInt(min(5,level+2))]);
    board[random.nextInt(board.length)]=target;
    return Question(World.focus,'Finde $target',target,[target,...symbols.skip(1).take(3)],'Tippe nur das Ziel.',interaction:Interaction.target,board:board);
   case Challenge.tapBattle:
    final goal=[5,6,8,10][level];return Question(World.focus,'$goal schnelle Treffer!','$goal',['$goal','0','1','2'],'$goal Treffer ergeben einen Punkt.',interaction:Interaction.tap);
   case Challenge.numberSort:
    final set=<int>{};while(set.length<4){set.add(1+random.nextInt([19,99,999,9999][level]));}
    final board=set.toList()..shuffle(random);
    final sorted=set.toList()..sort();
    if(board.join(' ')==sorted.join(' ')){final first=board[0];board[0]=board[1];board[1]=first;}
    final answer=sorted.join(' ');
    final wrong=List.generate(3,(i){final v=[...sorted];final a=v[i];v[i]=v[i+1];v[i+1]=a;return v.join(' ');});
    return Question(World.math,'Klein nach gross',answer,[answer,...wrong],'Reihenfolge: $answer',interaction:Interaction.sort,board:board.map((n)=>n.toString()).toList());
   case Challenge.compare:
    final numbers=<int>{a,b};while(numbers.length<4){numbers.add(maxDigit-minDigit<3?numbers.length+maxDigit:operand());}
    final largest=random.nextBool();
    final answer=largest?numbers.reduce(max):numbers.reduce(min);
    return pick(World.math,largest?'Welche Zahl ist am grössten?':'Welche Zahl ist am kleinsten?',answer.toString(),numbers.where((n)=>n!=answer).map((n)=>n.toString()).toList());
   case Challenge.missing:return level==0||random.nextBool()?number(World.math,'$a + ? = ${a+b}',b):number(World.math,'? − $b = $a',a+b);
   case Challenge.targetNumber:
    final target=a+b;
    final correct='$a + $b';
    final alternatives=<int>{};while(alternatives.length<3){final n=maxDigit-minDigit<3?maxDigit+1+alternatives.length:operand();if(n!=b)alternatives.add(n);}
    final wrong=alternatives.map((n)=>'$a + $n').toList();
    return pick(World.math,'Erreiche die Zahl $target',correct,wrong);
   case Challenge.trueFalse:
    final correct=random.nextBool();
    final result=a+b+(correct?0:1+random.nextInt(5));
    final answer=correct?'Richtig':'Falsch';
    return Question(World.logic,'$a + $b = $result',answer,const ['Richtig','Falsch'],'$a + $b = ${a+b}');
   case Challenge.reaction:
    return Question(World.focus,'JETZT!','LOS',const ['LOS','Zu früh','Falsch','Warten'],'Reagiere erst auf das Signal.',preview:'Warte auf das Signal …',interaction:Interaction.signal,board:[(900+random.nextInt([1000,1900,2600,3400][level])).toString()]);
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
