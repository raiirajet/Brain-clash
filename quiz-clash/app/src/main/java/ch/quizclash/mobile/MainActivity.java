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
    static final int BUNDLED_COUNT=5400;
    ArrayList<Q> bank=new ArrayList<>(),round=new ArrayList<>(),bundledBank=new ArrayList<>();
    Set<String> mistakes=new HashSet<>(), subjects=new TreeSet<>();
    ArrayList<Integer> order=new ArrayList<>();
    android.content.SharedPreferences prefs;
    LinearLayout root,body; ScrollView scroll;
    int grade=4,count=10,index=0,score=0,correct=0,streak=0,chosen=-1,totalAnswered=0;
    int mixedCount=10,profileGrade=0,avatarStyle=0,draftStyle=0;
    long avatarSeed,draftSeed;
    boolean setupFromClasses=false;
    String pendingProfileAction="";
    final Random avatarRandom=new Random();
    long xp=0;
    String screen="home",mode="training",difficulty="Alle";
    boolean imported=false,loading=false;
    String note="";
    final java.util.concurrent.ExecutorService io=Executors.newSingleThreadExecutor();

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        prefs=getSharedPreferences("quiz_progress",MODE_PRIVATE);
        xp=prefs.getLong("xp",0); totalAnswered=prefs.getInt("answered",0);
        profileGrade=ProfileModel.validGrade(prefs.getInt("profile_grade",0));
        grade=profileGrade>0?profileGrade:4;
        avatarStyle=ProfileModel.validStyle(prefs.getInt("avatar_style",0));
        if(!prefs.contains("avatar_seed"))prefs.edit().putLong("avatar_seed",avatarRandom.nextLong()).apply();
        avatarSeed=prefs.getLong("avatar_seed",0L);
        mistakes=new HashSet<>(prefs.getStringSet("mistakes",Collections.emptySet()));
        loading=true;
        home();
        io.execute(()->{
            ArrayList<Q> bundled=new ArrayList<>(), active;
            boolean fromImport=false;
            String message="";
            try {
                ArrayList<Q> loaded=new ArrayList<>();
                Set<String> ids=new HashSet<>(), stems=new HashSet<>();
                for(int g=1;g<=9;g++){
                    ImportResult parsed=parse(read(getAssets().open("bank/grade-"+g+".json")));
                    if(parsed.skipped!=0||parsed.questions.size()!=600)throw new IOException("Ungültige Klassendatei "+g);
                    for(Q q:parsed.questions){
                        if(q.grade!=g||!ids.add(q.id)||!stems.add(norm(q.question)))throw new IOException("Doppelte oder falsch zugeordnete Frage");
                        loaded.add(q);
                    }
                }
                if(loaded.size()!=BUNDLED_COUNT)throw new IOException("Unvollständige Fragenbank");
                bundled=loaded;
            }catch(Exception ex){message="Die eingebaute Fragenbank konnte nicht geladen werden.";}
            active=bundled;
            File saved=new File(getFilesDir(),"questions.json");
            if(saved.exists()){
                try{
                    ImportResult parsed=parse(read(new android.util.AtomicFile(saved).openRead()));
                    active=mergeBanks(bundled,parsed.questions);fromImport=active.size()>bundled.size();
                    if(parsed.skipped>0)message=parsed.skipped+" ungültige importierte Fragen übersprungen.";
                }catch(Exception ex){message="Gespeicherte Fragenbank nicht lesbar. Eingebaute Fragen werden verwendet.";}
            }
            final ArrayList<Q> selected=active, fixed=bundled;
            final boolean localImport=fromImport;
            final String status=message;
            runOnUiThread(()->{
                if(isFinishing()||isDestroyed())return;
                bundledBank=fixed;bank=selected;imported=localImport;loading=false;note=status;home();
            });
        });
    }
    static ArrayList<Q> mergeBanks(List<Q> fixed,List<Q> extra){
        ArrayList<Q> out=new ArrayList<>();Set<String> ids=new HashSet<>(),stems=new HashSet<>();
        for(List<Q> source:Arrays.asList(fixed,extra))for(Q q:source){String stem=norm(q.question);if(ids.contains(q.id)||stems.contains(stem))continue;ids.add(q.id);stems.add(stem);out.add(q);}
        return out;
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
    long classCount(int g){return bank.stream().filter(q->q.grade==g).count();}
    long classMistakes(int g){return bank.stream().filter(q->q.grade==g&&mistakes.contains(q.id)).count();}
    void profileAction(String requested){
        if(profileGrade==0){pendingProfileAction=requested;profileClass();return;}
        grade=profileGrade;subjects.clear();difficulty="Alle";setupFromClasses=false;
        mode=requested.equals("quick")?"training":requested;
        if(requested.equals("quick")){count=10;start();}else setup();
    }
    void home(){
        base("home","Quiz Clash","Dein persönliches Lern-Dashboard",false);
        if(loading){caption("Fragenbank wird geladen …");return;}
        LinearLayout profile=column(PURPLE,16);
        LinearLayout top=new LinearLayout(this);top.setOrientation(LinearLayout.HORIZONTAL);top.setGravity(Gravity.CENTER_VERTICAL);
        AvatarView portrait=new AvatarView(this,avatarSeed,avatarStyle);
        portrait.setContentDescription("Dein Avatar. Tippen zum Bearbeiten.");portrait.setOnClickListener(v->openAvatar());portrait.setClickable(true);portrait.setFocusable(true);
        LinearLayout.LayoutParams ap=new LinearLayout.LayoutParams(dp(92),dp(92));ap.rightMargin=dp(14);top.addView(portrait,ap);
        LinearLayout info=new LinearLayout(this);info.setOrientation(LinearLayout.VERTICAL);
        add(info,text("DEIN PROFIL",12,GOLD,true),4);
        add(info,text(profileGrade==0?"Welche Klasse besuchst du?":profileGrade+". Klasse",23,WHITE,true),5);
        add(info,text(profileGrade==0?"Wähle deine Klasse für passende Quizfragen.":classCount(profileGrade)+" passende Fragen",14,WHITE,false),0);
        top.addView(info,new LinearLayout.LayoutParams(0,-2,1));add(profile,top,14);
        add(profile,button(profileGrade==0?"Meine Klasse festlegen":"Klasse ändern",WHITE,INK,()->{pendingProfileAction="";profileClass();}),8);
        add(profile,button("Avatar gestalten",0xff3e329f,WHITE,()->openAvatar()),0);add(body,profile,14);

        LinearLayout hero=column(WHITE,16);
        add(hero,text("★  LEVEL "+level(),15,PURPLE,true),5);
        add(hero,text(xp+" XP",30,INK,true),5);
        ProgressBar p=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);p.setMax(1000);p.setProgress((int)(xp%1000));p.setProgressTintList(ColorStateList.valueOf(PURPLE));add(hero,p,8);
        add(hero,text((1000-xp%1000)+" XP bis zum nächsten Level",14,MUTED,false),8);
        if(profileGrade>0){
            int attempts=prefs.getInt("answered_grade_"+profileGrade,0),right=prefs.getInt("correct_grade_"+profileGrade,0);
            add(hero,text(attempts==0?"Klassenstatistik: noch keine neuen Antworten":attempts+" Antworten · "+Math.round(100.0*right/attempts)+" % richtig",14,INK,true),4);
            add(hero,text(classMistakes(profileGrade)+" Fragen zum Wiederholen",14,MUTED,false),0);
        }else add(hero,text(totalAnswered+" beantwortete Fragen insgesamt",14,MUTED,false),0);
        add(body,hero,16);
        if(!bank.isEmpty()){
            heading("Für dich");
            action(profileGrade==0?"▶  Meine Klasse wählen & starten":"▶  Meine Klasse · 10 Fragen",()->profileAction("quick"));
            secondary("📚  Fächer meiner Klasse",()->profileAction("training"));
            secondary("★  Tages-Challenge",()->profileAction("daily"));
            secondary("↻  Fehler meiner Klasse trainieren",()->profileAction("mistakes"));
            heading("Entdecken");
            secondary("⤨  Alle Fragen · Zufall",()->{mode="mixed";mixedSetup();});
            secondary("🎓  Andere Klasse üben",()->{mode="training";classes();});
            secondary("▥  Mein Fortschritt",()->stats());
        }else caption("Keine spielbaren Fragen verfügbar. Bitte importiere eine gültige JSON-Datei.");
        heading("Fragenbank");
        caption(bank.size()+" Fragen · Klassen 1–9 · "+bundledBank.size()+" fest eingebaut"+(imported?" + Zusatzfragen":""));
        caption("Lernfragenbank · redaktionelle Vorschau");
        if(!note.isEmpty())caption(note);
        secondary("＋  Zusatzfragen importieren (JSON)",()->pick());
        caption("Offline · ohne Werbung · keine Rechenaufgaben");
    }
    void profileClass(){
        base("profileClass","Meine Klasse","Die Auswahl wird auf diesem Gerät gespeichert.",true);
        for(int start=1;start<=9;start+=3){
            LinearLayout row=new LinearLayout(this);
            for(int g=start;g<start+3;g++){
                final int selected=g;
                TextView cell=button(g+". Klasse"+(profileGrade==g?" ✓":"")+"\\n"+classCount(g)+" Fragen",
                    profileGrade==g?PURPLE:WHITE,profileGrade==g?WHITE:INK,()->{
                        profileGrade=selected;prefs.edit().putInt("profile_grade",selected).apply();
                        String next=pendingProfileAction;pendingProfileAction="";
                        if(next.isEmpty())home();else profileAction(next);
                    });
                LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,-2,1);lp.setMargins(dp(3),0,dp(3),dp(10));row.addView(cell,lp);
            }add(body,row,0);
        }
        caption("Du kannst deine Klasse später ändern und jederzeit auch andere Klassen oder alle Fragen spielen.");
    }
    void openAvatar(){draftSeed=avatarSeed;draftStyle=avatarStyle;avatarEditor();}
    void avatarEditor(){
        base("avatar","Mein Avatar","Gestalte deinen eigenen Quiz-Helden.",true);
        LinearLayout panel=column(WHITE,16);
        AvatarView preview=new AvatarView(this,draftSeed,draftStyle);preview.setContentDescription("Avatar-Vorschau: "+ProfileModel.STYLES[draftStyle]);
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(dp(204),dp(204));lp.gravity=Gravity.CENTER_HORIZONTAL;lp.bottomMargin=dp(8);panel.addView(preview,lp);
        TextView label=text(ProfileModel.STYLES[draftStyle],20,INK,true);label.setGravity(Gravity.CENTER);add(panel,label,0);add(body,panel,14);
        heading("Wähle deinen Stil");
        for(int start=0;start<ProfileModel.STYLES.length;start+=2){
            LinearLayout row=new LinearLayout(this);
            for(int k=start;k<Math.min(start+2,ProfileModel.STYLES.length);k++){final int style=k;
                TextView v=button(ProfileModel.STYLES[k],draftStyle==k?PURPLE:WHITE,draftStyle==k?WHITE:INK,()->{draftStyle=style;avatarEditor();});
                LinearLayout.LayoutParams cp=new LinearLayout.LayoutParams(0,-2,1);cp.setMargins(dp(3),0,dp(3),dp(8));row.addView(v,cp);
            }add(body,row,0);
        }
        action("🎲  Neuen Avatar generieren",()->{draftSeed=avatarRandom.nextLong();avatarEditor();});
        secondary("✨  Zufälliger Stil",()->{draftStyle=avatarRandom.nextInt(ProfileModel.STYLES.length);draftSeed=avatarRandom.nextLong();avatarEditor();});
        action("✓  Avatar speichern",()->{avatarSeed=draftSeed;avatarStyle=draftStyle;prefs.edit().putLong("avatar_seed",avatarSeed).putInt("avatar_style",avatarStyle).apply();home();});
        caption("Lokal generierte Illustration. Keine Fotos, keine KI-Cloud und kein Konto erforderlich.");
    }
    void classes(){
        base("classes","Klasse zum Üben","Dein gespeichertes Profil bleibt unverändert.",true);
        for(int start=1;start<=9;start+=3){
            LinearLayout row=new LinearLayout(this);row.setOrientation(LinearLayout.HORIZONTAL);
            for(int g=start;g<start+3;g++){final int gg=g;long n=bank.stream().filter(q->q.grade==gg&&(!mode.equals("mistakes")||mistakes.contains(q.id))).count();
                TextView cell=button(g+". Klasse\n"+n+" Fragen",g==grade?PURPLE:WHITE,g==grade?WHITE:INK,()->{grade=gg;setupFromClasses=true;subjects.clear();difficulty="Alle";setup();});
                LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,-2,1);lp.setMargins(dp(3),0,dp(3),dp(10));row.addView(cell,lp);
            }
            add(body,row,0);
        }
        caption("Klassenstufen sind eine Orientierung am Lehrplan 21.");
    }
    ArrayList<Q> pool(){
        if(mode.equals("mixed"))return new ArrayList<>(bank);
        ArrayList<Q> out=new ArrayList<>();
        for(Q q:bank)if(q.grade==grade&&(subjects.isEmpty()||subjects.contains(q.subject))&&
          (difficulty.equals("Alle")||q.difficulty.equalsIgnoreCase(difficulty))&&(!mode.equals("mistakes")||mistakes.contains(q.id)))out.add(q);
        return out;
    }
    void mixedSetup(){
        base("mixed","Alle Fragen","Klassen 1–9 · alle Fächer · alle Schwierigkeitsgrade",true);
        LinearLayout card=column(PURPLE,20);
        add(card,text("⤨  Wissens-Mix",24,WHITE,true),8);
        add(card,text(bank.size()+" verfügbare Fragen",18,WHITE,false),8);
        add(card,text("Jede Runde wird neu gemischt. Keine Frage erscheint zweimal in derselben Runde.",15,WHITE,false),0);add(body,card,16);
        heading("Wie viele Fragen?");
        choices(new String[]{"5","10","20","50"},String.valueOf(mixedCount),s->{mixedCount=Integer.parseInt(s);mixedSetup();});
        add(body,button((mixedCount==0?"✓  ":"")+"Alle verfügbaren Fragen",mixedCount==0?PURPLE:WHITE,mixedCount==0?WHITE:INK,()->{mixedCount=0;mixedSetup();}),10);
        int n=mixedCount==0?bank.size():Math.min(mixedCount,bank.size());
        caption(n+" Fragen in dieser Runde · ohne Zeitlimit");
        if(n>0)action("Los geht’s!  →",()->start());else caption("Bitte zuerst eine Fragenbank importieren.");
    }
    void setup(){
        if(mode.equals("mixed")){mixedSetup();return;}
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
        ArrayList<Q> p=pool();if(p.isEmpty()){Toast.makeText(this,"Keine passenden Fragen verfügbar",Toast.LENGTH_SHORT).show();return;}
        if(mode.equals("daily")){
            p.sort(Comparator.comparing(q->q.id));
            long seed=java.time.LocalDate.now().toEpochDay()*31+grade;Collections.shuffle(p,new Random(seed));
        }else Collections.shuffle(p);
        int requested=mode.equals("daily")?10:mode.equals("mixed")?(mixedCount==0?p.size():mixedCount):count;
        round=new ArrayList<>(p.subList(0,Math.min(p.size(),requested)));
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
        int attempts=prefs.getInt("answered_grade_"+q.grade,0)+1;
        int right=prefs.getInt("correct_grade_"+q.grade,0)+(selected==q.answer?1:0);
        if(selected==q.answer){correct++;streak++;int points=streak>=3?125:100;score+=points;xp+=points;mistakes.remove(q.id);}
        else{streak=0;mistakes.add(q.id);}
        prefs.edit().putLong("xp",xp).putInt("answered",totalAnswered).putInt("answered_grade_"+q.grade,attempts).putInt("correct_grade_"+q.grade,right).putStringSet("mistakes",new HashSet<>(mistakes)).apply();
        quiz();
    }
    void result(){
        base("result","Runde geschafft!","Jede Frage bringt dich weiter.",false);
        LinearLayout card=column(PURPLE,22);
        add(card,text("★  "+score+" Punkte",32,WHITE,true),8);
        add(card,text(correct+" von "+round.size()+" richtig",22,WHITE,true),6);
        add(card,text("Level "+level()+"  ·  "+xp+" XP insgesamt",15,WHITE,false),0);add(body,card,18);
        int stars=(correct*3)/round.size();heading(stars==3?"★★★  Fantastisch!":stars==2?"★★☆  Gut gemacht!":stars==1?"★☆☆  Weiter so!":"Weiter üben lohnt sich!");
        action("Noch eine Runde",()->setup());secondary("Fehler trainieren",()->{boolean wasMixed=mode.equals("mixed");mode="mistakes";subjects.clear();difficulty="Alle";if(wasMixed)profileAction("mistakes");else setup();});secondary("Zur Startseite",()->home());
    }
    void stats(){
        base("stats","Mein Fortschritt","Dein persönlicher Lernweg.",true);
        heading("Level "+level());caption(xp+" XP insgesamt · "+totalAnswered+" beantwortete Fragen");
        heading("Fehlertraining");caption(mistakes.size()+" Fragen warten auf eine Wiederholung.");
        heading("Meine Klassenstatistik");
        caption("Antworten ab Version 0.1.4; frühere Gesamt-XP bleiben erhalten.");
        for(int g=1;g<=9;g++){int n=prefs.getInt("answered_grade_"+g,0),r=prefs.getInt("correct_grade_"+g,0);if(n>0)caption(g+". Klasse · "+r+" von "+n+" richtig");}
        heading("Verfügbare Fragen");
        for(int g=1;g<=9;g++){final int gg=g;caption(g+". Klasse  ·  "+bank.stream().filter(q->q.grade==gg).count()+" Fragen");}
        secondary("Fortschritt zurücksetzen",()->new AlertDialog.Builder(this).setTitle("Fortschritt löschen?").setMessage("XP und Fehlerliste werden gelöscht. Die Fragenbank bleibt erhalten.").setNegativeButton("Abbrechen",null).setPositiveButton("Löschen",(d,w)->{xp=0;totalAnswered=0;mistakes.clear();android.content.SharedPreferences.Editor e=prefs.edit().remove("xp").remove("answered").remove("mistakes");for(int g=1;g<=9;g++){e.remove("answered_grade_"+g).remove("correct_grade_"+g);}e.apply();stats();}).show());
    }
    void back(){
        switch(screen){case "quiz":new AlertDialog.Builder(this).setTitle("Runde beenden?").setMessage("Deine bereits verdienten Punkte bleiben gespeichert.").setNegativeButton("Weiterspielen",null).setPositiveButton("Beenden",(d,w)->home()).show();break;
        case "profileClass":pendingProfileAction="";home();break;case "avatar":home();break;case "mixed":home();break;case "setup":if(setupFromClasses)classes();else home();break;case "home":super.onBackPressed();break;default:home();}
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
                runOnUiThread(()->{if(isFinishing()||isDestroyed())return;bank=mergeBanks(bundledBank,parsed.questions);imported=bank.size()>bundledBank.size();loading=false;
                    note=(bank.size()-bundledBank.size())+" zusätzliche Fragen verfügbar. "+parsed.skipped+" ungültige oder doppelte Einträge übersprungen.";home();});
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
}
