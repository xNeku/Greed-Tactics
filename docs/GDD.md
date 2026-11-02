# GDD - Greed Tactics · Tactics Roguelite Isométrico (v0.2)

Nov 2, 2026 · @Neku

> Documento vivo. Cada cambio se registra en el **Changelog** del final.
> Las decisiones tomadas durante la implementación se marcan con **[Decidido vX]**.
> Lo que aún no está cerrado vive en la sección 14 (Preguntas abiertas).

## 1. Pitch y pilares

Roguelike táctico isométrico 2.5D. Combate por turnos rápido y legible, runs de 1-2 horas generadas por zonas, y un personaje que se va volviendo tuyo a base de jugarlo.

**Pilares (no se negocian):**

- **Rápido de decidir.** Cada turno se resuelve en segundos. Plantilla fija de habilidades y pocas decisiones por turno.
- **Locura controlada.** Las runs escalan hasta reglas absurdas, pero cada regla es legible en pantalla y sigue una gramática clara.
- **Apego por estilo de juego.** El personaje es fijo y con personalidad. El cariño sale de cómo lo juegas y de los modificadores que acumulas.
- **Variedad entre runs.** Zonas, enemigos, bendiciones, modificadores y armas cambian cada partida.

**Diferencial frente a Final Fantasy Tactics:** ritmo, reglas más locas y progresión roguelike con desbloqueos permanentes.

## 2. Bucles de run y de meta

**Bucle de run (1-2 horas):**

1. Creas o eliges el inicio: personaje fijo, arma (desbloqueada), compañero inicial.
2. Zona 1 (cueva): pisos con 2-4 combates y un boss o miniboss al final.
3. Tras cada combate: elección de bendición o modificador (1 de 3, reroll limitado).
4. Tras cada miniboss: desbloqueo de raza o clase (elección única, ver sección 10).
5. Zonas siguientes (cloacas, etc.) se abren según avanzas.
6. Muerte o victoria: la run termina. Se conserva lo que es permanente.

**Bucle de meta:**

- Desbloquear personajes jugando con ellos (cuanto más juegas, más habilidades y modificadores desbloqueas para ese personaje).
- Desbloquear armas vía gambling con fragmentos.
- Desbloquear razas y clases en minibosses.
- Subir maestría por personaje y arma.

**Qué persiste y qué no:**

- Persiste: personajes desbloqueados, habilidades del pool, armas desbloqueadas, razas y clases, maestría, fragmentos.
- No persiste: compañeros reclutados, bendiciones, modificadores de la run, objetos temporales.

## 3. Combate

**Orden de turno:** por velocidad. La cola de turnos siempre visible muestra los próximos 5-6 actores.

- **[Decidido v0.2] Sistema de carga (CT).** Cada "tick" todas las unidades vivas suman su VEL a su CT. La primera que llega al umbral (100, en `RulesConfig`) actúa y al terminar paga el umbral. Una unidad el doble de rápida actúa el doble de veces. Empates: más CT primero, luego orden de aparición. Es determinista, así que la cola mostrada es exactamente la que ocurrirá (salvo muertes).

**Recursos por turno:**

- **PM (puntos de movimiento):** casillas que puedes recorrer. Coste base 1 por casilla, más 1 por subir de altura.
- **PA (puntos de acción):** habilidades y ataque básico. Cada habilidad muestra su coste en PA.
- **MP (maná):** solo para habilidades que lo gastan.
- **[Decidido v0.2]** PM y PA se recargan al empezar cada turno de la unidad. Los PM se pueden gastar en varios movimientos dentro del mismo turno (mover, atacar, seguir moviendo). Valores iniciales: 2 PA por turno, ataque básico a 1 PA. Todo es dato (`UnitData`, `SkillData`).

**Movimiento:**

- Solo ortogonal (arriba, abajo, izquierda, derecha). Sin diagonales.
- Subir o bajar altura cuesta PM extra. Saltar más de 1 nivel de altura no está permitido salvo por habilidad.
- Las casillas alcanzables se muestran en azul antes de confirmar.
- **[Decidido v0.2]** Subir cuesta +1 PM por nivel; bajar no cuesta extra. Ambos son configurables en `RulesConfig` (`climb_up_cost`, `climb_down_cost`, `max_climb`). El límite de 1 nivel aplica en ambos sentidos.
- **[Decidido v0.2]** Cada terreno define su coste base (`TerrainData.move_cost`). El agua poco profunda cuesta 2 PM.
- **[Decidido v0.2]** Se puede atravesar a los aliados pero no detenerse en su casilla. Los enemigos bloquean el paso.
- **[Decidido v0.2]** Al moverse, la unidad queda mirando en la dirección del último paso. Al atacar, se gira hacia el objetivo.

**Ataque:**

- Cada habilidad define su forma en datos: punto único, línea, cruz, rombo, área 3x3, lanzamiento a distancia.
- El rango se previsualiza antes de confirmar. Lo que ves es lo que pasa.
- Orientación: "por la espalda" es la casilla opuesta a la dirección en la que mira el enemigo. Regla exacta en la sección 5.
- **[Decidido v0.2] Fórmulas iniciales** (`CombatFormulas`, todo ajustable):
  - Daño = `poder de la habilidad + ataque − defensa`, × multiplicador por lado (frente ×1, flanco ×1.1, espalda ×1.25). Mínimo 1.
  - Probabilidad de golpe = `100 − evasión × factor` (frente 1, flanco 0.5, espalda 0). Entre 5% y 100%.
  - Crítico = crítico base de la unidad, +15 puntos por la espalda. Daño crítico ×1.5.
  - El alcance vertical de cada habilidad (`vertical_reach`) limita la diferencia de altura con la casilla objetivo (melee: 1, arco: 3).
- **[Decidido v0.2] Previsión:** al pasar el ratón por un objetivo se muestra una ficha por cada unidad afectada con lado (Frente/Flanco/Espalda), daño, % de golpe y % de crítico, calculados con las mismas funciones que resuelven el ataque.

**Límites de combate:**

- Máximo 4 aliados activos por bando (tu personaje + 3).
- Duración objetivo: 4-6 minutos por combate.

## 4. Habilidades

**Plantilla fija:** todos los personajes tienen los mismos 4 tipos de habilidad:

- **Básica:** ataque por defecto, sin coste de PA o coste mínimo.
- **Lanzamiento:** a distancia, normalmente proyectil.
- **Área:** efecto sobre varias casillas.
- **Movimiento:** cambia cómo te desplazas o te colocas.

**Slots:**

- Empiezas con 4 slots (uno por tipo).
- Al jugar y desbloquear progresión se abren hasta 6 slots.
- Cada slot puede contener cualquier habilidad del pool de ese tipo, por lo que un personaje puede llevar dos de un mismo tipo.

**Pool por personaje:**

- Cada personaje tiene su pool de habilidades. Se desbloquean jugando con ese personaje.
- En run solo llevas las que tienes equipadas en los slots, más pasivas.

**Etiquetas:** cada habilidad lleva etiquetas (`basico`, `lanzamiento`, `area`, `movimiento`, y opcionalmente `proyectil`, `melee`, `fuego`, etc.). Los modificadores (sección 5) se aplican por etiqueta, no por habilidad concreta.

**[Decidido v0.2] Datos de una habilidad (`SkillData`):** tipo, etiquetas, coste PA/MP, alcance mínimo y máximo (distancia Manhattan), alcance vertical, forma del área (`SINGLE`, `DIAMOND`, `SQUARE`, `CROSS`, `LINE`) y tamaño, poder y si afecta a aliados. Un alcance 0-0 apunta a la propia casilla (habilidades centradas en uno mismo).

## 5. Modificadores

**Gramática de cada modificador:**

- **Etiqueta objetivo:** a qué habilidades afecta (ej. `lanzamiento`).
- **Disparador:** cuándo actúa (ej. al impactar, al acabar movimiento, al crítico, al empezar el turno).
- **Efecto:** qué cambia (ej. rebota 2 veces, explota en área 3x3).
- **Límite:** tope por run o por turno, para evitar cadenas infinitas (ej. máximo 3 rebotes).
- **Tipo:** *numérico* (suma o multiplica) o *comportamiento* (cambia una regla).

**Orden fijo de resolución:**

1. Cambios de forma y trayectoria (rebote, alcance, desvío).
2. Modificadores numéricos (daño, coste, radio).
3. Efectos al impacto (explosión, estado, empuje).
4. Encadenados (efectos que disparan otros), siempre con tope de saltos.

El orden es fijo y está documentado. El caos viene de acumular, no de resolver de forma ambigua.

**Conflictos:**

- Los numéricos se acumulan sin límite (dos `+1 alcance` suman).
- Los de comportamiento se toman una vez. Dos `rebota` no suman rebotes: se aplica el de mayor límite.
- Incompatibilidades definidas por tabla (ej. `atraviesa` y `bloquea` no pueden coexistir sobre la misma habilidad). Si no está en tabla, se permite.

**Orientación (para ataques por la espalda):**

- Cada enemigo tiene una dirección en la que mira (una de las 4 ortogonales).
- Atacar por la espalda = la casilla que está justo detrás del enemigo, en la dirección opuesta a la que mira.
- Si la casilla de atrás está ocupada o es un bloque, no cuenta como espalda.
- **[Decidido v0.2] Regla exacta implementada (`GridRules.get_attack_side`):**
  1. Se mira el eje dominante entre atacante y objetivo, relativo a hacia dónde mira el objetivo. Delante = **Frente**, detrás = **Espalda**, de lado o en diagonal perfecta = **Flanco**.
  2. Para que cuente como Espalda, la casilla justo detrás del objetivo debe estar libre: dentro del mapa, transitable, a una altura alcanzable (≤ `max_climb`) y sin ninguna unidad salvo el propio atacante. Si no, el objetivo "tiene la espalda cubierta" y el golpe cuenta como **Flanco**.
  3. Así la misma regla vale para cuerpo a cuerpo (estás en la casilla de atrás) y para ataques a distancia (disparas desde detrás).

**Reroll:**

- Al elegir de 1 de 3 en un checkpoint, puedes rerollear una vez por checkpoint.
- El reroll cuesta 1 moneda de run.

**Ejemplos:**

- *Cuchillo que rebota:* etiqueta `lanzamiento`, disparador al impactar, efecto rebota, límite 3 saltos.
- *Movimiento que explota:* etiqueta `movimiento`, disparador al acabar, efecto explosión 3x3, daño numérico.
- *Crítico por la espalda:* etiqueta `basico`, disparador al atacar por la espalda, efecto aumento de crítico, tipo numérico.

## 6. Personajes jugables

- Personajes **fijos**, con nombre, personalidad, estética y clase ya definidos. Ej.: Pablo, arquero humano.
- No hay creación de personaje. La estética y la clase vienen dadas.
- Pool inicial: unos 10 personajes. Algunos están desbloqueados desde el principio, el resto se desbloquean jugando.
- Cada personaje tiene su kit: 4 tipos de habilidad base, un pool propio de habilidades y pasivas, y un estilo de juego claro.

**Desbloqueo por uso:**

- Cuanto más juegas con un personaje, más habilidades y modificadores desbloqueas para él.
- Los desbloqueos de habilidad se ven en el pool del personaje, no en la run.

**Identidad:** el apego viene del estilo de juego, la voz y la historia. Cada personaje necesita al menos 2-3 líneas de diálogo por piso y un momento propio por zona.

**Personajes de prototipo (v0.2, provisionales):**

| Personaje | Raza · Clase | Rol | Kit actual |
|---|---|---|---|
| Kael | Humano · Caballero | Tanque melee | Tajo (básica), Onda de choque (área alrededor, 2 PA + 8 MP) |
| Pablo | Humano · Arquero | Daño a distancia | Golpe de arco (básica), Flecha (lanzamiento 2-4, alcance vertical 3) |

Enemigos de prototipo: Goblin (Saqueador, melee) y Limo (Bestia, melee lento y resistente).

## 7. Compañeros

- Son personajes preset con personalidad y rol definido, de la misma pool que los personajes jugables.
- **Roles base:** tanque, sanador, daño a distancia, control. Cada compañero encaja en uno.
- **Obtención:** uno al empezar la run, y uno nuevo al completar cada piso. Elegir entre 2-3 ofrecidos.
- **Límite en combate:** máximo 3 aliados activos. Los demás quedan en reserva y se cambian entre combates.
- **IA:** reglas de decisión por rol (prioridades simples: el sanador cura al aliado más bajo, el tanque se interpone, etc.). No se programa un comportamiento distinto por personaje.
- Los compañeros no persisten entre runs, pero los que hayas visto pueden salir de nuevo en futuras runs.
- **[v0.2]** Ya existe una IA base (`BasicAI`) que usan los enemigos: ataca si puede, si no se mueve a la casilla con mejor ataque, si no se acerca al rival más cercano. Las IAs por rol extenderán esta base.

## 8. Armas y equipo

**Armaduras:** eliminadas. La defensa sale de HP, evasión y rasgos de personaje.

**Armas:**

- Se eligen en la pantalla de inicio de run. Son el slot de equipo y se ven desde el primer combate.
- Cada arma define un playstyle (espada: control y golpes cortos; hacha: área y daño lento) y ofrece una estética propia.
- Cada arma lleva **1 modificador de arma** que afecta a sus etiquetas (ej. el hacha tiene `basico` + `melee`). Usa el mismo sistema de la sección 5.
- Las armas son permanentes una vez desbloqueadas.

**Gambling de desbloqueo (propuesta v0.1):**

- Coste: 3 fragmentos por tirada. Los fragmentos se ganan en runs (drops de bosses) y se acumulan entre runs.
- Pity: tras 10 tiradas sin arma nueva, la siguiente es garantizada. El contador se reinicia al obtener un arma.
- Duplicados: se convierten en 1 fragmento.
- Maestría: cada arma tiene su propia maestría por personaje. Subirla desbloquea nodos del árbol de nodos del arma (a definir en M3).

**Nota: las armas se desbloquean con gambling**. Los minibosses siguen desbloqueando razas y clases.

## 9. Mundo y runs

**Estructura:**

- Una run = 4-5 pisos (zonas). Cada zona tiene temática propia: cueva, cloacas, etc.
- Cada piso tiene 2-4 combates y termina en boss o miniboss.
- Duración objetivo: 1-2 horas por run completa.

**Generación:**

- Aleatoria dentro de cada zona: qué salas aparecen, qué enemigos cuadran, qué bloques y alturas tiene el mapa.
- Cada zona tiene un pool de enemigos y reglas de mapa (agua, alturas, planos).
- Los minibosses se eligen de una pool rotatoria por zona.
- **[v0.2]** El formato de mapa (`MapData`: filas de texto de terreno + filas de alturas + spawns) está pensado para que un generador procedural produzca mapas con `MapData.create()` y los valide con `MapData.validate()`.

**Apertura tipo Isaac:**

- Al principio, las runs tienen límites: menos zonas disponibles, menos slots de habilidad, menos bendiciones posibles.
- Cada miniboss vencido y cada zona completada abre nuevas posibilidades: zonas nuevas, más slots, pool de bendiciones más amplio.

**Planos:** 3 planos (subterráneo, suelo y superior). Se cambia de plano por escaleras, pozos o habilidades. Se introducen gradualmente, empezando por el suelo.

## 10. Desbloqueos de razas y clases

- Al vencer a un miniboss se ofrece **una elección**: quedarte con su raza o con su clase. Una sola.
- La elección es **permanente en la cuenta**. Si el personaje muere, lo desbloqueado sigue disponible para crear o usar en cualquier personaje.
- Las razas y clases disponibles para desbloquear **rotan** en una pool por zona. No siempre te toca desbloquear algo.
- **Gancho emocional:** el jugador se encariña con el miniboss que le toca. El desbloqueo es la recompensa, no el objetivo.

**Pendiente:** cómo se asigna una raza o clase desbloqueada a un personaje, dado que los personajes son fijos (ver sección 6). Propuesta: las razas y clases desbloqueadas se aplican a la **creación de run** como modificador de inicio, no cambian al personaje fijo.

## 11. Arte, estética y HUD

**Referencia visual:** capturas de Ranked Arena (adjuntas al inicio del proyecto).

**Mundo:**

- Tiles 3D con bloques elevados y agua animada. Geometría simple, sombras suaves.
- Alturas visibles y consultables (ej. "Elev. 0").
- Vista isométrica con cámara libre (Space para volver al personaje activo).
- **[v0.2] Implementado:** columnas 3D por casilla (1 nivel = 0,5 unidades), cuadrícula y damero sutil en la cara superior por shader, agua animada por shader, fondo navy. Cámara: Q/E rota 90º, rueda zoom, WASD/flechas o botón central para desplazar, Espacio vuelve a la unidad activa.

**Personajes:**

- Sprites pixel art como billboard que siempre miran a cámara.
- Aro de color en la base: rojo enemigo, azul aliado, amarillo unidad activa.
- Sombra en el suelo.
- **[v0.2] Implementado:** billboard vertical (eje Y fijo) con filtro nearest, el sprite se voltea según hacia dónde mira la unidad respecto a la cámara, flecha amarilla de orientación en el aro, etiqueta flotante con nombre y HP, números de daño flotantes. Sprites provisionales generados por `tools/generate_placeholder_sprites.py` (dibujados mirando a la derecha, pies en el borde inferior).

**HUD:**

- Cola de turnos arriba, con iniciales y color por bando.
- Ficha del personaje activo abajo a la izquierda: nombre, nivel, raza, clase, HP, MP, evasión.
- Comandos abajo a la derecha: Ataque, Habilidades, Esperar.
- Mensaje superior con la acción en curso.
- **[Decidido v0.2]** Los comandos son: Mover, un botón por cada habilidad equipada (con su coste) y Esperar, con atajos 1-6. Esperar entra en modo orientación (apuntas con el ratón y confirmas con clic o Enter). La ficha muestra la unidad bajo el ratón o, si no hay ninguna, la activa. Encima, una etiqueta con terreno y elevación de la casilla bajo el ratón.

**Feedback por color:** azul para movimiento, amarillo para objetivos y ataque, verde para la casilla seleccionada. Cada información tiene color y forma, no solo texto.

**Previsión:** toda acción muestra su área antes de confirmar. Los efectos encadenados tienen límite de saltos visible.

**Tipografía:** Nunito (OFL) en Regular, Bold y ExtraBold.

## 12. Arquitectura técnica (Godot 4.7)

**Principio:** datos fuera del código, reglas separadas de la presentación.

**Estructura de carpetas [v0.2]:**

```
core/        Reglas puras (RefCounted). Sin nodos, sin escenas. Testeables.
  data/      Definiciones de Resource: TerrainData, MapData, SkillData, UnitData, RulesConfig, BattleSetup
  grid/      GridDir, BattleGrid, GridRules, AreaShape, Pathfinder, ReachMap
  combat/    UnitState, TurnQueue, CombatState, CombatFormulas, AttackPreview, SkillResult
  ai/        BasicAI, AiAction
content/     Instancias .tres (lo que edita diseño): terrenos, mapas, unidades, habilidades, reglas, combates
scenes/      Presentación: cada .tscn junto a su .gd
  battle/    battle.tscn (raíz del combate), mapa, unidades, cámara, input del jugador
  ui/        HUD y tema visual
assets/      Fuentes, shaders, sprites
tests/       Runner headless, tests unitarios e integración
tools/       Scripts de soporte (generar sprites, re-guardar recursos)
docs/        GDD, roadmap, backlog, convenciones
```

**Datos como `Resource`:**

- `CharacterData`: nombre, raza, clase, sprite, pool de habilidades, pasivas. **[v0.2]** Implementado como `UnitData` (común a personajes, compañeros y enemigos). `CharacterData`/`EnemyData` extenderán de él cuando necesiten campos propios.
- `SkillData`: tipo, etiquetas, coste PA/MP, forma del área, efecto.
- `ModifierData`: etiqueta objetivo, disparador, efecto, límite, tipo (numérico o comportamiento). *(M1)*
- `WeaponData`, `EnemyData`, `ZoneData`, `BlessingData`. *(M1-M3)*
- **[v0.2]** `TerrainData` (transitable, coste PM, líquido, colores), `MapData` (ver §9), `RulesConfig` (todas las constantes de reglas), `BattleSetup` (mapa + plantillas de ambos bandos).

**Reglas (sin nodos visuales):**

- `CombatState`: turnos, cola, PM/PA/MP por actor. **[v0.2]** Expone comandos validados (`move_active_unit`, `use_skill`, `end_turn`) y señales (`turn_started`, `unit_moved`, `skill_resolved`, `unit_defeated`, `combat_finished`...). Un comando ilegal no cambia nada y devuelve vacío/null.
- `ResolutionPipeline`: aplica modificadores en el orden fijo de la sección 5. *(M1; hoy `CombatFormulas`)*
- `GridRules`: alcance, movimiento, orientación, alturas.
- `RunState`: pisos, combates, desbloqueos de la run. *(M2)*

**Presentación:** nodos de Godot que escuchan señales de las reglas. Nunca al revés.

- **[v0.2]** `BattleController` (raíz de `battle.tscn`) crea el `CombatState` desde un `BattleSetup`, instancia las vistas y lleva el bucle de turnos. `PlayerTurnInput` y la IA llaman a los mismos `execute_move/skill/end_turn`, que aplican el comando a las reglas y esperan (`await`) la animación correspondiente. `BattleHud` es una fachada sobre los widgets del HUD, cada uno en su propia escena.

**Mapa:** ~~`TileMapLayer` para el suelo y los bloques.~~ **[Decidido v0.2]** El mapa es 3D real (como en la referencia): `BattleMapView` dibuja una columna por casilla con `MultiMeshInstance3D` (un draw call para todo el terreno sólido y otro para el agua). El picking del ratón es analítico (rayo contra la caja de cada columna), sin físicas. Grafo 3D (x, y, altura) para pathfinding con escaleras, pozos y rampas, en lugar de `AStarGrid2D` plano: hoy `Pathfinder` (Dijkstra) trabaja sobre (x, y) con altura por casilla; los planos (§9) añadirán la tercera coordenada.

**Persistencia:** `Resource` serializados o JSON para el progreso de cuenta. Guardado tras cada combate y cada desbloqueo.

**Tests:** las reglas de la sección 5 y el pipeline de modificadores deben ser testeables sin escena. Es lo primero que se prueba.

- **[v0.2]** Runner propio sin dependencias (`tests/test_runner.gd`): cualquier `tests/unit/test_*.gd` que extienda `TestCase` se ejecuta; un error de script durante un test cuenta como fallo. Test de integración `tests/integration/autoplay_battle.gd`: juega el combate entero con IA en ambos bandos y falla si no termina o hay errores. CI en GitHub Actions ejecuta ambos en cada push.

**Regla para el agente:** cada modificador nuevo se añade como dato y pasa por los tests del pipeline antes de tocar contenido.

## 13. Roadmap

El roadmap detallado y su estado viven en [`ROADMAP.md`](ROADMAP.md). Las tareas concretas, en [`BACKLOG.md`](BACKLOG.md).

Cada hito tiene un criterio de salida. No se pasa al siguiente sin cumplirlo.

- **M0. Prototipo de grid** — Tiles isométricos con altura, movimiento ortogonal con coste PM, un personaje y un enemigo. Salida: mover y atacar en el grid con previsión. Tests de movimiento y orientación en verde.
- **M1. Combate completo** — Cola de turnos por velocidad, PM/PA/MP, plantilla de 4 slots, 3-4 habilidades base, 5 modificadores (2 de comportamiento, 3 numéricos), HUD completo. Salida: un combate de 4-6 minutos contra 3 enemigos, jugable de principio a fin sin tocar código para añadir contenido.
- **M2. Run jugable** — 1 zona, 3 pisos con 2-4 combates y boss. Bendiciones (1 de 3, reroll limitado). 1 compañero inicial y uno por piso. Muerte y victoria. Salida: una run completa en 20-30 minutos sin bugs bloqueantes.
- **M3. Meta y persistencia** — Guardado de cuenta, desbloqueo de personajes por uso, gambling de armas con pity, maestría por personaje y arma, desbloqueo de razas y clases en minibosses. Salida: el progreso sobrevive a cerrar el juego y a varias runs seguidas.
- **M4. Contenido** — 2-3 zonas, pool de 10 personajes con kit completo, pool de compañeros, unos 15-20 modificadores, 5 armas. Salida: tres runs seguidas dan experiencias distintas.
- **M5. Pulido y balance** — Los 3 planos completos, apertura tipo Isaac, arte final, audio, balance con playtests externos. Salida: runs de 1-2 horas con jugadores que no son del equipo, sin que se sientan forzadas.

## 14. Preguntas abiertas

- **Razas y clases desbloqueadas en personajes fijos:** propuesta en sección 10 (se aplican como modificador de inicio de run). Confirmar.
- **Maestría de armas:** ¿se desbloquea por usos del arma con un personaje concreto, o por usos del arma en general?
- **Tiempo de run:** 4-5 pisos encajan en 1-2 horas solo si los combates duran 4-6 minutos. Hay que validarlo en M2.
- **Compañeros con kit propio:** ¿pueden ser jugables en otra run o solo aparecen como aliados?
- **Cuenta de energía o límite de partidas:** no definido. Probablemente no hace falta.
- **Nombre del juego:** provisional "Greed Tactics" (nombre del repositorio). Confirmar.
- **[v0.2] Línea de visión:** ¿los proyectiles se bloquean con bloques altos o unidades en medio? Hoy no hay línea de visión, solo alcance vertical.
- **[v0.2] Bonus de altura:** ¿atacar desde arriba da daño o alcance extra (como en FFT)? Hoy no.
- **[v0.2] Coste del ataque básico:** el GDD dice "sin coste o coste mínimo". Con 0 PA sería infinito; hoy cuesta 1 de 2 PA (dos ataques por turno). Validar en M1 con la duración de combate.
- **[v0.2] Orientación al esperar:** hoy se elige a mano al terminar. ¿Automática hacia el enemigo más cercano para ir más rápido (pilar 1), con opción de cambiarla?
- **[v0.2] Agua:** hoy es transitable (2 PM). ¿Agua profunda intransitable / que impida atacar?

## Changelog

- **v0.2 (Nov 2, 2026)** — Arranque del proyecto en Godot 4.7.2. Añadidas las decisiones de implementación de M0 (marcadas **[Decidido v0.2]**): sistema de turnos CT, costes de altura, terreno, paso entre aliados, fórmulas de daño/golpe/crítico, regla exacta de espalda, comandos del HUD. Mapa 3D con MultiMesh en lugar de `TileMapLayer`. Estructura de carpetas, runner de tests e integración continua. Nuevas preguntas abiertas. Roadmap y backlog movidos a documentos propios.
- **v0.1 (Nov 2, 2026)** — Documento inicial.
