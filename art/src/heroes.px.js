// Greed Tactics — héroes (P0). 22x24 + contorno automático = 24x26.
// Mirando a la DERECHA, pies tocando el borde inferior.
// Build: node .claude/skills/pxl-pixel-art/bin/pxl.js build art/src/heroes.px.js --out art/out
pal({
  k: "#1c1828",                                     // contorno (28,24,40)
  s: "#f6cdaa", S: "#d6a080", e: "#1e1e32", E: "#ffffff",
  // Kael: pelo azul, armadura plateada, capa roja, espada
  h: "#4a6ad0", H: "#2e3e8a", j: "#8ab0ff",
  a: "#e4ebf4", A: "#a6b0c6", m: "#6c7490",
  c: "#d23c44", C: "#8c2430",
  b: "#6e4830", g: "#f0c446", p: "#3c4060", o: "#5a3c2c",
  w: "#f0f6ff", W: "#9aa8c0",
  // Pablo: capucha verde, arco
  v: "#5aa04e", V: "#336838", l: "#96d070", t: "#8a5a34", T: "#5c3a22", n: "#e8e0c8",
  // Lyra: sombrero morado, túnica azul, bastón
  u: "#8a4cc8", U: "#583088", y: "#b88ae8", z: "#3a7ad8", Z: "#24488e", q: "#78b8ff",
  r: "#f0e8b0", f: "#7ae8ff",
  // Nyx: capucha oscura, máscara roja, dagas
  d: "#4c4666", D: "#302b46", x: "#726a94", R: "#d23040", i: "#c8a0f0",
})

// Kael en dos piezas (torso y piernas) para poder animar la respiración.
sprite("_kael_top", `
  ......j..j.j........w.
  .....jhhjhhhj......wW.
  ....hhhjjhhhhhh....wW.
  ...hhhjhhhhhhhhh...wW.
  ..hhHhhhhhhhhhhhh..wW.
  ..hHhhhhhhhhhhhhhh.wW.
  .hHHhhhhhhsssshhh..wW.
  .HHhhhhhssssssshh..wW.
  .HHhhhhsssEesssEe..wW.
  ..HhhhhsssEesssEe..wW.
  ..HHhhSssssssssss..wW.
  ...HHhSSsssSssssS..wW.
  .....HSSSSSSSSSS...wW.
  ...cAAaaaaaaaaAA..ggg.
  ..ccAaaAaaaaaaAAsgggg.
  ..ccmAAaaaaaaaAssS.g..
  ..cccmAaaaaaaAAsSS.b..
  ..cccbbbbgbbbbbbb..b..
  ..CccmAaaaaaAAm.......
  ..CCcmAaaaaaAAm.......`)
sprite("_kael_legs", `
  ...CCcpppppppppp......
  ....CCppp...pppp......
  .....oooo...oooo......
  ....ooooo...ooooo.....`)
sprite("kael", { outline: "k", w: 22, h: 24 }, stamp("_kael_legs", 0, 20), stamp("_kael_top", 0, 0))

// Idle de prueba: respira (torso baja 1 px) y parpadea. 22x24 + contorno = 24x26.
anim("idle", { outline: "k", w: 22, h: 24 },
  stamp("_kael_legs", 0, 20),
  frame({ ms: 450 }, stamp("_kael_top", 0, 0)),
  frame({ ms: 450 }, stamp("_kael_top", 0, 1)),
  frame({ ms: 450 }, stamp("_kael_top", 0, 0)),
  frame({ ms: 150 }, stamp("_kael_top", 0, 0), grid(10, 8, "ss\nee"), grid(15, 8, "ss\nee")))
sheet("kael_sheet", ["idle"], { pad: 1 })

sprite("pablo", { outline: "k" }, `
  .......vvvv...........
  .....vvvvvvvv.........
  ....vvvvvvvvvv....t...
  ...vvlvvvvvvvvv...tT..
  ..vvlvvvvvvvvvvv...tT.
  ..vlvvvvvvvvvvvvv...t.
  ..vvvvvvvsssssvvv...tn
  .Vvvvvvsssssssss....tn
  .VVvvvvsssEesssEe...tn
  ..VvvvvsssEesssEe...tn
  ..VVvvSssssssssss...tn
  ...VVvSSsssSssssS...tn
  ....VVVSSSSSSSSV....tn
  ....VVvvvvvvvvvvvsssTn
  ...VVvvvlvvvvvvvSSSTtn
  ...VVvvvvvvvvvvv....tn
  ...VvvvvvvvvvvvV....tn
  ...Vvbbbbbgbbbbbb..tT.
  ...VVtvvvvvvvvVV..tT..
  ....VtvvvvvvvvV...t...
  .....tTTTTTTTTTT......
  .....TTTT...TTTT......
  .....oooo...oooo......
  ....ooooo...ooooo.....`)

sprite("lyra", { outline: "k" }, `
  ...............uu.....
  .............uuuU..f..
  ...........uuuuU..fff.
  .........uuyuuuU...t..
  ........uuyuuuuU...t..
  ......uuuyuuuuuuU..t..
  ..UUuuuuuuuuuuuuuUUr..
  ...UUUUUUUUUUUUUUU.t..
  .....rrrrsssssrrr..t..
  ....rrrrssEesssEr..t..
  ..SsrrrrssEesssEs..t..
  ....rrrSsssssssss..t..
  .....rrSSsssSsssS..t..
  ......rSSSSSSSSS...t..
  .....zZzzzzzzzzzzssst.
  ....zZzzzqzzzzzzSSStt.
  ....ZZzzzqzzzzzzz..t..
  ....ZzzzzqzzzzzzZ..t..
  ...ZZuuuuuugUuuuuu.t..
  ...ZzzzzzqzzzzzzZ..t..
  ...ZzzzzzqzzzzzzzZ.t..
  ...ZZzzzzqzzzzzzZZ.t..
  ....ZZZZZZZZZZZZZ..T..
  .....oooo...oooo......`)

sprite("nyx", { outline: "k" }, `
  ........dddd..........
  ......ddddddddd.......
  .....dddddddddddd.....
  ....ddxdddddddddddd...
  ...ddxddddddddddddd...
  ...dxdddddddddddddd...
  ..DddddddssssssDdd....
  ..DDdddsssssssssD.....
  ..DDdddsssiessiesD....
  ...DddRRRRRRRRRRR.....
  ...DDdRRRRRRRRRRRR....
  ....DDRRRRRRRRRRR.....
  .....DDDDSSSSSS.......
  ....RDdddddddddd...w..
  ...RRDdxddddddddssWw..
  ..RR.DdxdddddddddSSg..
  .RR..DddddddddddD..b..
  ..wW.DbbbbbgbbbbbD....
  ..gS.DDdddddddddDD....
  ..b..DDdxddddddDD.....
  .....DDDDDDDDDDDD.....
  ......DDDD...DDDD.....
  ......dddd...dddd.....
  .....ddddd...ddddd....`)
