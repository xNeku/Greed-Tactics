# Backlog — Greed Tactics

Lista priorizada de tareas. Cada tarea tiene un ID estable (`GT-xxx`) para referenciarla en commits y conversaciones.
El estado por hito está en [`ROADMAP.md`](ROADMAP.md).

**Prioridad:** P0 bloquea el hito actual · P1 necesaria para el hito · P2 mejora · P3 algún día
**Estado:** ⬜ pendiente · 🟡 en curso · 🔍 en revisión · ✅ hecho

## Siguiente (M0 → M1)

| ID | Tarea | Hito | Prio | Estado |
|---|---|---|---|---|
| GT-001 | Validar M0 jugando en Godot 4.7.2 (abrir proyecto, jugar un combate, reportar sensaciones y bugs) | M0 | P0 | 🔍 |
| GT-010 | Plantilla de 4 slots por personaje (Básica, Lanzamiento, Área, Movimiento) y validación en `UnitData` | M1 | P0 | ⬜ |
| GT-011 | Habilidades de tipo Movimiento: soporte en reglas (desplazar al usuario, saltar alturas) + 1 habilidad ejemplo | M1 | P0 | ⬜ |
| GT-012 | Kit de 4 habilidades para Kael y Pablo | M1 | P1 | ⬜ |
| GT-013 | `ModifierData` (etiqueta, disparador, efecto, límite, tipo) | M1 | P0 | ⬜ |
| GT-014 | `ResolutionPipeline` con el orden fijo del GDD §5 + tests sin escena | M1 | P0 | ⬜ |
| GT-015 | 5 modificadores: 3 numéricos (+daño, +alcance, −coste) y 2 de comportamiento (rebote, explosión al acabar movimiento) | M1 | P1 | ⬜ |
| GT-016 | Medir duración media de combate con autoplay y ajustar números (objetivo 4-6 min) | M1 | P1 | ⬜ |
| GT-017 | Estados alterados básicos (veneno, aturdido) como efecto al impacto | M1 | P2 | ⬜ |
| GT-018 | Mostrar la cola de turnos con retratos/colores y resaltar en el mapa la unidad al pasar por la cola | M1 | P2 | ⬜ |

## Más adelante

| ID | Tarea | Hito | Prio | Estado |
|---|---|---|---|---|
| GT-030 | Línea de visión para proyectiles (pregunta abierta GDD §14) | M1 | P2 | ⬜ |
| GT-031 | Bonus por altura (pregunta abierta GDD §14) | M1 | P3 | ⬜ |
| GT-032 | Sprites en 4 direcciones (frente/espalda) además del volteo horizontal | M4 | P2 | ⬜ |
| GT-033 | Animaciones de sprite (idle, andar, atacar, golpe) con `AnimatedSprite3D` / `SpriteFrames` | M4 | P2 | ⬜ |
| GT-034 | Arte final de tiles (texturas, bordes, decoración) | M5 | P2 | ⬜ |
| GT-035 | Internacionalización: textos de UI a CSV de traducciones (`tr()`) | M4 | P3 | ⬜ |
| GT-036 | Mando/teclado completo: mover el cursor de casillas sin ratón | M5 | P3 | ⬜ |
| GT-037 | Pathfinding con planos (x, y, plano) para escaleras y pozos (GDD §9) | M5 | P2 | ⬜ |
| GT-038 | Ajustes de cámara: límite de pitch, zoom suave al foco, opción de cámara ortográfica | M5 | P3 | ⬜ |
| GT-039 | Audio: SFX de pasos, golpes, UI; música por zona | M5 | P2 | ⬜ |
| GT-040 | Tabla de incompatibilidades de modificadores (GDD §5) | M1 | P1 | ⬜ |
| GT-041 | Escena `main.tscn` con menú y selección de combate (hoy arranca directo en `battle.tscn`) | M2 | P1 | ⬜ |
| GT-042 | `RunState` + mapa de run (GDD §9) | M2 | P0 | ⬜ |
| GT-043 | Generador procedural de `MapData` por zona | M2 | P0 | ⬜ |

## Hecho

| ID | Tarea | Hito | Fecha |
|---|---|---|---|
| GT-100 | Proyecto Godot 4.7.2, estructura de carpetas, input map, tema UI y fuente Nunito | M0 | 2026-11-02 |
| GT-101 | Recursos de datos: `TerrainData`, `MapData`, `SkillData`, `UnitData`, `RulesConfig`, `BattleSetup` | M0 | 2026-11-02 |
| GT-102 | Reglas de grid: direcciones, alturas, coste de PM, pathfinding Dijkstra, formas de área | M0 | 2026-11-02 |
| GT-103 | Orientación y regla de espalda con casilla cubierta | M0 | 2026-11-02 |
| GT-104 | `CombatState` con comandos validados y señales; fórmulas de daño/golpe/crítico | M0 | 2026-11-02 |
| GT-105 | Cola de turnos por velocidad (CT) con previsión determinista | M1 | 2026-11-02 |
| GT-106 | Mapa 3D con MultiMesh, shaders de terreno, agua y highlights; picking analítico | M0 | 2026-11-02 |
| GT-107 | Unidades billboard con aro de bando, flecha de orientación, etiqueta y números de daño | M0 | 2026-11-02 |
| GT-108 | Cámara libre (rotar, zoom, desplazar, centrar) | M0 | 2026-11-02 |
| GT-109 | HUD: barra superior + cola, mensaje, ficha, info de casilla, comandos, previsión, resultado | M1 | 2026-11-02 |
| GT-110 | Input del jugador por modos (mover, objetivo, orientación) | M0 | 2026-11-02 |
| GT-111 | IA enemiga básica (`BasicAI`) | M1 | 2026-11-02 |
| GT-112 | Runner de tests headless + 42 tests + test de integración autoplay + CI | M0 | 2026-11-02 |
| GT-113 | Sprites provisionales (Kael, Pablo, Goblin, Limo) y combate de prueba 2 vs 3 | M0 | 2026-11-02 |
