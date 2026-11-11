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

## Tras update AJN (el updater pisa scripts/, shaders/, managed y onnx/)

- Copia externa de los V2 ANTES de `Ctrl+U` (irrecuperables si el overlay los borra).
- Después: `git status` → diff en `scripts/` + `shaders/` + `onnx/` + bloque managed de `input.conf` → re-aplicar bloques `CUSTOM Desuka` → smoke test (Ctrl+E, Ctrl+J, slots) → commit en `dev`.

## Docs y skills

- Al cambiar estructura/stack/workflow: actualizar `AGENTS.md` y `.docs/`.
- Patrón repetido 3 veces → extraer a skill/comando.
