import 'dart:math';

enum Interaction { choices, sequence, pairs, signal, recall, stroop, target, tap, sort }
enum World { math, logic, memory, focus, words, mixed }
extension WorldLabel on World {
  String get label => const ['Mathematik','Logic Clash','Memory Arena','Focus Rush','Word Battle','Mixed Battle'][index];
}
class Question {
  final World world;
  final String prompt, answer, explanation, preview;
  final List<String> options;
  final Interaction interaction;
  final List<String> board;
  int get previewMs=>interaction==Interaction.sequence?board.length*480+400:interaction==Interaction.pairs?2600:interaction==Interaction.signal?(board.isEmpty?1800:int.parse(board.first)):preview.isEmpty?0:2200;
  const Question(this.world,this.prompt,this.answer,this.options,this.explanation,{this.preview='',this.interaction=Interaction.choices,this.board=const []});
  String get key=>'${world.name}|$prompt|$answer|$preview|${board.join(',')}';
  Map<String,dynamic> toJson()=>{'world':world.name,'prompt':prompt,'answer':answer,'options':options,'explanation':explanation,'preview':preview,'interaction':interaction.name,'board':board};
  factory Question.fromJson(Map data)=>Question(World.values.byName(data['world'] as String),data['prompt'] as String,data['answer'] as String,List<String>.from(data['options'] as List),data['explanation'] as String,preview:data['preview'] as String,interaction:Interaction.values.byName(data['interaction'] as String? ?? 'choices'),board:List<String>.from(data['board'] as List? ?? []));
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
        final op=random.nextInt(level<2?8:11);
        switch(op) {
          case 0:return number(world,'$a + $b = ?',a+b);
          case 1:return number(world,'${a+b} − $b = ?',a);
          case 2:return number(world,'$a × $b = ?',a*b);
          case 3:return number(world,'${a*b} ÷ $b = ?',a);
          case 4:return number(world,'? + $b = ${a+b}',a);
          case 5:return pick(world,'Welche Zahl ist grösser?',max(a,a+b).toString(),[a.toString(),(a-1).toString(),(a-2).toString()]);
          case 6:return number(world,'$a · ${a+b} · ${a+2*b} · ?',a+3*b);
          case 7:final x=1+random.nextInt(10),y=1+random.nextInt(10);return number(world,'$x × $y = ?',x*y);
          case 8:return number(world,'25 % von ${a*4}',a);
          case 9:return number(world,'½ von ${a*2}',a);
          default:return number(world,'$a + $b × 2',a+b*2);
        }
      case World.logic:
        final a=1+random.nextInt(9), b=2+random.nextInt(4);
        switch(random.nextInt(7)) {
          case 0:return number(world,'$a · ${a+b} · ${a+2*b} · ?',a+3*b);
          case 1:return number(world,'$a · ${a*2} · ${a*4} · ?',a*8);
          case 2:return pick(world,'● ▲ ■ ● ▲ ?', '■',['●','▲','◆']);
          case 3:return pick(world,'Welches passt nicht?','🐟',['🐱','🐶','🐭']);
          case 4:return pick(world,'Drehe ↑ um 90° im Uhrzeigersinn','→',['↑','↓','←']);
          case 5:return pick(world,'Schlüssel gehört zu …','Schloss',['Schuh','Glas','Stift']);
          default:return pick(world,'★ ◆ ◆ ★ ◆ ◆ ?', '★',['◆','■','▲']);
        }
      case World.memory:
        final length=3+level;
        final variant=random.nextInt(5);
        if(variant==3){
          final cells=List.generate(length,(_)=>random.nextInt(9).toString());
          final correct=cells.join(' ');
          final wrong=List.generate(3,(i){final copy=[...cells];copy[i]=((int.parse(copy[i])+1)%9).toString();return copy.join(' ');});
          return Question(world,'Tippe die Felder in derselben Reihenfolge',correct,[correct,...wrong],'Reihenfolge: $correct',preview:correct,interaction:Interaction.sequence,board:cells);
        }
        if(variant==4){
          final faces=['🐱','🐶','🦊','🐼','🐸','🐯']..shuffle(random);
          final cards=faces.take(2+level).expand((f)=>[f,f]).toList()..shuffle(random);
          return Question(world,'Finde alle Bildpaare','Paare gefunden',const ['Paare gefunden','Nicht gleich','Falsch','Noch nicht'],'Gleiche Bilder bilden ein Paar.',preview:'Merke die Karten',interaction:Interaction.pairs,board:cards);
        }
        final symbols=[['1','2','3','4','5','6','7','8','9'],['●','▲','■','◆','★','✚'],['🔴','🔵','🟢','🟡','🟣','🟠']][random.nextInt(3)];
        final seq=List.generate(length,(_)=>random.nextInt(symbols.length));
        String encode(List<int> s)=>s.map((i)=>symbols[i]).join(' ');
        final ans=encode(seq);
        final wrong=<String>{};
        for(var i=0;i<length&&wrong.length<3;i++) {
          final copy=[...seq];copy[i]=(copy[i]+1)%symbols.length;wrong.add(encode(copy));
        }
        return pick(world,'Welche Reihenfolge war sichtbar?',ans,wrong.toList(),preview:ans);
      case World.focus:
        final variant=random.nextInt(5);
        if(variant==2){final signals=['●','▲','■','◆']..shuffle(random);final target=signals[random.nextInt(4)];return Question(World.focus,'JETZT! Tippe $target',target,signals,'Reagiere erst auf das Signal.',preview:'Warte auf das Signal …',interaction:Interaction.signal,board:[(1100+random.nextInt(1400)).toString()]);}
        if(variant==3){return pick(world,'Welche Farbe hat der Kreis? 🔴 BLAU','Rot',['Blau','Grün','Gelb']);}
        if(variant==4){return pick(world,'Finde den blauen Kreis','🔵',['🔷','🔴','🟦']);}
        if(variant==0){
          final icons=['▲','●','■','◆','★','✚']..shuffle(random);
          final repeated=icons[0],odd=icons[1];
          final grid=List.filled(6+level*3,repeated);grid[random.nextInt(grid.length)]=odd;
          return pick(world,'Welches Symbol ist anders?\n${grid.join(' ')}',odd,[repeated,icons[2],icons[3]]);
        }
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
          ['Gegenteil von öffnen','schliessen','halten','zeigen','lesen'],
          ['Wie schreibt man es?','Bibliothek','Biblioteck','Bibliohthek','Biblothek'],
          ['Englisch: Fenster','window','winter','water','wall'],
          ['Englisch: Sonne','sun','sea','son','snow'],
          ['Englisch: Baum','tree','train','three','truck'],
          ['Gegenteil von laut','leise','gross','sauer','hell'],
          ['Ergänze: Schu_ (ein einzelner Schuh)','h','l','m','k'],
          ['Welches Wort passt zu 🐘?','Elefant','Tiger','Giraffe','Zebra'],
        ];
        final row=bank[random.nextInt(level==0?8:bank.length)];
        return pick(world,row[0],row[1],row.sublist(2));
      case World.mixed:throw StateError('Mixed must resolve');
    }
  }
  Question number(World w,String p,int n) {
    final wrong=<String>{};
    while(wrong.length<3) {
      final d=random.nextInt(13)-6;
      if(d!=0&&(n<0||n+d>=0)) wrong.add((n+d).toString());
    }
    return pick(w,p,n.toString(),wrong.toList());
  }
  Question pick(World w,String p,String a,List<String> wrong,{String preview=''}) {
    final choices=[a,...wrong.where((v)=>v!=a).toSet()]..shuffle(random);
    return Question(w,p,a,choices,'Richtig ist: $a',preview:preview);
  }
}

class ReviewQuestions extends Questions {
  final List<Question> due;
  ReviewQuestions(Iterable<Question> due):due=List.of(due);
  @override Question make(World world,int level){
    final i=due.indexWhere((q)=>world==World.mixed||q.world==world);
    return i<0?super.make(world,level):due.removeAt(i);
  }
}
