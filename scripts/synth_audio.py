"""Original, deterministic audio assets. Python standard library only."""
import math, wave, struct
from pathlib import Path
rate=22050
out=Path('android/app/src/main/res/raw')
out.mkdir(parents=True,exist_ok=True)
def write(name, notes, music=False):
    samples=[]
    for f,duration in notes:
        count=int(rate*duration)
        for i in range(count):
            t=i/rate
            env=min(1,t/.012,max(0,(duration-t)/.035))
            tone=math.sin(2*math.pi*f*t)+.16*math.sin(4*math.pi*f*t) if f else 0
            value=int(32767*(.10 if music else .23)*env*tone)
            samples.append(value)
    with wave.open(str(out/(name+'.wav')),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate)
        w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
effects={
 'right':[(660,.09),(880,.11)],'wrong':[(320,.12),(247,.12)],
 'streak':[(523,.07),(659,.07),(784,.09),(1047,.12)],
 'energy':[(440,.055),(587,.07)],'countdown':[(440,.1)],
 'start':[(523,.08),(659,.08),(784,.15)],
 'win':[(523,.1),(659,.1),(784,.1),(1047,.28)],
 'loss':[(440,.16),(392,.16),(330,.22)],'draw':[(440,.12),(523,.12),(440,.18)],
 'unlock':[(784,.07),(988,.07),(1175,.09),(1568,.17)],
 'menu':[(520,.055)]
}
for name,notes in effects.items():write('bc_'+name,notes)
write('bc_music',[(f,.25) for f in [262,330,392,330,294,349,440,349,330,392,494,392,294,349,440,349]*2],True)
