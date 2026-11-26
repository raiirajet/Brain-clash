package ch.quizclash.mobile;

import android.content.Context;
import android.graphics.*;
import android.view.View;

/** Original procedural vector art. No network or external image assets. */
final class AvatarView extends View {
    private static final int INK=0xff202541, WHITE=0xfffff9ea, SHADOW=0xff171b35;
    private final ProfileModel m;
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    AvatarView(Context context,long seed,int style){super(context);m=new ProfileModel(seed,style);}
    void fill(int color){p.setStyle(Paint.Style.FILL);p.setColor(color);p.setShader(null);}
    void ellipse(Canvas c,float l,float t,float r,float b,int color){fill(color);c.drawOval(l,t,r,b,p);}
    void circle(Canvas c,float x,float y,float radius,int color){fill(color);c.drawCircle(x,y,radius,p);}
    void rect(Canvas c,float l,float t,float r,float b,float radius,int color){fill(color);c.drawRoundRect(l,t,r,b,radius,radius,p);}
    void path(Canvas c,int color,float... xy){Path a=new Path();a.moveTo(xy[0],xy[1]);for(int i=2;i<xy.length;i+=2)a.lineTo(xy[i],xy[i+1]);a.close();fill(color);c.drawPath(a,p);}
    void stroke(Canvas c,int color,float width,float... xy){Path a=new Path();a.moveTo(xy[0],xy[1]);for(int i=2;i<xy.length;i+=2)a.lineTo(xy[i],xy[i+1]);fill(color);p.setStyle(Paint.Style.STROKE);p.setStrokeCap(Paint.Cap.ROUND);p.setStrokeJoin(Paint.Join.ROUND);p.setStrokeWidth(width);c.drawPath(a,p);p.setStyle(Paint.Style.FILL);}
    void sparkle(Canvas c,float x,float y,float s,int color){path(c,color,x,y-s,x+s*.24f,y-s*.24f,x+s,y,x+s*.24f,y+s*.24f,x,y+s,x-s*.24f,y+s*.24f,x-s,y,x-s*.24f,y-s*.24f);}
    void eyes(Canvas c,float y,boolean light){
        int eye=light?WHITE:INK;
        if(m.eyes==0){circle(c,39,y,4.5f,eye);circle(c,61,y,4.5f,eye);}
        else if(m.eyes==1){rect(c,34,y-5,43,y+5,3,eye);rect(c,57,y-5,66,y+5,3,eye);}
        else{stroke(c,eye,3.5f,34,y+2,39,y-3,44,y+2);stroke(c,eye,3.5f,56,y+2,61,y-3,66,y+2);}
    }
    void smile(Canvas c,float y,int color){fill(color);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2.7f);p.setStrokeCap(Paint.Cap.ROUND);c.drawArc(44,y-5,56,y+5,15,150,false,p);p.setStyle(Paint.Style.FILL);}
    @Override protected void onDraw(Canvas c){
        super.onDraw(c);
        float size=Math.min(getWidth(),getHeight());if(size<=0)return;
        c.save();c.translate((getWidth()-size)/2,(getHeight()-size)/2);c.scale(size/100f,size/100f);
        fill(m.background);c.drawCircle(50,50,49,p);
        Path clip=new Path();clip.addCircle(50,50,47,Path.Direction.CW);c.clipPath(clip);
        p.setShader(new LinearGradient(0,0,100,100,0x55ffffff,0x44000000,Shader.TileMode.CLAMP));c.drawRect(0,0,100,100,p);p.setShader(null);
        circle(c,50,49,37,0x17ffffff);sparkle(c,17,26,5,m.accent);sparkle(c,83,36,4,WHITE);circle(c,17,72,2,0x99ffffff);
        ellipse(c,20,85,80,98,0x44000000);
        switch(m.style){
            case 0: robot(c);break;
            case 1: fox(c);break;
            case 2: astronaut(c);break;
            default: monster(c);break;
        }
        c.restore();
    }
    private void robot(Canvas c){
        rect(c,29,69,71,100,13,INK);rect(c,34,73,66,98,10,m.primary);rect(c,42,77,58,89,4,SHADOW);
        sparkle(c,50,83,5,m.accent);
        stroke(c,INK,5,50,28,50,15);circle(c,50,14,5,m.accent);
        rect(c,18,41,28,58,5,INK);rect(c,72,41,82,58,5,INK);
        rect(c,24,25,76,73,15,INK);rect(c,27,27,73,69,13,m.primary);
        rect(c,31,36,69,59,8,INK);eyes(c,46,true);smile(c,51,m.accent);
        rect(c,33,29,53,32,2,0x88ffffff);
        if(m.detail==1){circle(c,31,63,2,m.accent);circle(c,69,63,2,m.accent);}
        else if(m.detail==2){rect(c,45,62,55,65,1,m.accent);}
    }
    private void fox(Canvas c){
        rect(c,24,71,76,100,20,INK);path(c,m.accent,28,76,50,88,72,76,70,100,30,100);
        path(c,INK,21,48,21,17,43,36,57,36,79,17,79,48);
        path(c,m.primary,25,43,25,23,43,39,57,39,75,23,75,43);
        path(c,WHITE,29,39,29,30,39,40);path(c,WHITE,71,39,71,30,61,40);
        ellipse(c,20,30,80,76,INK);ellipse(c,23,32,77,73,m.primary);
        path(c,WHITE,23,52,42,58,50,70,58,58,77,52,68,67,50,77,32,67);
        eyes(c,48,false);ellipse(c,46,58,54,64,INK);smile(c,65,INK);
        if(m.detail==1){circle(c,29,56,3,m.accent);circle(c,71,56,3,m.accent);}
        else if(m.detail==2){sparkle(c,50,36,5,m.accent);}
    }
    private void astronaut(Canvas c){
        rect(c,21,68,79,101,20,INK);rect(c,25,71,75,101,17,WHITE);
        rect(c,37,79,63,94,5,m.primary);circle(c,44,85,2.5f,INK);circle(c,56,85,2.5f,INK);
        circle(c,50,45,31,INK);circle(c,50,43,28,WHITE);circle(c,50,45,22,m.primary);circle(c,50,46,19,0xff263859);
        ellipse(c,34,31,49,37,0x88ffffff);eyes(c,47,true);smile(c,56,m.accent);
        rect(c,18,42,24,57,3,m.accent);rect(c,76,42,82,57,3,m.accent);
        if(m.detail==1)sparkle(c,68,26,6,m.accent);else if(m.detail==2)rect(c,46,17,54,21,2,m.accent);
    }
    private void monster(Canvas c){
        rect(c,25,65,75,101,20,INK);rect(c,29,70,71,100,17,m.primary);
        if(m.detail==0){path(c,INK,24,38,17,17,39,28);path(c,INK,76,38,83,17,61,28);path(c,m.accent,25,32,23,24,34,29);path(c,m.accent,75,32,77,24,66,29);}
        else if(m.detail==1){stroke(c,INK,4,50,32,50,17);circle(c,50,16,7,m.accent);}
        else {circle(c,28,30,11,INK);circle(c,72,30,11,INK);circle(c,28,30,7,m.accent);circle(c,72,30,7,m.accent);}
        ellipse(c,18,25,82,77,INK);ellipse(c,21,28,79,74,m.primary);
        ellipse(c,30,37,47,55,WHITE);ellipse(c,53,37,70,55,WHITE);eyes(c,46,false);
        ellipse(c,32,59,39,64,m.accent);ellipse(c,61,59,68,64,m.accent);smile(c,60,INK);
        sparkle(c,50,84,6,m.accent);
    }
}
