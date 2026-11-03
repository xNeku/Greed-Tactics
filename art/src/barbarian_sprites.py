import sys
from PIL import Image
D=sys.argv[1]
OUT=(2,2,1,255); STEEL=(146,146,146,255); STEEL_HI=(198,198,204,255); WOOD=(94,69,51,255); WOOD_DARK=(67,48,39,255)

def pad(img, right):
    o=Image.new('RGBA',(img.width+right,img.height),(0,0,0,0)); o.alpha_composite(img,(0,0)); return o

def outline(layer):
    px=layer.load(); w,h=layer.size
    solid={(x,y) for x in range(w) for y in range(h) if px[x,y][3]>0}
    for x in range(w):
        for y in range(h):
            if (x,y) not in solid and any((x+dx,y+dy) in solid for dx,dy in ((1,0),(-1,0),(0,1),(0,-1))):
                px[x,y]=OUT
    return layer

def axe_layer(size, head, handle_bottom):
    """Double-bit axe: head centered at `head`, handle down to `handle_bottom`."""
    layer=Image.new('RGBA',size,(0,0,0,0)); px=layer.load()
    hx,hy=head; bx,by=handle_bottom
    steps=by-(hy-2)
    for i in range(steps+1):
        y=hy-2+i; x=round(hx+(bx-hx)*i/steps)
        px[x,y]=WOOD if i%3 else WOOD_DARK
    blade=[(-2,-1),(-1,-1),(1,-1),(2,-1),(-2,0),(-1,0),(1,0),(2,0),(-2,1),(-1,1),(1,1),(2,1),(-1,-2),(1,-2),(-1,2),(1,2)]
    for dx,dy in blade:
        px[hx+dx,hy+dy]=STEEL
    for dx,dy in [(-2,-1),(-2,0),(-2,1),(2,-1),(2,0),(2,1)]:
        px[hx+dx,hy+dy]=STEEL_HI
    px[hx,hy-3]=WOOD_DARK
    return outline(layer)

front=pad(Image.open(f'{D}/barb_view0.png').convert('RGBA'),5)
axe=axe_layer(front.size,(20,6),(17,21))
f=Image.new('RGBA',front.size,(0,0,0,0)); f.alpha_composite(axe); f.alpha_composite(front)
f.save(f'{D}/barb_front.png')

side=Image.open(f'{D}/barb_view1.png').convert('RGBA').transpose(Image.Transpose.FLIP_LEFT_RIGHT)
side_p=Image.new('RGBA',(side.width+4,side.height),(0,0,0,0)); side_p.alpha_composite(side,(4,0))
axe2=axe_layer(side_p.size,(4,6),(8,21))
s=Image.new('RGBA',side_p.size,(0,0,0,0)); s.alpha_composite(axe2); s.alpha_composite(side_p)
s.save(f'{D}/barb_side.png')

prev=Image.new('RGBA',(70,34),(40,44,60,255))
for i,im in enumerate([Image.open(f'{D}/barb_view0.png'),f,s]):
    prev.alpha_composite(im.convert('RGBA'),(2+i*23,33-im.height))
prev.resize((prev.width*8,prev.height*8),Image.NEAREST).save(f'{D}/barb_preview.png')
print(f.size,s.size)
