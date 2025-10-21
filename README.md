[🇪🇸 Español](#mpvnet-desuka) | [🇬🇧 English](#mpvnet-desuka-en)

# ✨MPVNET DESUKA✨

**mpvnet desuka** es una versión personalizada de mpvnet diseñada con el objetivo de reproducir anime en la mejor calidad posible, mejorando la imagen original con el uso de shaders en tiempo real, sin perder detalles del fondo de la escena ni de las texturas. 
Además, incluye una interfaz moderna y funciones añadidas que lo convierten en un reproductor completo y fácil de usar.

<img width="2538" height="1350" alt="imagen" src="https://github.com/user-attachments/assets/8dbd4a62-3fd3-464a-86f6-e49ac8b4eed8" />

### 🎞️ Comparaciones

| Escenarios | Mejor Encode* vs AnimeJaNai V2** vs Anime4k*** |
|-|-|
| Primeros Planos | [Link](https://slow.pics/c/Cb703Qla) |
| Fondos, Texturas y Letras | [Link](https://slow.pics/c/AR9TAsPZ) |

****Mejor Encode** Blu-Ray segun Sneedex y SeaDex.*  
*****AnimeJaNai V2** con el modelo Ultra Compact. En mi opinion, el modelo (superior) Compact es un poco demasiado y requiere mucha mas potencia por poca mejora extra.*  
******Anime4k** con el modo A. En mi opinion, el mejor modo relacion nitidez/difuminado.*

## 🧰 Instalación

> 🪟 **Solo Windows**  
> 💻 *Puede funcionar en Linux mediante WINE, pero no está garantizado.*

1. **Extrae** la carpeta `mpvnet desuka` donde quieras.  
   - Recomendado: `C:\Program Files\mpvnet desuka` o `C:\APPs\mpvnet desuka` si eres especial como yo.

2. Si lo has guardado en otra ruta:
   - Ve a `portable_config/script-opts/discord.conf`
   - Edita la ruta en esta linea: `binary_path=C:\Program Files\mpvnet desuka\mpv-discord.exe`

3. Para **GPUs AMD**:
   - Ve a `mpvnet desuka > ctrl+E > Global Settings`
   - Y cambia `Upscaling Backend` de `TensorRT` a `DirectML`

4. La primera vez que cargues cada modelo de **AnimeJaNai**, se abrira una terminal. No te asustes, eso es el engine creando un perfil `.engine` para tu PC.  
Ten en cuenta que AnimeJaNai es un shader pesado y cada vez que lo actives tardara unos segundos en verse el cambio en el video. Si has de activarlo, desactivarlo o cambiar de modelo, pausa antes el video.

6. Ahora te toca aprender las **Keybinds** para saber como usarlo del todo :)  
Leete tambien el **changelog** (importante, para saber que cambios se han hecho y funciones extra que podrian ser de tu interes) + la documentacion, no seas vago.

### 🔄 Actualización

- **Opción 1:** Sustituye solo los archivos actualizados.  
- **Opción 2:** Elimina la carpeta anterior y extrae la nueva versión.  
*(Si usas AnimeJaNai, tendrás que regenerar los archivos `.engine`.)*

### 🧯 Troubleshooting

- Si AnimeJaNai no funciona (no carga o no ves cambios):  
➝ Borra todos los `.engine` en `mpvnet desuka/animejanai/onnx`.

- Si mpvnet o la interfaz se congela:  
➝ Abre el Administrador de tareas y mata el proceso de mpvnet y mpv-discord.exe. 
*(El mpvnet de AnimeJaNai es muy sensible, asi que tratalo con delicadeza. Si esta haciendo una cosa (cargando un modelo, desvaneciendo la interfaz...), espera a que termine antes de hacer la siguiente (maximizar la pantalla, cambiar la pista de subs...).)*

- Si aparece "thumbfast ERROR" y no aparecen los thumbnails:
➝ Cierra y vuelve a abrir el video, pero espera unos segundos antes de pasar el raton por encima de la barra, para que le de tiempo de cargar los frames.

- Si aparece "thumbfast ERROR", pero si aparecen los thumbnails:
➝ No hagas caso 👍🏻

## 📖 Documentación

### 🔧 Requisitos recomendados
- **AnimeJaNai**:

| Resolucion de tu pantalla | Perfil | GPU |
|-|-|-|
| 4K | Modo 1 Compact | RTX 4090 |
| 4K | Modo 2 Ultra Compact | RTX 3080 |
| 4K | Modo 3 Super Ulta Compact | RTX 3060 |
| 1080p | Cualquier Modo | GPU de gama media |

- **Anime4K** *(mas ligero)*:

| Resolucion de tu pantalla | Perfil | GPU |
|-|-|-|
| 4K | Cualquier Modo | GPU de gama media-alta y alta |
| 1080p | Cualquier Modo | GPU de gama media-baja y media |

### 🧩 Shaders incluidos

| Shader            | Descripción                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**AnimeJaNai V2 & V3**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Shader ONNX. V2: remasteriza la imagen 4K manteniendo todos los detalles, a la vez que elimina artefactos, pero en algunos casos puede verse raro en escenas con blur o aberracion cromatica. V3: resultado practicamente identico al original, no recomiendo usarlo. |
| [**Anime4K**](https://github.com/h5mcbox/anime4k)        | Shader GLSL. Mejora nitidez y elimina artefactos, pero suaviza mucho la imagen, perdiendo asi detalles del fondo de la escena y texturas aplicadas a la imagen.                             |

### 🧩 Scripts incluidos

| Script            | Descripción                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**autoload.lua**](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)   | Carga automáticamente todos los archivos de vídeo en la carpeta a la lista de reproducción. *(Uso una versión antigua a propósito)* |
| [**modernX**](https://github.com/zydezu/ModernX)        | Interfaz moderna para mpv, con modificaciones propias. *(Uso la rama mas mantenida a dia de hoy)*                            |
| [**thumbfast**](https://github.com/po5/thumbfast)      | Muestra miniaturas en la barra de progreso, como en YouTube.                                    |
| [**DiscordRPC**](https://github.com/tnychn/mpv-discord)     | Integración con Discord Rich Presence.                                                           |
| **Custom Config**  | mpv.conf, mpvnet.conf input.conf y script-opts personalizados. Fuentes: [Ref1](https://github.com/the-database/mpv-upscale-2x_animejanai) · [Ref2](https://github.com/Tsubajashi/mpv-settings)                                |
| [**mpvnet**](https://github.com/the-database/mpv-upscale-2x_animejanai)  | Version modificada por AnimeJaNai                                |

### ⌨️ Keybinds importantes

- `Click derecho`, `Espacio` ➝ Pausa  
- `Ctrl + Click derecho` ➝ Abre el menú contextual con todos los ajustes  
- `Ctrl + E` ➝ Abre el menú de AnimeJaNai  
- `Ctrl + J` ➝ Muestra qué modelo de AnimeJaNai está activo  
- `C` ➝ Abre el menú de mpvnet *(porfa no toques nada o puedes romper la config 😭🙏🏻 y será culpa tuya, no mía)*  
- `Ctrl + 1 / 2 / 3` ➝ Activa AnimeJaNai V2 (4090 / 3080 / 3060)  
- `Shift + 1 / 2 / 3` ➝ Activa AnimeJaNai V3 (4090 / 3080 / 3060)  
- `Ctrl + 0` ➝ Desactiva AnimeJaNai  
- `1–6` ➝ Activa los diferentes modos de Anime4K  
- `0` ➝ Desactiva Anime4K  
- `D` ➝ Activa o desactiva Discord Rich Presence  
- `S` ➝ Toma capturas de pantalla desde el reproductor  
- `↑` ➝ Subir volumen (+2)  
- `↓` ➝ Bajar volumen (−2)  
- `Shift + ↑` ➝ Subir volumen (+50)  
- `Shift + ↓` ➝ Bajar volumen (−50)  
- `→` ➝ Avanzar 5 segundos  
- `←` ➝ Retroceder 5 segundos  
- `Ctrl + →` ➝ Avanzar 85 segundos  
- `Ctrl + ←` ➝ Retroceder 85 segundos
- `Shift + →` ➝ Avanzar un fotograma  
- `Shift + ←` ➝ Retroceder un fotograma  

> 📝 *AnimeJaNai y anime4k se pueden usar en conjunto, pero es muy criminal, mejor no lo hagas.*

### ⚙️ Detalles importantes

- El guardado del **nivel de volumen** entre sesiones está desactivado por defecto.  
  → Si quieres activarlo, abre `mpvnet.conf` y cambia `remember-volume=no` a `yes`.

- La función **“watch later”** también está desactivada por defecto.  
  → Para activarla, abre `mpv.conf` y descomenta `watch-later-options=start`.

- Algunos botones de la interfaz tienen **dos funciones**:  
  → **Click derecho** = función principal  
  → **Click izquierdo** = función alternativa

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
  <summary><strong>🆕 MPVNET DESUKA V1 (RELEASE) - 25/08/2025</strong></summary>

- MPVNET AnimeJaNai v3.2.0 (MPVNET v7.1.1.3-beta + AnimeJaNai V3 + VapourSynth R70 + etc)
- ModernX 0.4.3 (actualizado)
- Thumbfast Feb 4, 2025 (actualizado)
- Se ha añadido el shader de AnimeJaNai V2 (la version buena), el mejor oversharpener.
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
  - Se ha arreglado sin querer (un poco) la estabilidad del mpvnet con animejanai funcionando al pasar de ventana a fullscreen y al reves. Ahora ya no crashea.
  - Se ha arreglado sin querer (un poco) la fluidez al avanzar/retroceder en el video cuando se usa el shader de animejanai.
  - Se ha traducido la interfaz de mpvnet al español.
- mpv.conf:
  - Se han fusionado mis cambios con los de AnimeJaNai.
  - Ahora se usa una GPU API y un proceso de renderizado mas eficiente.
  - Existe la funcion "Watch later" que guarda por donde has dejado el video, para continuar desde el punto donde lo dejaste, pero lo he deshabilitado por defecto.
- mpvnet.conf:
  - No guarda el volumen de la anterior sesion.
Nuevas keybinds importantes:
  - ctrl+right_click:           abre un menu contextual con todos los ajustes.
  - ctrl+E:                     abre el menu de animejanai.
  - ctrl+J:                     AnimeJaNai status.
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

---

# ✨MPVNET DESUKA (EN)✨

**mpvnet desuka** is a custom build of mpvnet made to play anime at the highest possible quality, enhancing the original image in real time through shaders without losing background or texture details.  
It also includes a modern interface and extra features, making it a complete and easy-to-use player.

<img width="2538" height="1350" alt="imagen" src="https://github.com/user-attachments/assets/8dbd4a62-3fd3-464a-86f6-e49ac8b4eed8" />

### 🎞️ Comparisons

| Scenarios | Best Encode* vs AnimeJaNai V2** vs Anime4K*** |
|-|-|
| Close-ups | [Link](https://slow.pics/c/Cb703Qla) |
| Backgrounds, Textures & Text | [Link](https://slow.pics/c/AR9TAsPZ) |

***Best Blu-Ray Encode** according to Sneedex and SeaDex.  
****AnimeJaNai V2** using the Ultra Compact model. In my opinion, the superior Compact model is a bit too much — it requires far more GPU power for very little visual improvement.  
*****Anime4K** in Mode A — in my opinion, the best balance between sharpness and softness.

## 🧰 Installation

> 🪟 **Windows only**  
> 💻 *Might work on Linux with WINE, but not guaranteed.*

1. **Extract** the `mpvnet desuka` folder wherever you want.  
   - Recommended: `C:\Program Files\mpvnet desuka` or `C:\APPs\mpvnet desuka` if you’re special like me.

2. If you saved it in a different path:
   - Go to `portable_config/script-opts/discord.conf`
   - Edit the line: `binary_path=C:\Program Files\mpvnet desuka\mpv-discord.exe`

3. For **AMD GPUs**:
   - Go to `mpvnet desuka > ctrl+E > Global Settings`
   - Change `Upscaling Backend` from `TensorRT` to `DirectML`

4. The first time you load any **AnimeJaNai** model, a terminal window will pop up. Don’t panic, the engine is creating a `.engine` profile for your PC.  
Keep in mind AnimeJaNai is heavy: every time you enable it, it’ll take a few seconds to apply. If you need to enable/disable or switch models, pause the video first.

6. Now it’s time to learn the **keybinds** so you can actually fully use it :)  
Also check the **changelog** (important to see what’s new or changed) and the **documentation**. Don’t be lazy.

### 🔄 Updating

- **Option 1:** Replace only the updated files.  
- **Option 2:** Delete the previous folder and extract the new version.  
  *(If you use AnimeJaNai, you’ll need to regenerate the `.engine` files.)*

### 🧯 Troubleshooting

- If AnimeJaNai doesn’t work (no load or no visible effect):  
  ➝ Delete all `.engine` files in `mpvnet desuka/animejanai/onnx`.

- If mpvnet or the interface freezes:  
  ➝ Open Task Manager and kill the mpvnet and mpv-discord.exe processes.  
  *(The AnimeJaNai build of mpvnet is very sensitive, if it’s doing something like loading a model or fading the interface, wait until it finishes before doing something else.)*

- If “thumbfast ERROR” appears and thumbnails don’t load:  
  ➝ Close and reopen the video, and wait a few seconds before hovering over the progress bar so frames can preload.

- If “thumbfast ERROR” appears but thumbnails do load:  
  ➝ Ignore it 👍🏻

## 📖 Documentation

### 🔧 Recommended Requirements

- **AnimeJaNai:**

| Your Screen Resolution | Profile | GPU |
|-|-|-|
| 4K | Mode 1 Compact | RTX 4090 |
| 4K | Mode 2 Ultra Compact | RTX 3080 |
| 4K | Mode 3 Super Ultra Compact | RTX 3060 |
| 1080p | Any Mode | Mid-range GPU |

- **Anime4K** *(lighter)*:

| Your Screen Resolution | Profile | GPU |
|-|-|-|
| 4K | Any Mode | Mid-high to high-end GPU |
| 1080p | Any Mode | Mid-low to mid-range GPU |

### 🧩 Included Shaders

| Shader            | Description                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**AnimeJaNai V2 & V3**](https://github.com/the-database/mpv-upscale-2x_animejanai) | ONNX shader. V2 remasters 4K video while preserving all details and removing artifacts, though in some cases it can look odd in scenes with blur or chromatic aberration. V3 produces a nearly identical result to the original — not recommended. |
| [**Anime4K**](https://github.com/h5mcbox/anime4k)        | GLSL shader. Sharpens and removes artifacts, but softens the image a lot, losing some background and texture details. |

### 🧩 Included Scripts

| Script            | Description                                                                                     |
|--------------------|--------------------------------------------------------------------------------------------------|
| [**autoload.lua**](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)   | Automatically loads all video files in the folder into the playlist. *(I use an old version on purpose.)* |
| [**modernX**](https://github.com/zydezu/ModernX)        | Modern mpvnet interface with custom modifications. *(Using the most maintained branch.)* |
| [**thumbfast**](https://github.com/po5/thumbfast)      | Displays thumbnails on the progress bar, just like YouTube. |
| [**DiscordRPC**](https://github.com/tnychn/mpv-discord)     | Discord Rich Presence integration. |
| **Custom Config**  | Custom `mpv.conf`, `mpvnet.conf`, `input.conf`, and `script-opts`. Sources: [Ref1](https://github.com/the-database/mpv-upscale-2x_animejanai) · [Ref2](https://github.com/Tsubajashi/mpv-settings) |
| [**mpvnet**](https://github.com/the-database/mpv-upscale-2x_animejanai)  | AnimeJaNai-modified version of mpvnet. |

### ⌨️ Keybinds

- `Right Click`, `Space` ➝ Pause  
- `Ctrl + Right Click` ➝ Opens contextual menu with all settings  
- `Ctrl + E` ➝ Opens AnimeJaNai menu  
- `Ctrl + J` ➝ Shows which AnimeJaNai model is active  
- `C` ➝ Opens mpvnet menu *(please don’t mess around or you might break the config 😭🙏🏻 and it’ll be your fault, not mine)*  
- `Ctrl + 1 / 2 / 3` ➝ Enable AnimeJaNai V2 (4090 / 3080 / 3060)  
- `Shift + 1 / 2 / 3` ➝ Enable AnimeJaNai V3 (4090 / 3080 / 3060)  
- `Ctrl + 0` ➝ Disable AnimeJaNai  
- `1–6` ➝ Enable different Anime4K modes  
- `0` ➝ Disable Anime4K  
- `D` ➝ Toggle Discord Rich Presence  
- `S` ➝ Take screenshots from the player  
- `Up` ➝ Volume +2  
- `Down` ➝ Volume −2  
- `Shift + Up` ➝ Volume +50  
- `Shift + Down` ➝ Volume −50  
- `Right` ➝ Jump +5 seconds  
- `Left` ➝ Jump −5 seconds  
- `Ctrl + Right` ➝ Jump +85 seconds  
- `Ctrl + Left` ➝ Jump −85 seconds
- `Shift + Right` ➝ Frame-step forward  
- `Shift + Left` ➝ Frame-step backward  

> 📝 *You technically can use AnimeJaNai and Anime4K together, but that’s ilegal. Don’t.*

### ⚙️ Additional Notes

- Saving the current **volume level** for the next session is disabled by default.  
  → To enable it, open `mpvnet.conf` and change `remember-volume=no` to `yes`.  

- The **“watch later”** feature is disabled by default.  
  → To enable it, open `mpv.conf` and uncomment `watch-later-options=start`.

- Some buttons in the interface have **dual functions**:  
  → **Right Click** = primary action  
  → **Left Click** = alternate action


## 🆕 Changelog

<details>
  <summary><strong>MPVNET DESUKA V1.2 - 4/10/2025</strong></summary>

- Added a missing keybind from my previous mpv setup.
</details>

<details>
  <summary><strong>MPVNET DESUKA V1.1 - 15/09/2025</strong></summary>

- Added compatibility with Windows 11 rounded corners.  
- Tweaked thumbnail design.
</details>

<details>
  <summary><strong>🆕 MPVNET DESUKA V1 (RELEASE) - 25/08/2025</strong></summary>

- MPVNET AnimeJaNai v3.2.0 (MPVNET v7.1.1.3-beta + AnimeJaNai V3 + VapourSynth R70 + etc)  
- ModernX 0.4.3 (updated)  
- Thumbfast Feb 4, 2025 (updated)  
- Added AnimeJaNai V2 shader (the good one).  
- Migrated from mpv average to mpvnet.  
- Migrated all previous modifications.
- ModernX:
	- Added screenshot button.  
	- Added pin window button.  
	- New icons, font, and hover effects.  
	- Redesigned thumbnails.  
	- Added chapter name display.  
	- Improved UI scale, text, and messages.  
	- Fixed overlap between title and description.  
	- Accidentally fixed (a little bit) AnimeJaNai stability issues when switching fullscreen.  
	- Accidentally improved (a little bit) seek smoothness with AnimeJaNai enabled.  
	- Translated mpvnet UI into Spanish.
 - mpv.conf:
	- Merged my changes with AnimeJaNai.  
	- More efficient GPU API and rendering process.  
	- “Watch later” feature exists but is disabled by default.
 - mpvnet.conf:
	- Doesn’t save previous session volume.
 - New keybinds:
	- `Ctrl + Right Click` ➝ Context menu  
	- `Ctrl + E` ➝ AnimeJaNai menu  
	- `Ctrl + J` ➝ AnimeJaNai status  
	- `C` ➝ mpvnet menu (don’t break things 😭)  
	- `S` ➝ Screenshot  
	- `M` ➝ Mute  
	- `Ctrl + 1,2,3` ➝ AnimeJaNai V2  
	- `Shift + 1,2,3` ➝ AnimeJaNai V3  
	- `Ctrl + 0` ➝ Disable AnimeJaNai  
	- `1–6` ➝ Anime4K  
	- `0` ➝ Disable Anime4K
 - DiscordRPC:
	- Toggled with `D`.
</details>

<details>
  <summary><strong>MPV v5.1</strong></summary>

- Various keybind fixes.  
- Reverted to old Autoload version (the new one is not configurable and loads everything).
</details>

<details>
  <summary><strong>MPV v5</strong></summary>

- MPV 64-bit V3 (2024-08) — better shader performance in theory.  
- Safer, cleaner `input.conf` with better keybinds.  
- Improved subtitle/audio language preference and UI behavior.  
- Updated ModernX branch with hover effects, rounded icons, gradient, and more.  
- Added Thumbfast for YouTube-like thumbnails.  
- Other tweaks and cleanup.
</details>

---

### 🇪🇸 MADE IN (S)PAIN 🇪🇸


