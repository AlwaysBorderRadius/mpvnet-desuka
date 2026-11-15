# Workflow plan → build → review

1. **Plan**: solo diseño, sin tocar código.
2. **Build**: implementación en una rama/sesión por tarea coherente.
3. **Review**: verificación obligatoria + `/review` (delega en el subagente
   `reviewer`: sesión hija, contexto fresco, read-only; reporta por severidad
   con archivo y línea).

## Git

- `main` = solo estable. `dev` = trabajo diario (puede romper).
- Tras cada build verificado (verificación OK + review sin críticos):
  `commit + push` a `dev` automáticamente, sin pedir permiso.
- A `main` SOLO por merge cuando el usuario lo diga explícito. Nunca commit
  directo a `main`.
- Merge a `main` con versión en el mensaje: `[vN] merge dev: <resumen>`
  + cuerpo con los subjects de `git log --no-merges main..dev`.
- Tag anotado sobre ese mismo commit (`git tag -a vN` + push junto con
  `main`). Versión y tag suben siempre juntos: cada merge a `main` es
  candidato a release; la release pública se declara aparte, sin renumerar.
- Rollback: en `dev`, `reset --hard` al commit bueno; en `main`, `revert`
  del merge (`reset` al tag con `--force` solo en emergencia).

## Releases (draft-first, publish manual)

- Preview en `dev` (`/changelog-preview`, sin efectos) → README ES con el preview de
  chuleta (en web apuntar a `dev`) → `/translate` al final → merge `[vN]` + tag lockstep
  → `/release` empaqueta y crea/actualiza el draft (`--draft` siempre; mismo tag =
  backup + update in place; tag publicado = abortar). Cuerpos editados a mano en la web
  se preservan: solo se refresca `## Descargas`/`## Downloads`, regenerar todo exige orden
  explicita.
- Publish manual en la web. Pre-release solo para beta pública (el checker ignora
  pre-releases en `releases/latest`); beta privada = ficheros de `.dist\` a mano, sin GitHub.

## Tras update AJN (el updater pisa scripts/, shaders/, managed y onnx/)

- Copia externa de los V2 ANTES de `Ctrl+U` (irrecuperables si el overlay los borra).
- Después: `git status` → diff en `scripts/` + `shaders/` + `onnx/` + bloque managed de `input.conf` → re-aplicar bloques `CUSTOM Desuka` → smoke test (Ctrl+E, Ctrl+J, slots) → commit en `dev`.

## Docs y skills

- Al cambiar estructura/stack/workflow: actualizar `AGENTS.md` y `.docs/`.
- Patrón repetido 3 veces → extraer a skill/comando.
