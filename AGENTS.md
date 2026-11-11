# AGENTS.md — mpvnet desuka

Repo portable de mpvnet para Windows: reproductor + `portable_config/` (scripts,
opciones, keybinds) + tooling en `.tools/`.

## Stack

- **mpvnet** portable sobre mpv (`libmpv`), Windows.
- **Lua 5.1 / LuaJIT** vía scripts mpv. Fichero principal:
  `portable_config/scripts/modernx.lua` (OSC ModernX adaptado).
- **Python** (estándar + el `python.exe` portable del repo) para tooling,
  p. ej. `.tools/twemoji2ass_flags.py` (genera `flag-assets.lua`; ojo: `.tools/`
  está ignorado por git, vive solo en local).
- **Banderas vectoriales ASS**: `flag-assets.lua` mapea `cc` ISO a dibujos
  (`w` + lista `d`, un evento por color, coordenadas `\p1` normalizadas a 256
  de alto). Incluye bloque custom `BEGIN CUSTOM` con Senyera/Ikurrina/gallega.
- Sin runtime Lua local: no hay `lua`/`luac`; la verificación es revisión
  estática del diff + chequeos de paridad + prueba visual en mpv.

## Ficheros clave

- `portable_config/scripts/modernx.lua` — OSC + tooltips/listas de pistas.
- `portable_config/scripts/flag-assets.lua` — bundle generado + custom.
- `portable_config/script-opts/modernx.conf` — opciones (`track_language_mode`,
  `track_flag_gap`, `track_flag_size`, `font`, tamaños).
- `portable_config/input.conf` — keybinds (p. ej. ciclo de subtítulos por
  `script-message-to modernx cycle-sub[-down]`).
- `.tools/twemoji2ass_flags.py` — generador (requiere red para Twemoji).

## Convenciones

- Cambios propios delimitados con `CUSTOM Desuka` (bloques) y
  `EDIT Desuka` (líneas). Comentarios en inglés, cortos. En `.conf`,
  comentarios de una línea con `DESUKA:`.
- Tablas de idioma en paridad estricta: `track_names["en"]`/`["es"]` mismas
  claves (+ centinelas `und`/`""`/`unknown` solo en nombres); `lang_to_cc`
  cubre las claves reales. Sin asset para un `cc` → fallback a `[code]`.
- Validar opciones nuevas en `validate_user_opts()` (aviso + default seguro).
- Medición de tooltips: avances calibrados para la `font` del conf; si cambia
  la fuente hay que recalibrar `CHAR_ADVANCE`.
- No usar `type`/`next` como parámetro o local en Lua: eclipsan a los builtins
  `type()`/`next()` (upstream lo hace en varias funciones; ya nos rompió
  `get_tracklist` una vez).
- Los `.conf` de `portable_config/` se commitean en cada rama como parte del
  estado portable (incluidos `mpv.conf`, `discord.conf` y `update-checker.conf`
  con sus ajustes locales).

## Workflow (resumen; detalle en `.docs/workflow.md`)

Ciclo por tarea: **plan → build → review**. Tras cada build: verificación +
`/review` (subagente `reviewer`, read-only). Ramas: `main` estable,
`dev` trabajo diario. Tras build verificado: commit + push a `dev`
automático. A `main` solo por merge explícito + tag anotado `vN`/`beta-N`.

## Versionado (qué sube a git)

- Regla: se trackea lo que añades o modificas + piezas mínimas para que un
  clon + base upstream funcione. La base upstream (mpvnet, dlls, `inference/`,
  `benchmarks/`, scripts `animejanai_*.lua`, managed confs) NO se versiona.
- Track además: `animejanai/animejanai.conf` (slots del manager),
  `animejanai/onnx/` (modelos .onnx incl. V2 retirados + su LICENSE),
  `portable_config/shaders/` (Anime4K propios), `mpv-discord.exe`,
  `fonts/`, `console.conf`.
- Nunca: `*.engine` / `*.timing.cache` (GPU-local), `cache/`, `watch_later/`,
  `*.log`, `backups/`, `manager-ui.json`, managed (`mpv-animejanai.conf`,
  `input-animejanai.conf`).
- Antes de cada update AJN (`Ctrl+U` pisa `scripts/`, `shaders/`, managed y
  `onnx/`): copia externa de los V2. Después: `git status` → re-aplicar
  bloques CUSTOM → smoke test → commit.
- Renombres de ficheros dev los hace el dueño; no renombrar trackeados por
  iniciativa propia.
