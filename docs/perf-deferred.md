# Optimizaciones diferidas (rendimiento del OSC)

Contexto: `modernx.lua` procesa cada evento de ratón en el hilo principal de mpv
y pinta el OSD a ritmo de `tick` (limitado por `display-fps`). Con ratones de
1000 Hz + pantallas de 144/240 Hz, un meneo sostenido genera cientos de eventos/s
más notificaciones de propiedades por frame (`playback-time`, ...). Si el
drenaje no da abasto, la cola de eventos del cliente se llena y mpv lo desactiva
(`Too many events queued` + `Can't find script 'modernx'`), dejando el OSD
congelado. Los puntos de abajo quedaron aparcados a propósito: aplicar solo si
vuelve a haber saturación con el log en `info`.

Estado actual (ya aplicado, no tocar): `thumbfast clear` solo en transición,
`enable/disable_key_bindings('window-controls')` solo en transición,
`input-doubleclick-time=200`, `mbtn_left_dbl` como clic, `drop_gesture` en el
menú, thumb bajo demanda (solo si cambia el segundo de hover),
caché de `get_virt_mouse_pos()` por frame (la ruta de input la invalida al
entrar: los clics siguen leyendo en vivo), tooltips fijos anclados al botón,
`msg-level=all=warn`, tripwire temporal de salud del bucle (`max_tick` +
eventos/5s a nivel warn; quitar cuando el freeze quede diagnosticado),
backpressure adaptativo (shed de micro-moves solo bajo flood sostenido,
nunca en drag ni con menú abierto; clics/rueda intactos).

## 1. Suelo de tick a 1/30 solo con menú abierto → APLICADO

- `request_tick()` usa `max(tick_delay, 1/30)` mientras `state.track_menu`
  existe. El menú es estático: a 30Hz es indistinguible y corta a la mitad
  los re-renders con banderas, justo el caso que saturaba.
- El OSC normal sigue a ritmo completo (sin cambios); el veto del usuario
  sobre capar la interfaz queda respetado fuera del menú.
- Si hiciera falta más, el siguiente paso sería el suelo global
  (`tick_delay = max(1/display_fps, 1/60)` en `set_tick_delay`, con guard
  para `display-fps <= 0`).

## 2. Short-circuit de micro-movimientos (+ `min_mouse_move`) → APLICADO EN FORMA ADAPTATIVA

- Implementado como backpressure con histéresis (no como veto fijo): el shed
  se activa en cuanto se supera el umbral (750 moves, sin esperar al borde
  de ventana) y el timer de 5 s lo desactiva en ventanas tranquilas (< 500).
- Solo descarta micro-moves (< 3 px **en ambos ejes**) sin drag activo ni
  menú abierto: temblor puro; un gesto direccional (p. ej. 10 px en X)
  siempre pasa.
- Los movimientos descartados no consumen presupuesto de desplazamiento
  (`last_mouseX/Y` no se toca), así que derivas lentas acaban procesándose.
- Clics y rueda nunca se podan. Comportamiento idéntico fuera de flood.
- Contador y ventana viven en un único timer compartido de 5 s (también lo
  usa el tripwire temporal); al quitar el tripwire, el timer permanente se
  queda solo con el rollover del flood.

## 3. Caché de `get_virt_mouse_pos()` por frame → APLICADO

- Era: cada `mouse_hit()` hacía 2 IPCs (`get_mouse_pos` + `get_osd_size`);
  un render rozaba las ~100 llamadas.
- Ahora los hit-tests de un mismo tick comparten una lectura; `process_event`
  la invalida al entrar para que los clics sigan leyendo en vivo.
- Se mantiene aquí como referencia de lo ya hecho (cero cambio visible).
