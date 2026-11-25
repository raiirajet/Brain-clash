
"""Generate store artwork from the existing original Brain Clash branding."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
out=Path('output/store')
out.mkdir(parents=True,exist_ok=True)
logo=Image.open('assets/branding/brain_clash.webp').convert('RGBA')
icon=Image.new('RGBA',(512,512),'#080b15')
logo.thumbnail((440,440),Image.Resampling.LANCZOS)
icon.alpha_composite(logo,((512-logo.width)//2,(512-logo.height)//2))
icon.save(out/'icon-512.png')
im=Image.new('RGB',(1024,500),'#080b15')
draw=ImageDraw.Draw(im)
for y in range(500):
    for x in range(1024):
        f=x/1023
        glow=max(0,1-abs(y-250)/300)
        draw.point((x,y),(int(8+28*f*glow),int(11+32*(1-f)*glow),int(21+55*(1-f)*glow)))
draw.rounded_rectangle((35,35,989,465),radius=32,outline='#344d78',width=2)
for i in range(8):
    draw.line((590+i*48,60,745+i*48,440),fill='#28324b',width=2)
logo=Image.open('assets/branding/brain_clash.webp').convert('RGBA')
logo.thumbnail((330,330),Image.Resampling.LANCZOS)
im.paste(logo,(650+(330-logo.width)//2,85+(330-logo.height)//2),logo)
heading=ImageFont.truetype('assets/fonts/Outfit.ttf',75)
heading.set_variation_by_axes([800])
body=ImageFont.truetype('assets/fonts/Inter.ttf',28)
draw.text((75,116),'BRAIN',font=heading,fill='#eef5ff')
draw.text((75,194),'CLASH',font=heading,fill='#ff943c')
draw.text((80,308),'PLAY. THINK. WIN.',font=body,fill='#eef5ff')
draw.rounded_rectangle((80,363,488,375),radius=6,fill='#318bff')
im.save(out/'feature-1024x500.png')
