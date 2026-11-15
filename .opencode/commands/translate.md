---
description: Traduce al ingles el README y la seccion EN del draft desde el ES congelado
---
Flujo /translate (ultimo paso antes del merge, solo con el ES ya cerrado):

1. Fuentes congeladas pre-merge: `README.md` (ES) en `dev` + notas del preview
   (`.dist/vN-notes.md` de `/changelog-preview`). Si el draft ya existe y su cuerpo ES
   esta mas pulido (via `gh release view vN --json body`), ese manda; si discrepan,
   pregunta.
2. Genera `README.en.md` (traduccion fiel del ES, con cabecera `English | [Espanol](README.md)`)
   y anade la cabecera `Espanol | [English](README.en.md)` arriba de `README.md` si falta.
3. Genera la seccion EN del cuerpo (`## What's new` completa + tabla `## Downloads` espejo
   con los mismos enlaces) para pegar en el draft. No toques el ES.
4. Muestra el resultado para revision humana. No commitea solo: incluye los ficheros en
   el siguiente commit a `dev` tras el visto bueno.
