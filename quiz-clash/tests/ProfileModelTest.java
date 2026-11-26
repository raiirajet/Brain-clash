package ch.quizclash.mobile;
public class ProfileModelTest {
    private static void check(boolean b){if(!b)throw new AssertionError();}
    public static void main(String[] args){
        for(int g=-10;g<=20;g++)check(ProfileModel.validGrade(g)==(g>=1&&g<=9?g:0));
        check(ProfileModel.validStyle(-1)==0);check(ProfileModel.validStyle(4)==0);
        java.util.Set<String> variants=new java.util.HashSet<>();
        for(int style=0;style<4;style++)for(long seed=0;seed<200;seed++){
            ProfileModel a=new ProfileModel(seed,style),b=new ProfileModel(seed,style);
            check(a.style==style&&a.background==b.background&&a.primary==b.primary&&a.accent==b.accent&&a.eyes==b.eyes&&a.detail==b.detail);
            check(a.eyes>=0&&a.eyes<3&&a.detail>=0&&a.detail<3);
            variants.add(a.style+":"+a.background+":"+a.primary+":"+a.accent+":"+a.eyes+":"+a.detail);
        }
        check(variants.size()>100);
        System.out.println("Profile grade bounds and deterministic avatar generation passed; "+variants.size()+" sampled variants.");
    }
}
