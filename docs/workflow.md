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
- Tag anotado en cada paso a estable: `vN` / `beta-N`
  (`git tag -a <tag> -m "..."` + `git push origin main <tag>`).
- Rollback: en `dev`, `reset --hard` al commit bueno; en `main`, `revert`
  del merge (`reset` al tag con `--force` solo en emergencia).

## Docs y skills

- Al cambiar estructura/stack/workflow: actualizar `AGENTS.md` y `docs/`.
- Patrón repetido 3 veces → extraer a skill/comando.
