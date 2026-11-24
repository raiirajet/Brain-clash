import 'dart:math';
import 'questions.dart';

enum Challenge { mathClassic, addition, subtraction, multiplication, division, timesTable, arithmeticMix, compare, missing, logic, memory, focus, words, mixed, reaction, odd, sequence, pairs, trueFalse, targetNumber }
extension ChallengeInfo on Challenge {
 String get label=>const ['Mathematik Mix (klassisch)','Addition','Subtraktion','Multiplikation','Division','Einmaleins','Rechen-Mix','Zahlen-Duell','Zahlenlücke','Logic Clash','Memory Arena','Focus Rush','Word Battle','Mixed Battle','Signal Sprint','Symbol-Jagd','Licht-Memory','Paare-Duell','Wahr oder falsch','Zahlen-Ziel'][index];
 String get symbol=>const ['±','+','−','×','÷','1×1','±×','>','?','◆','◉','◎','ABC','⚡','!','★','▦','◫','✓','🎯'][index];
 World get world=>switch(this){
  Challenge.logic||Challenge.trueFalse=>World.logic,
  Challenge.memory||Challenge.sequence||Challenge.pairs=>World.memory,
  Challenge.focus||Challenge.reaction||Challenge.odd=>World.focus,
  Challenge.words=>World.words,Challenge.mixed=>World.mixed,_=>World.math,
 };
 bool get usesDigits=>const [Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division,Challenge.arithmeticMix,Challenge.compare,Challenge.missing,Challenge.targetNumber,Challenge.trueFalse].contains(this);
 bool get standard=>const [Challenge.mathClassic,Challenge.logic,Challenge.memory,Challenge.focus,Challenge.words,Challenge.mixed].contains(this);
 bool get numeric=>world==World.math;
}
class ChallengeQuestions extends Questions{
 final Challenge challenge;
 final int digits;
 final List<Question> due;
 ChallengeQuestions(this.challenge,this.digits,{Random? random,Iterable<Question> reviews=const []}):due=List.of(reviews),super(random);
 int get minDigit=>[1,10,100][digits.clamp(1,3).toInt()-1];
 int get maxDigit=>[9,99,999][digits.clamp(1,3).toInt()-1];
 int operand()=>minDigit+random.nextInt(maxDigit-minDigit+1);
 @override Question make(World world,int level){
  if(challenge.standard){
   final i=due.indexWhere((q)=>world==World.mixed||q.world==world);
   if(i>=0)return due.removeAt(i);
   return super.make(world,level);
  }
  final a=operand(),b=operand();
  final type=challenge==Challenge.arithmeticMix?[Challenge.addition,Challenge.subtraction,Challenge.multiplication,Challenge.division][random.nextInt(4)]:challenge;
  switch(type){
   case Challenge.addition:return number(World.math,'$a + $b = ?',a+b);
   case Challenge.subtraction:return number(World.math,'${max(a,b)} − ${min(a,b)} = ?', (a-b).abs());
   case Challenge.multiplication:return number(World.math,'$a × $b = ?',a*b);
   case Challenge.division:
    // Dividend has exactly the selected digits; the divisor is nonzero and the quotient integral.
    final divisor=2+random.nextInt(min(12,maxDigit)-1);
    final lo=max(1,(minDigit+divisor-1)~/divisor),hi=maxDigit~/divisor;
    final quotient=lo+random.nextInt(hi-lo+1);
    return number(World.math,'${quotient*divisor} ÷ $divisor = ?',quotient);
   case Challenge.timesTable:
    final x=1+random.nextInt(10),y=1+random.nextInt(10);
    return number(World.math,'$x × $y = ?',x*y);
   case Challenge.compare:
    final numbers=<int>{a,b};while(numbers.length<4){numbers.add(operand());}
    final largest=random.nextBool();
    final answer=largest?numbers.reduce(max):numbers.reduce(min);
    return pick(World.math,largest?'Welche Zahl ist am grössten?':'Welche Zahl ist am kleinsten?',answer.toString(),numbers.where((n)=>n!=answer).map((n)=>n.toString()).toList());
   case Challenge.missing:return number(World.math,'$a + ? = ${a+b}',b);
   case Challenge.targetNumber:
    final target=a+b;
    final correct='$a + $b';
    final wrong=List.generate(3,(i)=>'$a + ${b+i+1}');
    return pick(World.math,'Erreiche die Zahl $target',correct,wrong);
   case Challenge.trueFalse:
    final correct=random.nextBool();
    final result=a+b+(correct?0:1+random.nextInt(5));
    final answer=correct?'Richtig':'Falsch';
    return Question(World.logic,'$a + $b = $result',answer,const ['Richtig','Falsch'],'$a + $b = ${a+b}');
   case Challenge.reaction:
    final signs=['●','▲','■','◆']..shuffle(random);
    return Question(World.focus,'JETZT! Tippe ${signs.first}',signs.first,signs,'Reagiere erst auf das Signal.',preview:'Warte auf das Signal …',interaction:Interaction.signal,board:[(900+random.nextInt(1900)).toString()]);
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
