---
description: Revisa el diff actual antes de cerrar una tarea (delega en el subagente reviewer)
agent: reviewer
---
Revisa este diff. Reporta primero bugs, luego riesgos y desviaciones de las convenciones de AGENTS.md, con archivo y línea:
!`git diff --no-color --stat && git diff --no-color`
