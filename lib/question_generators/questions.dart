import 'dart:math';

enum World { math, logic, memory, focus, words, mixed }
extension WorldLabel on World {
  String get label => const ['Mathematik','Logic Clash','Memory Arena','Focus Rush','Word Battle','Mixed Battle'][index];
}
class Question {
  final World world;
  final String prompt, answer, explanation, preview;
  final List<String> options;
  const Question(this.world,this.prompt,this.answer,this.options,this.explanation,{this.preview=''});
}
class Questions {
  final Random random;
  Questions([Random? random]):random=random??Random();
  Question make(World world,int level) {
    level=level.clamp(0,3).toInt();
    if(world==World.mixed) world=World.values[random.nextInt(5)];
    switch(world) {
      case World.math:
        final a=1+random.nextInt([10,30,70,120][level]);
        final b=1+random.nextInt([10,12,20,30][level]);
        final op=random.nextInt(level<2?6:9);
        switch(op) {
          case 0:return number(world,'$a + $b = ?',a+b);
          case 1:return number(world,'${a+b} − $b = ?',a);
          case 2:return number(world,'$a × $b = ?',a*b);
          case 3:return number(world,'${a*b} ÷ $b = ?',a);
          case 4:return number(world,'? + $b = ${a+b}',a);
          case 5:return pick(world,'Welche Zahl ist grösser?',max(a,a+b).toString(),[a.toString(),(a-1).toString(),(a-2).toString()]);
          case 6:return number(world,'25 % von ${a*4}',a);
          case 7:return number(world,'½ von ${a*2}',a);
          default:return number(world,'$a + $b × 2',a+b*2);
        }
      case World.logic:
        final a=1+random.nextInt(9), b=2+random.nextInt(4);
        switch(random.nextInt(4)) {
          case 0:return number(world,'$a · ${a+b} · ${a+2*b} · ?',a+3*b);
          case 1:return number(world,'$a · ${a*2} · ${a*4} · ?',a*8);
          case 2:return pick(world,'● ▲ ■ ● ▲ ?', '■',['●','▲','◆']);
          default:return pick(world,'Welches passt nicht?','🐟',['🐱','🐶','🐭']);
        }
      case World.memory:
        final length=3+level;
        final seq=List.generate(length,(_)=>1+random.nextInt(9));
        final ans=seq.join(' ');
        final wrong=<String>{};
        for(var i=0;i<length&&wrong.length<3;i++) {
          final copy=[...seq];copy[i]=copy[i]%9+1;wrong.add(copy.join(' '));
        }
        return pick(world,'Welche Reihenfolge war sichtbar?',ans,wrong.toList(),preview:ans);
      case World.focus:
        final symbols=['▲','●','■','◆','★','✚'];
        final target=symbols[random.nextInt(symbols.length)];
        final count=1+random.nextInt(4);
        final row=List.generate(count,(_)=>target)..addAll(List.generate(5+level,(_)=>symbols.where((s)=>s!=target).elementAt(random.nextInt(5))))..shuffle(random);
        return number(world,'Zähle $target\n${row.join(' ')}',count);
      case World.words:
        const bank=[
          ['Gegenteil von kalt','warm','nass','klein','hell'],
          ['Synonym für schnell','rasch','langsam','laut','weich'],
          ['Wie schreibt man es?','Fahrrad','Farad','Fahrad','Farrad'],
          ['Englisch: Hund','dog','cat','bird','fish'],
          ['Englisch: Apfel','apple','pear','grape','bread'],
          ['Ergänze: Blu_e','m','n','r','s'],
          ['Welches Wort passt zu 🍌?','Banane','Birne','Apfel','Kirsche'],
          ['Gegenteil von mutig','ängstlich','freundlich','ruhig','froh'],
          ['Synonym für beginnen','anfangen','aufhören','verlieren','suchen'],
          ['Wie schreibt man es?','Rhythmus','Rytmus','Rhytmus','Rythmuss'],
          ['Englisch: Wolke','cloud','crowd','clown','clock'],
          ['Englisch: Brücke','bridge','bright','bread','brick'],
        ];
        final row=bank[random.nextInt(level<2?8:bank.length)];
        return pick(world,row[0],row[1],row.sublist(2));
      case World.mixed:throw StateError('Mixed must resolve');
    }
  }
  Question number(World w,String p,int n) {
    final wrong=<String>{};
    while(wrong.length<3) {
      final d=random.nextInt(13)-6;
      if(d!=0&&n+d>=0) wrong.add((n+d).toString());
    }
    return pick(w,p,n.toString(),wrong.toList());
  }
  Question pick(World w,String p,String a,List<String> wrong,{String preview=''}) {
    final choices=[a,...wrong.where((v)=>v!=a).toSet()]..shuffle(random);
    return Question(w,p,a,choices,'Richtig ist: $a',preview:preview);
  }
}
