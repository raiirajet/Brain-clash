package ch.quizclash.mobile;
import java.util.Random;
final class ProfileModel {
    static final String[] STYLES={"Roboter","Fuchs","Astronaut","Monster"};
    static int validGrade(int g){return g>=1&&g<=9?g:0;}
    static int validStyle(int s){return s>=0&&s<STYLES.length?s:0;}
    static final int[] BACK={0xff4936a6,0xff146878,0xffaa4b26,0xff6943a4,0xff2d598d,0xffa33f69};
    static final int[] PRIMARY={0xff78d6ed,0xffffb866,0xffc6b1ff,0xff8ce0ab,0xfff2a3c5,0xffffd66b};
    static final int[] ACCENT={0xffffda78,0xffb3e6ff,0xffffa1ba,0xffb9f3bf,0xffded0ff,0xfffff0b0};
    final int style,background,primary,accent,eyes,detail;
    ProfileModel(long seed,int selectedStyle){
        style=validStyle(selectedStyle);
        Random r=new Random(seed);
        background=BACK[r.nextInt(BACK.length)];primary=PRIMARY[r.nextInt(PRIMARY.length)];accent=ACCENT[r.nextInt(ACCENT.length)];eyes=r.nextInt(3);detail=r.nextInt(3);
    }
}
