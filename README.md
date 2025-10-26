[🇪🇸 Español](#mpvnet-desuka) | [🇬🇧 English](#mpvnet-desuka-en)

# ✨MPVNET DESUKA✨

**mpvnet desuka** es una versión personalizada de mpvnet creada con el objetivo de ver anime en la mejor calidad y comodidad posible.  
Remasteriza a 4k la imagen original con el uso de shaders en tiempo real, sin perder detalles del fondo de la escena ni de las texturas, a la vez que se eliminan los artefactos que puedan haber. Incluye tambien, una interfaz moderna y funciones extra, convirtiendolo asi en un reproductor completo y fácil de usar, a diferencia del mpv/mpvnet base. 

> 📝 *Tambien apto para pelis y series.*

<img width="2674" height="1383" alt="Captura de pantalla (427)" src="https://github.com/user-attachments/assets/195fad87-b80a-42a7-88ba-d2e7e4601df4" />

### 🎞️ Comparaciones

| Escenarios | Mejor Encode* vs AnimeJaNai V2 UC vs Anime4k Mode A (los mas nitidos) |
|-|-|
| Primeros Planos | [Link](https://slow.pics/c/Cb703Qla) |
| Fondos y Texturas | [Link](https://slow.pics/c/AR9TAsPZ) |

> 📝 ***Mejor Encode:** El mejor encode que existe, segun Sneedex y SeaDex.*  

| Shaders | Comparaciones Extra |
|-|-|
| Mejor Encode vs AnimeJaNai V3 C vs AnimeJaNai V2 UC vs Anime4k Mode A | [Link](https://slow.pics/c/XJtobDb0) |
| Mejor Encode vs AnimeJaNai V3 C vs AnimeJaNai V3 Sharp SUC / UC / C vs AnimeJaNai V2 UC | [Link](https://slow.pics/c/3Cz5SCTY) |
| Mejor Encode vs Anime4k Mode A vs AnimeJaNai V2 SUC vs AnimeJaNai V2 UC | [Link](https://slow.pics/c/QgO4Wf5i) |

> 📝 *Si te cuesta ver las diferencias entre, por ejemplo: la 2a captura y la 4a o 5a, usa la opción de Slider.*  

### Mi recomendacion:  

| Opción Recomendada | Shader y Modelo | Situaciones de uso |
|-|-|-|
| Opcion 1 | AnimeJaNai V2 UC | El más nitido, sin pasarse (en mi opinion, AnimeJaNai V2 C es demasiado). |
| Opcion 2 | AnimeJaNai V3 Sharp C > UC > SUC | Recomendado si eres mas puritano y quieres un buen balance entre nitidez/fidelidad. |
| Opcion 3 | AnimeJaNai V2 SUC > Anime4k | Recomendado si quieres mas nitidez, pero te limita la GPU. (Ambas opciones difuminan un poco los fondos, sobretodo Anime4k). |
| Opcion 4 | AnimeJaNai V3 C > UC > SUC | Recomendado si eres muy puritano, y solo quieres pulir la imagen y eliminar todos los artefactos que pueda tener el encode. |

## 🧰 Instalación

> 🪟 **Windows Only**  
> 💻 *Puede que funcione en Linux mediante WINE, pero no te lo aseguro.*

1. **Extrae** la carpeta `mpvnet desuka` donde quieras.  
   - Recomendado: `C:\Program Files\mpvnet desuka` o `C:\APPs\mpvnet desuka` si eres especial como yo.

2. Si lo has guardado en otra ruta:
   - Ve a `portable_config/script-opts/discord.conf`
   - Edita la ruta en esta linea: `binary_path=C:\Program Files\mpvnet desuka\mpv-discord.exe`

3. Para **GPUs AMD**:
   - Ve a `mpvnet desuka > ctrl+E > Global Settings`
   - Y cambia `Upscaling Backend` de `TensorRT` a `DirectML`

4. En **GPUs NVIDIA**:
   - La primera vez que cargues cada modelo de **AnimeJaNai**, se abrira una terminal. No te asustes, eso es el engine creando un perfil `.engine` para tu PC.  

- Ten en cuenta que AnimeJaNai es un shader pesado y cada vez que lo actives tardara unos segundos en verse el cambio en el video.  
  Pausa el video antes de activarlo, desactivarlo o cambiar de modelo y no maximices ni entres en pantalla completa mientras carga.

- El mpvnet de AnimeJaNai es muy sensible, asi que tratalo con delicadeza.  
  Si esta haciendo una cosa (cargando un modelo, desvaneciendo la interfaz...), espera a que termine antes de hacer la siguiente (cambiar la pista de subs, avanzar/retroceder...).

5. Ahora te toca aprender las **Keybinds** para saber como usarlo del todo :)  
Leete tambien el **changelog** (¡muy interesante!) y la **documentacion** + la documentacion de lo que esta incluido si quieres saber mas.

### 🧯 Troubleshooting

- Si AnimeJaNai no funciona (no carga o no ves cambios):  
➝ Borra todos los `.engine` en `mpvnet desuka/animejanai/onnx`.

- Si mpvnet o la interfaz se congela:  
➝ Abre el Administrador de tareas y mata el proceso de `mpvnet` y `mpv-discord.exe`. 

## 📖 Documentación

### 🔧 Requisitos recomendados

- **AnimeJaNai**:

| Modelo | GPU |
|-|-|
| Compact (C) | RTX 4090 |
| Ultra Compact (UC) | RTX 3080 |
| Super Ultra Compact (SUC) | RTX 3060 |

- **Anime4K** *(mas ligero)*:

| Resolucion de tu pantalla | Modo | GPU |
|-|-|-|
| 4K | Cualquier Modo | GPU de gama media-alta y alta |
| 1080p | Cualquier Modo | GPU de gama media-baja y media |

### 🧩 ¿Qué incluye?

| | Tipo | Descripción |
|-|-|-|
| [**AnimeJaNai V2 & V3**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Shader ONNX | V2: Remasteriza la imagen a 4K aumentando drasticamente el nivel de detalle y nitidez, a la vez que elimina artefactos, pero en algunos casos puede verse raro en escenas con blur o aberracion cromatica. V3: Recomendado para puristas. Remasteriza la imagen a 4K manteniendo todos los detalles, arreglando el line art, eliminando bordes de sierra y otros artefactos que puedan haber, mientras preserva los efectos originales de blur, difuminados, aberracion cromatica... Aunque cuesta apreciar la diferencia. En cambio la version Sharp, ofrece lo mismo, pero con un poco mas de nitidez.  |
| [**Anime4K**](https://github.com/h5mcbox/anime4k) | Shader GLSL | Mejora la nitidez y elimina artefactos, pero suaviza mucho la imagen, perdiendo asi detalles del fondo de la escena y texturas aplicadas al dibujado. |
| [**autoload**](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) | Script | Carga automáticamente todos los archivos de vídeo en la carpeta a la lista de reproducción. |
| [**modernX**](https://github.com/zydezu/ModernX) | Script | Interfaz moderna para mpv, con modificaciones propias. *(Uso la rama mas mantenida a dia de hoy)* |
| [**thumbfast**](https://github.com/po5/thumbfast) | Script | Muestra miniaturas en la barra de progreso, como en YouTube. *(Uso una version antigua a proposito)* |
| [**DiscordRPC**](https://github.com/tnychn/mpv-discord) | Script | Integración con Discord Rich Presence. |
| **Custom Config** | Configuración | Comportamiento del reproductor personalizado, a travs de modificaciones a: mpv.conf, mpvnet.conf input.conf, animejanai.conf y script-opts. Fuentes: [Ref1](https://github.com/the-database/mpv-upscale-2x_animejanai) · [Ref2](https://github.com/Tsubajashi/mpv-settings) |
| [**mpvnet**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Reproductor Base | Version modificada por AnimeJaNai. |

### ⌨️ Keybinds importantes

- `Click derecho`, `Espacio` ➝ Pausa  
- `Ctrl + Click derecho` ➝ Abre el menú contextual con todos los ajustes  
- `Ctrl + E` ➝ Abre el menú de AnimeJaNai  
- `Ctrl + J` ➝ Muestra qué modelo de AnimeJaNai está activo  
- `C` ➝ Abre el menú de mpvnet *(porfa no toques nada o puedes romper la config 😭🙏🏻 y será culpa tuya, no mía)*  
- `Ctrl + 1 / 2 / 3` ➝ Activa AnimeJaNai V2 ( C / UC / SUC )
- `Ctrl + 4 / 5 / 6` ➝ Activa AnimeJaNai V3 Sharp ( C / UC / SUC )
- `Ctrl + 7 / 8` ➝ Perfiles de AnimeJaNai vacios, por si quieres encadenar varios modelos en un perfil nuevo, desde el menu de AnimeJaNai. 
- `Ctrl + 7` ➝ Activa AnimeJaNai V1 SD Beta  
- `Shift + 1 / 2 / 3` ➝ Activa AnimeJaNai V3 ( C / UC / SUC )  
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

### ⚙️ Algunos detalles importantes

- El guardado del **nivel de volumen** entre sesiones está desactivado por defecto.  
  → Si quieres activarlo, abre `mpvnet.conf` y cambia `remember-volume=no` a `yes`.

- La función **“watch later”** también está desactivada por defecto.  
  → Para activarla, abre `mpv.conf`, cambia `resume-playback=no` a `yes` y descomenta `watch-later-options=start`.

- Algunos botones de la interfaz tienen **dos funciones**:  
  → **Click derecho** = función principal  
  → **Click izquierdo** = función alternativa

- Las pistas de Audio y Subtitulos se cargaran automatiamente en este orden, independientemente de su posición (puedes cambiarlo en `mpv.conf`):  
  → **Audio:** `Japones`, `Ingles`, `Español`, etc.  
  → **Subtitulos:** `Español`, `Latino`, `Ingles`, etc.

# ✨MPV DESUKA (LITTLE)✨

Mi antigua version, actualizada con los cambios de la nueva.

## ¿Qué cambia?

- Usa **mpv** en lugar de **mpvnet** como base  
- Incluye solo **Anime4K** (sin AnimeJaNai)  
- Pesa **~120 MB** en lugar de más de **6 GB**  
- Es **100 % estable**, sin *crasheos*  
- También funciona en **Linux con Wine**
- Para instalar, tan solo sigue los pasos 1 y 2

> 📝 *Las Keybinds de teclas y la configuración son las mismas.*

## 🆕 Changelog (Pre-GitHub)

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

**mpvnet desuka** is a custom build of mpvnet made to watch anime in the best possible quality and comfort.  
It upscales to 4k the original image using real-time shaders, without losing any details in the background or textures, while eliminating any artifacts that may be present. It also includes a modern interface and extra features, making it a complete and easy-to-use player, unlike the base mpv/mpvnet. 

> 📝 *Also suitable for movies and series.*

<img width="2674" height="1383" alt="Captura de pantalla (427)" src="https://github.com/user-attachments/assets/195fad87-b80a-42a7-88ba-d2e7e4601df4" />

### 🎞️ Comparisons

| Scenarios | Best Encode* vs AnimeJaNai V2 UC vs Anime4k Mode A (the sharpest ones) |
|-|-|
| Close-ups | [Link](https://slow.pics/c/Cb703Qla) |
| Backgrounds and Textures | [Link](https://slow.pics/c/AR9TAsPZ) |

> 📝 ***Best Encode:** The best encode available according to Sneedex and SeaDex.*  

| Shaders | Extra Comparisons |
|-|-|
| Best Encode vs AnimeJaNai V3 C vs AnimeJaNai V2 UC vs Anime4k Mode A | [Link](https://slow.pics/c/XJtobDb0) |
| Best Encode vs AnimeJaNai V3 C vs AnimeJaNai V3 Sharp SUC / UC / C vs AnimeJaNai V2 UC | [Link](https://slow.pics/c/3Cz5SCTY) |
| Best Encode vs Anime4k Mode A vs AnimeJaNai V2 SUC vs AnimeJaNai V2 UC | [Link](https://slow.pics/c/QgO4Wf5i) |

> 📝 *If you have a hard time seeing the differences between, for example, the 2nd and 4th, 5th... screenshots, use the Slider option.*  

### My recommendation:  

| Recommended Option | Shader and Model | Use cases |
|-|-|-|
| Option 1 | AnimeJaNai V2 UC | The sharpest, without being excessive (in my opinion, AnimeJaNai V2 C is too much). |
| Option 2 | AnimeJaNai V3 Sharp C > UC > SUC | Recommended if you are more purist and want a good balance between sharpness and fidelity. |
| Option 3 | AnimeJaNai V2 SUC > Anime4k | Recommended if you want more sharpness, but are limited by your GPU. (Both options blur the backgrounds a little, especially Anime4k). |
| Option 4 | AnimeJaNai V3 C > UC > SUC | Recommended if you are really purist and only want to polish the image and remove all the artifacts that the encoding may have. |

## 🧰 Installation

> 🪟 **Windows only**  
> 💻 *Might work on Linux with WINE, but idk.*

1. **Extract** the `mpvnet desuka` folder wherever you want.  
   - Recommended: `C:\Program Files\mpvnet desuka` or `C:\APPs\mpvnet desuka` if you’re special like me.

2. If you saved it in a different path:
   - Go to `portable_config/script-opts/discord.conf`
   - Edit the line: `binary_path=C:\Program Files\mpvnet desuka\mpv-discord.exe`

3. For **AMD GPUs**:
   - Go to `mpvnet desuka > ctrl+E > Global Settings`
   - Change `Upscaling Backend` from `TensorRT` to `DirectML`

4. In **NVIDIA GPUs**:
   - The first time you load any **AnimeJaNai** model, a terminal window will pop up. Don’t panic, the engine is creating a `.engine` profile for your PC.
   
- Keep in mind AnimeJaNai is heavy: every time you enable it, it’ll take a few seconds to apply.  
  Pause the video before switching models, and do not maximize nor enter full screen while the shader is still loading.

- The AnimeJaNai build of mpvnet is very "sensitive", so treat it with care.  
  If it’s doing something like loading a model or fading the interface, wait until it finishes before doing something else like seeking backward/forward.

5. Now it’s time to learn the **keybinds** so you can actually fully use it :)  
Also check the **changelog** (very interesting!) and the **documentation** + the documentation of what's included if you want to know more.

### 🧯 Troubleshooting

- If AnimeJaNai doesn’t work (no load or no visible effect):  
  ➝ Delete all `.engine` files in `mpvnet desuka/animejanai/onnx`.

- If mpvnet or the interface freezes:  
  ➝ Open Task Manager and kill the mpvnet and mpv-discord.exe processes.  

## 📖 Documentation

### 🔧 Recommended Requirements

- **AnimeJaNai**:

| Model | GPU |
|-|-|
| Compact (C) | RTX 4090 |
| Ultra Compact (UC) | RTX 3080 |
| Super Ultra Compact (SUC) | RTX 3060 |

- **Anime4K** *(lighter)*:

| Your Screen Resolution | Mode | GPU |
|-|-|-|
| 4K | Any Mode | Mid-high to high-end GPU |
| 1080p | Any Mode | Mid-low to mid-range GPU |

### 🧩 What's included?

| | Tipo | Descripción |
|-|-|-|
| [**AnimeJaNai V2 & V3**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Shader ONNX | Remasters the image to 4K, drastically increasing the level of detail and sharpness while removing artifacts, but in some cases it may look strange in scenes with blur or chromatic aberration. V3: Recommended for purists. Remasters the image to 4K, maintaining all the details, fixing the line art, removing jagged edges and other artifacts that may be present, while preserving the original effects of blur, dithering, chromatic aberration... Although it's hard to see the difference. On the other hand, the Sharp version offers the same thing, but with a little more sharpness. |
| [**Anime4K**](https://github.com/h5mcbox/anime4k) | Shader GLSL | Sharpens and removes artifacts, but softens the image a lot, losing some background and texture details. |
| [**autoload**](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) | Script | Automatically loads all video files in the folder into the playlist. |
| [**modernX**](https://github.com/zydezu/ModernX) | Script | Modern mpvnet interface with custom modifications. *(Using the most maintained branch.)* |
| [**thumbfast**](https://github.com/po5/thumbfast) | Script | Displays thumbnails on the progress bar, just like YouTube. *(Using a previous commit to fix a bug.)* |
| [**DiscordRPC**](https://github.com/tnychn/mpv-discord) | Script |  Discord Rich Presence integration. |
| **Custom Config** | Configuración | Custom player behavior, through modifications to: mpv.conf, mpvnet.conf, input.conf, animejanai.conf, and script-opts. Sources: [Ref1](https://github.com/the-database/mpv-upscale-2x_animejanai) · [Ref2](https://github.com/Tsubajashi/mpv-settings) |
| [**mpvnet**](https://github.com/the-database/mpv-upscale-2x_animejanai) | Base player | AnimeJaNai modified version of mpvnet. |

### ⌨️ Keybinds

- `Right Click`, `Space` ➝ Pause  
- `Ctrl + Right Click` ➝ Opens contextual menu with all settings  
- `Ctrl + E` ➝ Opens AnimeJaNai menu  
- `Ctrl + J` ➝ Shows which AnimeJaNai model is active  
- `C` ➝ Opens mpvnet menu *(please don’t mess around or you might break the config 😭🙏🏻 and it’ll be your fault, not mine)*  
- `Ctrl + 1 / 2 / 3` ➝ Enable AnimeJaNai V2 (C / UC / SUC)
- `Ctrl + 4 / 5 / 6` ➝ Enable AnimeJaNai V3 Sharp (C / UC / SUC)
- `Ctrl + 7 / 8` ➝ Empty AnimeJaNai profiles, in case you want to chain several models into a new profile from the AnimeJaNai menu.
- `Ctrl + 7` ➝ Enable AnimeJaNai V1 SD Beta  
- `Shift + 1 / 2 / 3` ➝ Enable AnimeJaNai V3 (C / UC / SUC)  
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
  → To enable it, open `mpv.conf`, change `resume-playback=no` to `yes` and uncomment `watch-later-options=start`.

- Some buttons in the interface have **dual functions**:  
  → **Right Click** = primary action  
  → **Left Click** = alternate action

- Audio and subtitle tracks will load automatically in this order, regardless of their position (you can change it in `mpv.conf`):  
  → **Audio:** `Japanese`, `English`, `Spanish`, etc.  
  → **Subtitles:** `Spanish`, `Latin`, `English`, etc.

# ✨MPV DESUKA (LITTLE)✨

My older build, updated with the latest changes.

## What’s different?

- Uses **mpv** instead of **mpvnet** as the base  
- Includes only **Anime4K** (no AnimeJaNai)  
- Size reduced to **~120 MB** instead of **6 GB+**  
- **100 % stable**, no crashes  
- Also works on **Linux with Wine**
- To install it, just follow steps 1 and 2

> 📝 *Keybinds and configuration are the same.*

## 🆕 Changelog (Pre-GitHub)

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
