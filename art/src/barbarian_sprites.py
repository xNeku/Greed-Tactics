"""Sigrid (barbarian): Neku's views, no weapon (Neku will send the two-handed axes)."""
# NOTE (v0.6.1): Neku retouched the result in the hero workshop; assets/ is now the
# source of truth. Re-running this script would undo those edits.
import sys
from PIL import Image
D=sys.argv[1]  # folder with barb_view0.png (front) and barb_view1.png (side)

front=Image.open(f'{D}/barb_view0.png').convert('RGBA')
front.save(f'{D}/barb_front.png')
# The game expects side views facing right.
side=Image.open(f'{D}/barb_view1.png').convert('RGBA').transpose(Image.Transpose.FLIP_LEFT_RIGHT)
side.save(f'{D}/barb_side.png')

prev=Image.new('RGBA',(40,34),(40,44,60,255))
for i,im in enumerate([front,side]):
    prev.alpha_composite(im,(2+i*21,33-im.height))
prev.resize((prev.width*8,prev.height*8),Image.NEAREST).save(f'{D}/barb_preview.png')
print(front.size,side.size)
