import sys
# NOTE (v0.6.1): Neku retouched kael.png / kael_side.png in the hero workshop;
# assets/ is now the source of truth. Re-running this script would undo those edits.
from PIL import Image
D=sys.argv[1]
PAL={'#':(1,1,1),'a':(82,55,44),'b':(112,78,62),'c':(198,139,106),'d':(168,54,52),'e':(163,102,74),
     'f':(38,38,38),'g':(133,116,80),'h':(174,156,112),'i':(148,98,32),'j':(190,136,51),
     'k':(62,62,70),'w':(226,220,204),'v':(176,170,158)}
FRONT_ORIG=[
"......#######......",".....#abbbbba#.....","....#abbbbbbba#....","...#aaabbbbbaaa#...","...#aaccaaaccaa#...",
"...#accccccccca#...","...#accdcccccca#...","..#caca#ece#acac#..","..#cacc#ccc#ccac#..","...##cdccccccc##...",
"....#eccccccce#....","...####eccce####...","..#cc#f#####f#cc#..","..#cc#ffeeeff#cc#..",".#cce#fffffff#ecc#.",
".#cc#fffffffff#cc#.","#cce#fffffffff#ecc#","#cc###fffffff###cc#","#cce#g#######g#ecc#","#ec#bhhhghgghhb#ce#",
".###ghhhghghhbh###.","...#bhhhg#ghhgb#...","...#ghhgg#ghhhg#...","....#####.#####....","....#iii#.#iii#....",
"...#jjji#.#ijjj#...","...######.######..."]
FRONT=[
"......#######......",
".....#abbbbba#.....",
"....#abbbbbbba#....",
"...#aaabbbbbaaa#...",
"...#aaccaaaccaa#...",
"...#accccccccca#...",
"...#acadccccaaa#...",
"..#caca#ece#acac#..",
"..#cacc#ccc#ccac#..",
"...##cdccccccc##...",
"....#ecceeecce#....",
"...####eccce####...",
"..#cc#f#####f#cc#..",
".#ccc#ffeeeff#ccc#.",
".#cce#fkkfkkf#ecc#.",
".#cce#fkfffkf#ecc#.",
"#cce##fffffff##ecc#",
"#www##fffffff##www#",
"#cce#gbbbjbbbg#ecc#",
"#ec#bhhhghgghhb#ce#",
".###ghhhghghhbh###.",
"...#bhhhg#ghhgb#...",
"...#ghhgg#ghhhg#...",
"....#####.#####....",
"....#iii#.#iii#....",
"...#jjji#.#ijjj#...",
"...######.######...",
]
SIDE_ORIG=[
"....######....","...#abbbbb##..","..#bbbbbbbba#.",".#bbbbbbbbbba#",".#ecccbbbbbaa#",".#cccccbbaaaa#",
".#caaccba#aaa#",".#e#cccacc#aa#","#cc#eccccc#a#.","#ccccccce#a#..",".#ccccccee#...","..#ccce###....",
"...####fcf#...","...#ef#ccc#...","...#ff#ccc##..","..#fff#ecc##..","..#fff#ecc##..","..#fff#ccc##..",
"..####ccc###..","..#gh#ecc#g#..","..##hh###gg#..","...#ghgbbh#...","....#hhhhg#...","....######....",
".....#iji#....","....#jjii#....","....######...."]
SIDE=[
"....######....",
"...#abbbbb##..",
"..#bbbbbbbba#.",
".#bbbbbbbbbba#",
".#ecccbbbbbaa#",
".#cccccbbaaaa#",
".#aaaccba#aaa#",
".#e#cccacc#aa#",
"#cc#eccccc#a#.",
"#ccccccce#a#..",
".#eeccccee#...",
"..#ccce###....",
"...####fcf#...",
"...#kf#ccc#...",
"...#kf#ccc##..",
"...#ff#ecc##..",
"...#ff#ecc##..",
"...#ff#www##..",
"..#bbb#ccc##..",
"..#gh#ecc#g#..",
"..##hh###gg#..",
"...#ghgbbh#...",
"....#hhhhg#...",
"....######....",
".....#iji#....",
"....#jjii#....",
"....######....",
]
def render(rows, flip=False):
    w=max(len(r) for r in rows); im=Image.new('RGBA',(w,len(rows)),(0,0,0,0)); px=im.load()
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch!='.': px[x,y]=PAL[ch]+(255,)
    return im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else im
for name,rows in [('front',FRONT),('side',SIDE),('front_orig',FRONT_ORIG),('side_orig',SIDE_ORIG)]:
    assert all(len(r)==len(rows[0]) for r in rows), name
render(FRONT).save(f'{D}/brawler_front.png')
render(SIDE, flip=True).save(f'{D}/brawler_side.png')
# comparison: original vs improved, on 3 backgrounds
items=[render(FRONT_ORIG),render(FRONT),render(SIDE_ORIG),render(SIDE)]
bgs=[(27,29,43),(117,204,153),(237,204,140)]
cell=32; out=Image.new('RGBA',(len(items)*cell,len(bgs)*cell))
for j,bg in enumerate(bgs):
    for i,it in enumerate(items):
        t=Image.new('RGBA',(cell,cell),bg+(255,)); t.paste(it,((cell-it.width)//2,cell-it.height-2),it); out.paste(t,(i*cell,j*cell))
out.resize((out.width*7,out.height*7),Image.NEAREST).save(f'{D}/brawler_compare.png')
print('ok')
