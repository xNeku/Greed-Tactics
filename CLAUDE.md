# Instrucciones para agentes (Claude)

Proyecto: **Greed Tactics**, roguelike táctico isométrico en **Godot 4.7.2** (GDScript).
Responsable: @Neku (habla en español). Responde siempre en español.

## Flujo de trabajo acordado

1. El agente hace los cambios en una rama `claude/<tema>`, valida y hace push.
2. El agente le da a Neku **los comandos exactos para copiar y pegar** en su terminal (traer la rama, probar, fusionar).
3. Si Neku cambia algo por su cuenta, avisa y el agente le dice qué ejecutar para sincronizar.
4. En cada entrega se actualizan, si aplica: `docs/GDD.md` (decisiones + changelog), `docs/ROADMAP.md` y `docs/BACKLOG.md`.

## Antes de entregar (obligatorio)

```bash
godot --headless --import
godot --headless --script res://tests/test_runner.gd           # todos en verde
godot --headless --script res://tests/integration/autoplay_battle.gd   # termina sin errores
godot --headless --script res://tests/integration/autoplay_run.gd -- 5 # runs simuladas sin errores
godot --headless --script res://tests/integration/autoplay_ui_run.gd   # recorrido de pantallas sin errores
godot --headless --script res://tests/integration/player_input_smoke.gd # input del jugador sin errores
godot --headless --quit-after 300                              # la escena principal arranca sin errores
```

Si se editan `.tscn`/`.tres` a mano: `godot --headless --script res://tools/resave_resources.gd`.

## Reglas de arquitectura

- Lee `docs/CONVENTIONS.md`. Resumen: datos en `content/` (`.tres`), reglas puras en `core/` (sin nodos), presentación en `scenes/` (escucha señales de las reglas, nunca al revés).
- Escenas reales con nodos (`.tscn`), un componente por escena, scripts junto a su escena.
- Tipado estático en todo. Código y comentarios en inglés; docs y textos de UI en español.
- **Regla del GDD:** cada modificador nuevo se añade como dato y pasa por los tests del pipeline antes de tocar contenido.
- Toda regla nueva en `core/` llega con tests en `tests/unit/`.
- No metas números de reglas en código: `RulesConfig`, `RunConfig` o el `Resource` correspondiente.
- Solo `GameSession` (autoload `Game`, `scenes/app/`) cambia de escena.
- En `--script` los autoloads también se cargan pero no están en el árbol hasta el primer frame: haz `await process_frame` antes de usarlos.
