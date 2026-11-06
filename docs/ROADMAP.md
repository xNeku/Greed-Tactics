# Roadmap — Greed Tactics

Hitos del GDD (§13) con su estado real. **No se pasa al siguiente hito sin cumplir el criterio de salida.**
Las tareas concretas de cada hito están en [`BACKLOG.md`](BACKLOG.md) (IDs `GT-xxx`).

Leyenda: ✅ hecho · 🟡 en curso · ⬜ pendiente · 🔍 pendiente de validar por @Neku

| Hito | Estado | Resumen |
|---|---|---|
| M0. Prototipo de grid | ✅ | Validado por Neku ("me gusta"). |
| M1. Combate completo | 🔍 | 4 clases, ira/maná/enfriamientos, 25 modificadores, estados, IA táctica, flechas y efectos (v0.4). Falta validarlo jugando. |
| M2. Run jugable | 🟡 | v0.7: protagonista + reclutas, mapa de etapa con bifurcaciones, objetivos opcionales, escalado por grupo. Faltan tienda, eventos, armas y pulido. |
| M3. Meta y persistencia | ⬜ | Decidido: compañeros = héroes jugables con progresión bilateral (GDD §7). |
| M4. Contenido | 🟡 | Adelantado: 5 zonas (castillo y fábrica nuevas, con enemigos prestados), 12 enemigos, 3 minibosses, 22 modificadores; armas iniciales de Neku dibujadas en la mano (faltan sus estadísticas y el martillo). |
| M5. Pulido y balance | ⬜ | |

---

## M0. Prototipo de grid — ✅

Criterio de salida cumplido: mover y atacar en el grid con previsión; tests de movimiento y orientación en verde; validado por @Neku.

## M1. Combate completo (vertical slice de combate) — 🔍

**Criterio de salida:** un combate de 4-6 minutos contra 3 enemigos, jugable de principio a fin **sin tocar código para añadir contenido**.

- ✅ Cola de turnos por velocidad (CT) siempre visible.
- ✅ PM / PA / MP por turno + **ira** y **enfriamientos** (v0.3).
- ✅ HUD: cola, ficha (con barra de maná o ira), comandos con coste y mutación ★, mensaje, previsión, resultado.
- ✅ Plantilla de 4 slots (Básica, Lanzamiento, Área, Movimiento) en las 4 clases — GT-010.
- ✅ Habilidades de Movimiento: teletransporte, carga y aparecer a la espalda — GT-011.
- ✅ 4 habilidades por clase (+ 8 mutaciones por ira) — GT-012.
- ✅ `ModifierData` + `ResolutionPipeline` con el orden fijo del GDD §5 — GT-013, GT-014.
- ✅ 22 modificadores (numéricos y de comportamiento) con tests del pipeline — GT-015.
- ✅ Tabla de incompatibilidades — GT-040.
- ✅ Feedback de acciones: flechas, zona de daño, previsión completa, panel de habilidad (v0.4) — GT-201, GT-220.
- ✅ Efectos visuales placeholder por habilidad (v0.4) — GT-221.
- ✅ Estados alterados: quemado, veneno, ralentizado, aturdido, silencio (v0.4) — GT-017.
- ✅ IA táctica con mapa de amenaza y perfiles (v0.4) — GT-203.
- 🔍 Medir duración real del combate con jugador humano (objetivo 4-6 min) — GT-016.

## M2. Run jugable — 🟡

**Criterio de salida:** una run completa en 20-30 minutos sin bugs bloqueantes.

- ✅ `RunState` y mapa de run: 2 etapas × 4 fases, miniboss en la fase 4 — GT-042.
- ✅ Generador procedural de `MapData` para Cueva, Bosque y Desierto — GT-043.
- ✅ Recompensas: modificador 1 de 3 con reroll (fases pares), oro (impares), XP y nivel.
- ✅ Vida persistente, revivir tras victoria, curar con oro.
- ✅ Pantallas de menú, mapa de run, recompensa y fin de run — GT-041.
- ⬜ Bendiciones (GDD §2) separadas de los modificadores — GT-050.
- ⬜ Compañeros: 1 inicial + 1 por piso, IA por rol — GT-051.
- ⬜ Validar duración de run (20-30 min) jugando — GT-052.

## M3. Meta y persistencia — ⬜

**Criterio de salida:** el progreso sobrevive a cerrar el juego y a varias runs seguidas.

- ⬜ Guardado de cuenta (tras cada combate y desbloqueo).
- ⬜ Desbloqueo de personajes y habilidades por uso.
- ⬜ Gambling de armas con pity y duplicados → fragmentos.
- ⬜ Maestría por personaje y arma.
- ⬜ Compañeros = héroes jugables con progresión bilateral: lo que mejoras de un personaje lo lleva también como aliado (GT-262).
- ⬜ Desbloqueo de raza/clase en minibosses.

## M4. Contenido — 🟡

**Criterio de salida:** tres runs seguidas dan experiencias distintas.

- ✅ 3 zonas con generador propio, 12 enemigos, 3 minibosses, 22 modificadores.
- ⬜ 10 personajes con kit completo, pool de compañeros, 5 armas.

## M5. Pulido y balance — ⬜

**Criterio de salida:** runs de 1-2 horas con jugadores externos sin que se sientan forzadas.

- ⬜ 3 planos, apertura tipo Isaac, arte final, audio, balance con playtests externos.
