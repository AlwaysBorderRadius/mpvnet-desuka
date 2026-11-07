# Optimizaciones diferidas (rendimiento del OSC)

## 0. Causa raíz del freeze (2026-11) → CONTENIDA

- `render()`: con el cursor quieto sobre el OSC y el hide-timeout vencido
  (`bottom_hover=no`), re-armaba `hide_timer` con `timeout <= 0` → tick
  inmediato que volvía a `render()` y se re-armaba: miles de renders/s.
- Cada tick es barato (`max_tick` bajo, `set_osd` descarta texto idéntico),
  pero el hilo Lua saturado no drena la cola de entrada →
  `Too many events queued` → `Can't find script 'modernx'`.
  Por eso congelaba en hover/parado/pausa y mover el ratón "descongelaba"
  (refresca `showtime` y rompe el bucle).
- Contención: `hide_timer.timeout = max(timeout, 1/30)` (re-chequeo a
  30 Hz; el suelo 1/30 es el mismo del menú abierto, el global sigue 1/60).
  Verificado headless (menú abierto, cursor aparcado, `showtime` rancio,
  `bottom_hover=no`): sin el fix el disyuntor salta y cuenta 1037 ticks/3 s
  podando renders; con el fix 174 ticks/3 s (~55/s entre ambos timers) sin
  tormenta.
- El disyuntor de tormenta queda como red de seguridad.

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
`msg-level=all=warn`, tripwire temporal de salud del bucle (quitar cuando el
freeze quede diagnosticado), backpressure adaptativo (shed de micro-moves
solo bajo flood sostenido, nunca en drag ni con menú abierto; clics/rueda
intactos), **medidas desesperadas aplicadas tras el freeze del 2026-11-07**:
suelo global de tick a 1/60, shed global de micro-moves sin drag ni menú,
disyuntor de tormenta de ticks (>240/s poda renders, TEMP DIAGNOSTIC),
contadores `rt`/`riz` de origen de ticks (TEMP DIAGNOSTIC).

## 1. Suelo de tick → APLICADO GLOBAL A 1/60 (+ 1/30 SOLO CON MENÚ)

- `set_tick_delay()`: `tick_delay = max(1/display_fps, 1/60)` con el guard
  `display-fps <= 0` ya existente. `request_tick()` mantiene además
  `max(tick_delay, 1/30)` con el menú abierto.
- Nuevo hallazgo que lo justifica: `loop health` con `ticks=192895/5s`
  (tormenta de ticks con `max_tick` bajo): el peligro no es solo un tick
  lento, sino decenas de miles de ticks/s baratos que impiden drenar input.

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

## 2b. Shed global de micro-movimientos → APLICADO (DESESPERADA)

- Con freeze aun con shed adaptativo activo, se aplica el veto fijo que se
  había aparcado: sin drag y sin menú, los movimientos < 3 px en ambos ejes
  vuelven sin `show_osc` ni tick y **sin** refrescar la referencia (como el
  shed adaptativo), así que las derivas lentas acumulan y acaban pasando.
- El temblor de mano ya no genera ticks; gestos direccionales y derivas
  siguen pasando al superar el umbral. Clics/rueda intactos.

## 4. Disyuntor de tormenta de ticks → APLICADO (TEMP DIAGNOSTIC)

- Si un segundo acumula > 240 ticks, se podan los renders (se mantiene la
  cadencia del timer) y se avisa una vez (`diag tick storm`);
  la salida («over») exige una ventana tranquila (<= 120), con histéresis
  para no flapear. Los ticks de fade animado están exentos (re-arman por
  diseño y terminan solos): solo se podan ticks sin animación.
- Contadores `rt` (llamadas a `request_tick`) y `riz` (llamadas a
  `request_init_resize`) en el `loop health` para localizar la vía de la
  tormenta en el próximo log. Histéresis de tooltip innecesaria: los
  tooltips ya van anclados al botón, no siguen al cursor.

## 3. Caché de `get_virt_mouse_pos()` por frame → APLICADO

- Era: cada `mouse_hit()` hacía 2 IPCs (`get_mouse_pos` + `get_osd_size`);
  un render rozaba las ~100 llamadas.
- Ahora los hit-tests de un mismo tick comparten una lectura; `process_event`
  la invalida al entrar para que los clics sigan leyendo en vivo.
- Se mantiene aquí como referencia de lo ya hecho (cero cambio visible).
