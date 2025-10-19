# MPVNET DESUKA

> Formerly known as: Codename ACHUS


# INSTALACION 

## WINDOWS ONLY (PORTABLE) / (PUEDE QUE FUNCIONE EN LINUX CON WINE)
1. (si tienes una instalacion anterior, eliminalo todo o guardalo en otro sitio)

2. Tan solo suelta la carpeta "mpvnet desuka" donde quieras (Recomiendo: `C:\Program Files\mpvnet desuka` o `C:\APPS\mpvnet desuka`)

3. Depende de donde lo hayas guardado, tendras que modificar la siguiente linea en: `mpvnet desuka > portable_config > script-opts > discord.conf` 
	- `binary_path=C:\.APPs\mpvnet desuka\mpv-discord.exe` 		--> cambia la ruta si lo tienes en otro lugar

4. GPU AMD: abre `mpvnet desuka > ctrl+E > Global Settings` tab y cambia `Upscaling Backend` de `TensorRT` a `DirectML`

5. Ahora te toca aprender las keybinds (usa `ctrl+f`) para saber como usarlo todo :) y leete el changelog(importante) + la docu, no seas vago.

6. Troubleshooting: Si por alguna razon no te va Animejanai (no cargan, no ves cambios), ve a: `mpvnet desuka > animejanai > onnx` y borra todos los archivos `.engine`


# DOCUMENTACIÓN

## Qué es:
- Mi MPV customizado (Compatible con Windows y Linux)
- Recomendado para ver anime, series y películas
- ¡Para usar Anime4K en pantallas 4k se recomienda un PC de gama alta y para pantallas 1080 uno de gama media!
- ¡Para usar Animejanai en pantallas 4k se recomienda un PC de gama alta (modo 1 - RTX 4090, modo 2 - RTX 3080, modo 3 - RTX 3060) y para pantallas 1080 uno de gama media!
- Abre input.conf para ver los keybinds

## Qué incluye:
- mpvnet modificado por Animejanai
  - https://github.com/the-database/mpv-upscale-2x_animejanai
- Anime4K
  - https://github.com/h5mcbox/anime4k
- Animejanai V3 (cacota) y V2 (la buena)
  - https://github.com/the-database/mpv-upscale-2x_animejanai
- Autoload (una version antigua a proposito, la nueva carga todo lo que haya en la carpeta, no solo videos)
  - https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua
- ModernX - Customizacion extra hecha por Edu
  - https://github.com/zydezu/ModernX
- Thumbfast
  - https://github.com/po5/thumbfast
- DiscordRPC
  - No me acuerdo o se ha perdido por internet, era un proyecto antiguo y es el mejor que hay
- Custom Config (mpv.conf, input.conf, mpvnet.conf, script-opts) - Customizacion extra hecha por Edu
  - https://github.com/the-database/mpv-upscale-2x_animejanai
  - https://github.com/Tsubajashi/mpv-settings

## Scripts utilizados:
- autoload.lua: Carga automáticamente todos los archivos de una carpeta en una lista de reproducción.
- discord.lua: Activa la integración de MPV con el RPC de Discord.
- modernX: Interfaz moderna para MPV (derivada de la rama más reciente y con modificaciones propias).
- thumbfast: Muestra miniaturas en la barra de progreso, similar a YouTube.

## Shaders utilizados:
- Anime4K: Shader glsl que aplica "filtros" (calculos geometricos) que mejoran la nitidez y la calidad del dibujo, además de suavizar la imagen para eliminar artefactos y ruido, todo en tiempo real.
- Animejanai V3 (cacota) y V2 (la buena): Shader ONNX (red neuronal) que remasteriza el anime a 4K en tiempo real. La V2 aumenta drasticamente la nitidez de la imagen sin difuminar, manteniendo asi detalles y texturas. En la V3 no se nota una diferencia entre usalo y el original.


# CHANGELOG

## MPVNET DESUKA V1.2 - 4/10/2025

- Añadida una keybind faltante del anterior mpv

## MPVNET DESUKA V1.1 - 15/09/2025

- Añadida compatibilidad con los bordes redondos de w11
- Retocado diseño de los thumbnails

## NUEVO: MPVNET DESUKA V1 (RELEASE) - 25/08/2025
- MPVNET Animejanai v3.2.0 (MPVNET v7.1.1.3-beta + Animejanai V3 + VapourSynth R70 + etc)
- ModernX 0.4.3 (actualizado)
- Thumbfast Feb 4, 2025 (actualizado)
- Se ha añadido el shader de Animejanai V2 (la version buena), el mejor oversharpener.
- Se ha migrado de mpv average a mpvnet.
- Se han migrado TODAS las modificaciones anteriores a este nuevo mpvnet.
- ModernX:
  - Añadido boton de screenshot.
  - Añadido boton de pinear ventana.
  - Nuevos iconos para los botones.
  - Nueva font.
  - Nuevos efectos de hover.
  - Nuevo diseño para los thumbnails.
  - Añadida descripcion del capitulo o peso del archivo (este ultimo esta deshabilitado).
  - Se ha añadido el nombre del chapter.
  - Se ha mejorado el tamaño de la interfaz, textos y mensajes.
  - Se ha arreglado el overlap ente Titulo y Descripcion.
  - Se ha arreglado sin querer la estabilidad del mpvnet con animejanai funcionando al pasar de ventana a fullscreen y al reves. Ahora ya no crashea.
  - Se ha arreglado sin querer la fluidez al avanzar/retroceder en el video cuando se usa el shader de animejanai.
  - Se ha traducido la interfaz de mpvnet al español.
- mpv.conf:
  - Se han fusionado mis cambios con los de Animejanai.
  - Ahora se usa una GPU API y un proceso de renderizado mas eficiente.
  - Existe la funcion "Watch later" que guarda por donde has dejado el video, para continuar desde el punto donde lo dejaste, pero lo he deshabilitado por defecto.
- mpvnet.conf:
  - No guarda el volumen de la anterior sesion.
Nuevas keybinds importantes:
  - ctrl+right_click:           abre un menu contextual con todos los ajustes.
  - ctrl+E:                     abre el menu de animejanai.
  - ctrl+J:                     Animejanai status.
  - C:                          abre el menu de mpvnet (porfa no toques nada o romperas el archivo de config 😭🙏🏻 y sera culpa tuya, no mia).
  - S:                          Toma captura de pantalla.
  - M:                          Mutea el video.
  - ctrl+1, ctrl+2, ctrl+3:     inicia animejanai v2.
  - shift+1, shift+2, shift+3:  inicia animejanai v3.
  - ctrl+0:                     quita animejanai.
  - 1 - 6:                      inicia anime4k.
  - 0:                          quita anime4k.
- DiscordRPC:
  - Se ha cambiado la key de On/Off a 'D'.
- Y seguramente mas cosas...

## MPV v5.1
- Varios fixes a las keybinds sobretodo.
- Vuelta a la version antigua del Autoload, carga lo que ha de cargar. La nueva no es configurable y se lo traga todo.

## MPV v5
- Versión de MPV: 64-bit V3 2024-08 (la V3 tiene mejor rendimiento con shaders, en teoría).
- Custom Config:
  - input.conf:
    - Eliminadas opciones peligrosas y configuradas combinaciones de teclas más seguras (a prueba de errores, evitando dañar el video accidentalmente al presionar una tecla incorrecta).
    - Añadidas más opciones útiles y simplificadas otras:
      - Avance por fotogramas.
      - Avance/retroceso de 5 segundos arreglado, ahora es exacto.
      - Los shaders de Anime4K son ahora más fáciles de usar.
      - Funciones para ajustar subtítulos y audios en caso de desincronización.
    - Compatibilidad con Linux
  - mpv.conf:
    - Mejora en la preferencia de idioma en subtítulos y audios.
    - Ajustado tiempo de escondido de la interfaz y raton.
    - Mejorado el estilo de los mensajes en pantalla.
    - Ajustes varios en el estilo de la ventana.
    - Opción para aumentar/disminuir el tamaño de los subtítulos (desactivada por defecto porque sobrescribe las fuentes de los subs).
	- Archivo bastante toqueteado, creo que he quitado cosas innecesarias, he reordenado y he actualizado un par de cosas como lo de vo=GPU-Next y profile=high-quality
- ModernX:
  - Ahora se utiliza una rama más reciente con más funciones.
  - Íconos redondeados.
  - Efectos hover en los botones.
  - Mejor degradado.
  - Opción para mover los subtítulos al salir la interfaz (desactivada por defecto, lo que he hecho yo es más cómodo).
  - Tamaño del título del archivo ajustado.
  - Ahora, los botones de avanzar/retroceder del ratón cambian de capítulo.
- ModernX personalizado:
  - Ahora se parece más a la versión anterior.
  - Lista subtítulos y audios al cambiar.
  - Estilos de los mensajes en pantalla ajustados (más agradables).
  - La interfaz (OSC) se desvanece en la pausa.
  - Arreglada la función de los botones centrales.
  - Efecto hover eliminado de elementos que no son botones.
- Thumbfast:
  - Se ha añadido Thumbfast a ModernX, ahora aparecerán miniaturas en la barra de tiempo como en YouTube.
- Autoload:
  - Nueva versión de Autoload.