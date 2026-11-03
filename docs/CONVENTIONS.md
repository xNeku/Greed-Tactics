# Convenciones de código y contenido

## Principios

1. **Datos fuera del código.** Todo lo que diseño quiera tocar (stats, habilidades, mapas, reglas) es un `Resource` en `content/`. Si añadir contenido obliga a tocar código, es un bug de arquitectura.
2. **Reglas separadas de la presentación.** `core/` no conoce nodos ni escenas: solo `RefCounted` y `Resource`. Las escenas (`scenes/`) leen el estado y escuchan señales; nunca al revés.
3. **Lo que ves es lo que pasa.** La previsión del HUD y la resolución usan las mismas funciones (`CombatState.preview_skill`).
4. **Testeable sin escena.** Toda regla nueva en `core/` llega con su test en `tests/unit/`.

## Carpetas

| Carpeta | Qué va | Qué NO va |
|---|---|---|
| `core/data/` | Scripts de definición de `Resource` (`class_name XxxData`) | Instancias `.tres` |
| `core/grid/`, `core/combat/`, `core/ai/`, `core/mapgen/`, `core/run/` | Reglas puras | Nodos, `get_tree()`, escenas |
| `content/` | `.tres` de contenido | Scripts |
| `scenes/` | `.tscn` + su `.gd` en la misma carpeta | Reglas de juego |
| `assets/` | Fuentes, shaders, sprites, audio | Scripts de juego |
| `tests/` | Tests unitarios (`unit/`) e integración (`integration/`) | |
| `tools/` | Scripts de soporte (no se cargan en el juego) | |

## GDScript

- Godot **4.7.2**, GDScript con **tipado estático en todo** (`var x: int`, `func f() -> void`, `Array[UnitState]`, `Dictionary[Vector2i, int]`).
- Identificadores y comentarios de código **en inglés**; documentación y textos de UI **en español**.
- Nombres: `PascalCase` para clases y nodos, `snake_case` para archivos, funciones y variables, `UPPER_SNAKE_CASE` para constantes. Privado = prefijo `_`.
- Un `class_name` por archivo; el archivo se llama como la clase en `snake_case`.
- Orden dentro de un script: `class_name` / `extends` / doc `##` / señales / enums / constantes / `@export` / `@onready` / variables públicas / privadas / `_init` y `_ready` / métodos públicos / privados. Agrupa con `#region` cuando ayude.
- Comentarios de documentación con `##` (salen en la ayuda del editor).
- Nodos que el script necesita: `%NombreUnico` (unique name) o `$Ruta` corta. Nada de rutas largas frágiles.
- Comunicación hacia arriba con **señales**; hacia abajo con llamadas a métodos.
- Animaciones de presentación como corrutinas (`await`) que el controlador espera.
- Sin números mágicos de reglas en código: van a `RulesConfig` o al `Resource` correspondiente.

## Escenas

- Cada componente reutilizable es su propia escena (`unit_view.tscn`, `command_menu.tscn`...).
- Estilos de UI en `scenes/ui/theme/ui_theme.tres` mediante *type variations* (`TopBar`, `HeaderLabel`...), no con overrides sueltos.
- Si editas `.tscn`/`.tres` a mano, ejecuta `tools/resave_resources.gd` para dejarlos en formato del editor.

## Contenido

- **Mapas:** `MapData` con `terrain_rows` (un carácter por casilla = `TerrainData.symbol`) y `height_rows` (`0-9`, luego `a-z`). Spawns en orden de la plantilla. `MapData.validate()` se ejecuta al cargar el combate.
- **Unidades:** `UnitData`. Sprite pixel art mirando a la **derecha**, pies en el borde inferior.
- **Habilidades:** `SkillData` con tipo de la plantilla y etiquetas en minúsculas sin tildes (`basico`, `lanzamiento`, `area`, `movimiento`, `proyectil`, `melee`, `fuego`, `hielo`, `arcano`, `flecha`, `daga`, `hacha`, `sombra`...). Las mutaciones por ira llevan ★ en el nombre y el mismo tipo que la original.
- **Modificadores:** `ModifierData` con id único en `snake_case`; las incompatibilidades se referencian por id.
- **Zonas:** `ZoneData`; los símbolos de terreno deben ser únicos dentro de la zona (hay test).
- **Sprites de Neku:** se reconstruyen pixel perfect y se guardan como `<id>.png` (frente) y `<id>_side.png` (lado, mirando a la derecha), pies en el borde inferior. Los retoques viven en `art/src/<id>_sprites.py`.
- **Animaciones:** `art/src/<id>_animations.py` genera `<id>_sheet.png` + `.json`; `godot --headless --script res://tools/build_sprite_frames.gd -- <sheet.png> <salida.tres>` crea el `SpriteFrames` que se asigna a `UnitData.sprite_frames`. Nombres: `<estado>_<vista>` (idle/walk/attack/hit × front/side).
- **Sprites provisionales:** se regeneran con `python3 tools/generate_placeholder_sprites.py` (ASCII art, con intercambio de paleta `art_of` y espejo `flip`).

## Git

- Ramas: `main` estable; trabajo en ramas `claude/<tema>` o `feature/<tema>`.
- Commits en español, imperativo y con el ID del backlog cuando aplique: `GT-013: añade ModifierData`.
- Se versionan `.uid` e `.import` (Godot 4.4+). No se versiona `.godot/`.

## Tests

```bash
godot --headless --import
godot --headless --script res://tests/test_runner.gd
godot --headless --script res://tests/integration/autoplay_battle.gd
godot --headless --script res://tests/integration/autoplay_run.gd -- 5
godot --headless --script res://tests/integration/autoplay_ui_run.gd
godot --headless --script res://tests/integration/player_input_smoke.gd
```

- `tests/unit/test_*.gd` extiende `TestCase`; cada `func test_*()` se ejecuta en una instancia nueva tras `before_each()`.
- Usa `TestFixtures` para construir mapas y unidades en memoria.
- Un error de script durante un test cuenta como fallo.
