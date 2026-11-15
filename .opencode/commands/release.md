---
description: Congela main+tag, empaqueta full+patch y crea/actualiza el draft (siempre draft)
---
Flujo /release (el agente principal lo ejecuta paso a paso, nada es automatico):

1. Precondiciones: rama `dev` limpia de lo que se va a publicar, README.md ES ya editado
   (vale editarlo en la web de GitHub apuntando a rama `dev`), `current_version` en
   portable_config/script-opts/update_checker.conf igual al tag previsto. Si el ES del
   draft se pulio en la web, esa es la version buena.
2. Merge `dev` -> `main` con mensaje `[vN] merge dev: <resumen>` + tag anotado `vN` en
   lockstep (workflow en .docs/workflow.md). Solo cuando el usuario lo ordene.
3. Ejecutar `.tools/New-DesukaRelease.ps1 -Version N` (modo normal: exige main limpio +
   tag en HEAD). Artefactos quedan en `.dist/vN/`.
4. Cuerpo del draft: delega en el subagente `releaser` pasandole en el prompt el LOG
   (`git log --no-color <ultimo-publicado>..vN --oneline`), DESUKA_VER, AJN_VER
   (version.txt), FULL_NAME, PATCH_NAME y AJN_URL. Guarda su salida en `.dist/vN-body.md`.
5. `gh release create vN --draft --title "vN" -F .dist/vN-body.md <full> <patch>`.
   Si existe draft del MISMO tag: respalda su cuerpo en `.dist/` y actualiza in place
   (`gh release edit` + re-subida de assets homonimos); si el cuerpo fue editado a mano
   en la web, solo refresca el bloque `## Descargas` (y `## Downloads` si existe),
   nunca regeneres todo sin orden explicita. Draft de OTRO tag: no tocar. Tag ya
   publicado: abortar. Jamas publicar (el publish es clic manual del usuario).
6. Deja la URL del draft para revision. Verificacion + `/review` antes del push a `main`.
