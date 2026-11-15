# AGENTS.md — mpv Desuka

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

## File ownership (convención de marcadores)

- Propios (comentarios normales, sin bloques `CUSTOM`/`EDIT`): `portable_config/scripts/update_checker.lua`,
  `quick_subtitle_edit.lua`, `screenshotfolder.lua` (nombre heredado de una de sus dos fuentes,
  se conserva como identificador funcional).
- Base upstream (lo nuestro en bloques `CUSTOM`/`EDIT`): `modernx.lua`
  (https://github.com/zydezu/ModernX @ 739a201), `thumbfast.lua`
  (https://github.com/po5/thumbfast @ 0f711de), `autoload.lua`
  (https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua @ 867990d949e9),
  `portable_config/scripts/animejanai_*.lua` (updater-owned),
  `discord.lua` (https://github.com/tnychn/mpv-discord @ 9224b11, archivado 2024, sin más updates).
- Nombre: visible `mpv Desuka` (`MPV DESUKA` en el README); técnico `mpv-desuka` (slug, ficheros,
  URLs) y carpeta `mpv desuka`.

## Convenciones

- Cabecera upstream en ficheros con base upstream, primera línea:
  `-- Upstream: <url> @ <commit> [(nota breve)]`. Si no hay commit exacto, nota honesta
  (p. ej. `(dir early-check removed)`, `(archived 2024, no further updates)`).
- Marcadores propios, comentarios en inglés y cortos. Bloques:
  `-- >>> CUSTOM Desuka: qué <<<` … `-- <<< CUSTOM Desuka >>>`.
  Líneas: sufijo inline `-- >>> EDIT Desuka <<< -- por qué`, en la propia
  línea (nunca standalone ni envolviendo). En `.conf`, `# DESUKA: ...`.
  Legacy anterior exento; todo marcador nuevo sigue este formato.
- Tablas de idioma en paridad estricta: `track_names["en"]`/`["es"]` mismas
  claves (+ centinelas `und`/`""`/`unknown` solo en nombres); `lang_to_cc`
  cubre las claves reales. Sin asset para un `cc` → fallback a `[code]`.
- Validar opciones nuevas en `validate_user_opts()` (aviso + default seguro).
- Medición de tooltips: avances calibrados para la `font` del conf; si cambia
  la fuente hay que recalibrar `CHAR_ADVANCE`.
- No usar `type`/`next` como parámetro o local en Lua: eclipsan a los builtins
  `type()`/`next()` (upstream lo hace en varias funciones; ya nos rompió
  `get_tracklist` una vez).
- No añadir `local` a nivel de chunk en `modernx.lua`: el chunk principal
  está en el límite de 200 locales de Lua 5.1 (rompe la carga del script);
  usar globales de script como `track_menu_*`.
- Botón menú (`menu_button`): abre el menú avanzado propio (dropdown ASS
  con filas parseadas de `#menu:` en `input.conf` en cada apertura; usa
  estilo/sección `menu-controls` y comparte visual `track_menu_*`).
  El `show-menu` nativo de mpvnet no sirve aquí: lo suprime cerca de
  los bordes (zonas muertas 10% laterales/superior, 22% inferior).
- Los `.conf` de `portable_config/` se commitean en cada rama como parte del
  estado portable (incluidos `mpv.conf`, `discord.conf` y `update_checker.conf`
  con sus ajustes locales).

## Workflow (resumen; detalle en `.docs/workflow.md`)

Ciclo por tarea: **plan → build → review**. Tras cada build: verificación +
`/review` (subagente `reviewer`, read-only). Ramas: `main` estable,
`dev` trabajo diario. Tras build verificado: commit + push a `dev`
automático. A `main` solo por merge explícito `[vN] merge dev` + tag anotado
`vN` en lockstep (versión y tag siempre juntos).

## Releases desuka

- Versión: `portable_config/script-opts/update_checker.conf` (`current_version`); tag `v{misma}`.
  `version.txt` = base AJN, solo para filenames/notas. `update_checker.lua` default `""` + fail-fast
  (sin fallback inventado).
- Artefactos: `mpv-desuka-vN-ajn-vM-full.7z` (contenedor `mpv desuka\`) +
  `mpv-desuka-vN-ajn-vM-patch.zip` (plano, overlay sobre AJN). Los genera
  `.tools/New-DesukaRelease.ps1` (local, gitignored); salida en `.dist\vN\` (gitignored).
- Orden: `/changelog-preview` (dev, sin efectos) → README ES (en web apuntar a `dev`) →
  `/translate` (EN, al final) → merge `[vN]` + tag lockstep → `/release` (solo draft,
  jamás publish) → pulir draft en web → publish manual. Cuerpos editados a mano se
  preservan (solo se refresca `## Descargas`/`## Downloads`).
- Beta privada: `-BetaLocal` empaqueta desde `dev` para reparto manual, sin tag/draft/merge.

## Versionado (qué sube a git)

- Regla: se trackea lo que añades o modificas + piezas mínimas para que un
  clon + base upstream funcione. La base upstream (mpvnet, dlls, `inference/`,
  `benchmarks/`, managed confs) NO se versiona. Excepción: los scripts
  `animejanai_*.lua` sí se versionan aunque sean updater-owned.
- Track además: `animejanai/animejanai.conf` (slots del manager),
  `animejanai/onnx/` (modelos .onnx incl. V2 retirados + su LICENSE),
  `portable_config/shaders/` (Anime4K propios), `mpv-discord.exe`,
  `fonts/`, `console.conf`,
  `portable_config/scripts/animejanai_*.lua` (updater-owned, CUSTOMs; el diff
  post-update guía la re-aplicación).
- Nunca: `*.engine` / `*.timing.cache` (GPU-local), `cache/`, `watch_later/`,
  `*.log`, `backups/`, `manager-ui.json`, managed (`mpv-animejanai.conf`,
  `input-animejanai.conf`).
- Antes de cada update AJN (`Ctrl+U` pisa `scripts/`, `shaders/`, managed y
  `onnx/`): copia externa de los V2. Después: `git status` → re-aplicar
  bloques CUSTOM → smoke test → commit.
- Renombres de ficheros dev los hace el dueño; no renombrar trackeados por
  iniciativa propia.
