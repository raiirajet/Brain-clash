package ch.quizclash.mobile;
import java.util.*;
public class RankModelTest {
    static void check(boolean ok){if(!ok)throw new AssertionError();}
    public static void main(String[] args){
        check(RankModel.validName("Quiz-Fuchs"));check(RankModel.validName("Mäxli 7"));
        check(!RankModel.validName("A"));check(!RankModel.validName("abc@example.com"));check(!RankModel.validName("a\nb"));
        check(RankModel.nameKey("  Quiz   Fuchs ").equals("quiz fuchs"));
        Map<String,Integer> grades=new HashMap<>();grades.put("a",4);grades.put("b",5);
        Set<String> solved=new HashSet<>(Arrays.asList("a","a","b","imported"));
        check(RankModel.count(solved,grades,0)==2);check(RankModel.count(solved,grades,4)==1);check(RankModel.count(solved,grades,8)==0);
        List<RankModel.Entry> entries=Arrays.asList(
            new RankModel.Entry("x","Zed",4,10,0,0),new RankModel.Entry("a","Ada",4,10,0,1),
            new RankModel.Entry("b","Ben",4,4,0,2),new RankModel.Entry("c","Cal",4,0,0,0));
        List<RankModel.Entry> ranked=RankModel.rank(entries);
        check(ranked.size()==3&&ranked.get(0).id.equals("a")&&ranked.get(0).rank==1&&ranked.get(1).rank==1&&ranked.get(2).rank==3);
        check(ranked.get(0).points()==1000);check(entries.get(0).rank==0);
        Set<String> titles=new HashSet<>();for(int i=1;i<=10;i++)titles.add(RankModel.title(i));
        check(titles.size()==10&&!titles.contains(RankModel.title(11)));
        System.out.println("Ranking tests passed: name validation, unique scoring, grade filters, ties, titles.");
    }
}
