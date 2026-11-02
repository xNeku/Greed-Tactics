# Roadmap — Greed Tactics

Hitos del GDD (§13) con su estado real. **No se pasa al siguiente hito sin cumplir el criterio de salida.**
Las tareas concretas de cada hito están en [`BACKLOG.md`](BACKLOG.md) (IDs `GT-xxx`).

Leyenda: ✅ hecho · 🟡 en curso · ⬜ pendiente · 🔍 pendiente de validar por @Neku

| Hito | Estado | Resumen |
|---|---|---|
| M0. Prototipo de grid | 🔍 | Implementado y testeado. Falta tu validación jugándolo. |
| M1. Combate completo | 🟡 | Turnos, PM/PA/MP y HUD ya hechos. Faltan slots, modificadores y pipeline. |
| M2. Run jugable | ⬜ | |
| M3. Meta y persistencia | ⬜ | |
| M4. Contenido | ⬜ | |
| M5. Pulido y balance | ⬜ | |

---

## M0. Prototipo de grid (1-2 semanas) — 🔍

**Criterio de salida:** mover y atacar en el grid con previsión. Tests de movimiento y orientación en verde.

- ✅ Mapa 3D isométrico con alturas, agua animada y bloques (`BattleMapView`, datos en `MapData`).
- ✅ Movimiento ortogonal con coste de PM, coste de subida y límite de salto (`Pathfinder`, `GridRules`).
- ✅ Previsualización de movimiento (azul) y camino (azul claro), casilla bajo el ratón (verde).
- ✅ Ataque con rango (naranja), área (amarillo) y ficha de previsión (lado, daño, golpe, crítico).
- ✅ Orientación y regla de espalda (`GridRules.get_attack_side`).
- ✅ Tests de movimiento y orientación en verde (`tests/unit/test_movement.gd`, `test_orientation.gd`).
- ✅ Extra adelantado de M1: cola de turnos por velocidad, varias unidades por bando, IA enemiga básica, victoria/derrota.
- 🔍 Validación de @Neku jugando en Godot 4.7.2.

## M1. Combate completo (vertical slice de combate) — 🟡

**Criterio de salida:** un combate de 4-6 minutos contra 3 enemigos, jugable de principio a fin **sin tocar código para añadir contenido**.

- ✅ Cola de turnos por velocidad (CT) siempre visible.
- ✅ PM / PA / MP por turno.
- ✅ HUD: cola, ficha, comandos, mensaje, previsión, resultado.
- ✅ Combate contra 3 enemigos con victoria/derrota.
- ⬜ Plantilla de 4 slots (Básica, Lanzamiento, Área, Movimiento) por personaje — GT-010.
- ⬜ Habilidades de tipo Movimiento (salto, carga, intercambio) — GT-011.
- ⬜ 3-4 habilidades base por personaje — GT-012.
- ⬜ `ModifierData` + `ResolutionPipeline` con el orden fijo del GDD §5 — GT-013, GT-014.
- ⬜ 5 modificadores (2 de comportamiento, 3 numéricos) con tests — GT-015.
- ⬜ Medir duración real del combate (objetivo 4-6 min) — GT-016.

## M2. Run jugable — ⬜

**Criterio de salida:** una run completa en 20-30 minutos sin bugs bloqueantes.

- ⬜ `RunState` y escena de mapa de run: 1 zona, 3 pisos, 2-4 combates + boss.
- ⬜ Generador procedural de `MapData` por zona.
- ⬜ Bendiciones: elegir 1 de 3, reroll con moneda de run.
- ⬜ Compañeros: 1 inicial + 1 por piso, IA por rol.
- ⬜ Pantallas de inicio, muerte y victoria de run.

## M3. Meta y persistencia — ⬜

**Criterio de salida:** el progreso sobrevive a cerrar el juego y a varias runs seguidas.

- ⬜ Guardado de cuenta (tras cada combate y desbloqueo).
- ⬜ Desbloqueo de personajes y habilidades por uso.
- ⬜ Gambling de armas con pity y duplicados → fragmentos.
- ⬜ Maestría por personaje y arma.
- ⬜ Desbloqueo de raza/clase en minibosses.

## M4. Contenido — ⬜

**Criterio de salida:** tres runs seguidas dan experiencias distintas.

- ⬜ 2-3 zonas, 10 personajes con kit completo, pool de compañeros, 15-20 modificadores, 5 armas.

## M5. Pulido y balance — ⬜

**Criterio de salida:** runs de 1-2 horas con jugadores externos sin que se sientan forzadas.

- ⬜ 3 planos, apertura tipo Isaac, arte final, audio, balance con playtests externos.
