import sys
from PIL import Image
D=sys.argv[1]
PAL={'#':(1,1,1),'a':(37,37,37),'b':(77,54,45),'c':(145,89,60),'d':(178,118,82),'e':(111,31,27),'f':(154,48,43),
     'g':(131,110,97),'o':(236,190,64),'O':(176,124,32),'t':(26,22,26)}
FRONT_ORIG=[
".............###...","......#######abb#..",".....#cdddddc#abb#.","....#cdddddddc#ab#.","...#cdddddddddc#a#.",
"...#ddddddddddd##..","...#ddddddddddd#...","...#ddddddddddd#...","..#dcdc#cdc#cdcd#..","..#dcdd#ddd#ddcd#..",
"...##ddddddddd##...","....#cdddddddc#....","...####cdddc####...","..#cddc#####cddc#..","..#ddddcccccdddd#..",
".#ddcdddddddddcdd#.",".#dd#ddddddddd#dd#.","#ddc#ddddddddd#cdd#","#dd##ddddddddd##dd#","#ddc###########cdd#",
"#cd#eeffefbffee#dc#",".###bfffefefffb###.","...#bbfff#ffffb#...","...#bfbfe#effbb#...","....#ffe#.#eff#....",
"....#eee#.#eee#....","...#dcdc#.#ccdd#...","...######.######..."]
FRONT=[
"........##.........",
".......#ab#........",
"......##aa###......",
".....#cdddddc#.....",
"....#cdddddddc#....",
"...#cdddddddddc#...",
"...#ddddddddddd#...",
"...#ddddddddddd#...",
"...#ddddddddddd#...",
"..#dcdc#cdc#cdcd#..",
"..#dcdd#ddd#ddcd#..",
".o.##ddddddddd##.o.",
"o.o.#cdddddddc#.o.o",
"o.o####cdddc####o.o",
".O.#cdc#####cdc#.O.",
"..#dttcccccccttd#..",
"..#dd#tdddddt#dd#..",
"..#tt#dtdddtd#tt#..",
"..#cd#ddtdtdd#dc#..",
"..#dd#dddtddd#dd#..",
"..#dc#########cd#..",
"..#cd#effefbe#dc#..",
"..####bffeffb####..",
"....#bfff#fffb#....",
"....#bfbe#effb#....",
".....#ffe#eff#.....",
".....#eee#eee#.....",
"....#dcdc#ccdd#....",
"....###########....",
]
SIDE=[
"............##..",
"....######.#bb#.",
"...#cddddc#aabb#",
"..#cddddddc#aab#",
".#cddddddddc#aa#",
".#dddddddddc##a#",
".#dddddddddc#.#.",
".#dccdddc#cc#...",
".#c#dddddd#c#...",
"#dd#cddddd#c#...",
"#dddddddc#c#....",
".#ddddddcc#o....",
"..#dddc###o.o...",
"...####ddcO.o...",
"...#cdddd#.O....",
"...#dd#ttd#.....",
"...#d#dtdd##....",
"...#t#tttd##....",
"...#d#cdtd##....",
"..####ddd###....",
"..#ef#cdd#e#....",
"..#eff###ee#....",
"...#effgee#.....",
"....#bfgee#.....",
"....#ffge#......",
".....#ebe#......",
"....#dddc#......",
"....######......",
]
def render(rows, flip=False):
    w=max(len(r) for r in rows)
    im=Image.new('RGBA',(w,len(rows)),(0,0,0,0)); px=im.load()
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch!='.': px[x,y]=PAL[ch]+(255,)
    return im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else im
for n,rows in [('front',FRONT),('side',SIDE)]:
    bad=[i for i,r in enumerate(rows) if len(r)!=len(rows[0])]
    assert not bad,(n,bad)
render(FRONT).save(f'{D}/archer_front.png')  # D = output folder (argv[1])
render(SIDE,True).save(f'{D}/archer_side.png')
items=[render(FRONT_ORIG),render(FRONT),Image.open(f'{D}/archer_view1.png').convert('RGBA'),render(SIDE)]
bgs=[(27,29,43),(117,204,153),(237,204,140)]
cell=34; out=Image.new('RGBA',(len(items)*cell,len(bgs)*cell))
for j,bg in enumerate(bgs):
    for i,it in enumerate(items):
        t=Image.new('RGBA',(cell,cell),bg+(255,)); t.paste(it,((cell-it.width)//2,cell-it.height-2),it); out.paste(t,(i*cell,j*cell))
out.resize((out.width*7,out.height*7),Image.NEAREST).save(f'{D}/archer_compare.png')
print('ok')
