# Greed Tactics

Roguelike táctico isométrico 2.5D por turnos, hecho con **Godot 4.7.2**.
Combate rápido y legible, runs generadas por zonas y personajes que se vuelven tuyos a base de jugarlos.

![estado](https://img.shields.io/badge/prototipo-v0.3%20run%20jugable-blue)

## Documentación

| Documento | Para qué |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | Diseño del juego (documento vivo, con changelog) |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Hitos M0-M5 y su estado |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Tareas priorizadas (`GT-xxx`) |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | Normas de código, escenas, contenido y git |

## Cómo abrirlo

1. Instala **Godot 4.7.2** (versión estándar, no hace falta .NET).
2. Clona el repo y abre `project.godot` desde el gestor de proyectos.
3. Pulsa **F5**: arranca el menú principal.
   - **Nueva run:** 2 etapas × 4 fases con mapas procedurales (Cueva, Bosque, Desierto) y miniboss en la fase 4. Las fases pares dan un modificador a elegir entre 3; las impares, oro. Siempre XP.
   - **Combate rápido:** un combate suelto en una zona aleatoria.
   - Para probar solo el combate: abre `scenes/battle/battle.tscn` y pulsa **F6** (usa `content/battles/quick_battle.tres`, mapa aleatorio de bosque).
   - Depuración: en `scenes/app/game.tscn` activa `autoplay_battles` para que la IA juegue también por ti.

## Clases jugables

| Héroe | Clase | Recurso | Idea |
|---|---|---|---|
| Kael | Guerrero | Ira | Primera línea: carga, torbellino, hacha arrojadiza |
| Nyx | Asesina | Ira | Aparece a la espalda, críticos, dagas |
| Lyra | Maga | Maná | Daño a distancia, bola de fuego, parpadeo |
| Pablo | Arquero | Enfriamientos | Alcance largo, lluvia de flechas, voltereta gratis |

**Ira:** empieza en 0, se gana pegando y recibiendo golpes, aumenta el daño (+0,5% por punto) y se gasta en habilidades. Por encima de cierto umbral (50-70), cada habilidad **muta** en una versión mucho más fuerte (★ en el menú de comandos).

## Controles

| Acción | Control |
|---|---|
| Seleccionar casilla / confirmar | Clic izquierdo |
| Cancelar / volver | Clic derecho o Esc |
| Comandos (Mover, 4 habilidades, Esperar) | Botones o teclas 1-6 (pasa el ratón por encima para ver la descripción y los modificadores) |
| Terminar turno en modo orientación | Clic o Enter |
| Rotar cámara | Q / E |
| Zoom | Rueda del ratón |
| Mover cámara | WASD, flechas o arrastrar con botón central |
| Centrar en la unidad activa | Espacio |

## Estructura

```
core/       Reglas puras, sin nodos: datos, grid, combate, pipeline de modificadores, IA, generador de mapas, run.
content/    Datos del juego en .tres: terrenos, zonas, unidades, habilidades, modificadores, reglas, run, combates.
scenes/     Escenas y sus scripts: app (autoload Game), menú, run, combate, mapa, props, unidades, cámara, HUD, UI.
assets/     Fuentes, shaders y sprites.
tests/      Tests unitarios e integración (runner propio, sin plugins).
tools/      Utilidades (generar sprites, re-guardar recursos).
docs/       GDD, roadmap, backlog y convenciones.
```

### Añadir contenido sin tocar código

- **Nuevo enemigo:** duplica un `.tres` de `content/units/enemies/`, cambia stats, sprite y habilidades, y añádelo al `enemy_pool` (o `miniboss_pool`) de una zona en `content/zones/`.
- **Nueva habilidad:** duplica una de `content/skills/` y ajusta tipo, etiquetas, costes (PA, maná, ira, enfriamiento), alcance, área, movimiento, empuje y poder. Para una mutación por ira, asigna otra habilidad a `empowered_variant` y su umbral.
- **Nuevo modificador:** duplica uno de `content/modifiers/` (etiqueta objetivo, disparador, efecto, valor, límite, incompatibilidades) y añádelo a `modifier_pool` de `content/run/default_run.tres`.
- **Nueva zona:** duplica una de `content/zones/`: terrenos por rol (suelo, alternativo, alto, líquido, orilla, obstáculos, muros), tamaño, alturas, densidades, luz y enemigos. Elige el `layout` (bosque, desierto o cueva) y añádela a `zones` de la run.
- **Nuevo terreno:** crea un `TerrainData` con un `symbol` libre (único dentro de su zona) y, si quieres, un `prop_scene` de `scenes/battle/props/`.
- **Mapa a mano:** como `content/maps/test_arena.tres` (filas de texto de terreno y alturas).
- **Run:** `content/run/default_run.tres` controla etapas, fases, recompensas, escalado de enemigos, XP y costes.

## Tests

```bash
godot --headless --import
godot --headless --script res://tests/test_runner.gd
godot --headless --script res://tests/integration/autoplay_battle.gd
godot --headless --script res://tests/integration/autoplay_run.gd -- 5      # simula 5 runs y muestra balance
godot --headless --script res://tests/integration/autoplay_ui_run.gd        # recorre todas las pantallas
godot --headless --script res://tests/integration/player_input_smoke.gd     # prueba el input del jugador
```

GitHub Actions los ejecuta en cada push y pull request.

## Créditos

- Fuente [Nunito](https://fonts.google.com/specimen/Nunito) — SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
