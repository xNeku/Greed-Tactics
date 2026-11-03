"""Status icons added in v0.6 (toxin charges, taunt, aegis). Same style as
tools/generate_placeholder_sprites.py (10x10 + outline)."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools'))
from generate_placeholder_sprites import render  # noqa: E402

OUT = Path(__file__).resolve().parents[2] / 'assets' / 'sprites' / 'status'
ICONS = {
    'toxin': {'palette': {'p': (170, 90, 230), 'P': (110, 50, 170), 'g': (170, 255, 110)}, 'art': [
        '....p.....', '...ppp....', '..ppppp...', '..pPpPp...', '.ppgpgpp..',
        '.ppppppp..', '.ppPgPpp..', '..ppppp...', '...ppp....',
    ]},
    'taunt': {'palette': {'r': (240, 70, 60), 'w': (255, 235, 220)}, 'art': [
        '.r.r.r.', 'rrrrrrr', 'r.www.r', 'r..w..r', 'r..w..r',
        'r.....r', 'r..w..r', 'rrrrrrr',
    ]},
    'aegis': {'palette': {'y': (255, 225, 120), 'Y': (200, 160, 60), 'w': (255, 255, 240)}, 'art': [
        'yyyyyyyyy', 'yYwwwwwYy', 'yYwyyywYy', 'yYwyyywYy', '.yYwyywYy.'[:9],
        '.yYwwwYy.', '..yYwYy..', '...yYy...', '....y....',
    ]},
}
for name, spec in ICONS.items():
    render(spec).save(OUT / f'{name}.png')
    print('wrote', name)
