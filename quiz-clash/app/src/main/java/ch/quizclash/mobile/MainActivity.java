package ch.quizclash.mobile;

import android.app.*;
import android.os.*;
import android.content.*;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {
    static final int BG=0xfff4f3fb, INK=0xff211c45, MUTED=0xff57546d, PURPLE=0xff5446c7,
        GREEN=0xff176c49, RED=0xffa52b42, WHITE=0xffffffff, GOLD=0xffffe3a1;
    static final int IMPORT=41, LIMIT=24*1024*1024;
    static class Q {
        String id,subject,question,explanation,topic,difficulty;
        int grade,answer;
        ArrayList<String> options;
        Q(String i,int g,String s,String t,String d,String q,ArrayList<String> o,int a,String e) {
            id=i;grade=g;subject=s;topic=t;difficulty=d;question=q;options=o;answer=a;explanation=e;
        }
    }
    ArrayList<Q> bank=new ArrayList<>(),round=new ArrayList<>();
    Set<String> mistakes=new HashSet<>(), subjects=new TreeSet<>();
    ArrayList<Integer> order=new ArrayList<>();
    android.content.SharedPreferences prefs;
    LinearLayout root,body; ScrollView scroll;
    int grade=4,count=10,index=0,score=0,correct=0,streak=0,chosen=-1,totalAnswered=0;
    long xp=0;
    String screen="home",mode="training",difficulty="Alle";
    boolean imported=false,loading=false;
    String note="";
    final java.util.concurrent.ExecutorService io=Executors.newSingleThreadExecutor();

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        prefs=getSharedPreferences("quiz_progress",MODE_PRIVATE);
        xp=prefs.getLong("xp",0); totalAnswered=prefs.getInt("answered",0);
        grade=Math.max(1,Math.min(9,prefs.getInt("grade",4)));
        mistakes=new HashSet<>(prefs.getStringSet("mistakes",Collections.emptySet()));
        demo();
        home();
        File saved=new File(getFilesDir(),"questions.json");
        if(saved.exists()) { loading=true;home();io.execute(()->{
            try { String raw=read(new FileInputStream(saved)); ImportResult parsed=parse(raw);
                runOnUiThread(()->{if(isFinishing()||isDestroyed())return;bank=parsed.questions;imported=true;loading=false;home();});
            } catch(Exception ex){runOnUiThread(()->{if(isFinishing()||isDestroyed())return;loading=false;note="Gespeicherte Bank konnte nicht geladen werden. Demo aktiv.";home();});}
        });}
    }
    int dp(float n){return (int)(n*getResources().getDisplayMetrics().density+0.5f);}
    GradientDrawable bg(int color,int radius){GradientDrawable g=new GradientDrawable();g.setColor(color);g.setCornerRadius(dp(radius));return g;}
    TextView text(String s,int size,int color,boolean bold){
        TextView v=new TextView(this);v.setText(s);v.setTextSize(size);v.setTextColor(color);
        v.setTypeface(Typeface.DEFAULT,bold?Typeface.BOLD:Typeface.NORMAL);v.setLineSpacing(dp(2),1f);return v;
    }
    void add(LinearLayout p,View v,int bottom){
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.bottomMargin=dp(bottom);p.addView(v,lp);
    }
    LinearLayout column(int color,int pad){
        LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);l.setPadding(dp(pad),dp(pad),dp(pad),dp(pad));l.setBackground(bg(color,20));return l;
    }
    TextView button(String label,int color,int fg,Runnable run){
        TextView v=text(label,16,fg,true);v.setGravity(Gravity.CENTER);v.setMinHeight(dp(54));
        v.setPadding(dp(14),dp(13),dp(14),dp(13));v.setBackground(bg(color,16));v.setClickable(true);v.setFocusable(true);
        v.setOnClickListener(x->run.run());
        return v;
    }
    void base(String name,String heading,String subtitle,boolean back){
        screen=name;
        getWindow().setStatusBarColor(BG);getWindow().setNavigationBarColor(BG);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR|View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(BG);
        root.setOnApplyWindowInsetsListener((v,insets)->{
            if(Build.VERSION.SDK_INT>=30){android.graphics.Insets i=insets.getInsets(WindowInsets.Type.systemBars()|WindowInsets.Type.displayCutout());v.setPadding(i.left,i.top,i.right,i.bottom);}
            else v.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());
            return insets;
        });
        LinearLayout header=column(BG,16);
        if(back)add(header,button("‹  Zurück",WHITE,INK,()->back()),8);
        add(header,text(heading,29,INK,true),3);
        add(header,text(subtitle,14,MUTED,false),0);root.addView(header);
        scroll=new ScrollView(this);scroll.setFillViewport(false);
        body=column(BG,16);body.setPadding(dp(16),dp(2),dp(16),dp(24));scroll.addView(body);
        root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        setContentView(root);root.requestApplyInsets();
    }
    void heading(String s){add(body,text(s,19,INK,true),9);}
    void caption(String s){add(body,text(s,14,MUTED,false),12);}
    void action(String s,Runnable r){add(body,button(s,PURPLE,WHITE,r),10);}
    void secondary(String s,Runnable r){add(body,button(s,WHITE,INK,r),10);}
    String icon(String s){
        String k=s.toLowerCase(Locale.ROOT);
        if(k.contains("deutsch"))return "📚";if(k.contains("englisch"))return "🌍";if(k.contains("franz"))return "💬";
        if(k.contains("italien"))return "🇮🇹";if(k.contains("natur")||k.contains("nmg")||k.equals("nt"))return "🌱";
        if(k.contains("musik"))return "🎵";if(k.contains("sport"))return "🏅";if(k.contains("medien")||k.contains("informatik"))return "💻";
        if(k.contains("gestalt")||k.contains("ttg"))return "🎨";if(k.contains("geschichte")||k.contains("rzg"))return "🗺";
        if(k.contains("wah")||k.contains("haushalt"))return "🍎";return "✦";
    }
    int level(){return (int)Math.min(Integer.MAX_VALUE,1+xp/1000);}
    void home(){
        base("home","Quiz Clash","Dein Wissen. Dein Abenteuer.",false);
        LinearLayout hero=column(PURPLE,20);
        add(hero,text("✦  LEVEL "+level(),14,0xffffe3a1,true),8);
        add(hero,text(xp+" XP",34,WHITE,true),5);
        ProgressBar p=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);p.setMax(1000);p.setProgress((int)(xp%1000));p.setProgressTintList(ColorStateList.valueOf(GOLD));add(hero,p,8);
        add(hero,text((1000-xp%1000)+" XP bis zum nächsten Level",14,WHITE,false),0);add(body,hero,17);
        heading("Bereit für eine Runde?");
        if(loading){caption("Fragenbank wird geladen …");return;}
        action("▶  Quiz starten",()->{mode="training";classes();});
        secondary("★  Tages-Challenge",()->{mode="daily";classes();});
        secondary("↻  Fehler trainieren  ("+mistakes.size()+")",()->{mode="mistakes";classes();});
        secondary("▥  Mein Fortschritt",()->stats());
        heading("Fragenbank");
        caption((imported?"Importierte Fragen · redaktionell nicht freigegeben":"Demo-Fragenbank")+" · "+bank.size()+" Fragen · Klassen 1–9");
        if(!note.isEmpty())caption(note);
        secondary("＋  Fragenbank importieren (JSON)",()->pick());
        caption("Offline · ohne Werbung · keine Rechenaufgaben");
    }
    void classes(){
        base("classes","Deine Klasse","Wähle deine Schulstufe.",true);
        for(int start=1;start<=9;start+=3){
            LinearLayout row=new LinearLayout(this);row.setOrientation(LinearLayout.HORIZONTAL);
            for(int g=start;g<start+3;g++){final int gg=g;long n=bank.stream().filter(q->q.grade==gg&&(!mode.equals("mistakes")||mistakes.contains(q.id))).count();
                TextView cell=button(g+". Klasse\n"+n+" Fragen",g==grade?PURPLE:WHITE,g==grade?WHITE:INK,()->{grade=gg;prefs.edit().putInt("grade",grade).apply();subjects.clear();difficulty="Alle";setup();});
                LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,-2,1);lp.setMargins(dp(3),0,dp(3),dp(10));row.addView(cell,lp);
            }
            add(body,row,0);
        }
        caption("Klassenstufen sind eine Orientierung am Lehrplan 21.");
    }
    ArrayList<Q> pool(){
        ArrayList<Q> out=new ArrayList<>();
        for(Q q:bank)if(q.grade==grade&&(subjects.isEmpty()||subjects.contains(q.subject))&&
          (difficulty.equals("Alle")||q.difficulty.equalsIgnoreCase(difficulty))&&(!mode.equals("mistakes")||mistakes.contains(q.id)))out.add(q);
        return out;
    }
    void setup(){
        base("setup",grade+". Klasse",mode.equals("daily")?"Tages-Challenge":mode.equals("mistakes")?"Fehlertraining":"Stelle dein Quiz zusammen.",true);
        TreeMap<String,Integer> cats=new TreeMap<>();
        for(Q q:bank)if(q.grade==grade&&(!mode.equals("mistakes")||mistakes.contains(q.id)))cats.merge(q.subject,1,Integer::sum);
        if(cats.isEmpty()){caption("Hier gibt es noch keine passenden Fragen.");secondary("Andere Klasse wählen",()->classes());return;}
        if(!mode.equals("daily")){
            heading("Fächer · mehrere möglich");
            secondary(subjects.isEmpty()?"✓ Alle Fächer":"Alle Fächer auswählen",()->{subjects.clear();setup();});
            for(Map.Entry<String,Integer> e:cats.entrySet()){
                String s=e.getKey();
                add(body,button((subjects.contains(s)?"✓  ":"")+icon(s)+"  "+s+"  ·  "+e.getValue(),subjects.contains(s)?PURPLE:WHITE,subjects.contains(s)?WHITE:INK,()->{if(!subjects.add(s))subjects.remove(s);setup();}),8);
            }
            heading("Schwierigkeit");
            choices(new String[]{"Alle","leicht","mittel","schwer"},difficulty,s->{difficulty=s;setup();});
            heading("Rundenlänge");
            choices(new String[]{"5","10","20"},String.valueOf(count),s->{count=Integer.parseInt(s);setup();});
        }else caption("Bis zu 10 Fragen. Jeden Tag eine neue Auswahl, ohne Zeitdruck.");
        int available=pool().size();int requested=mode.equals("daily")?10:count;
        caption(available==0?"Keine Fragen für diese Auswahl.":Math.min(available,requested)+" Fragen in dieser Runde · "+available+" verfügbar");
        if(available>0)action("Los geht's!  →",()->start());
    }
    interface Pick {void choose(String s);}
    void choices(String[] values,String selected,Pick cb){
        LinearLayout row=new LinearLayout(this);
        for(String s:values){TextView v=button(s,s.equals(selected)?PURPLE:WHITE,s.equals(selected)?WHITE:INK,()->cb.choose(s));
            LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,-2,1);lp.setMargins(dp(2),0,dp(2),dp(8));row.addView(v,lp);}
        add(body,row,3);
    }
    void start(){
        ArrayList<Q> p=pool();if(p.isEmpty())return;
        if(mode.equals("daily")){
            p.sort(Comparator.comparing(q->q.id));
            long seed=java.time.LocalDate.now().toEpochDay()*31+grade;Collections.shuffle(p,new Random(seed));
        }else Collections.shuffle(p);
        round=new ArrayList<>(p.subList(0,Math.min(p.size(),mode.equals("daily")?10:count)));
        index=score=correct=streak=0;chosen=-1;shuffleAnswers();quiz();
    }
    void shuffleAnswers(){
        order=new ArrayList<>();for(int i=0;i<round.get(index).options.size();i++)order.add(i);
        Collections.shuffle(order);
    }
    void quiz(){
        if(index>=round.size()){result();return;}
        Q q=round.get(index);
        base("quiz","Frage "+(index+1)+" / "+round.size(),"★ "+score+" Punkte     •     Serie "+streak,true);
        ProgressBar p=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);p.setMax(round.size());p.setProgress(index+(chosen>=0?1:0));p.setProgressTintList(ColorStateList.valueOf(PURPLE));add(body,p,14);
        LinearLayout panel=column(WHITE,20);
        add(panel,text(icon(q.subject)+"  "+q.subject+" · "+q.grade+". Klasse",14,PURPLE,true),10);
        add(panel,text(q.question,24,INK,true),0);add(body,panel,16);
        for(int i=0;i<order.size();i++){final int oi=order.get(i);
            int color=WHITE,fg=INK;String prefix=(char)('A'+i)+".  ";
            if(chosen>=0&&oi==q.answer){color=0xffd7f3e4;fg=GREEN;prefix="✓  ";}
            else if(chosen==oi){color=0xffffdce4;fg=RED;prefix="✗  ";}
            TextView b=button(prefix+q.options.get(oi),color,fg,()->answer(oi));
            if(chosen>=0){b.setOnClickListener(null);b.setClickable(false);}
            add(body,b,9);
        }
        if(chosen>=0){
            boolean good=chosen==q.answer;LinearLayout feedback=column(good?0xffd7f3e4:0xffffe9ed,16);
            add(feedback,text(good?"Super! +"+(streak>=3?125:100)+" Punkte":"Nicht ganz – du lernst dazu!",19,good?GREEN:RED,true),7);
            add(feedback,text(q.explanation,16,INK,false),0);add(body,feedback,12);
            action(index+1==round.size()?"Ergebnis ansehen":"Nächste Frage  →",()->{if(chosen<0)return;index++;chosen=-1;if(index==round.size())result();else{shuffleAnswers();quiz();}});
        }
    }
    void answer(int selected){
        if(!screen.equals("quiz")||chosen>=0||index>=round.size())return;
        Q q=round.get(index);chosen=selected;totalAnswered++;
        if(selected==q.answer){correct++;streak++;int points=streak>=3?125:100;score+=points;xp+=points;mistakes.remove(q.id);}
        else{streak=0;mistakes.add(q.id);}
        prefs.edit().putLong("xp",xp).putInt("answered",totalAnswered).putStringSet("mistakes",new HashSet<>(mistakes)).apply();
        quiz();
    }
    void result(){
        base("result","Runde geschafft!","Jede Frage bringt dich weiter.",false);
        LinearLayout card=column(PURPLE,22);
        add(card,text("★  "+score+" Punkte",32,WHITE,true),8);
        add(card,text(correct+" von "+round.size()+" richtig",22,WHITE,true),6);
        add(card,text("Level "+level()+"  ·  "+xp+" XP insgesamt",15,WHITE,false),0);add(body,card,18);
        int stars=(correct*3)/round.size();heading(stars==3?"★★★  Fantastisch!":stars==2?"★★☆  Gut gemacht!":stars==1?"★☆☆  Weiter so!":"Weiter üben lohnt sich!");
        action("Noch eine Runde",()->setup());secondary("Fehler trainieren",()->{mode="mistakes";subjects.clear();difficulty="Alle";setup();});secondary("Zur Startseite",()->home());
    }
    void stats(){
        base("stats","Mein Fortschritt","Dein persönlicher Lernweg.",true);
        heading("Level "+level());caption(xp+" XP insgesamt · "+totalAnswered+" beantwortete Fragen");
        heading("Fehlertraining");caption(mistakes.size()+" Fragen warten auf eine Wiederholung.");
        heading("Verfügbare Fragen");
        for(int g=1;g<=9;g++){final int gg=g;caption(g+". Klasse  ·  "+bank.stream().filter(q->q.grade==gg).count()+" Fragen");}
        secondary("Fortschritt zurücksetzen",()->new AlertDialog.Builder(this).setTitle("Fortschritt löschen?").setMessage("XP und Fehlerliste werden gelöscht. Die Fragenbank bleibt erhalten.").setNegativeButton("Abbrechen",null).setPositiveButton("Löschen",(d,w)->{xp=0;totalAnswered=0;mistakes.clear();prefs.edit().remove("xp").remove("answered").remove("mistakes").apply();stats();}).show());
    }
    void back(){
        switch(screen){case "quiz":new AlertDialog.Builder(this).setTitle("Runde beenden?").setMessage("Deine bereits verdienten Punkte bleiben gespeichert.").setNegativeButton("Weiterspielen",null).setPositiveButton("Beenden",(d,w)->home()).show();break;
        case "setup":classes();break;case "home":super.onBackPressed();break;default:home();}
    }
    @Override public void onBackPressed(){back();}
    void pick(){
        if(loading)return;
        Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);i.addCategory(Intent.CATEGORY_OPENABLE);i.setType("*/*");i.putExtra(Intent.EXTRA_MIME_TYPES,new String[]{"application/json","text/plain","application/octet-stream"});
        try{startActivityForResult(i,IMPORT);}catch(Exception e){note="Kein Dateiauswahldienst verfügbar.";home();}
    }
    @Override protected void onActivityResult(int req,int res,Intent data){
        super.onActivityResult(req,res,data);if(req!=IMPORT||res!=RESULT_OK||data==null||data.getData()==null)return;
        Uri uri=data.getData();loading=true;home();
        io.execute(()->{
            try{
                String raw=read(getContentResolver().openInputStream(uri));ImportResult parsed=parse(raw);
                // Persist atomically; retain the old bank on error.
                android.util.AtomicFile af=new android.util.AtomicFile(new File(getFilesDir(),"questions.json"));
                FileOutputStream out=af.startWrite();
                try{out.write(raw.getBytes(StandardCharsets.UTF_8));af.finishWrite(out);}catch(Exception e){af.failWrite(out);throw e;}
                runOnUiThread(()->{if(isFinishing()||isDestroyed())return;bank=parsed.questions;imported=true;loading=false;mistakes.clear();prefs.edit().remove("mistakes").apply();
                    note=bank.size()+" Fragen importiert. "+parsed.skipped+" ungültige oder doppelte Einträge übersprungen.";home();});
            }catch(Exception e){runOnUiThread(()->{if(isFinishing()||isDestroyed())return;loading=false;note="Import nicht möglich: "+(e.getMessage()==null?"unbekannter Fehler":e.getMessage());home();});}
        });
    }
    static String read(InputStream input)throws IOException{
        if(input==null)throw new IOException("Datei nicht lesbar");
        try(InputStream in=input;ByteArrayOutputStream out=new ByteArrayOutputStream()){
            byte[] b=new byte[8192];int n,total=0;while((n=in.read(b))!=-1){total+=n;if(total>LIMIT)throw new IOException("Datei ist grösser als 24 MB");out.write(b,0,n);}
            String s=out.toString("UTF-8");return s.startsWith("\uFEFF")?s.substring(1):s;
        }
    }
    static Object value(JSONObject o,String... keys){for(String k:keys)if(o.has(k)&&!o.isNull(k))return o.opt(k);return null;}
    static String str(JSONObject o,String... keys){Object v=value(o,keys);return v==null?"":v.toString().trim();}
    static int number(Object v){if(v==null)return -1;String s=v.toString().trim();try{return Integer.parseInt(s);}catch(Exception e){return -1;}}
    static String norm(String s){return java.text.Normalizer.normalize(s,java.text.Normalizer.Form.NFC).trim().replaceAll("\\s+"," ").toLowerCase(Locale.ROOT);}
    static class ImportResult {ArrayList<Q> questions=new ArrayList<>();int skipped=0;}
    static ImportResult parse(String raw)throws JSONException,IOException{
        Object root=new JSONTokener(raw).nextValue();JSONArray rows;
        if(root instanceof JSONArray)rows=(JSONArray)root;
        else if(root instanceof JSONObject){Object v=value((JSONObject)root,"questions","fragen","items","data","records","datensaetze");rows=v instanceof JSONArray?(JSONArray)v:null;}
        else rows=null;
        if(rows==null||rows.length()==0||rows.length()>20000)throw new IOException("JSON muss 1–20'000 Fragen als Liste enthalten");
        ImportResult result=new ImportResult();Set<String> ids=new HashSet<>(),stems=new HashSet<>();
        for(int i=0;i<rows.length();i++){
            JSONObject r=rows.optJSONObject(i);if(r==null){result.skipped++;continue;}
            String id=str(r,"id","question_id","frage_id"),sub=str(r,"subject","fach","category","kategorie"),
                stem=str(r,"question","frage","prompt","question_text","text"),exp=str(r,"explanation","erklaerung","erklärung","feedback"),
                topic=str(r,"topic","unterthema","thema","subtopic","sub_topic"),diff=str(r,"difficulty","schwierigkeit","schwierigkeitsgrad","schwierigkeitsstufe");
            int grade=number(value(r,"grade","klasse","class","class_level","classLevel","klassenstufe","grade_level"));
            Object os=value(r,"options","antwortoptionen","antworten","choices","answer_options");
            ArrayList<String> opts=new ArrayList<>();
            if(os instanceof JSONArray){JSONArray arr=(JSONArray)os;for(int k=0;k<arr.length();k++){Object option=arr.opt(k);opts.add(option instanceof String?((String)option).trim():option instanceof JSONObject?str((JSONObject)option,"text","answer","label"):"");}}
            else if(os instanceof JSONObject){JSONObject map=(JSONObject)os;for(String k:new String[]{"A","B","C","D"})if(map.has(k))opts.add(map.optString(k).trim());}
            int a=number(value(r,"correct_index","correctIndex","correct_answer_index","correctAnswerIndex","antwortindex","korrekter_antwortindex","richtige_antwort_index","richtige_antwortindex","answer_index","loesungsindex","lösungsindex"));
            String answerText=str(r,"correct_answer","correctAnswer","richtige_antwort","richtigeAntwort","antwort","loesung","lösung");
            if(a<0&&!answerText.isEmpty()){a=opts.indexOf(answerText);if(a<0&&answerText.matches("[ABCD]"))a=answerText.charAt(0)-'A';}
            Set<String> unique=new HashSet<>();for(String o:opts)unique.add(norm(o));
            String key=grade+"|"+norm(sub)+"|"+norm(stem);
            if(id.isEmpty()||sub.isEmpty()||stem.isEmpty()||exp.isEmpty()||grade<1||grade>9||!(opts.size()==4||opts.size()==2)||a<0||a>=opts.size()||unique.size()!=opts.size()||unique.contains("")||norm(sub).contains("mathematik")||ids.contains(id)||stems.contains(key)||
                (!answerText.isEmpty()&&opts.contains(answerText)&&!opts.get(a).equals(answerText))){result.skipped++;continue;}
            ids.add(id);stems.add(key);result.questions.add(new Q(id,grade,sub,topic,diff,stem,opts,a,exp));
        }
        if(result.questions.isEmpty())throw new IOException("Keine gültigen Fragen erkannt. Prüfe JSON-Feldnamen und Antwortindizes.");
        return result;
    }
    void d(int g,String sub,String question,String right,String b,String c,String d,String exp){
        bank.add(new Q("demo-"+g+"-"+bank.size(),g,sub,"Demo","mittel",question,new ArrayList<>(Arrays.asList(right,b,c,d)),0,exp));
    }
    void demo(){
        d(1,"Deutsch","Welches Wort reimt sich auf Maus?","Haus","Baum","Tisch","Hund","Maus und Haus klingen am Ende gleich.");
        d(1,"NMG","Welches Tier kann fliegen?","Spatz","Igel","Kuh","Frosch","Ein Spatz hat Flügel und kann fliegen.");
        d(1,"Musik","Womit spielst du eine Trommel?","Mit Händen oder Schlägeln","Mit einer Schere","Mit einem Lineal zum Zeichnen","Mit einem Pinsel","Eine Trommel klingt, wenn ihr Fell angeschlagen wird.");
        d(2,"Deutsch","Welches Wort ist ein Nomen?","Blume","schnell","laufen","rot","Blume bezeichnet eine Pflanze und ist ein Nomen.");
        d(2,"NMG","Was brauchen Pflanzen zum Wachsen?","Wasser und Licht","Plastik und Rauch","Nur Sand","Nur Dunkelheit","Pflanzen benötigen unter anderem Wasser und Licht.");
        d(2,"Sport","Was hilft beim Velofahren, den Kopf zu schützen?","Velohelm","Handschuhe","Rucksack","Schal","Ein passender Helm schützt den Kopf bei einem Sturz.");
        d(3,"Englisch","What is the English word for «Hund»?","dog","cat","bird","fish","Dog bedeutet Hund.");
        d(3,"Deutsch","Was ist das Gegenteil von leise?","laut","langsam","kalt","klein","Leise und laut sind Gegenteile.");
        d(3,"NMG","Welche Jahreszeit folgt auf den Sommer?","Herbst","Winter","Frühling","Sommer","Nach dem Sommer beginnt der Herbst.");
        d(4,"NMG","Welcher Kanton ist flächenmässig der grösste?","Graubünden","Zürich","Genf","Zug","Graubünden ist der grösste Kanton der Schweiz.");
        d(4,"Deutsch","Welches Wort ist ein Verb?","springen","Schule","gelb","heute","Springen bezeichnet eine Tätigkeit.");
        d(4,"Englisch","Which word means «Fenster»?","window","door","wall","floor","Window bedeutet Fenster.");
        d(5,"Französisch","Was bedeutet «bonjour»?","Guten Tag","Gute Nacht","Danke","Bis morgen","Bonjour ist eine Begrüssung am Tag.");
        d(5,"NMG","Welches Organ pumpt Blut durch den Körper?","Herz","Magen","Lunge","Leber","Das Herz pumpt Blut durch die Blutgefässe.");
        d(5,"Medien und Informatik","Was ist ein starkes Passwort?","Ein langes, einzigartiges Passwort","Der eigene Vorname","123456","Das Wort Passwort","Lange einzigartige Passwörter sind schwerer zu erraten.");
        d(6,"Deutsch","Welche Zeitform hat «Ich habe gelesen»?","Perfekt","Präsens","Futur I","Präteritum","Habe gelesen ist das Perfekt.");
        d(6,"Englisch","Choose the past tense of «go».","went","goed","goes","going","Went ist die unregelmässige Vergangenheitsform von go.");
        d(6,"NMG","Was beschreibt den Wasserkreislauf?","Verdunstung, Kondensation und Niederschlag","Nur das Gefrieren","Nur die Strömung eines Flusses","Nur die Reinigung von Trinkwasser","Wasser verdunstet, kondensiert und fällt als Niederschlag zurück.");
        d(7,"Natur und Technik","Was ist bei der Fotosynthese ein Ausgangsstoff?","Kohlenstoffdioxid","Helium","Stickstoffgas","Kochsalz","Pflanzen nutzen unter anderem Kohlenstoffdioxid, Wasser und Lichtenergie.");
        d(7,"Räume, Zeiten, Gesellschaften","Was bezeichnet eine Demokratie?","Eine Herrschaftsform mit politischer Beteiligung des Volkes","Eine Herrschaft ohne Wahlen durch eine einzelne Person","Eine Gebirgsform","Ein Wirtschaftszweig","In einer Demokratie kann das Volk an politischen Entscheidungen mitwirken.");
        d(7,"WAH","Warum sollen rohe Pouletteile getrennt von Salat verarbeitet werden?","Um Keimübertragung zu vermeiden","Damit der Salat mehr Farbe hat","Damit das Poulet schneller abkühlt","Damit beide gleich riechen","Getrennte Arbeitsflächen und Geräte verringern Kreuzkontamination.");
        d(8,"Natur und Technik","Welche Teilchen tragen eine negative elektrische Ladung?","Elektronen","Protonen","Neutronen","Photonen","Elektronen sind negativ geladen.");
        d(8,"Räume, Zeiten, Gesellschaften","Welche Epoche ist für die Industrialisierung in Europa besonders bedeutend?","19. Jahrhundert","5. Jahrhundert","12. Jahrhundert","Antike","Im 19. Jahrhundert verbreiteten sich Fabriken und Maschinen stark.");
        d(8,"Französisch","Welche Form passt: Nous ___ à Genève. (habiter)","habitons","habitez","habite","habitent","Bei nous lautet die Form habitons.");
        d(9,"Natur und Technik","Welche Aufgabe hat die DNA?","Erbinformation speichern","Sauerstoff im Blut transportieren","Nahrung im Magen zerkleinern","Licht ins Auge bündeln","DNA enthält die genetische Information.");
        d(9,"Berufliche Orientierung","Was gehört typischerweise in ein Bewerbungsschreiben?","Motivation und Bezug zur Stelle","Passwörter","Eine unpassende Einkaufsliste","Nur ein Emoji","Ein Bewerbungsschreiben erklärt, warum die Stelle und die Person zusammenpassen.");
        d(9,"Medien und Informatik","Was ist Phishing?","Ein Versuch, vertrauliche Daten durch Täuschung zu erlangen","Eine Methode zur Datensicherung","Ein Programm für Tabellen","Eine Art der Bildschirmreinigung","Phishing täuscht Vertrauen vor, um beispielsweise Zugangsdaten zu stehlen.");
    }
}
