# Greed Tactics

Roguelike táctico isométrico 2.5D por turnos, hecho con **Godot 4.7.2**.
Combate rápido y legible, runs generadas por zonas y personajes que se vuelven tuyos a base de jugarlos.

![estado](https://img.shields.io/badge/hito-M0%20prototipo%20de%20grid-blue)

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
3. Pulsa **F5**: arranca el combate de prueba (`scenes/battle/battle.tscn`).

## Controles

| Acción | Control |
|---|---|
| Seleccionar casilla / confirmar | Clic izquierdo |
| Cancelar / volver | Clic derecho o Esc |
| Comandos (Mover, habilidades, Esperar) | Botones o teclas 1-6 |
| Terminar turno en modo orientación | Clic o Enter |
| Rotar cámara | Q / E |
| Zoom | Rueda del ratón |
| Mover cámara | WASD, flechas o arrastrar con botón central |
| Centrar en la unidad activa | Espacio |

## Estructura

```
core/       Reglas puras, sin nodos (datos, grid, combate, IA). Testeable.
content/    Datos del juego en .tres: terrenos, mapas, unidades, habilidades, reglas, combates.
scenes/     Escenas y sus scripts: combate, mapa, unidades, cámara, HUD.
assets/     Fuentes, shaders y sprites.
tests/      Tests unitarios e integración (runner propio, sin plugins).
tools/      Utilidades (generar sprites, re-guardar recursos).
docs/       GDD, roadmap, backlog y convenciones.
```

### Añadir contenido sin tocar código

- **Nueva unidad:** duplica `content/units/goblin.tres`, cambia stats, sprite y habilidades, y añádela a un `BattleSetup` de `content/battles/`.
- **Nueva habilidad:** duplica `content/skills/slash.tres` y ajusta tipo, coste, alcance, área y poder.
- **Nuevo mapa:** duplica `content/maps/test_arena.tres`. Cada fila de `terrain_rows` es una fila del mapa (un carácter por casilla: `g` hierba, `s` piedra, `w` agua) y `height_rows` su altura (`0-9`).
- **Nuevo terreno:** crea un `TerrainData` con un `symbol` libre y añádelo a `terrains` del mapa.

## Tests

```bash
godot --headless --import
godot --headless --script res://tests/test_runner.gd
godot --headless --script res://tests/integration/autoplay_battle.gd
```

GitHub Actions los ejecuta en cada push y pull request.

## Créditos

- Fuente [Nunito](https://fonts.google.com/specimen/Nunito) — SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
