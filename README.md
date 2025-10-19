# MPVNET DESUKA

**mpvnet desuka** es una versión personalizada de mpvnet diseñada con el objetivo de ofrecer la mejor calidad posible al ver anime, mejorando la imagen gracias al uso de shaders en tiempo real, sin perder detalles en el fondo de la escena ni de las texturas. 
Además, incluye una interfaz moderna y mejoras añadidas que lo convierten en un reproductor completo y fácil de usar.

## 🧰 Instalación

> 🪟 **Solo Windows (Portable)**  
> 💻 *Puede funcionar en Linux mediante WINE, pero no está garantizado.*

1. **Extrae** la carpeta `mpvnet desuka` donde quieras.  
   - Recomendado: `C:\Program Files\mpvnet desuka` o `C:\APPs\mpvnet desuka` si eres especial como yo.

2. Si lo has guardado en otra ruta:
   - Ve a `portable_config/script-opts/discord.conf`
   - Edita la ruta en esta linea: `binary_path=C:\Program Files\mpvnet desuka\mpv-discord.exe`

4. Para **GPUs AMD**:
   - Ve a `mpvnet desuka > ctrl+E > Global Settings`
   - Y cambia `Upscaling Backend` de `TensorRT` a `DirectML`

5. Ahora te toca aprender las keybinds para saber como usarlo del todo :) y leete el changelog (importante) + la docu, no seas vago.

### 🔄 Actualización

- **Opción 1:** Sustituye solo los archivos actualizados.  
- **Opción 2:** Elimina la carpeta anterior y extrae la nueva versión.  
*(Si usas Animejanai, tendrás que regenerar los archivos `.engine`.)*

### 🧯 Troubleshooting

- Si Animejanai no funciona (no carga o no ves cambios):  
➝ Borra todos los `.engine` en `mpvnet desuka/animejanai/onnx`.

- Si mpvnet se congela:  
➝ Abre el Administrador de tareas y mata el proceso.

## 📖 Documentación

### Requisitos recomendados
- **Animejanai**:
  - 4K ➝ Modo 1 ➝ RTX 4090
  - 4K ➝ Modo 2 ➝ RTX 3080
  - 4K ➝ Modo 3 ➝ RTX 3060
  - 1080p ➝ Cualquier Modo ➝ PC de gama media
- **Anime4K** *(mas ligero)*:
  - 4K ➝ PC de gama media-alta y alta
  - 1080p ➝ PC de gama media-baja y media

### 🧩 Shaders incluidos

| Shader            | Descripción                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**Animejanai V2 & V3**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Shader ONNX. V2: remasteriza la imagen 4K manteniendo todos los detalles, a la vez que elimina artefactos, pero puede verse raro en escenas con blur o aberracion cromatica. V3: resultado practicamente identico al original, no recomiendo usarlo. |
| [**Anime4K**](https://github.com/h5mcbox/anime4k)        | Shader GLSL. Mejora nitidez y elimina artefactos, pero suaviza mucho la imagen, perdiendo asi detalles del fondo de la escena y texturas aplicadas a la imagen.                             |

### 🧩 Scripts incluidos

| Script            | Descripción                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**autoload.lua**](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)   | Carga automáticamente todos los archivos de vídeo en la carpeta a la lista de reproducción. *(Uso una versión antigua a propósito)* |
| [**modernX**](https://github.com/zydezu/ModernX)        | Interfaz moderna para mpvnet, con modificaciones propias. *(Uso la rama mas mantenida a dia de hoy)*                            |
| [**thumbfast**](https://github.com/po5/thumbfast)      | Muestra miniaturas en la barra de progreso, como en YouTube.                                    |
| [**DiscordRPC**](https://github.com/tnychn/mpv-discord)     | Integración con Discord Rich Presence.                                                           |
| **Custom Config**  | mpv.conf, mpvnet.conf input.conf y script-opts personalizados. Fuentes: [Ref1](https://github.com/the-database/mpv-upscale-2x_animejanai) · [Ref2](https://github.com/Tsubajashi/mpv-settings)                                |
| [**mpvnet**](https://github.com/the-database/mpv-upscale-2x_animejanai)  | Version modificada por Animejanai                                |

### ⌨️ Keybinds importantes

- `Ctrl + Click derecho` ➝ Menú contextual con todos los ajustes.  
- `Ctrl + E` ➝ Menú de Animejanai.  
- `C` ➝ Menú de mpvnet *(porfa no toques nada o puede q rompas el archivo de config 😭🙏🏻 y sera culpa tuya, no mia)*.  
- `Ctrl + 1 / 2 / 3` ➝ Activa Animejanai V2 (4090 / 3080 / 3060).  
- `Shift + 1 / 2 / 3` ➝ Activa Animejanai V3 (4090 / 3080 / 3060).  
- `Ctrl + 0` ➝ Desactiva Animejanai.  
- `1–6` ➝ Activa los diferentes modos de Anime4K.  
- `0` ➝ Desactiva Anime4K.  
- `D` ➝ Activa/Desactiva Discord Rich Presence.

> 📝 *Animejanai y anime4k se pueden usar en conjunto, pero es muy criminal, mejor no lo hagas.*

## 🆕 Changelog

<details>
  <summary><strong>MPVNET DESUKA V1.2 - 4/10/2025</strong></summary>
	- Añadida una keybind faltante de mi anterior mpv
</details>

<details>
  <summary><strong>MPVNET DESUKA V1.1 - 15/09/2025</strong></summary>
	- Añadida compatibilidad con los bordes redondeados de w11
	- Retocado diseño de los thumbnails
</details>
<details>
  <summary><strong>NUEVO: MPVNET DESUKA V1 (RELEASE) - 25/08/2025</strong></summary>
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
</details>
<details>
  <summary><strong>MPV v5.1</strong></summary>
- Varios fixes a las keybinds sobretodo.
- Vuelta a la version antigua del Autoload, carga lo que ha de cargar. La nueva no es configurable y se lo traga todo.
</details>
<details>
  <summary><strong>MPV v5</strong></summary>
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
</details>
