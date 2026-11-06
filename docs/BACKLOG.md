# Backlog — Greed Tactics

Lista priorizada de tareas. Cada tarea tiene un ID estable (`GT-xxx`) para referenciarla en commits y conversaciones.
El estado por hito está en [`ROADMAP.md`](ROADMAP.md).

**Prioridad:** P0 bloquea el hito actual · P1 necesaria para el hito · P2 mejora · P3 algún día
**Estado:** ⬜ pendiente · 🟡 en curso · 🔍 en revisión · ✅ hecho

## Siguiente

| ID | Tarea | Hito | Prio | Estado |
|---|---|---|---|---|
| GT-253 | Animaciones de Tohil, Sigrid y Pablo (como las de Kael) | M4 | P1 | ⬜ |
| GT-254 | Habilidades que interactúen con el tótem (detonarlo, teletransportarse a él) y modificadores de tótem | M1 | P2 | ⬜ |
| GT-251 | Animaciones de Pablo (y del resto cuando lleguen sus sprites) con `art/src` + `tools/build_sprite_frames.gd` | M4 | P1 | ⬜ |
| GT-252 | Pablo sin arco visible en el sprite: decidir con Neku si lo lleva a la espalda o en la mano | M4 | P2 | ⬜ |
| GT-260 | Importador del taller: los sprites ya se importan (`tools/hero_workshop/import_sheets.py`); falta pasar armas, pasivas y desbloqueables cuando existan en el juego | M4 | P1 | 🟡 |
| GT-276 | Casillas de tienda y de evento en el mapa de run (gastar oro, decisiones con riesgo) | M2 | P1 | ⬜ |
| GT-282 | Coreografías para el resto de habilidades (enemigos y jefes incluidos), anticipación y animaciones de lanzamiento por personaje | M5 | P1 | ⬜ |
| GT-277 | Armas en el juego: ataque básico, pasiva y estadísticas del arma; botín en la run y desbloqueo permanente (el dibujo en la mano ya está: GT-284) | M4 | P1 | ⬜ |
| GT-280 | Equipamiento de habilidades: elegir qué habilidades llevas (y así qué modificadores te salen) | M3 | P1 | ⬜ |
| GT-278 | Más objetivos de combate (matar al líder, aguantar X turnos) y que la IA enemiga persiga la carreta / tape la salida | M2 | P2 | ⬜ |
| GT-274 | Varios golpes por habilidad suman el ataque entero en cada golpe: revisar si los golpes extra deben escalar menos (afecta a Sigrid, Kael, luchador, berserker) | M5 | P2 | ⬜ |
| GT-272 | Animaciones de invocar y de hundirse/emerger en la arena (troll); el elemental "crece" visualmente con el impulso | M4 | P2 | ⬜ |
| GT-267 | Artefacto de modificadores: catálogo con categorías según a qué afectan (daño, área, movimiento, estados, recursos...), editable por Neku e importable al juego | M1 | P1 | ⬜ |
| GT-268 | Armas: un sprite por arma con punto de agarre, que se dibuja encima de la mano de cada personaje (todos comparten estructura) | M4 | P1 | ⬜ |
| GT-269 | IA nivel 2: anticipar el turno del jugador (minimax de 1 jugada), coordinación entre enemigos (rodear, no bloquearse), roles por arquetipo | M1 | P2 | ⬜ |
| GT-262 | Compañeros = héroes jugables con progresión bilateral: aparecen a nivel de run con su progresión de cuenta (depende de la meta de M3) | M3 | P1 | ⬜ |
| GT-263 | Jefes de verdad: diseñarlos en el taller (Neku) y meterlos en las zonas | M4 | P1 | ⬜ |
| GT-257 | Equilibrar a Nyx, Elara y Grizka jugando (con ellas la IA gana 1/5 runs simuladas frente a 3/5 del grupo por defecto) | M5 | P1 | ⬜ |
| GT-258 | Animaciones y armas de Nyx, Elara y Grizka cuando Neku pase los sprites | M4 | P2 | ⬜ |
| GT-255 | Integrar las hachas a dos manos de Sigrid cuando Neku pase el sprite del arma | M4 | P1 | ⬜ |
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
| GT-241 | Kael camorrista: kit a puños, sprites de frente/lado y animaciones (idle, andar, puñetazo, golpe) | M4 | 2026-11-03 |
| GT-242 | Sprite de Pablo de Neku: más delgado, moño frontal, aros dorados pegados a la oreja (sin tribales, v0.5.1); frente + lado | M4 | 2026-11-03 |
| GT-243 | Terrenos con textura procedural, decoración, niebla, sol, glow, partículas por zona, viñeta | M5 | 2026-11-03 |
| GT-285 | Proyectiles con `ProjectileLook` (pixel art + orbes por shader, estela, luz, carga/fogonazo, impacto con parón y sacudida) y tajo/retroceso del arma en la mano | M5 | 2026-11-06 |
| GT-284 | Armas de la Armería en el juego: `WeaponData` + pose por vista, dibujadas en la mano (shader que gira sin deformar), armas dobles en espejo, importador `tools/armory/import_weapons.py` | M4 | 2026-11-06 |
| GT-283 | Armería por tipos de arma + 7 armas iniciales de Neku (sprites ajustados a escala, agarre estimado, voltear en la prueba); magos con «Manos (magia)» | M4 | 2026-11-06 |
| GT-281 | v0.8: sistema de coreografías de efectos + 4 habilidades de muestra (Tiro certero, Lluvia de brasas, Salto aplastante, Paso sombrío) y grabador `tools/vfx_showcase.gd` | M5 | 2026-11-06 |
| GT-279 | v0.7.1: protagonista +1 PM/+1 PA, IA de combos y prioridad a sanadores/protagonista, Armería (artefacto) | M2 | 2026-11-05 |
| GT-275 | v0.7: protagonista + reclutas, mapa con bifurcaciones, objetivos (proteger/escapar), Lobo solitario, modificadores solo del protagonista, escalado por grupo; pantallas de mapa y reclutar | M2 | 2026-11-05 |
| GT-273 | Bosque de Neku: luchador, asesina, berserker, curandero, ratas (3 tamaños/colores) y Ent miniboss con rodar y bombitas; mecánicas de apoyo, rodar, cargas, usos por turno y crítico por estado | M4 | 2026-11-04 |
| GT-271 | Troll elemental de arena (miniboss del desierto) + Elemental de arena; reglas de invocadores (control, muerte en cadena, límite), crecimiento al moverse, foco compartido, cobertura y escape con teletransporte | M4 | 2026-11-04 |
| GT-270 | Desierto de Neku: trasgos con daga, arco y brujo + escorpión nuevo (sprites recuperados, 2 habilidades cada uno); IA anti-bloqueo por turnos sin daño | M4 | 2026-11-04 |
| GT-266 | v0.6.2: menú Mover/Atacar/Esperar con página de habilidades, sin bocadillos, rango y zona al seleccionar; subir sin coste; IA que busca casillas de ataque (rampas, alturas) | M1 | 2026-11-04 |
| GT-265 | Primera importación del taller: retoques de Neku en los sprites de Kael (y sus animaciones), Pablo, Tohil, Nyx, Sigrid, Elara y Grizka | M4 | 2026-11-03 |
| GT-264 | Taller: categoría de enemigos (jefes, minibosses, normales) con ficha editable y creación/borrado de enemigos nuevos | M4 | 2026-11-03 |
| GT-261 | Taller de héroes (artefacto en claude.ai): editor pixel perfect con lápiz, goma, gotero, cubo, simetría, deshacer, paleta, vista previa y PNG; fichas con skills, pasivas, desbloqueables y arma. Fuente en `tools/hero_workshop/`, datos con `tools/export_hero_sheets.gd` | M4 | 2026-11-03 |
| GT-259 | v0.6: Nyx asesina táctica (toxina acumulable, provocación), Elara paladina (curas, Égida), Grizka pistolera (retroceso); menú en rejilla | M1 | 2026-11-03 |
| GT-256 | Correcciones v0.5.1: aros de Pablo, sin tribales, Sigrid sin hacha, chamán Tohil (hombre), grupo inicial con los 4 de Neku | M4 | 2026-11-03 |
| GT-250 | Bloqueo raro: un arquero enemigo huía para siempre; la IA ahora pesa menos el peligro cuando puede atacar | M1 | 2026-11-03 |
| GT-244 | Tohil, chamán de fuego: invocaciones, estructuras, auras, estados positivos | M1 | 2026-11-03 |
| GT-245 | Sigrid, bárbara nórdica: golpes múltiples, robo de vida, autoestado temerario, salto con knockup | M1 | 2026-11-03 |
| GT-246 | Plantel de 6 héroes y selección de grupo de 4 en el menú | M2 | 2026-11-03 |
| GT-213 | Tests: 91 unitarios + simulación de runs + recorrido end-to-end de pantallas | M1 | 2026-11-02 |
| GT-100…113 | Base M0 (proyecto, datos, grid, combate, HUD, cámara, IA, tests, CI) | M0 | 2026-11-02 |
