package ch.quizclash.mobile;

import java.text.Normalizer;
import java.util.*;

final class RankModel {
    private static final String[] TITLES={"Quiz-Legende","Wissens-Champion","Brain Master","Quiz-Ass","Wissens-Profi","Quiz-Talent","Denk-Held","Wissens-Scout","Quiz-Star","Aufsteiger"};
    static String title(int rank){return rank>=1&&rank<=10?TITLES[rank-1]:"Wissensentdecker";}
    static String cleanName(String value){return Normalizer.normalize(value==null?"":value,Normalizer.Form.NFC).trim().replaceAll("\\s+"," ");}
    static String nameKey(String value){return cleanName(value).toLowerCase(Locale.ROOT);}
    static boolean validName(String name){
        if(name==null||name.codePointCount(0,name.length())<2||name.codePointCount(0,name.length())>24)return false;
        return name.matches("[\\p{L}\\p{N}][\\p{L}\\p{M}\\p{N} _-]*")&&name.codePoints().anyMatch(Character::isLetterOrDigit);
    }
    static int count(Set<String> ids,Map<String,Integer> grades,int scope){
        int n=0;for(String id:ids){Integer g=grades.get(id);if(g!=null&&(scope==0||g==scope))n++;}return n;
    }
    static class Entry{
        final String id,name;final int grade,unique,style;final long seed;int rank;
        Entry(String id,String name,int grade,int unique,long seed,int style){this.id=id;this.name=name;this.grade=grade;this.unique=unique;this.seed=seed;this.style=style;}
        int points(){return unique*100;}
    }
    static ArrayList<Entry> rank(Collection<Entry> source){
        ArrayList<Entry> sorted=new ArrayList<>();
        for(Entry e:source)if(e.unique>0)sorted.add(new Entry(e.id,e.name,e.grade,e.unique,e.seed,e.style));
        sorted.sort(Comparator.comparingInt((Entry e)->e.unique).reversed().thenComparing(e->nameKey(e.name)).thenComparing(e->e.id));
        int rank=0,last=-1;
        for(int i=0;i<sorted.size();i++){Entry e=sorted.get(i);if(e.unique!=last){rank=i+1;last=e.unique;}e.rank=rank;}
        return sorted;
    }
}
