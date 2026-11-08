# Kit de diagnóstico (rendimiento del OSC)

## 1. Incidente 2026-11: freeze por tormenta de ticks (resuelto)

- Síntoma: hacer hover unos segundos sobre un botón (p. ej. subs)
  congelaba la interfaz: hover/tiempo/progreso seguían moviéndose, pero
  clics y toasts no respondían.
- Firmas en `mpv.log` (buscar con `grep`):
  - `[e][modernx] Too many events queued.` — una vez, al inicio del corte.
  - `[v][cplayer] Can't find script 'modernx' when handling input.` — en
    cascada con cada `Run command: mouse` / `script-binding` posterior.
    `button="-1", mode="single"` = movimiento, no clic.
  - `modernx: loop health: ... ticks=192895` con `max_tick` bajo —
    tormenta de ticks baratos (no es un tick lento).
  - `modernx: diag tick storm, shedding renders` — el disyuntor conteniendo.
- Causa raíz: `render()` re-armaba `hide_timer` con `timeout <= 0` cuando el
  cursor quedaba quieto sobre el OSC con el hide-timeout vencido
  (`bottom_hover=no`): tick inmediato que se re-autoarmaba cada render
  (miles de renders/s). El hilo Lua saturado dejaba de drenar la cola de
  entrada → desbordamiento → `Can't find script`.
- Contención definitiva: `hide_timer.timeout = max(timeout, 1/30)`
  (re-chequeo a 30 Hz en vez de bucle inmediato).
- Verificado headless (menú abierto, cursor aparcado, `showtime` rancio,
  `bottom_hover=no`): sin el fix, 1037 ticks/3 s con tormenta; con el fix,
  174 ticks/3 s sin tormenta.

## 2. Cómo re-armar el kit de diagnóstico completo (si vuelve algo similar)

Commits en `dev`, en orden de aplicación con `git cherry-pick`:
- `1ff2aa7`: tripwire base (`loop health`: eventos/5s + `max_tick`) +
  caché de `get_virt_mouse_pos()` por frame.
- `fc3ac99`: tripwire en temporizador propio + backpressure adaptativo.
- `0257b60`: tripwire ampliado (inputs/mouse/ticks, flags de estado,
  avisos de transición de flood, marcadores de apertura/cierre de menú).
- `f8fbce5`: disyuntor de tormenta + contadores `rt`/`riz` de origen de
  tick + suelo global 1/60 + shed global (estos dos últimos revertidos:
  ver sección 4).
- `75594db`: clamp del `hide_timer` (la cura).

## 3. Estado final: lo que queda en el código (impacto 0 en uso normal)

- Clamp `hide_timer` a 1/30 (cura probada; solo actúa en el caso
  "ocultar vencido + cursor encima", retraso máximo 33 ms ahí).
- Disyuntor de tormenta con umbral relativo `max(240, 4×fps)` + sus
  propios avisos de transición (`diag tick storm` / `over`: red de
  seguridad + alarma; el flood adaptativo entra/sale en silencio).
- Tripwire `loop health` en anomalía (detector general; solo avisa si
  `max_tick > 250 ms` o `inputs > 750/5 s`).
- Backpressure adaptativo: shed de micro-moves (< 3 px) solo bajo flood
  sostenido, nunca en drag ni con menú; clics/rueda intactos.
- Caché de `get_virt_mouse_pos()` por render (la ruta de input la invalida
  al entrar: los clics siguen leyendo en vivo).
- Menú modal: clic fuera dismitea y traga; rueda fuera se traga (ni volumen
  ni seek mientras está abierto; dentro hace scroll).
- Tooltips fijos anclados al botón; `msg-level=all=warn`; menú de pistas +
  guards anti-hover; doble-clic como clic; `drop_gesture`; thumb bajo
  demanda + clear en transición; fix del hot loop de `osc_init` (12 k
  inits/sesión) en vídeos con capítulos; guards de `window-controls`.

## 4. Retirado (diagnóstico cumplido o tocaba vetos del dueño)

- Suelo global de tick a 1/60 y shed global de micro-moves: volvieron ritmo
  de `display-fps` y shed solo-adaptativo. Sin ellos no hay ningún cap ni
  zona muerta en uso normal.
- Suelo 1/30 solo-con-menú: innecesario tras la cura; el menú rinde a
  ritmo normal y el disyuntor cubre tormentas.
- Resto TEMP: contadores `rt`/`riz`, marcadores de menú, avisos de
  transición de flood (ver sección 2 para recuperarlos).
