---
description: Vista previa del changelog ES para la proxima release (sin empaquetar ni subir)
agent: releaser
---
Genera SOLO el cuerpo del draft en modo preview (sin crear nada en GitHub).

Base del rango: el tag del ultimo release PUBLICADO (hoy: `1.3`, no el ultimo
tag git; en futuras releases sustituye `1.3` por el ultimo publicado). Si el usuario
indica otra base en el mensaje, usa esa; si el LOG de abajo no cubre el rango pedido,
pide el log correcto en vez de inventar.

Datos (tras publicar vN, actualizar la linea 13 con la nueva base):
!`git tag --list --sort=version:refname`
!`git log --no-color 1.3..HEAD --oneline`

DESUKA_VER = valor actual de `current_version` en portable_config/script-opts/update_checker.conf.
AJN_VER = primera linea de version.txt. FULL_NAME y PATCH_NAME =
mpv-desuka-vDESUKA_VER-ajn-vAJN_VER-full.7z / mpv-desuka-vDESUKA_VER-ajn-vAJN_VER-patch.zip.
AJN_URL = https://github.com/the-database/mpv-upscale-2x_animejanai/releases/tag/AJN_VER.

El agente principal guarda tu salida en .dist/vDESUKA_VER-notes.md para usarla de chuleta
del README. No ejecutes nada, no toques GitHub.
