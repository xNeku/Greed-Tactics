# GDD - Greed Tactics · Tactics Roguelite Isométrico (v0.7)

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

- Desbloquear personajes jugando con ellos (cuanto más juegas, más habilidades y modificadores desbloqueas para ese personaje). **[v0.6]** Esa mejora también se nota cuando el personaje sale como compañero (progresión bilateral, §7).
- Desbloquear armas vía gambling con fragmentos.
- Desbloquear razas y clases en minibosses.
- Subir maestría por personaje y arma.

**Qué persiste y qué no:**

- Persiste: personajes desbloqueados, habilidades del pool, armas desbloqueadas, razas y clases, maestría, fragmentos.
- No persiste: compañeros reclutados, bendiciones, modificadores de la run, objetos temporales.

**[Decidido v0.7, Neku] Nuevo bucle de run: protagonista + reclutas.** Sustituye a la estructura v0.3 (los 4 héroes juntos desde el principio).
- **Protagonista:** en el menú eliges UN héroe. Empiezas la run solo con él. Si cae en un combate, se pierde la run aunque queden compañeros. La IA lo protege más cuando juega por él (doble miedo a las casillas amenazadas).
- **[v0.7.1, Neku] El protagonista siempre es más rápido:** +1 PM y +1 PA en todos los combates (`RunConfig.protagonist_move_bonus` / `protagonist_action_bonus`). Sustituye al bonus de vida y daño de v0.7 («no tiene sentido empezar individualmente más fuerte que luego»).
- **Reclutar:** casillas del mapa (2 por etapa garantizadas) y tras vencer al miniboss de la primera etapa. Te ofrecen 3 héroes del plantel que no tienes y eliges uno (o ninguno). Llegan a nivel del grupo con la vida llena y **los controlas tú**. Máximo 4. Con el grupo lleno, reclutar da oro.
- **Los modificadores de la run solo afectan al protagonista.** Se ofrecen los genéricos (sin etiqueta) y los que encajan con las etiquetas de las habilidades que **lleva** (nada de magia a un luchador físico ni de cuerpo a cuerpo a quien solo dispara). Cuando exista el equipamiento de habilidades, si te pones 3 de proyectil te saldrán modificadores de proyectil.
- **Mapa de etapa con bifurcaciones** (`RunMap`): 5 pasos por etapa de 2-3 casillas cada uno, unidas por caminos; el último es el miniboss. Tipos:
  - *Combate* (oro + XP)
  - *Élite* (más enemigos y +2 niveles: modificador + XP×1.5)
  - *Reclutar*
  - *Descanso* (+40% de vida, solo justo antes del miniboss)
  - *Miniboss* (modificador + recluta)
- **Objetivos opcionales** en algunos combates (35%), con premio extra si se cumplen (modificador + 10 oro):
  - *Proteger la carreta*: debe seguir en pie al ganar.
  - *Escapar*: llevar al protagonista a la zona turquesa del borde, lo que **gana el combate al instante**.
- **Escalado por tamaño de grupo:**
  - enemigos por combate 2/3/4/5 según el grupo (+1 en la etapa 2);
  - acompañantes del miniboss 0/1/2/3;
  - **mapas más pequeños con poca gente** (60% / 72% / 86% / 100% del tamaño de la zona).
- **Niveles:** los enemigos son nivel 1 en la etapa 1 y nivel 3 en la etapa 2 (+15% de estadísticas). Ya no suben en cada paso.
- **Equilibrio (simulaciones):** el grupo controlado por la IA gana ~37% de las runs (12/32), con un protagonista distinto del plantel cada vez.

**[Decidido v0.3, sustituido en v0.7] Estructura del prototipo de run** (`RunConfig` en `content/run/default_run.tres`, todo ajustable):

- **2 etapas × 4 fases.** Cada etapa toma una temática distinta al azar (Cueva, Bosque, Desierto). La **fase 4 de cada etapa es el miniboss** de la zona (+2 enemigos normales).
- **Recompensas:** las fases **pares** (2 y 4) dan **1 modificador a elegir entre 3 + XP**; las **impares** dan **oro + XP**. Reroll: 1 por elección, cuesta 5 de oro.
- **Grupo:** los 4 héroes (una por clase) van juntos. El **nivel es compartido** y sube con XP (40 XP para nivel 2, +25 por nivel); al subir, el grupo se cura un 25%.
- **La vida persiste entre fases.** Un héroe caído vuelve con el 25% de vida tras una victoria. Si cae todo el grupo, se pierde la run.
- **Oro:** sirve para rerollear y para curar al grupo (+50% de vida por 15 de oro) desde el mapa de la run.
- **Escalado:** los enemigos suben 1 nivel por fase y 3 por etapa, +12% de estadísticas por etapa, y cada etapa trae un enemigo más por combate.
- Pantallas: menú principal → mapa de run → combate → recompensa → ... → fin de run. También hay **combate rápido** (zona aleatoria) desde el menú.

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
- **[Decidido v0.3] Bonus de altura:** +5% de daño por cada nivel por encima del objetivo (`RulesConfig.height_damage_bonus`, 0 para desactivarlo).
- **[Decidido v0.3] Recursos por clase** (`UnitData.resource_kind`):
  - **Maná** (Maga): se gasta en habilidades y se regenera 4 por turno.
  - **Ira** (Guerrero y Asesina): empieza en 0 cada combate y llega hasta 100. Se gana **pegando** (+14 por golpe acertado) y **siendo golpeado** (+6 más un extra proporcional a la vida perdida). **Cuanta más ira, más daño:** +0,5% por punto (+50% con 100). Las habilidades fuertes **gastan ira**. Cada habilidad tiene un **umbral de mutación** (50-70): con la ira por encima, la habilidad se sustituye por su versión mutada (★), mucho más potente.
  - **Sin recurso** (Arquero): solo PA. Sus habilidades fuertes tienen **enfriamiento** (turnos de espera).

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

**[Decidido v0.3] Habilidades de movimiento** (`SkillData.motion`): `TELEPORT` (salta a una casilla libre ignorando alturas), `CHARGE` (corre en línea recta y golpea al llegar al lado del objetivo) y `BEHIND_TARGET` (aparece a la espalda del objetivo y golpea; necesita la espalda libre). Además, cualquier habilidad puede **empujar** (`knockback`): el objetivo se desplaza hasta chocar con un obstáculo, una unidad o una pared más alta que `max_climb` (las caídas sí se permiten).

**[Decidido v0.4] Estados alterados** (`StatusData` en `content/statuses/`, todo dato). Volver a aplicar un estado renueva su duración (no se acumula). Actúan al empezar el turno de la unidad afectada:

| Estado | Color | Efecto | Lo aplican |
|---|---|---|---|
| Quemado | rojo | −8% de la vida máxima por turno, 2 turnos | Bola de fuego, mod. *Munición incendiaria* |
| Envenenado | verde | −4% de la vida máxima −2 por turno, 3 turnos | Dagas, Lluvia de dagas, Escorpión, Bandido, mod. *Hojas envenenadas* |
| Ralentizado | azul | −2 PM y −35% de velocidad (actúa menos), 2 turnos | Lanza de hielo, Tiro certero, Raíces del Ent |
| Aturdido | icono de estrellas | pierde su próximo turno | Golpe brutal ★ (35%), Carga imparable ★, Pisotón del Ogro (40%), mod. *Golpe aturdidor* (al crítico) |
| Silenciado | icono de bocadillo tachado | solo puede usar el ataque básico, 2 turnos | Ejecución sombría ★ |

Las habilidades se pueden lanzar a casillas vacías (libertad total); solo las que lo exigen (carga, aparecer a la espalda) necesitan un enemigo como objetivo.

**[Decidido v0.3] Reglas de objetivo** (`SkillData.target_rule`): cualquier casilla, solo enemigos, solo casillas libres o uno mismo (alcance 0).

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

**[Decidido v0.3] Implementación (`ModifierData` + `ResolutionPipeline`):**

| Etapa | Efectos | Tipo |
|---|---|---|
| 1. Forma y trayectoria | `RANGE` (+alcance), `AREA_SIZE` (+área; una casilla pasa a rombo), `BOUNCE` (rebote, límite = saltos) | numérico / comportamiento |
| 2. Numéricos | `DAMAGE_FLAT`, `DAMAGE_PERCENT`, `COST_REDUCTION` (−maná/ira y −1 de enfriamiento por cada 10), `CRIT_CHANCE`, `RAGE_ON_HIT` | numérico |
| 3. Al impacto | `EXPLODE` (% del daño a los adyacentes, límite = radio), `KNOCKBACK`, `LIFESTEAL` | comportamiento |
| 4. Encadenados | los saltos de `BOUNCE` (hasta el enemigo más cercano a ≤3 casillas, sin repetir), con tope = límite | comportamiento |
| Al matar | `REFUND_AP` (recupera PA, límite = veces por turno) | comportamiento |

- **Disparadores:** `ALWAYS`, `ON_BACK_ATTACK`, `ON_CRIT`, `ON_KILL`. Los condicionales se evalúan golpe a golpe.
- El tipo (numérico o comportamiento) se **deduce del efecto**, así no puede haber datos incoherentes.
- La **mutación por ira se aplica antes** que los modificadores: los modificadores afectan también a la versión mutada.
- **Tabla de incompatibilidades:** `ModifierData.incompatible_with` (por id). Ejemplo: *Rebote* y *Detonación*. El primero que consigues se queda; las ofertas nunca te ofrecen algo incompatible con lo que tienes ni un comportamiento repetido.
- Las ofertas solo incluyen modificadores cuya etiqueta usa alguna habilidad del grupo.
- Pool actual: 25 modificadores en `content/modifiers/` (3 de estados en v0.4: `APPLY_STATUS`, se añade al final del enum para no romper datos guardados).

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

**[Decidido v0.3] Las 4 clases jugables del prototipo** (plantilla completa: básica, lanzamiento, área, movimiento):

| Personaje | Clase | Recurso | Básica | Lanzamiento | Área | Movimiento |
|---|---|---|---|---|---|---|
| Kael | Camorrista (v0.5) | Ira | Puñetazo → ★ Gancho brutal (50) | Lanzar escombros → ★ Pedrusco (60) | Ráfaga de golpes → ★ Trifulca (70) | Placaje → ★ Embestida de toro (50) |
| Nyx | Asesina táctica (v0.6) | Ira | Aguijón → ★ Doble aguijón (50) | Dardo de burla → ★ Dardo de rencor (60) | Nube tóxica → ★ Miasma (70) | Paso sombrío → ★ Ejecución sombría (50) |
| Lyra | Maga | Maná | Proyectil arcano (gratis) | Lanza de hielo (empuja) | Bola de fuego | Parpadeo (teletransporte) |
| Pablo | Arquero | Enfriamientos | Disparo (2-5) | Tiro certero (3-7, CD 2) | Lluvia de flechas (3x3, CD 3) | Voltereta (0 PA, CD 2) |

(El número entre paréntesis es la ira necesaria para la mutación.)

**[v0.5] Tohil, Chamán de fuego** (sprite de Neku; hombre): maná, muchísimo alcance, poco daño; su valor son los efectos.
- *Ascua* (básica, 2-6, 35% quemar) · *Lanzar tótem* (2-7, invoca un **Tótem de fuego**) · *Lluvia de brasas* (área 3-8, 70% quemar) · *Paso de humo* (teletransporte 2-5 que ralentiza a los adyacentes al llegar).
- **Tótem de fuego:** estructura (no juega turno, no cuenta para ganar/perder, el enemigo puede destruirlo; uno por chamán, lanzar otro destruye el anterior). **Aura** de radio 2: aliados con *Fervor* (+20% daño, +4% vida por turno), enemigos con *Humo asfixiante* (−1 PM, −15% velocidad, −3% vida por turno).
- Nuevas mecánicas genéricas: `SkillData.summon`, `UnitData.is_structure`, `UnitData.aura` (`AuraData`), estados positivos (`damage_percent_bonus`, `heal_percent_per_turn`, `silent`).

**[v0.5] Sigrid, Bárbara humana nórdica** (sprite de Neku; sin arma visible hasta que Neku pase las hachas a dos manos): ira; agresiva y arriesgada.
- *Tajo salvaje* (2 golpes rápidos, roba 15%) → ★ *Carnicería* (3 golpes, roba 25%) · *Hacha voladora* (2-4, empuja) → ★ *Tormenta de acero* (cruz) · *Remolino sangriento* (8 casillas, roba 30%, se vuelve **Temeraria**: +25% daño, −50% defensa) → ★ *Danza de la masacre* (2 giros) · *Salto aplastante* (salta 2-4 ignorando alturas, golpea alrededor y **lanza por los aires** = pierden el turno) → ★ *Caída del cielo* (3x3).
- Mecánicas genéricas nuevas: `SkillData.strikes` (golpes múltiples), `lifesteal_percent`, `self_status`; estados con `defense_percent_bonus` y tipo `KNOCKUP` (animación de salto).

**[v0.6] Nyx, Asesina táctica** (sprite de Neku): ira; golpea poco, se mueve muchísimo (6 PM, 14 vel.) y **todo lo que hace mete cargas de Toxina**.
- *Toxina*: estado acumulable (`StatusData.max_stacks` = 6). Cada carga quita 2% vida máx. + 2 por turno; las cargas multiplican el daño. Cada golpe de un ataque múltiple añade una carga. La previsión muestra «cargas 2 → 3» y el icono lleva el número.
- *Provocado* (`StatusData.taunts`): la unidad recuerda quién la provocó y la IA solo valora golpearle a él y solo se acerca a él, mientras viva y dure el estado.
- *Dardo de burla* (2-5, toxina + provoca) → ★ *Dardo de rencor* (cruz) · *Nube tóxica* (rombo) → ★ *Miasma* (rombo 2) · *Paso sombrío* (espalda, 2-6) → ★ *Ejecución sombría* (2 golpes + silencio).
- `SkillData.extra_statuses`: estados adicionales que se aplican siempre con el principal.

**[v0.6] Elara, Paladina elfa** (sprite de Neku): maná; tanque (130 PV, 8 def.), control, curas y golpes muy fuertes.
- *Golpe sagrado* (17, 25% aturdir) · *Lanza de luz* (línea 2-4, empuja, 60% aturdir) · *Resplandor* (rombo 2 a su alrededor: daña enemigos y **cura 20%** a aliados, ella incluida) · *Carga del juramento* (carga 2-5, empuja y se da **Égida** +60% defensa).
- Mecánica nueva: `SkillData.heal_percent` (cura % de la vida máx. a los aliados del área). La previsión pinta en verde a los curados y dice cuánto; la IA valora curar (`AiProfile.heal_weight`).

**[v0.6] Grizka, Goblin pistolera** (sprite de Neku): enfriamientos; atracadora rápida de poco alcance, cañón de cristal (62 PV, 1 def., 30% crít.).
- **Retroceso** (`SkillData.recoil`): tras disparar sale despedida N casillas en dirección contraria al objetivo; se para ante obstáculos, unidades o muros. La previsión dibuja la flecha verde y la casilla final; la IA puntúa la casilla final.
- *Quemarropa* (1-2, retroceso 1) · *Doble cañón* (línea 1-3, 2 tiros, retroceso 2, queda Temeraria) · *Abanico de plomo* (cruz, retroceso 1) · *Salto de pólvora* (1-2, retroceso 4: entrar, pegar y largarse).

**[Decidido v0.6] Taller de héroes y enemigos:** artefacto privado de Neku en claude.ai (fuente `tools/hero_workshop/taller.html`). Guarda en su base de datos un documento por héroe (`heroes/<id>`) y por enemigo (`enemies/<id>`, con categoría jefe / miniboss / normal, zonas, comportamiento, estadísticas y recompensas; Neku puede crear enemigos nuevos desde ahí): sprites de frente/lado/arma como paleta + filas (`.` = transparente), skills, pasivas, desbloqueables y arma. `tools/export_hero_sheets.gd` genera esos documentos desde el juego (`{heroes, enemies}`) y `tools/hero_workshop/import_sheets.py` trae de vuelta los sprites editados (regenerando las animaciones de Kael). Desde v0.6.1 los PNG de `assets/` retocados por Neku son la fuente; los scripts de `art/src/` ya no se vuelven a ejecutar sobre ellos; Claude lee los cambios de Neku y los pasa a `assets/` y `content/`.

**[Decidido v0.5, sustituido en v0.7: ahora se elige un único protagonista] Plantel y grupo:** `RunConfig.roster` (8 héroes: Kael, Pablo, Tohil, Nyx, Sigrid, Elara, Grizka, Lyra) y `party_size` 4. En el menú se eligen 4 haciendo clic en sus tarjetas; el combate rápido usa el mismo grupo.

**[Decidido v0.5.1] Personajes de Neku = jugables:** los sprites que pasa Neku son héroes del jugador, nunca enemigos. El grupo inicial son los cuatro suyos (Kael, Pablo, Tohil, Sigrid) para ir probándolos; Nyx y Lyra quedan en el plantel. Las armas las dibuja Neku: no se añaden armas inventadas a sus sprites.

**[v0.3] Enemigos por zona:** Cueva (Goblin, Murciélago, Limo; miniboss **Ogro de las cavernas**), Bosque (Lobo, Goblin arquero, Jabalí, Goblin; miniboss **Ent anciano**), Desierto (Escorpión, Bandido, Momia; miniboss **Gusano de arena**, que emerge a tu espalda).

**[v0.6.3] Desierto de Neku:** enemigos normales = **Trasgo con daga** (Puñalada trapera + *Pincha y huye*: pega y salta 2 atrás), **Trasgo con arco** (Flecha 2-5 que alcanza mucha altura + *Flecha lastrante* que ralentiza), **Trasgo brujo** (*Dardo de ponzoña* y *Nube de veneno*: cargas de toxina) y **Escorpión** (sprite nuevo de Neku a mitad de densidad; Aguijón + *Tenaza* 35% aturdir). Bandido y Momia salen del desierto (sus datos siguen en `content/units/enemies/`).

**[Decidido v0.6.3, Neku] Invocaciones (para todo el juego):**
- Una invocación la **controla quien la invoca**: si la invoca el jugador, la mueve el jugador; si la invoca un enemigo, la IA. Las estructuras (tótem) no juegan turno.
- **Si muere el invocador, mueren todas sus invocaciones** (y las de sus invocaciones). Matar al invocador gana el combate si solo quedaban sus invocaciones.
- `SkillData.summon_limit`: cuántas puede tener vivas a la vez; al pasarse, la nueva sustituye a la más antigua (tótem = 1).

**[v0.6.3] Miniboss del desierto: Troll elemental de arena** (sprite de Neku; sustituye al Gusano de arena, cuyos datos siguen en `content/`). Frágil (140 PV), rápido (5 PM, 12 vel.):
- *Alzar elemental*: un **Elemental de arena** por turno en una casilla libre a 1-3 (máx. 4 vivos).
- *Lanza de arena*: 3-6 casillas, 70% de **Hundido en arena** (-2 PM, 2 turnos).
- *Tránsito bajo la arena*: se teletransporta a 3-7 (enfriamiento 2) para escapar.
- IA `summoner`: guarda distancia y se **refugia entre sus elementales** (`AiProfile.ally_cover_weight`); usa el teletransporte cuando llega a un sitio claramente más seguro que andando.
- **Elemental de arena** (sprite de Claude, a retocar en el taller): nace débil (16 PV, 6 ATQ), pega a 1-2 casillas y **crece al moverse**: +2 PV máx. y +1 ATQ por casilla recorrida (`UnitData.hp_per_cell_moved` / `attack_per_cell_moved`). IA `swarm`: **foco compartido** (`AiProfile.shared_focus_weight`), todos van a por el último rival que golpeó su equipo (`CombatState.focus_target`).

**[v0.6.4] Bosque de Neku** (sprites de Neku; lobo, jabalí y goblin arquero salen del bosque, el goblin queda en la cueva):
- **Luchador del bosque**: rápido (6 PM); *Golpes veloces* (2 golpes) y *Acometida* (carga 2-4).
- **Asesina del bosque**: rapidísima, poco daño; *Puñal envenenado* y *Paso venenoso* (a la espalda): **crítico seguro contra envenenados** (`SkillData.crit_vs_status_kind`).
- **Berserker del bosque** (como Sigrid): *Hachas sedientas* (2 golpes, roba 35%) y *Salto salvaje* (salta 2-4, golpea alrededor, 50% por los aires, roba vida).
- **Viejo curandero**: no ataca, lento (2 PM) y frágil. *Savia lejana* (cura 30% a un aliado en cualquier parte del mapa), *Círculo de savia* (cura 20% en rombo 2 a su alrededor) y *Brisa del bosque* (**Prisa**: +2 PM, 2 turnos) cuando nadie necesita cura. IA `support`: se queda cerca de sus aliados.
- **Ratas** (relleno, 50% de crítico): **Ratilla** (pequeña, marrón, 6 PM), **Rata** (gris, 5 PM) y **Rata gorda** (negra, enorme, 3 PM, más vida). El tamaño sale de la densidad: la pequeña es el dibujo reducido a la mitad, la gorda el dibujo original.
- **Miniboss: Ent** (sustituye al Ent anciano; sprite de Neku a su resolución, 34x39). 340 PV, poco daño. *Rodar*: rueda en línea recta hasta el borde del mapa **por encima de cualquier altura u obstáculo**, arrollando una franja de 5 casillas (poco daño, 50% de lanzar por los aires); una vez por turno. Cada rodada le da una carga de **Rodando** (máx. 2, 2 turnos): recibe **el doble de daño** y su defensa baja a la mitad. Con 2 cargas puede gastar *Bombita de semillas* (alcance infinito, rombo, buen daño). *Golpe de raíz* cuerpo a cuerpo.
- Mecánicas genéricas nuevas: `Motion.ROLL`, `TargetRule.ALLY_UNIT`, `SkillData.ally_status` (buffs), `max_uses_per_turn`, `requires_status`/`requires_stacks` (gastar cargas), `StatusData.move_bonus` y `damage_taken_percent_bonus`. `CombatState.get_skill_area` calcula el área real de cualquier habilidad (también rodar).
- **Equilibrio:** con los primeros números el grupo de la IA ganaba 1-2 runs de 10; se bajó velocidad (13-14), ataque por nivel (1) y los golpes de luchador y asesina, y el salto del berserker pasó a 50%. Ahora ~4/10, como antes.

**[v0.7.1] IA de combos y prioridades** (para todos los enemigos y la IA del jugador):
- Cuenta el **daño esperado con críticos**: quien critica seguro contra envenenados va a por los envenenados (y así con cualquier `crit_vs_status_kind`).
- **Prepara combos:** aplicar un estado vale más si algún aliado puede explotarlo (crítico seguro contra ese tipo, vulnerabilidad, menos defensa) — `AiProfile.combo_weight`.
- **Prioridad de objetivos:** sanadores y apoyos primero (`support_target_weight`), y el protagonista del jugador es un objetivo apetecible (`protagonist_target_weight`), sin dejar de valorar remates y amenazas.

**[v0.8] Coreografías de habilidades (efectos):** cada habilidad puede tener una `SkillChoreography` (`SkillData.choreography`, datos en `content/vfx/`) hecha de pasos reutilizables (`scenes/battle/vfx/choreo/`):
- `SkyStep` (oscurecer y teñir cielo, luz, niebla volumétrica y brillo);
- `CameraStep` (foco, zoom cinematográfico y temblor);
- `TimeStep` (congelado de impacto y cámara lenta);
- `LightStep` (luz dinámica con sombras y parpadeo);
- `ParticlesStep` (partículas cuadradas tipo píxel: estallido, esfera, lluvia sobre el área o concentración);
- `ShockwaveStep`, `BeamStep` (proyectil con luz y estela) y `SlashStep`;
- `ScreenStep` (destello, aberración de color y viñeta teñida);
- `UnitStep` (desvanecer, reaparecer y cargar).

Fases: CAST → movimiento → ARRIVE → IMPACT (por golpe) → END, y al final se restaura todo. Muestra: Tiro certero (Pablo), Lluvia de brasas (Tohil), Salto aplastante (Sigrid) y Paso sombrío (Nyx). Pensado para el Mac (Forward+: niebla volumetrica y luces); en Compatibility se degrada sin romperse. `tools/vfx_showcase.gd` graba cada habilidad con el modo vídeo de Godot.

**[v0.7.1] Armería** (artefacto privado de Neku, fuente `tools/armory/armeria.html`): un documento por arma (`weapons/<id>`) con sprite pixel perfect, **punto de agarre**, delante/detrás del cuerpo, tipo, rareza, cómo se consigue, quién la puede llevar, ataque básico que da, pasiva y cambios de estadísticas. Cada héroe tiene marcada su **mano** de frente y de lado (`hands/<heroe>`), y la armería enseña el arma colocada en su mano. **[v0.8.2]** La colocación es **por vista** (`pose.front` / `pose.side`): giro en pasos de 15°, tamaño ×0.25-×3, voltear y delante/detrás del cuerpo. La prueba se compone a la resolución real del juego (muestreo al píxel más cercano) para ver cómo queda el arma girada. Organizada **por tipo de arma** (pestañas: Puños, Daga, Espada, Sable, Mandoble, Hacha, Hacha a dos manos, Martillo, Arco, Pistola, Bastón, Varita, Manos (magia)); cada tipo lista todos sus diseños.
- **[v0.8.1, Neku] Armas iniciales «cutrillas»** (para que luego se note el contraste): Hacha de leñador, Hacha a dos manos oxidada (Sigrid), Daga oxidada (Nyx), Mandoble de hierro (Elara), Espada corta, Arco de caza (Pablo) y Pistola de chispa (Grizka).
- **Los magos empiezan sin bastón:** Tohil y Lyra lanzan la magia con las manos (tipo «Manos (magia)»). Kael pelea con los puños.
- Sprites recuperados de las imágenes de Neku y ajustados a la escala del juego con `art/src/fit_weapon.py` (reduce, vuelve a la paleta original y redibuja el contorno); la cuerda del arco se dibuja aparte (`art/src/bow_string.py`). Copias en `assets/sprites/weapons/`.

**[v0.6.3] Anti-bloqueo de la IA:** `CombatState.turns_without_damage` cuenta los turnos seguidos sin que nadie pierda vida; el miedo de la IA a las casillas amenazadas baja hasta 0 en `AiProfile.patience_turns` (8) turnos. Evita empates eternos de dos bandos esperando en el borde del alcance del otro.

## 7. Compañeros

- Son personajes preset con personalidad y rol definido, de la misma pool que los personajes jugables.
- **Roles base:** tanque, sanador, daño a distancia, control. Cada compañero encaja en uno.
- **Obtención:** uno al empezar la run, y uno nuevo al completar cada piso. Elegir entre 2-3 ofrecidos.
- **Límite en combate:** máximo 3 aliados activos. Los demás quedan en reserva y se cambian entre combates.
- **IA:** reglas de decisión por rol (prioridades simples: el sanador cura al aliado más bajo, el tanque se interpone, etc.). No se programa un comportamiento distinto por personaje.
- Los compañeros no persisten entre runs, pero los que hayas visto pueden salir de nuevo en futuras runs.
- **[Decidido v0.6, Neku] Los compañeros son nuestros propios héroes jugables** (Kael, Pablo, Tohil, Nyx, Sigrid, Elara, Grizka...), no personajes aparte. Un compañero es el mismo `UnitData` que el héroe, con su kit, su sprite y su arma.
- **[Decidido v0.6, Neku] Progresión bilateral:** lo que mejoras de un personaje en la meta (maestría, habilidades y pasivas desbloqueadas, arma) lo lleva también cuando aparece como compañero en mitad de una run. Si mejoras a Elara jugando con ella, la Elara que te encuentres como aliada será mejor.
- **Propuesta v0.6 (pendiente de confirmar):**
  - El compañero aparece **al nivel actual de la run** y con la progresión de cuenta de ese personaje; no trae los modificadores de run (esos son del grupo que empezó).
  - Solo pueden salir como compañeros los héroes que **no** están en tu grupo.
  - La progresión va también en sentido contrario: los combates que gana un personaje como compañero le dan **maestría reducida** (p. ej. 50%) para la meta. Así usarlo como aliado también lo mejora.
  - Lo controla la IA con un perfil por rol (`AiProfile`). Opción a decidir: que el jugador pueda controlarlo.
- **[Decidido v0.4] IA táctica** (`BasicAI` + `AiProfile` en `content/ai/`). Cada decisión:
  1. Calcula un **mapa de amenaza**: cuánto daño podrían hacer los rivales a cada casilla el turno siguiente (su movimiento + alcance + daño).
  2. Puntúa cada combinación **moverse + habilidad + objetivo**: daño esperado, bonus por **matar**, por rematar **heridos** (focus fire), por quitar de en medio a los **peligrosos** (más ataque), por aplicar **estados**, menos el coste del recurso y menos la **amenaza** de la casilla donde acaba.
  3. Si no puede atacar, se **recoloca**: los melee avanzan, los de distancia **mantienen la distancia** y nadie se queda donde lo pueden reventar si lo puede evitar. Busca la **espalda** de forma natural (más daño).
  - Perfiles: `melee_aggressive` (goblin, limo, momia, jabalí), `skirmisher` (lobo, murciélago, escorpión, bandido), `ranged` (goblin arquero, distancia 4), `boss` (casi ignora el peligro, foco total).
  - La misma IA juega por el jugador en el autoplay, así que las simulaciones son una referencia exigente.
  - **[v0.6.2] Casillas de ataque:** cuando no puede atacar este turno, la IA calcula todas las casillas desde las que alguna de sus habilidades alcanzaría a un rival (alcance + área, diferencia de altura ≤ alcance vertical, línea recta si hace falta) y se acerca a la más cercana andando (Dijkstra multi-origen). Si no hay ninguna alcanzable, al menos reduce la distancia en línea recta.
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
- **[Decidido v0.3] Generador procedural (`MapGenerator`)**, determinista por semilla, parametrizado por `ZoneData`:
  - **Tamaño** aleatorio por zona: 19-24 × 14-18 (casi el doble que la arena de M0), siempre más ancho que alto.
  - **Bosque:** colinas por ruido (0-4 niveles); un **río** cruza el eje corto con orillas en pendiente (forma un valle); arboledas agrupadas por ruido; las cimas son roca; una **senda** de tierra de oeste a este que vadea el río.
  - **Desierto:** dunas suaves; 2-4 **mesetas** de arenisca altas (3-6 niveles) de contorno irregular, cada una con una **rampa** escalonada para subir; a veces un **oasis** con orilla de hierba; cactus y rocas dispersos.
  - **Cueva:** muros de roca por **autómata celular** (bordes cerrados, pilares interiores), solo la región abierta más grande; muros solo un poco más altos que el suelo para que no tapen; manchas de roca húmeda; **pozas** junto a los muros; estalagmitas y cristales.
  - **Spawns:** jugadores en la franja oeste y enemigos en la este (el mapa se refleja al azar).
  - **Garantía de conectividad:** se comprueba con las reglas reales de movimiento que todos los spawns se alcanzan entre sí; si no, se excava el camino más barato y se suavizan sus alturas.
  - Cada zona define además su luz (fondo, ambiente, sol) y su pool de enemigos y minibosses.
  - Decorado: cada terreno puede tener un `prop_scene` (árbol, cactus, roca, estalagmita, cristal).

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

**[Decidido v0.4] Feedback antes de confirmar (flechas y colores):**

- Casillas: **azul** = alcanzable, **azul claro** = camino, **amarillo tenue** = alcance de la habilidad, **rojo** = zona de daño (si solo afecta a una casilla, solo esa), **verde** = dónde aterrizas, **naranja** = dónde acaba un objetivo empujado.
- **Flechas en parábola** que se mueven en tiempo real (siguen al ratón suavemente, trazo discontinuo animado):
  - **Verde**: tu movimiento y el de las habilidades de movimiento.
  - **Roja**: tu ataque (desde donde golpearás tras moverte si la habilidad te mueve).
  - **Naranja**: empujes. Si el empuje **se corta** por un obstáculo, la flecha acaba donde se queda y aparece una **✕ roja** en lo que lo bloquea.
  - **Amarilla**: la cadena de **rebotes** prevista.
  - **Gris**: movimiento **a medias**. Si apuntas fuera de tu alcance, la flecha verde llega hasta donde te dan los PM y la gris sigue hasta donde querías; al hacer clic te mueves lo máximo posible por ese camino.
- Los **enemigos también enseñan sus flechas** un instante antes de actuar.
- **Ficha de previsión** por objetivo: lado, daño (y crítico), vida antes → después, golpe y crítico, estados que aplicará con su probabilidad, empuje (y si se corta) y rebotes. Si hay varias, se colocan en fila sin taparse.
- **Panel de habilidad** al seleccionarla: tipo, coste, etiquetas, descripción, alcance, área, efectos y modificadores que la afectan.

**[Decidido v0.4] Efectos visuales (placeholder):** cada habilidad tiene `vfx_style` (tajo, proyectil, proyectil en parábola, nova o automático) y `vfx_color`. Proyectiles con estela y luz, explosiones con chispas + onda + destello, tajos en arco, una explosión pequeña en cada casilla del área, sacudida de cámara en críticos y explosiones, números flotantes, textos de estado ("¡Quemado!"), **tinte del sprite** del color del estado e **iconos de estado** sobre la cabeza.

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
  ai/        BasicAI (táctica, v0.4), AiAction
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

- **[v0.3]** Nuevas carpetas: `core/mapgen/` (`MapGenerator`), `core/run/` (`RunState`, `HeroState`, `ModifierOffer`), `scenes/app/` (autoload `Game` = `GameSession`, único sitio que cambia de escena), `scenes/menu/`, `scenes/run/` (mapa de run, recompensa, fin) y `scenes/ui/components/` (tarjetas reutilizables). `EffectiveSkill` es la habilidad ya resuelta (mutación + modificadores) que usan targeting, previsión y resolución.

- **[v0.2]** `BattleController` (raíz de `battle.tscn`) crea el `CombatState` desde un `BattleSetup`, instancia las vistas y lleva el bucle de turnos. `PlayerTurnInput` y la IA llaman a los mismos `execute_move/skill/end_turn`, que aplican el comando a las reglas y esperan (`await`) la animación correspondiente. `BattleHud` es una fachada sobre los widgets del HUD, cada uno en su propia escena.

**Mapa:** ~~`TileMapLayer` para el suelo y los bloques.~~ **[Decidido v0.2]** El mapa es 3D real (como en la referencia): `BattleMapView` dibuja una columna por casilla con `MultiMeshInstance3D` (un draw call para todo el terreno sólido y otro para el agua). El picking del ratón es analítico (rayo contra la caja de cada columna), sin físicas. Grafo 3D (x, y, altura) para pathfinding con escaleras, pozos y rampas, en lugar de `AStarGrid2D` plano: hoy `Pathfinder` (Dijkstra) trabaja sobre (x, y) con altura por casilla; los planos (§9) añadirán la tercera coordenada.

**Persistencia:** `Resource` serializados o JSON para el progreso de cuenta. Guardado tras cada combate y cada desbloqueo.

**Tests:** las reglas de la sección 5 y el pipeline de modificadores deben ser testeables sin escena. Es lo primero que se prueba.

- **[v0.2]** Runner propio sin dependencias (`tests/test_runner.gd`): cualquier `tests/unit/test_*.gd` que extienda `TestCase` se ejecuta; un error de script durante un test cuenta como fallo. Test de integración `tests/integration/autoplay_battle.gd`: juega el combate entero con IA en ambos bandos y falla si no termina o hay errores. CI en GitHub Actions ejecuta ambos en cada push.
- **[v0.4.1]** Arte: cada unidad puede tener vista frontal (`sprite`) y de lado (`sprite_side`, mirando a la derecha). Si mira hacia la cámara se usa la frontal; si se aleja, la de lado volteada según la dirección. Kael usa el sprite de Neku (guerrero que pelea a puños).
- **[v0.3]** `tests/integration/autoplay_run.gd` simula runs completas solo con reglas (rápido, imprime estadísticas de balance) y `tests/integration/autoplay_ui_run.gd` recorre las pantallas reales de punta a punta (con pantalla o Xvfb guarda una captura de cada una).

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
- ~~**Compañeros con kit propio:**~~ → resuelto en v0.6: los compañeros son los mismos héroes jugables, con progresión bilateral (§7).
- **[v0.6] Compañeros:** ¿los controla la IA o el jugador? ¿Cuentan dentro del grupo de 4 o van aparte (máx. 3 aliados activos)? ¿Usarlos como aliados les da maestría (y cuánta)?
- **Cuenta de energía o límite de partidas:** no definido. Probablemente no hace falta.
- **Nombre del juego:** provisional "Greed Tactics" (nombre del repositorio). Confirmar.
- **[v0.2] Línea de visión:** ¿los proyectiles se bloquean con bloques altos o unidades en medio? Hoy no hay línea de visión, solo alcance vertical.
- ~~**[v0.2] Bonus de altura**~~ → resuelto en v0.3: +5% de daño por nivel de ventaja (configurable).
- **[v0.2] Coste del ataque básico:** el GDD dice "sin coste o coste mínimo". Con 0 PA sería infinito; hoy cuesta 1 de 2 PA (dos ataques por turno). Validar en M1 con la duración de combate.
- **[v0.2] Orientación al esperar:** hoy se elige a mano al terminar. ¿Automática hacia el enemigo más cercano para ir más rápido (pilar 1), con opción de cambiarla?
- **[v0.2] Agua:** hoy es transitable (2 PM). ¿Agua profunda intransitable / que impida atacar?
- **[v0.3] Arquero:** se interpretó "el arquero no (usa maná ni ira)" como **enfriamientos**. Confirmar o proponer otro recurso (munición, concentración...).
- **[v0.3] Fase del miniboss:** hoy el miniboss es la fase 4 (4 combates por etapa, 8 por run). ¿O el miniboss debe ser un 5º combate aparte?
- **[v0.3] Grupo:** hoy los 4 héroes van siempre juntos. ¿Se elige 1 personaje principal + compañeros (GDD §7)?
- **[v0.3] Curación entre fases** con oro: ¿se mantiene o se sustituye por otra cosa (tienda, eventos)?
- **[v0.4] Dificultad:** "el juego tiene que ser jodido". Con la IA táctica jugando por el jugador, la run se gana ~40% de las veces (los minibosses son el gran filtro) y los combates duran 30-90 turnos de unidad. Validar a mano; se ajusta en `content/run/default_run.tres` (nivel base 3, +2 niveles por fase, +3 por etapa, +25% de estadísticas por etapa, 4-5 enemigos por fase, miniboss + 3).

## Changelog

- **v0.8 (Nov 6, 2026)** — Coreografías de habilidades: cielo, cámara, tiempo, luces dinámicas, partículas pixeladas, ondas, proyectiles con estela y efectos de pantalla, como datos. Muestra con 4 habilidades (2 cuerpo a cuerpo, 1 magia, 1 distancia).
- **v0.7.1 (Nov 5, 2026)** — El protagonista pasa a tener +1 PM y +1 PA siempre (fuera el bonus de vida y daño). IA de combos (daño esperado con críticos, preparar estados que los aliados explotan) y prioridad a sanadores y al protagonista. Armería: artefacto para dibujar armas, marcar el agarre y la mano de cada héroe y definir sus cualidades.
- **v0.7 (Nov 5, 2026)** — Nuevo bucle de run (decisión de Neku): un protagonista, reclutas que controlas tú, mapa de etapa con bifurcaciones (combate, élite, reclutar, descanso, miniboss), objetivos opcionales (proteger la carreta, escapar), Lobo solitario, modificadores solo para el protagonista, mapas y enemigos según el tamaño del grupo. Pantallas nuevas: mapa de run con caminos, reclutar; menú de protagonista; panel de objetivo y estrella del protagonista en combate. Arreglado: la semilla de la run ya da siempre el mismo mapa.
- **v0.6.4 (Nov 4, 2026)** — Bosque de Neku: luchador, asesina, berserker, viejo curandero, tres ratas y el **Ent** que rueda. Mecánicas: rodar, objetivo aliado, buffs, usos por turno, cargas que se gastan, crítico seguro por estado, prisa, vulnerabilidad. Arreglado: el troll podía invocar dos elementales por turno (ahora `max_uses_per_turn` = 1).
- **v0.6.3 (Nov 4, 2026)** — Desierto de Neku (trasgos con daga, arco y brujo; escorpión nuevo) y su miniboss **Troll elemental de arena** con **Elementales de arena**. Reglas nuevas para todo el juego: las invocaciones las controla su invocador, mueren con él y tienen límite (`summon_limit`); crecimiento al moverse; foco compartido; refugio entre aliados; la IA escapa con teletransportes. IA anti-bloqueo (`patience_turns`). `autoplay_battle.gd` acepta zona y enemigos (`-- desert sand_troll,trasgo_dagger`).
- **v0.6.2 (Nov 4, 2026)** — Tras la primera partida larga de Neku: menú de acciones en dos páginas (**1 Mover · 2 Atacar · 3 Esperar**; Atacar abre las habilidades 1-6; Esc vuelve atrás), sin bocadillos (solo el marco de la habilidad, también al pasar el ratón por el botón); al elegir una habilidad se ve su rango al momento y, si es sobre uno mismo o tiene una sola casilla posible, su zona y la previsión sin mover el ratón (se lanza pulsando otra vez su tecla, Enter o clic). **Subir escalones ya no cuesta PM extra** (`climb_up_cost` = 0 en las reglas). La IA busca las **casillas desde donde puede atacar** (alcance, área, altura, línea recta) y camina hacia ellas: encuentra rampas y no se queda huyendo cuando el jugador está en alto.
- **v0.6 (Nov 3, 2026)** — Tres heroínas de Neku: **Nyx** rehecha como asesina táctica (toxina acumulable y provocación), **Elara** paladina elfa (curas en área, aturdimientos, Égida) y **Grizka** goblin pistolera (retroceso). Mecánicas genéricas: `max_stacks`, `taunts`, `extra_statuses`, `heal_percent`, `recoil`. Plantel de 8; el menú muestra las tarjetas en rejilla de 4 columnas con la descripción como tooltip. `autoplay_run.gd` acepta un grupo (`-- 5 nyx,paladin,gunner,shaman`).
- **v0.5.1 (Nov 3, 2026)** — Correcciones de Neku: Pablo sin tatuajes tribales y con los aros pegados a la oreja; Sigrid sin el hacha añadida (las armas las pasará Neku); el chamán es hombre y se llama **Tohil**; grupo inicial = Kael, Pablo, Tohil, Sigrid.
- **v0.5 (Nov 3, 2026)** — Personalidad: Kael pasa a ser **Camorrista** (pelea a puños: Puñetazo, Lanzar escombros, Ráfaga de golpes, Placaje y sus mutaciones Gancho brutal, Pedrusco, Trifulca, Embestida de toro; mod. *Nudillos de hierro*). Sprites de Neku para Kael y Pablo (frente + lado) y **animaciones** de Kael (reposo, andar, puñetazo, golpe recibido) con `SpriteFrames`. Terrenos con textura procedural por tipo (hierba con laterales de tierra, roca agrietada, dunas, sendero con guijarros, cueva húmeda), bisel y oclusión; decoración (matojos, flores, guijarros, arbustos secos, setas luminosas); niebla, ángulo de sol, glow y partículas por zona (luciérnagas, polvo, motas); cristales que iluminan; viñeta.

- **v0.4 (Nov 3, 2026)** — Game feel: flechas de previsión en parábola (movimiento, ataque, empuje, rebotes, movimiento a medias), zona de daño en rojo, aterrizaje en verde, marca de bloqueo; efectos visuales placeholder por habilidad; 5 estados alterados con tinte e iconos; ficha de previsión ampliada y panel de habilidad; IA táctica con mapa de amenaza y perfiles; dificultad subida.

- **v0.3 (Nov 2, 2026)** — Prototipo de run: 4 clases jugables (Guerrero y Asesina con ira y mutaciones, Maga con maná, Arquero con enfriamientos) con la plantilla de 4 habilidades; habilidades de movimiento (teletransporte, carga, aparecer a la espalda) y empuje; `ModifierData` + `ResolutionPipeline` con el orden fijo de §5 y 22 modificadores; generador procedural de mapas para Cueva, Bosque y Desierto; 12 enemigos y 3 minibosses; run de 2 etapas × 4 fases con recompensas (modificador en pares, oro en impares), XP, nivel, vida persistente y curación; menú, mapa de run, recompensas y fin de run; bonus de altura.

- **v0.2 (Nov 2, 2026)** — Arranque del proyecto en Godot 4.7.2. Añadidas las decisiones de implementación de M0 (marcadas **[Decidido v0.2]**): sistema de turnos CT, costes de altura, terreno, paso entre aliados, fórmulas de daño/golpe/crítico, regla exacta de espalda, comandos del HUD. Mapa 3D con MultiMesh en lugar de `TileMapLayer`. Estructura de carpetas, runner de tests e integración continua. Nuevas preguntas abiertas. Roadmap y backlog movidos a documentos propios.
- **v0.1 (Nov 2, 2026)** — Documento inicial.
