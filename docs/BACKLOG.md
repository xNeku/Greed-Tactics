# Backlog — Greed Tactics

Lista priorizada de tareas. Cada tarea tiene un ID estable (`GT-xxx`) para referenciarla en commits y conversaciones.
El estado por hito está en [`ROADMAP.md`](ROADMAP.md).

**Prioridad:** P0 bloquea el hito actual · P1 necesaria para el hito · P2 mejora · P3 algún día
**Estado:** ⬜ pendiente · 🟡 en curso · 🔍 en revisión · ✅ hecho

## Siguiente

| ID | Tarea | Hito | Prio | Estado |
|---|---|---|---|---|
| GT-230 | Validar el feel v0.4 jugando: flechas, zona roja, efectos, estados y dificultad de la IA | M1 | P0 | 🔍 |
| GT-231 | Ocultar o hacer transparentes los árboles/muros que tapan unidades o la casilla bajo el ratón | M1 | P1 | ⬜ |
| GT-232 | Animación de "cast" del usuario (brillo/pose) y anticipación del enemigo antes de golpear | M1 | P2 | ⬜ |
| GT-233 | Estados: más efectos (sangrado, escudo, provocar) e inmunidades de bosses | M1 | P2 | ⬜ |
| GT-234 | IA: usar habilidades de movimiento sin daño para huir/reposicionarse y esperar al umbral de ira | M1 | P2 | ⬜ |
| GT-235 | Opción de dificultad (fácil/normal/difícil) como multiplicador de `RunConfig` | M2 | P2 | ⬜ |
| GT-202 | Previsualizar el daño de las explosiones de modificadores (hoy solo se indica "explota") | M1 | P3 | ⬜ |
| GT-200 | Validar el prototipo v0.3 jugando: una run completa + combates rápidos de cada zona. Anotar sensaciones de ritmo, clases, ira y mapas | M1/M2 | P0 | 🔍 |
| GT-016 | Medir duración media de combate con jugador humano y ajustar números (objetivo 4-6 min) | M1 | P1 | ⬜ |
| GT-052 | Validar duración de run (objetivo 20-30 min en este prototipo) | M2 | P1 | ⬜ |
| GT-050 | Bendiciones (GDD §2) separadas de los modificadores | M2 | P1 | ⬜ |
| GT-051 | Compañeros: elegir personaje principal + compañeros, IA por rol (GDD §7) | M2 | P1 | ⬜ |
| GT-205 | Mapa de run con ramas (elegir camino entre fases) | M2 | P2 | ⬜ |
| GT-206 | Tienda / eventos entre fases como uso alternativo del oro | M2 | P2 | ⬜ |
| GT-207 | Generador: más variedad (puentes, ruinas, desniveles con escaleras, zonas estrechas), validar "sentido lógico" con más semillas | M2 | P2 | ⬜ |
| GT-018 | Cola de turnos con retratos y resaltar la unidad en el mapa al pasar por la cola | M1 | P2 | ⬜ |

## Más adelante

| ID | Tarea | Hito | Prio | Estado |
|---|---|---|---|---|
| GT-030 | Línea de visión para proyectiles (pregunta abierta GDD §14) | M1 | P2 | ⬜ |
| GT-032 | Sprites por dirección: frente + lado hechos (v0.4.1, `UnitData.sprite_side`); falta espaldas | M4 | P2 | 🟡 |
| GT-033 | Animaciones de sprite (idle, andar, atacar, golpe) con `AnimatedSprite3D` / `SpriteFrames` | M4 | P2 | ⬜ |
| GT-034 | Arte final de tiles y props | M5 | P2 | ⬜ |
| GT-035 | Internacionalización: textos de UI a CSV de traducciones (`tr()`) | M4 | P3 | ⬜ |
| GT-036 | Mando/teclado completo: mover el cursor de casillas sin ratón | M5 | P3 | ⬜ |
| GT-037 | Pathfinding con planos (x, y, plano) para escaleras y pozos (GDD §9) | M5 | P2 | ⬜ |
| GT-038 | Ajustes de cámara: límite de pitch, ocultar muros que tapan unidades, opción ortográfica | M5 | P2 | ⬜ |
| GT-039 | Audio: SFX de pasos, golpes, UI; música por zona | M5 | P2 | ⬜ |
| GT-060 | Guardado de cuenta y de run en curso | M3 | P0 | ⬜ |
| GT-061 | Gambling de armas con pity | M3 | P1 | ⬜ |

## Hecho

| ID | Tarea | Hito | Fecha |
|---|---|---|---|
| GT-001 | Validación de M0 por Neku | M0 | 2026-11-02 |
| GT-010 | Plantilla de 4 tipos de habilidad por clase (+ test de contenido) | M1 | 2026-11-02 |
| GT-011 | Habilidades de movimiento: teletransporte, carga, aparecer a la espalda; empuje | M1 | 2026-11-02 |
| GT-012 | Kits de 4 habilidades para Guerrero, Asesina, Maga y Arquero | M1 | 2026-11-02 |
| GT-013 | `ModifierData` (etiqueta, disparador, efecto, límite; tipo deducido) | M1 | 2026-11-02 |
| GT-014 | `ResolutionPipeline` con el orden fijo del §5 + tests | M1 | 2026-11-02 |
| GT-015 | 22 modificadores de contenido | M1 | 2026-11-02 |
| GT-031 | Bonus de daño por altura | M1 | 2026-11-02 |
| GT-040 | Tabla de incompatibilidades de modificadores | M1 | 2026-11-02 |
| GT-041 | Menú principal, mapa de run, recompensas y fin de run (autoload `Game`) | M2 | 2026-11-02 |
| GT-042 | `RunState`: 2 etapas × 4 fases, miniboss, recompensas, XP, nivel, vida persistente, curación | M2 | 2026-11-02 |
| GT-043 | Generador procedural para Cueva, Bosque y Desierto con conectividad garantizada | M2 | 2026-11-02 |
| GT-210 | Ira (ganancia, bonus de daño, coste, mutaciones), maná con regeneración, enfriamientos | M1 | 2026-11-02 |
| GT-211 | Modificadores de comportamiento en combate: rebote, explosión, robo de vida, empuje, reembolso de PA | M1 | 2026-11-02 |
| GT-212 | 12 enemigos y 3 minibosses con sprites provisionales; props 3D (árbol, cactus, roca, estalagmita, cristal) | M4 | 2026-11-02 |
| GT-017 | Estados alterados (quemado, veneno, ralentizado, aturdido, silencio) con tinte e iconos | M1 | 2026-11-03 |
| GT-201 | Previsión completa: vida resultante, estados, empuje cortado, rebotes; panel de habilidad | M1 | 2026-11-03 |
| GT-203 | IA táctica: mapa de amenaza, foco en heridos/peligrosos, distancia preferida, perfiles por enemigo | M1 | 2026-11-03 |
| GT-220 | Flechas de previsión en parábola (verde/roja/naranja/amarilla/gris) y marca de bloqueo; movimiento a medias | M1 | 2026-11-03 |
| GT-221 | Efectos visuales placeholder (proyectil, parábola, tajo, nova, explosiones por casilla), sacudida de cámara | M1 | 2026-11-03 |
| GT-240 | Sprite del guerrero (Kael) de Neku: vectorizado pixel perfect desde JPG, sin barriga, vendas, cinturón; vistas frente y lado | M4 | 2026-11-03 |
| GT-213 | Tests: 91 unitarios + simulación de runs + recorrido end-to-end de pantallas | M1 | 2026-11-02 |
| GT-100…113 | Base M0 (proyecto, datos, grid, combate, HUD, cámara, IA, tests, CI) | M0 | 2026-11-02 |
