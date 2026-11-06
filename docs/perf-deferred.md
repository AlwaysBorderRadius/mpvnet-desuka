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
menú, thumb bajo demanda (solo si cambia el segundo de hover).

## 1. Suelo de tick a 1/60

- Qué: `tick_delay = max(1/display-fps, 1/60)` en `set_tick_delay()`.
- Efecto: en pantallas de 144/240 Hz los renders completos bajan a 60/s
  (2.4-4x menos trabajo); en 60 Hz no cambia nada.
- Riesgo: el OSD iría a 60 Hz en pantallas rápidas. Para un OSC (fades de
  150 ms, timecode, drag de seekbar) 60 Hz sobra, pero el dueño prefiere no
  tocar fluidez sin medir antes.
- Si se retoma, añadir también guard contra `display-fps <= 0`
  (`1/0 = inf` = ticks muertos = OSD congelado para siempre).

## 2. Short-circuit de micro-movimientos (+ `min_mouse_move`)

- Qué: en `process_event()` (`mouse_move`), si el desplazamiento < umbral
  (2-3 px) y no hay drag activo (`state.active_element == nil`) ni menú
  abierto, actualizar `last_mouseX/Y` y volver sin `show_osc` ni
  `request_tick`.
- Efecto: recorta el grueso de los ~1000 ev/s de un ratón 1000 Hz en reposo
  con temblor de mano.
- Riesgo: el highlight/tooltip del hover puede retrasarse como máximo el
  umbral (2-3 px sobre botones de ~24 px: imperceptible). No afecta a drags
  (seek/volumen siguen al píxel) ni al menú abierto.
- Alternativa suave (ya existe la opción, hoy a 0): subir solo
  `min_mouse_move` a 2-3 en `modernx.conf`. Ojo: hoy esa opción solo salta el
  `show_osc()`, no el tick/render; sin el early-out el ahorro es menor.

## 3. Caché de `get_virt_mouse_pos()` por frame

- Qué: hoy cada `mouse_hit()` hace 2 IPCs (`get_mouse_pos` + `get_osd_size`);
  un render roza las ~100 llamadas para leer una posición que no debería
  cambiar a mitad de frame. Cachear el par `(mx, my)` una vez por render y
  reutilizarlo en `render_elements()` / `render_track_menu()`.
- Efecto: ~100 IPC menos por frame, cero cambio visible (misma foto fija
  para todos los hit-tests del frame; de hecho evita inconsistencias si el
  ratón se mueve a mitad de render).
- Riesgo: la caché debe vivir SOLO en la ruta de render. La ruta de clic
  (`process_event` down/up) debe seguir leyendo en vivo o un clic justo en
  un borde podría evaluarse con la posición del frame anterior.
