-- quick_subtitle_edit.lua (v2)
-- Editor rápido de subtítulos externos para mpv.
-- Teclas:
--   Ctrl+z        -> editar el subtítulo actual EN PANTALLA (en el sitio del
--                    subtítulo real, con su estilo y cursor fijo).
--   Ctrl+Shift+z  -> editar en el OSD clásico (fallback/manual).
--
-- Características:
--   * Soporta doble subtítulo simultáneo (pista primaria + secundaria).
--   * Detecta todos los eventos solapados en el instante actual (diálogo,
--     karaoke, carteles...) y muestra un selector OSD si hay varios.
--   * Extrae automáticamente pistas embebidas (ffmpeg) y las selecciona.
--   * Editor con cursor multi-línea (UP/DOWN cambian de línea sin tocar el
--     volumen), teclas con repetición al mantener pulsado (flechas, BS, DEL).
--   * En ASS oculta las tags al editar y restaura las tags iniciales al
--     guardar ({\an8}, posicionamiento, etc.).
--   * Modo pantalla: overlay ASS con el estilo real del evento (fuente,
--     tamaño, colores, bordes, alineación y márgenes del archivo), cursor
--     fijo, y la pista editada se oculta mientras se edita.
--   * Pausa automática al abrir el editor, restaurando el estado al salir.
--   * Guardado robusto: reemplaza solo la línea/bloque del evento,
--     preservando BOM y saltos de línea originales (CRLF/LF).

local utils = require 'mp.utils'
local msg = require 'mp.msg'

--------------------------------------------------------------------------
-- Estado global
--------------------------------------------------------------------------
local state = "idle"        -- "idle" | "select" | "edit"
local candidates = {}       -- eventos candidatos (selector)
local sel_index = 1
local edit = nil            -- sesión de edición activa
local pause_saved = nil     -- estado de pausa previo a entrar
local pending_dead = ""     -- dead key pendiente (´ ¨ ` ^ ~)
local registered = {}       -- nombres de key bindings activos
local binding_counter = 0
local editor_mode_request = "screen"  -- modo pedido al lanzar la edición
local loading = false       -- true mientras se buscan candidatos
-- local loading_timer = nil -- timer del spinner (desactivado, ver show_loading)
local loading_overlay = nil -- overlay del spinner de carga
local selector_overlay = nil-- overlay del menú selector
local help_overlay = nil    -- overlay de la leyenda de controles (esquina sup-izq)
local pending = {}          -- buffers no guardados por candidato al cambiar de evento
local screen = nil          -- estado del modo pantalla (copia-máscara, pista temporal)
local script_created_files = {} -- archivos extraídos por el script aún sin guardar (borrar al cancelar)
local session_rollback = nil    -- sid/secondary-sid previos a la extracción (restaurar al cancelar)
local font_dir_state = nil     -- { old } de osd-fonts-dir para el overlay del editor ("" si no había)
local session_edit_dir = nil   -- carpeta temporal de sesión junto al vídeo (subedit.temp)
local last_session_dir = nil   -- última carpeta de sesión conocida (para limpiarla al apagar aun sin estar activa)

local SECTION_KEYS = {}     -- (reservado para futuros modos)

--------------------------------------------------------------------------
-- Utilidades UTF-8
--------------------------------------------------------------------------
local function utf8_len(str)
    local _, count = string.gsub(str, "[^\128-\193]", "")
    return count
end

local function utf8_char_len(s, pos)
    local b = s:byte(pos)
    if not b then return 0 end
    if b >= 0xF0 then return 4 end
    if b >= 0xE0 then return 3 end
    if b >= 0xC0 then return 2 end
    return 1
end

local function utf8_sub(str, i, j)
    local pos = 1
    local bytes = #str

    local function decode()
        if pos > bytes then return nil end
        local len = utf8_char_len(str, pos)
        pos = pos + len
        return len
    end

    local start_pos = 1
    if i and i > 1 then
        for _ = 1, i - 1 do
            if not decode() then return "" end
        end
        start_pos = pos
    end

    if not j then
        return str:sub(start_pos)
    end
    if j < i then return "" end

    for _ = i, j do
        if not decode() then break end
    end
    return str:sub(start_pos, pos - 1)
end

local function utf8_codepoint(s)
    local b1 = s:byte(1)
    if b1 < 0x80 then
        return b1
    elseif b1 < 0xE0 then
        return (b1 - 0xC0) * 0x40 + (s:byte(2) - 0x80)
    elseif b1 < 0xF0 then
        return (b1 - 0xE0) * 0x1000 + (s:byte(2) - 0x80) * 0x40 + (s:byte(3) - 0x80)
    else
        return (b1 - 0xF0) * 0x40000 + (s:byte(2) - 0x80) * 0x1000
             + (s:byte(3) - 0x80) * 0x40 + (s:byte(4) - 0x80)
    end
end

local function utf8_chars(s)
    local out = {}
    local pos = 1
    while pos <= #s do
        local len = utf8_char_len(s, pos)
        table.insert(out, s:sub(pos, pos + len - 1))
        pos = pos + len
    end
    return out
end

-- Divide un buffer en líneas (separador "\n"). Siempre devuelve >= 1 línea.
local function split_lines(s)
    local lines = {}
    for line in (s .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    return lines
end

-- Posición de cursor (índice de carácter en el buffer con "\n") -> línea/columna
local function pos_to_linecol(buffer, pos)
    local lines = split_lines(buffer)
    local rem = pos
    for i, l in ipairs(lines) do
        local llen = utf8_len(l)
        if rem <= llen then
            return i, rem, lines
        end
        rem = rem - llen - 1
    end
    local last = #lines
    return last, utf8_len(lines[last]), lines
end

local function linecol_to_pos(lines, line, col)
    local pos = 0
    for i = 1, line - 1 do
        pos = pos + utf8_len(lines[i]) + 1
    end
    return pos + col
end

local function insert_at(s, pos, ins)
    return utf8_sub(s, 1, pos) .. ins .. utf8_sub(s, pos + 1)
end

--------------------------------------------------------------------------
-- Utilidades de archivo
--------------------------------------------------------------------------
local function norm_path(p)
    return (p:lower():gsub("/", "\\"))
end

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then
        return nil, "No se pudo abrir el archivo"
    end
    local content = f:read("*all")
    f:close()
    if not content then
        return nil, "No se pudo leer el archivo"
    end
    return content
end

local function write_file(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function escape_ass(s)
    local res = mp.command_native({"escape-ass", s})
    if type(res) == "string" then return res end
    return s
end


--------------------------------------------------------------------------
-- Parsers de subtítulos
--------------------------------------------------------------------------
local function parse_srt_time(s)
    if not s then return nil end
    local h, m, sec, ms = s:match("(%d+):(%d+):(%d+)[,.](%d+)")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec)
             + tonumber(ms) / (10 ^ #ms)
    end
    return nil
end

local function parse_ass_time(s)
    if not s then return nil end
    local h, m, rest = s:match("^%s*(%d+):(%d+):([%d%.]+)%s*$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(rest)
    end
    return nil
end

-- Divide el contenido en líneas crudas conservando el terminador (\r\n o \n)
local function split_raw_lines(content)
    local lines = {}
    local pos = 1
    local len = #content
    while pos <= len do
        local nl = content:find("\n", pos, true)
        if nl then
            table.insert(lines, content:sub(pos, nl))
            pos = nl + 1
        else
            table.insert(lines, content:sub(pos))
            break
        end
    end
    return lines
end

local function doc_common(content)
    local bom = content:sub(1, 3) == "\239\187\191"
    local body = bom and content:sub(4) or content
    local eol = body:find("\r\n", 1, true) and "\r\n" or "\n"
    return bom, body, eol
end

local function parse_srt(content)
    local bom, body, eol = doc_common(content)
    local raw = split_raw_lines(body)
    local events = {}
    local i, n = 1, #raw

    local function blank(s) return s:match("^[%s\r\n]*$") ~= nil end
    local function strip(s) return (s:gsub("[\r\n]", "")) end

    while i <= n do
        while i <= n and blank(raw[i]) do i = i + 1 end
        if i > n then break end

        local first = i
        local idx_raw, num = nil, nil
        local l1 = strip(raw[i])
        local mnum = l1:match("^%s*(%d+)%s*$")
        if mnum and i + 1 <= n and strip(raw[i + 1]):find("%-%->", 1) then
            num = tonumber(mnum)
            idx_raw = raw[i]
            i = i + 1
        end

        local time_raw = raw[i]
        local tl = strip(time_raw or "")
        local s_str, e_str = tl:match("(%d+:%d+:%d+[,%.]%d+)%s*%-%->%s*(%d+:%d+:%d+[,%.]%d+)")
        local st, en = parse_srt_time(s_str), parse_srt_time(e_str)

        if st and en then
            i = i + 1
            local text_parts = {}
            while i <= n and not blank(raw[i]) do
                table.insert(text_parts, strip(raw[i]))
                i = i + 1
            end
            table.insert(events, {
                num = num,
                idx_raw = idx_raw,
                time_raw = time_raw,
                start_time = st,
                end_time = en,
                text = table.concat(text_parts, "\n"),
                first = first,
                last = i - 1,
            })
        else
            i = i + 1
        end
    end

    return {kind = "srt", bom = bom, eol = eol, lines = raw, events = events}
end

local function parse_ass(content)
    local bom, body, eol = doc_common(content)
    local raw = split_raw_lines(body)
    local events = {}

    for idx, line in ipairs(raw) do
        local s = (line:gsub("[\r\n]", ""))
        local prefix, rest = s:match("^(%s*Dialogue%s*:%s*)(.*)$")
        if prefix then
            local fields, ok = {}, true
            for k = 1, 9 do
                local c = rest:find(",", 1, true)
                if not c then
                    ok = false
                    break
                end
                fields[k] = rest:sub(1, c - 1)
                rest = rest:sub(c + 1)
            end
            if ok then
                local st, en = parse_ass_time(fields[2]), parse_ass_time(fields[3])
                if st and en then
                    table.insert(events, {
                        line_index = idx,
                        prefix = prefix,
                        layer = fields[1],
                        start = fields[2],
                        ["end"] = fields[3],
                        style = fields[4],
                        name = fields[5],
                        marginl = fields[6],
                        marginr = fields[7],
                        marginv = fields[8],
                        effect = fields[9],
                        text = rest,
                        start_time = st,
                        end_time = en,
                    })
                end
            end
        end
    end

    return {kind = "ass", bom = bom, eol = eol, lines = raw, events = events}
end

local function parse_by_ext(path, content)
    local ext = path:match("%.(%w+)$")
    if ext then ext = ext:lower() end
    if ext == "srt" then return parse_srt(content) end
    if ext == "ass" or ext == "ssa" then return parse_ass(content) end
    return nil
end

--------------------------------------------------------------------------
-- Guardado: aplicar el texto nuevo al documento parseado
--------------------------------------------------------------------------
local function apply_event_text(doc, ev, new_text)
    if doc.kind == "ass" then
        local tail = doc.lines[ev.line_index]:match("[\r\n]*$") or ""
        local fields = table.concat({
            ev.layer, ev.start, ev["end"], ev.style, ev.name,
            ev.marginl, ev.marginr, ev.marginv, ev.effect,
        }, ",")
        doc.lines[ev.line_index] = ev.prefix .. fields .. "," .. new_text .. tail
    else
        local last_tail = doc.lines[ev.last]:match("[\r\n]*$") or ""
        local new_lines = {}
        if ev.idx_raw then
            table.insert(new_lines, ev.idx_raw)
        end
        table.insert(new_lines, ev.time_raw)
        local tls = split_lines(new_text)
        if #tls == 0 then tls = {""} end
        for i, tl in ipairs(tls) do
            local term = (i == #tls) and last_tail or doc.eol
            table.insert(new_lines, tl .. term)
        end
        for k = ev.last, ev.first, -1 do
            table.remove(doc.lines, k)
        end
        for i = #new_lines, 1, -1 do
            table.insert(doc.lines, ev.first, new_lines[i])
        end
    end
end

--------------------------------------------------------------------------
-- Pistas de subtítulo y extracción de embebidas
--------------------------------------------------------------------------
local function get_sub_tracks()
    local tracks = mp.get_property_native("track-list") or {}
    local subs = {}
    for _, tr in ipairs(tracks) do
        if tr.type == "sub" and tr.selected then
            local ms = tr["main-selection"]
            local role = (ms == 0 and "Principal")
                      or (ms == 1 and "Secundaria")
                      or ("Pista " .. tostring(tr.id))
            subs[#subs + 1] = {track = tr, role = role}
        end
    end
    table.sort(subs, function(a, b)
        return (a.track["main-selection"] or 99) < (b.track["main-selection"] or 99)
    end)
    return subs
end

-- Espera a que aparezca en track-list una pista sub con ese archivo y llama cb(id)
local function watch_track(path, cb)
    local np = norm_path(path)
    local done = false
    local function check()
        for _, tr in ipairs(mp.get_property_native("track-list") or {}) do
            if tr.type == "sub" and tr["external-filename"]
                and norm_path(tr["external-filename"]) == np then
                return tr.id
            end
        end
        return nil
    end
    local id = check()
    if id then
        cb(id)
        return
    end
    local obs
    obs = function()
        local found = check()
        if found and not done then
            done = true
            mp.unobserve_property(obs)
            cb(found)
        end
    end
    mp.observe_property("track-list", "native", obs)
    mp.add_timeout(10, function()
        if not done then
            done = true
            mp.unobserve_property(obs)
        end
    end)
end

-- Devuelve el archivo editable de la pista (extrae si es embebida).
local function resolve_track_file(sub)
    local t = sub.track
    if t.external and t["external-filename"] then
        msg.info("[pista] external: " .. t["external-filename"])
        return t["external-filename"]
    end

    local video_path = mp.get_property("path")
    if not video_path then
        return nil, "No se pudo obtener la ruta del video"
    end
    if video_path:find("://") then
        return nil, "No se puede extraer de una URL"
    end

    local dir, filename = utils.split_path(video_path)
    local name = filename:match("^(.*)%.%w+$") or filename
    local codec = t.codec or ""
    local ext = (codec:find("ass") or codec:find("ssa")) and ".ass" or ".srt"
    local out = utils.join_path(dir, name .. ".sub" .. t.id .. ext)
    msg.info("[pista] embebida t.id=" .. tostring(t.id) .. " out=" .. out)

    if not utils.file_info(out) then
        msg.info("[extracción] ffmpeg extrae pista " .. tostring(t.id) .. " → " .. out)
        local res = utils.subprocess({
            args = {"ffmpeg", "-nostdin", "-y", "-i", video_path,
                    "-map", "0:s:" .. (t.id - 1), out},
            playback_only = false,
            capture_stderr = true,
        })
        if not res or res.status ~= 0 then
            local err = res and (res.error or res.stderr or "desconocido") or "desconocido"
            msg.warn("[extracción] ERROR: " .. tostring(err))
            return nil, "Error al extraer la pista: " .. tostring(err)
        end
        -- Archivo creado por el script y aún sin guardar: si la edición se
        -- cancela, se elimina y la selección vuelve a la pista embebida.
        script_created_files[norm_path(out)] = true
        msg.info("[script_created] registrado para borrado al cancelar: " .. out)
    else
        msg.info("[extracción] archivo ya existe (reutiliza): " .. out)
    end

    -- Cambiar la selección de la pista embebida al archivo extraído
    if t["main-selection"] == 1 then
        msg.info("[pista] sub-add (auto) " .. out)
        mp.commandv("sub-add", out, "auto")
        watch_track(out, function(id)
            mp.set_property_number("secondary-sid", id)
        end)
    else
        msg.info("[pista] sub-add (cached) " .. out)
        mp.commandv("sub-add", out, "cached")
    end

    return out
end

local function find_track_ids_by_file(path)
    local np = norm_path(path)
    local ids = {}
    for _, tr in ipairs(mp.get_property_native("track-list") or {}) do
        if tr.type == "sub" and tr["external-filename"]
            and norm_path(tr["external-filename"]) == np then
            table.insert(ids, tr.id)
        end
    end
    return ids
end

--------------------------------------------------------------------------
-- Key bindings (registro/desregistro dinámico)
--------------------------------------------------------------------------
local function bind(key, fn, repeatable)
    binding_counter = binding_counter + 1
    local name = "subedit_" .. binding_counter
    local flags = {}
    if repeatable then flags.repeatable = true end
    mp.add_forced_key_binding(key, name, fn, flags)
    table.insert(registered, name)
end

local function unbind_all()
    for _, name in ipairs(registered) do
        mp.remove_key_binding(name)
    end
    registered = {}
end

--------------------------------------------------------------------------
-- Gestión de modos
--------------------------------------------------------------------------
-- Estilo OSD compartido por toda la UI del script: texto blanco 100% opaco
-- con borde negro, misma fuente/tamaño en todos los elementos.
local function osd_h()
    return mp.get_property_number("osd-height") or 720
end

local function osd_style_tags()
    local h = osd_h()
    local fs = math.max(14, math.floor(h / 36))
    local bord = math.max(1, math.floor(fs / 14))
    return string.format(
        "\\fs%d\\1c&HFFFFFF&\\1a&H00&\\3c&H000000&\\3a&H00&\\bord%d", fs, bord)
end

-- Estilo para los paneles en la esquina superior izquierda (\an7\pos(fs,fs))
local function osd_corner_style()
    local h = osd_h()
    local fs = math.max(14, math.floor(h / 36))
    return "{\\an7\\pos(" .. fs .. "," .. fs .. ")" .. osd_style_tags() .. "}"
end

-- Mensajes puntuales: show-text escapa las etiquetas ASS, así que se pasa
-- el texto plano y queda en la posición/estilo por defecto del OSD.
local function ui_msg(text, dur)
    mp.osd_message(text, dur)
end

-- Animación de puntos braille recorriendo el perímetro de un cuadrado
-- (celda braille 2x4). TEMPORALMENTE DESACTIVADA: el timer no avanzaba de
-- cuadro y se quedaba atascado en el primer carácter. A arreglar otro día.
-- local loading_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"}
-- local loading_i = 1

local function stop_loading()
    -- if loading_timer then
    --     loading_timer:kill()
    --     loading_timer = nil
    -- end
    if loading_overlay then
        loading_overlay:remove()
        loading_overlay = nil
    end
end

-- Spinner en la esquina superior izquierda (misma esquina que el menú
-- selector y los controles del editor en pantalla)
local function show_loading()
    stop_loading()
    if not mp.create_osd_overlay then
        ui_msg("Buscando subtítulos...", 100)
        return
    end
    local w = mp.get_property_number("osd-width") or 1280
    local h = osd_h()
    local ov = mp.create_osd_overlay("ass-events")
    if not ov then
        ui_msg("Buscando subtítulos...", 100)
        return
    end
    ov.res_x = w
    ov.res_y = h
    loading_overlay = ov
    -- Animación braille desactivada (ver arriba): solo texto fijo.
    ov.data = osd_corner_style() .. "  Buscando subtítulos..."
    ov:update()
end

local function pause_enter()
    if pause_saved == nil then
        pause_saved = mp.get_property_bool("pause") or false
        if not pause_saved then
            mp.set_property_bool("pause", true)
        end
    end
end

-- Modo pantalla con copia-máscara: se muestra la pista real (libass) intacta y
-- solo se enmascara (se vacía el texto) el evento que se está editando, mediante
-- una copia temporal del archivo que se añade como pista de sustitución. Así el
-- contexto (otros eventos, estilos, posiciones) se ve exactamente como en el
-- original sin reconstrucción por overlays.
local function build_screen_copy(doc)
    local lines = {}
    for i, l in ipairs(doc.lines) do
        lines[i] = l
    end
    local ndoc = {}
    for k, v in pairs(doc) do
        ndoc[k] = v
    end
    ndoc.lines = lines
    ndoc.events = {}
    for _, ev in ipairs(doc.events) do
        local nev = {}
        for k2, v2 in pairs(ev) do
            nev[k2] = v2
        end
        ndoc.events[#ndoc.events + 1] = nev
    end
    return ndoc
end

local function serialize_doc(doc)
    return (doc.bom and "\239\187\191" or "") .. table.concat(doc.lines)
end

-- Compatible con la nomenclatura antigua de máscara (sustituye la extensión),
-- pero dentro de la carpeta de sesión junto al vídeo.
local function screen_temp_path(path)
    local name = path:gsub("[^\\/]+$", "")
    local base = path:match("([^\\/]+)$") or "sub"
    base = base:gsub("%.([^%.\\/]+)$", ".tmp.%1")
    local dir = session_edit_dir
    if not dir then
        return utils.join_path(name, base)
    end
    return utils.join_path(dir, base)
end

-- Creación/borrado de la carpeta de sesión multiplataforma: utils.subprocess
-- (en Windows mpv lanza los procesos ocultos, sin ventana de cmd), con retry
-- solo frente al fallo transitorio de parseo de mpv (res.status == -1), que
-- puede aparecer si un subprocess va inmediatamente después de una extracción
-- ffmpeg/ffprobe del mismo tick. La comprobación real del resultado es
-- utils.file_info() en los llamadores.
local is_win = package.config:sub(1, 1) == "\\"
local fs_mkdir_args = is_win and { "cmd.exe", "/d", "/c", "mkdir" }
    or { "mkdir", "-p", "--" }
local fs_rmdir_args = is_win and { "cmd.exe", "/d", "/c", "rmdir", "/s", "/q" }
    or { "rm", "-rf", "--" }

local function fs_command(base, path)
    local args = {}
    for i = 1, #base do
        args[i] = base[i]
    end
    args[#args + 1] = path
    for _ = 1, 3 do
        local r = utils.subprocess({ args = args, playback_only = false })
        if r and r.status ~= -1 then
            return r
        end
    end
    return nil
end

local function fs_mkdir(path)
    return fs_command(fs_mkdir_args, path)
end

local function fs_rmtree(path)
    return fs_command(fs_rmdir_args, path)
end

-- Nombre fijo de la carpeta de sesión. RED DE SEGURIDAD: todas las rutas que se
-- borran (os.remove/rmdir) deben estar bajo una carpeta que se llame
-- EXACTAMENTE así; si una ruta no lo cumple, se aborta la limpieza y solo se
-- registra por log en lugar de tocar archivos del usuario.
local SESSION_DIR_NAME = "subedit.temp"

-- ¿La ruta apunta exactamente a la carpeta de sesión (basename subedit.temp)?
-- Normaliza separadores: en Windows split_path reconoce "/" y "\".
local function is_session_dir(path)
    if not path or type(path) ~= "string" then return false end
    local _, name = utils.split_path(path:gsub("/", "\\"))
    return name == SESSION_DIR_NAME
end

-- ¿La ruta está dentro (o es) la carpeta de sesión, o es su subcarpeta fonts?
-- Comparación por prefijo normalizado (minúsculas + separadores "\").
local function under_session_dir(path)
    if is_session_dir(path) then return true end
    if not session_edit_dir or is_session_dir(session_edit_dir) then
        local base = session_edit_dir and norm_path(session_edit_dir) or ""
        local p = norm_path(path or "")
        if base ~= "" and p:sub(1, #base) == base and (#p == #base or p:sub(#base + 1, #base + 1) == "\\") then
            return true
        end
    end
    return false
end

local function log_del(path, motivo)
    msg.info("[BORRADO] " .. tostring(motivo) .. " -> " .. tostring(path))
end

-- Crea (si falta) y devuelve la carpeta de sesión "<dir_del_video>\subedit.temp".
-- La subcarpeta "fonts" (cache de fuentes por sesión, get_font_cache_dir) vive
-- aquí y se conserva entre ediciones; solo se borra al cerrar el reproductor.
-- Si el vídeo no es un archivo local (URL) devuelve nil: en ese caso no hay
-- pantalla-máscara ni fuentes.
local function get_session_edit_dir()
    local video_path = mp.get_property("path")
    if not video_path or type(video_path) ~= "string" or video_path:find("://") then
        msg.info("[sesión] sin video local (path=" .. tostring(video_path) .. "): sin carpeta de sesión")
        return nil
    end
    local dir, filename = utils.split_path(video_path)
    local folder = utils.join_path(dir, SESSION_DIR_NAME)
    if not is_session_dir(folder) then
        msg.warn("[sesión] folder inesperado (NO es subedit.temp), no se crea carpeta de sesión: "
              .. tostring(folder))
        return nil
    end
    msg.info("[sesión] video=" .. video_path .. " | carpeta de sesión=" .. folder)
    if not (utils.file_info(folder) and utils.file_info(folder).is_dir) then
        if is_win then
            fs_mkdir(folder:gsub("/", "\\"))
        else
            fs_mkdir(folder)
        end
        if not (utils.file_info(folder) and utils.file_info(folder).is_dir) then
            msg.warn("[sesión] no se pudo crear la carpeta de sesión: " .. folder)
            return nil
        end
    end
    session_edit_dir = folder
    last_session_dir = folder
    return folder
end

-- Cache de fuentes de la sesión: "<dir_del_video>\subedit.temp\fonts". Se crea
-- una vez y los archivos extraídos se reutilizan en todas las ediciones de esa
-- sesión de mpv; el borrado completo queda para el apagado (shutdown).
local function get_font_cache_dir()
    local session = get_session_edit_dir()
    if not session then return nil end
    local fonts = utils.join_path(session, "fonts")
    if not (utils.file_info(fonts) and utils.file_info(fonts).is_dir) then
        if is_win then
            fs_mkdir(fonts:gsub("/", "\\"))
        else
            fs_mkdir(fonts)
        end
        if not (utils.file_info(fonts) and utils.file_info(fonts).is_dir) then
            return nil
        end
    end
    return fonts
end

-- Borrado de la carpeta de sesión. Conserva la subcarpeta "fonts" (cache de
-- fuentes por sesión) salvo que se indique discard_fonts, que se usa al apagar
-- para limpiar todo. Reintenta solo frente al glitch de parseo de mpv.
local function remove_session_edit_dir(discard_fonts)
    local folder = session_edit_dir or last_session_dir
    session_edit_dir = nil
    if discard_fonts then
        last_session_dir = nil
    end
    if not folder then
        msg.info("[borrado] remove_session_edit_dir: no hay session_edit_dir, no-op")
        return
    end
    -- RED DE SEGURIDAD: solo se borra dentro de subedit.temp. Si por cualquier
    -- razón folder apuntara a la carpeta del vídeo (o similar), se aborta y se
    -- informa por log; NUNCA se toca lo que no es del script.
    if not is_session_dir(folder) then
        msg.warn("[borrado] ¡ABORTADO! folder no es subedit.temp, posible resolución incorrecta: "
              .. tostring(folder)
              .. "  (path del vídeo=" .. tostring(mp.get_property("path")) .. ")")
        return
    end
    if not (utils.file_info(folder) and utils.file_info(folder).is_dir) then
        msg.info("[borrado] remove_session_edit_dir: carpeta no existe, no-op: " .. folder)
        return
    end
    local function rm(p)
        log_del(p, "rmtree sesión")
        if is_win then
            fs_rmtree(p:gsub("/", "\\"))
        else
            fs_rmtree(p)
        end
    end
    if discard_fonts then
        msg.info("[borrado] remove_session_edit_dir(discard): rmtree carpeta completa: " .. folder)
        rm(folder)
        return
    end
    local entries = utils.readdir(folder, "all") or {}
    msg.info("[borrado] remove_session_edit_dir: entradas en " .. folder .. ": " .. tostring(#entries))
    for _, e in ipairs(entries) do
        msg.info("[borrado]   entry: " .. tostring(e))
        if e ~= "fonts" and e ~= "." and e ~= ".." then
            local p = utils.join_path(folder, e)
            local info = utils.file_info(p)
            if info then
                if info.is_dir then
                    rm(p)
                else
                    log_del(p, "os.remove sesión")
                    os.remove(p)
                end
            end
        end
    end
end

-- Fuentes embebidas del contenedor (MKV/MP4) para el overlay del editor: la
-- capa OSD de libass no recibe los adjuntos del vídeo (solo la pista de
-- subtítulos real), así que si la línea usa una fuente embebida que no está
-- instalada, el texto editable saldría con una fuente genérica. Se extrae SOLO
-- lo necesario para la línea en edición, se re-evalúa en cada cambio de línea
-- (Ctrl+↑/↓) y se cachea en la subcarpeta "fonts" de la sesión hasta cerrar el
-- reproductor. Si la línea usa únicamente fuentes instaladas, no se lanza
-- ningún ffprobe/ffmpeg ni se toca osd-fonts-dir (traza rápida).
local FONT_EXTS = { ".ttf", ".otf", ".ttc", ".otc" }

local function is_font_file(name)
    local n = tostring(name or ""):lower()
    for _, e in ipairs(FONT_EXTS) do
        if n:sub(-#e) == e then return true end
    end
    return false
end

-- parse_ass_meta se define más abajo en el chunk; esta declaración forward
-- permite usarlo aquí (event_font_families).
local parse_ass_meta

-- Clave canónica de un nombre de fuente/familia (minúsculas, solo alfanumérico):
-- permite comparar "Trebuchet MS", "trebuc.ttf", "TrebuchetMS" como iguales.
local function font_name_key(s)
    return tostring(s or ""):lower():gsub("[^%w]", "")
end

-- Familias comunes de Windows: nombre canónico -> fichero en C:\Windows\Fonts
-- (y típicamente término del attach del contenedor, p. ej. trebuc.ttf). Sirve
-- para detectar "ya instalada" y para emparejar familia -> adjunto.
local FONT_INSTALLED = {
    ["arial"] = "arial.ttf",
    ["arialblack"] = "ariblk.ttf",
    ["arialnarrow"] = "arialn.ttf",
    ["bookantiqua"] = "bkant.ttf",
    ["calibri"] = "calibri.ttf",
    ["cambria"] = "cambria.ttf",
    ["candara"] = "candara.ttf",
    ["comicsansms"] = "comic.ttf",
    ["consolas"] = "Consola.ttf",
    ["constantia"] = "constan.ttf",
    ["corbel"] = "corbel.ttf",
    ["couriernew"] = "cour.ttf",
    ["franklingothic"] = "framd.ttf",
    ["garamond"] = "gara.ttf",
    ["georgia"] = "georgia.ttf",
    ["impact"] = "impact.ttf",
    ["lucidasans"] = "lsans.ttf",
    ["lucidasansunicode"] = "lsansuni.ttf",
    ["palatinolinotype"] = "pala.ttf",
    ["segoeui"] = "segoeui.ttf",
    ["tahoma"] = "tahoma.ttf",
    ["timesnewroman"] = "times.ttf",
    ["trebuchetms"] = "trebuc.ttf",
    ["verdana"] = "verdana.ttf",
}

-- ¿La familia está instalada en el sistema Windows?
local function family_installed(family)
    local wfile = FONT_INSTALLED[font_name_key(family)]
    if not wfile then return false end
    local info = utils.file_info("C:\\Windows\\Fonts\\" .. wfile)
    return info and not info.is_dir
end

-- ¿La familia ya está cubierta por la cache fonts/ de la sesión?
local function font_cache_has(dir, family)
    local key = font_name_key(family)
    local mstem = nil
    local wfile = FONT_INSTALLED[key]
    if wfile then
        local stem = wfile:match("^(.+)%.[^.]+$")
        mstem = stem and font_name_key(stem)
    end
    local files = utils.readdir(dir, "files") or {}
    for _, f in ipairs(files) do
        if is_font_file(f) then
            local stem = f:match("^(.+)%.[^.]+$")
            local k = stem and font_name_key(stem) or ""
            if k == key or (mstem and k == mstem) then
                return true
            end
        end
    end
    return false
end

-- ¿El texto está íntegramente en Latin-1? Si la línea contiene glifos fuera
-- (CJK, etc.) se conserva el modo clásico (extraer todo) para no romper el
-- render de esos caracteres en el overlay.
local function is_latin1_text(s)
    local i, n = 1, #s
    while i <= n do
        local b = s:byte(i)
        if b < 0x80 then
            i = i + 1
        else
            local len, cp
            if b >= 0xC2 and b <= 0xDF then
                len, cp = 2, b - 0xC0
            elseif b >= 0xE0 and b <= 0xEF then
                len, cp = 3, b - 0xE0
            elseif b >= 0xF0 and b <= 0xF4 then
                len, cp = 4, b - 0xF0
            else
                return false
            end
            if i + len - 1 > n then return false end
            for k = 2, len do
                local c = s:byte(i + k - 1)
                if not (c and c >= 0x80 and c <= 0xBF) then return false end
                cp = cp * 0x40 + (c - 0x80)
            end
            if cp > 0xFF then return false end
            i = i + len
        end
    end
    return true
end

-- Familias de fuente que usa la línea en edición: Fontname del Style +
-- overrides \fn del texto. Devuelve lista de nombres únicos. Para subtítulos
-- que no son ASS (SRT/SUP) devuelve {} (no referencian fuentes embebidas).
local function event_font_families(cand)
    local doc, ev = cand and cand.doc, cand and cand.event
    local out = {}
    if not (doc and doc.kind == "ass") then return out end
    local meta = parse_ass_meta(doc)
    local function add(fam)
        fam = tostring(fam or ""):gsub("^%s*(.-)%s*$", "%1"):gsub('^"(.-)"$', "%1")
        if fam == "" then return end
        local k = font_name_key(fam)
        for _, e in ipairs(out) do
            if font_name_key(e) == k then return end
        end
        out[#out + 1] = fam
    end
    if ev and ev.style and ev.style ~= "" then
        local stf = meta.styles[ev.style]
        if stf and stf[2] then add(stf[2]) end
    end
    if ev and ev.text and ev.text:find("fn", 1, true) then
        for m in ev.text:gmatch("\\fn([^\\}]+)") do add(m) end
    end
    return out
end

-- Enumerar los streams "attachment" (fuentes) en su orden real: la opción
-- -dump_attachment:t:N usa N dentro de los adjuntos del contenedor.
local function list_attachments(video_path)
    local probe = utils.subprocess({
        args = { "ffprobe", "-v", "error", "-of", "default=noprint_wrappers=1",
                 "-show_entries", "stream=codec_type:stream_tags=filename",
                 video_path },
        playback_only = false,
        capture_stderr = true,
    })
    local attach = {}        -- 1-based: nombre de cada adjunto
    local last_attach = false
    for line in tostring(probe and probe.stdout or ""):gmatch("[^\r\n]+") do
        if line == "codec_type=attachment" then
            attach[#attach + 1] = ""
            last_attach = true
        elseif line:match("^codec_type=") then
            last_attach = false
        elseif last_attach and line:match("^TAG:filename=") then
            attach[#attach] = line:sub(14)
        end
    end
    return attach
end

local function all_font_indices(attach)
    local out = {}
    for i = 1, #attach do
        if is_font_file(attach[i]) then out[i] = true end
    end
    return out
end

-- Empareja una familia con el adjunto de fuente correspondiente por nombre
-- normalizado (priorizando el nombre Windows canónico). Índice 1-based o nil.
local function match_attachment(family, attach)
    local key = font_name_key(family)
    local mstem = nil
    local wfile = FONT_INSTALLED[key]
    if wfile then
        local stem = wfile:match("^(.+)%.[^.]+$")
        mstem = stem and font_name_key(stem)
    end
    local best, best_score = nil, 0
    for i = 1, #attach do
        local name = attach[i]
        if name and is_font_file(name) then
            local stem = name:match("^(.+)%.[^.]+$")
            local k = stem and font_name_key(stem) or ""
            local score = 0
            if mstem and k == mstem then
                score = 3
            elseif key ~= "" and k == key then
                score = 2
            elseif mstem and k ~= "" and (k:sub(1, #mstem) == mstem or mstem:sub(1, #k) == k) then
                score = 1
            end
            if score > best_score then
                best, best_score = i, score
            end
        end
    end
    return best
end

-- Decide qué fuentes hacen falta para la línea en edición y las extrae a la
-- cache fonts/ de la sesión. Re-evaluado en el arranque de edición y en
-- switch_edit (Ctrl+↑/↓). Si la línea usa solo fuentes instaladas no lanza
-- ningún subprocess y no toca osd-fonts-dir.
local function ensure_edit_fonts(cand)
    local families = event_font_families(cand)
    if #families == 0 then
        msg.info("[fuentes] sin familias (fast path) — sin extracción")
        return
    end

    -- Fast path: si todas las familias de la línea están instaladas en el
    -- sistema, no se crea ninguna carpeta ni se lanza ningún subprocess.
    local non_installed = {}
    for _, fam in ipairs(families) do
        if not family_installed(fam) then
            non_installed[#non_installed + 1] = fam
        end
    end
    if #non_installed == 0 then
        msg.info("[fuentes] todas instaladas (" .. table.concat(families, ", ")
              .. ") — fast path, sin ffprobe/ffmpeg")
        return
    end
    msg.info("[fuentes] familias no instaladas: " .. table.concat(non_installed, ", "))

    local video_path = mp.get_property("path")
    if not video_path or type(video_path) ~= "string" or video_path:find("://") then
        return
    end
    local dir = get_font_cache_dir()
    if not dir then return end

    local needs = {}
    for _, fam in ipairs(non_installed) do
        if not font_cache_has(dir, fam) then
            needs[#needs + 1] = fam
        end
    end
    if #needs == 0 then
        msg.info("[fuentes] todas ya en cache " .. dir)
        return
    end
    msg.info("[fuentes] faltan en cache: " .. table.concat(needs, ", "))

    -- Guard conservador: texto fuera de Latin-1 -> extraer todas las fuentes
    -- (equivalente al comportamiento clásico; evita fallback de glifos).
    local conservative = not is_latin1_text(cand and cand.event and (cand.event.text or ""))

    local attach = list_attachments(video_path)
    local want
    if conservative then
        want = all_font_indices(attach)
    else
        want = {}
        for _, fam in ipairs(needs) do
            local idx = match_attachment(fam, attach)
            if idx then
                want[idx] = true
            else
                conservative = true
                break
            end
        end
        if conservative then
            want = all_font_indices(attach)
        end
    end

    local args = { "ffmpeg", "-nostdin", "-y" }
    local n = 0
    for i = 1, #attach do
        local name = attach[i]
        if want[i] and is_font_file(name) then
            -- Cache de sesión: si el archivo ya existe (extraído antes), se
            -- salta sin volver a escribir.
            local target = utils.join_path(dir, name)
            local info = utils.file_info(target)
            if info and not info.is_dir then
                -- ya en cache
            else
                args[#args + 1] = "-dump_attachment:t:" .. (i - 1)
                args[#args + 1] = target
                n = n + 1
            end
        end
    end
    if n == 0 then
        msg.info("[fuentes] nada que extraer (ya en cache)")
        return
    end
    args[#args + 1] = "-i"
    args[#args + 1] = video_path
    msg.info("[fuentes] ffmpeg extrae " .. tostring(n) .. " fuentes a " .. dir)
    utils.subprocess({
        args = args,
        playback_only = false,
        capture_stderr = true,
    })
    -- El exit != 0 es normal ("At least one output file must be specified");
    -- se decide por los ficheros realmente escritos.

    if not font_dir_state then
        local old = mp.get_property("osd-fonts-dir") or ""
        local ok = pcall(mp.set_property, "osd-fonts-dir", dir)
        if not ok then return end
        font_dir_state = { old = old }
        msg.info("[fuentes] osd-fonts-dir = " .. dir .. " (anterior=" .. old .. ")")
    end
end

local function restore_edit_fonts()
    if not font_dir_state then return end
    local st = font_dir_state
    font_dir_state = nil
    pcall(mp.set_property, "osd-fonts-dir", st.old)
end

-- Regenera la copia temporal: siempre parte del documento ORIGINAL (edit.doc,
-- que no se muta durante la edición) para que los índices de evento (first/last
-- o line_index) sigan correspondiendo, vacía SOLO el evento en edición y
-- recarga la pista temporal para volver a renderizar.
local function refresh_screen_mask()
    if not edit or not screen then return end
    local tdoc = build_screen_copy(edit.doc)
    apply_event_text(tdoc, edit.event, "")
    if not write_file(screen.temp, serialize_doc(tdoc)) then
        msg.warn("No se pudo escribir la copia temporal, usando OSD")
        return false
    end
    if screen.tracked then
        for _, id in ipairs(screen.tracked) do
            mp.commandv("sub-reload", tostring(id))
        end
    end
    return true
end

-- Mueve la selección de la pista editada a la copia temporal (enmascarada).
-- Restaura los valores originales (cadenas, pueden ser "no") al salir.
local function fix_screen_selection(cand)
    if not screen or #screen.tracked == 0 then
        msg.warn("No se pudo añadir la pista temporal, usando OSD")
        return false
    end
    local temp_id = screen.tracked[1]
    local ms = cand.sub.track["main-selection"]
    local prop = (ms == 1) and "secondary-sid" or "sid"
    local other = (ms == 1) and "sid" or "secondary-sid"
    local orig_ids = find_track_ids_by_file(edit.file)
    local function in_orig(v)
        local n = tonumber(v)
        if not n then return false end
        for _, o in ipairs(orig_ids) do
            if o == n then return true end
        end
        return false
    end
    -- Si la otra selección muestra el mismo archivo editado, desactivarla
    -- (evita duplicado sin máscara del evento en edición).
    local other_val = mp.get_property(other)
    if other_val ~= nil and in_orig(other_val) then
        mp.set_property(other, "no")
    end
    mp.set_property_number(prop, temp_id)
    return true
end

local function cleanup_screen(discard)
    if not screen then return end
    local scr = screen
    screen = nil
    if scr.tracked then
        for _, id in ipairs(scr.tracked) do
            msg.info("[borrado] sub-remove pista temporal " .. tostring(id))
            mp.commandv("sub-remove", tostring(id))
        end
    end
    if not discard then
        if scr.orig_sid then
            mp.set_property("sid", scr.orig_sid)
        end
        if scr.orig_sid2 then
            mp.set_property("secondary-sid", scr.orig_sid2)
        end
    end
    if scr.temp then
        -- RED DE SEGURIDAD: la máscara debe vivir bajo subedit.temp (o bien
        -- tener el patrón *.tmp.*). Cualquier otra ruta se ignora por log.
        local _, bname = utils.split_path(scr.temp)
        local tmp_pattern = bname and bname:match("^.+%.tmp%.%w+$") ~= nil
        local safe = under_session_dir(scr.temp) or tmp_pattern
        if safe then
            log_del(scr.temp, "máscara pantalla")
            pcall(os.remove, scr.temp)
        else
            msg.warn("[borrado] ¡NO se borra la máscara! Ruta fuera de subedit.temp: "
                  .. tostring(scr.temp))
        end
    end
end

-- Al cancelar: elimina los archivos extraídos (pistas embebidas) creados por
-- el script en esta ejecución y aún no guardados, y restaura la selección que
-- había antes de la extracción (vuelve a la pista embebida del contenedor).
local function cleanup_disposable()
    local vdir = nil
    local vp = mp.get_property("path")
    if vp and type(vp) == "string" and not vp:find("://") then
        vdir, _ = utils.split_path(vp)
    end
    for p, _ in pairs(script_created_files) do
        for _, id in ipairs(find_track_ids_by_file(p)) do
            msg.info("[borrado] sub-remove pista " .. tostring(id) .. " (script_created) de " .. p)
            mp.commandv("sub-remove", tostring(id))
        end
        -- RED DE SEGURIDAD: solo borrar archivos que coincidan con nuestro
        -- patrón de extracción: <nombre>.sub<N>.<ext>, ubicados en la carpeta
        -- del vídeo. Cualquier otra ruta se ignora y se informa por log.
        local _, bname = utils.split_path(p)
        local matches_pattern = bname and bname:match("^.+%.sub%d+%.[%w]+$")
        local in_video_dir = true
        if vdir and norm_path(p) ~= norm_path(utils.join_path(vdir, bname)) then
            in_video_dir = false
        end
        if matches_pattern and in_video_dir then
            log_del(p, "extraído sin guardar")
            pcall(os.remove, p)
        else
            msg.warn("[borrado] ¡NO se borra! Fuera de patrón o ubicación insegura: "
                  .. tostring(p)
                  .. "  (bname=" .. tostring(bname)
                  .. "  vdir=" .. tostring(vdir) .. ")")
        end
    end
    script_created_files = {}
    -- La carpeta de sesión se crea antes de la extracción ffmpeg; si el flujo
    -- sale tarde o temprano, aquí se limpia (si ya hubo edición, exit_mode la
    -- vuelve a intentar y es un no-op).
    remove_session_edit_dir()
    if session_rollback then
        mp.set_property("sid", session_rollback.sid)
        mp.set_property("secondary-sid", session_rollback.sid2)
        session_rollback = nil
    end
end

local function exit_mode(message, dur, discard)
    msg.info("[salida] exit_mode: mensaje=" .. tostring(message)
          .. " discard=" .. tostring(discard)
          .. " path=" .. tostring(mp.get_property("path")))
    unbind_all()
    stop_loading()
    if selector_overlay then
        selector_overlay:remove()
        selector_overlay = nil
    end
    if help_overlay then
        help_overlay:remove()
        help_overlay = nil
    end
    if edit then
        if edit.overlay then
            edit.overlay:remove()
        end
    end
    cleanup_screen(discard)
    if discard then
        cleanup_disposable()
    else
        session_rollback = nil
    end
    remove_session_edit_dir()
    state = "idle"
    edit = nil
    candidates = {}
    pending = {}
    sel_index = 1
    pending_dead = ""
    loading = false
    if pause_saved ~= nil then
        if not pause_saved then
            mp.set_property_bool("pause", false)
        end
        pause_saved = nil
    end
    if message then
        ui_msg(message, dur or 2)
    end
end

local function cancel_edit()
    exit_mode("Edición cancelada", 1.5, true)
end

--------------------------------------------------------------------------
-- Selector OSD (varios eventos solapados)
--------------------------------------------------------------------------
local function candidate_preview(c)
    local t = c.event.text
    t = t:gsub("%b{}", "")
    if c.doc.kind == "ass" then
        t = t:gsub("\\[Nnh]", " ")
    end
    t = t:gsub("\n", " ")
    t = t:gsub("%s+", " ")
    if utf8_len(t) > 60 then
        t = utf8_sub(t, 1, 60) .. "..."
    end
    return t
end

local function render_selector()
    local lines = {}
    table.insert(lines, string.format(
        "Subtítulos en este instante: %d — elige cuál editar", #candidates))
    table.insert(lines, "")
    for i, c in ipairs(candidates) do
        local mark = (i == sel_index) and ">" or "\\h"
        table.insert(lines, string.format("%s %d. %s",
            mark, i, escape_ass(candidate_preview(c))))
    end
    table.insert(lines, "")
    table.insert(lines, "↑/↓: elegir · Enter: editar · Esc: cancelar")

    if selector_overlay then
        selector_overlay.data = osd_corner_style()
            .. table.concat(lines, "\\N")
        selector_overlay:update()
    else
        ui_msg(table.concat(lines, "\n"), 100)
    end
end

local function start_edit(cand)  -- forward declaration (definida más abajo)
end

local function selector_key(key)
    if state ~= "select" then return end
    if key == "UP" then
        sel_index = sel_index - 1
        if sel_index < 1 then sel_index = #candidates end
        render_selector()
    elseif key == "DOWN" then
        sel_index = sel_index + 1
        if sel_index > #candidates then sel_index = 1 end
        render_selector()
    elseif key == "ENTER" then
        local cand = candidates[sel_index]
        if cand then start_edit(cand) end
    elseif key == "ESC" then
        cancel_edit()
    end
end

local function register_selector_bindings()
    bind("UP", function() selector_key("UP") end, true)
    bind("DOWN", function() selector_key("DOWN") end, true)
    bind("ENTER", function() selector_key("ENTER") end)
    bind("KP_ENTER", function() selector_key("ENTER") end)
    bind("ESC", function() selector_key("ESC") end)
end

local function enter_selector(cands)
    candidates = cands
    sel_index = 1
    state = "select"
    if mp.create_osd_overlay and not selector_overlay then
        selector_overlay = mp.create_osd_overlay("ass-events")
        selector_overlay.res_x = mp.get_property_number("osd-width") or 1280
        selector_overlay.res_y = mp.get_property_number("osd-height") or 720
    end
    register_selector_bindings()
    render_selector()
end

--------------------------------------------------------------------------
-- Editor
--------------------------------------------------------------------------
local accents = {
    ["´"] = {a="á", e="é", i="í", o="ó", u="ú",
             A="Á", E="É", I="Í", O="Ó", U="Ú"},
    ["¨"] = {a="ä", e="ë", i="ï", o="ö", u="ü",
             A="Ä", E="Ë", I="Ï", O="Ö", U="Ü"},
    ["`"] = {a="à", e="è", i="ì", o="ò", u="ù",
             A="À", E="È", I="Ì", O="Ò", U="Ù"},
    ["^"] = {a="â", e="ê", i="î", o="ô", u="û",
             A="Â", E="Ê", I="Î", O="Ô", U="Û"},
    ["~"] = {a="ã", o="õ", n="ñ", A="Ã", O="Õ", N="Ñ"},
}

-- Separa las tags ASS iniciales ({\an8}...) del texto visible.
-- Devuelve: prefijo de tags, texto sin tags, si había tags intermedias.
local function split_ass_tags(text)
    local pos = 1
    local prefix = ""
    while true do
        local seg = text:sub(pos)
        local ws = seg:match("^%s*") or ""
        local s, e = seg:find("^%b{}", #ws + 1)
        if not s then break end
        prefix = prefix .. seg:sub(1, e)
        pos = pos + e
    end
    local rest = text:sub(pos)
    local had_inline = rest:find("%b{}") ~= nil
    local plain = rest:gsub("%b{}", "")
    return prefix, plain, had_inline
end

-- Detecta si un subtítulo es demasiado complejo para edición segura:
-- solo cuando hay bloques de tags entre las palabras (romperían el texto)
-- o cuando no queda texto editables (dibujos vectoriales, solo tags).
local function is_complex_subtitle(text)
    local _, plain, had_inline = split_ass_tags(text)
    if had_inline then return true end
    if plain == "" then return true end
    return false
end

--------------------------------------------------------------------------
-- Render en pantalla: metadata ASS (PlayRes, estilos)
--------------------------------------------------------------------------
-- Metadatos de cabecera ASS/SSA. Definida por asignación para poder declararla
-- (forward) desde la zona de fuentes.
parse_ass_meta = function(doc)
    -- El default replica libass (ScaledBorderAndShadow por defecto = 0, como
    -- VSFilter): sin línea explícita, el contorno/sombra no se escala con el
    -- vídeo. Solo se escala si el header lo pide con "1".
    local meta = {playresx = nil, playresy = nil, scaledborder = false, styles = {}, ssa = false}
    local section = ""
    for _, rawline in ipairs(doc.lines) do
        local s = (rawline:gsub("[\r\n]", ""))
        local sec = s:match("^%s*%[(.+)%]%s*$")
        if sec then
            section = sec:lower()
        elseif section == "script info" then
            local k, v = s:match("^%s*([^:%[%]]+):%s*(.-)%s*$")
            if k then
                k = k:lower()
                if k == "playresx" then
                    meta.playresx = tonumber(v)
                elseif k == "playresy" then
                    meta.playresy = tonumber(v)
                elseif k == "scaledborderandshadow" then
                    meta.scaledborder = (v ~= "0")
                end
            end
        elseif section == "v4+ styles" or section == "v4 styles" then
            if section == "v4 styles" then meta.ssa = true end
            local rest = s:match("^%s*Style%s*:%s*(.*)$")
            if rest then
                local f = {}
                while true do
                    local c = rest:find(",", 1, true)
                    if not c then
                        table.insert(f, rest)
                        break
                    end
                    table.insert(f, rest:sub(1, c - 1))
                    rest = rest:sub(c + 1)
                end
                if f[1] and f[1] ~= "" then
                    meta.styles[f[1]] = f
                end
            end
        end
    end
    return meta
end

-- Color ASS "&HAABBGGRR" -> {rgb="BBGGRR", a="AA"} (alpha ASS: 00 = opaco)
local function ass_color(value)
    if type(value) ~= "string" then return nil end
    local hex = value:match("[Hh]([0-9a-fA-F]+)")
    if not hex or hex == "" then
        hex = value:match("^%s*([0-9a-fA-F]+)%s*$")
    end
    if not hex then return nil end
    hex = hex:upper()
    if #hex > 8 then hex = hex:sub(-8) end
    if #hex < 8 then hex = string.rep("0", 8 - #hex) .. hex end
    return {rgb = hex:sub(3), a = hex:sub(1, 2)}
end

-- Color de opciones mpv ("#RRGGBB[AA]" o "r/g/b[/a]") -> color ASS
local function mp_color_to_ass(c)
    if type(c) ~= "string" or c == "" then return nil end
    local r, g, b, a
    local hex = c:match("^#([0-9a-fA-F]+)$")
    if hex then
        if #hex == 6 then
            r, g, b, a = hex:sub(1, 2), hex:sub(3, 4), hex:sub(5, 6), "FF"
        elseif #hex == 8 then
            r, g, b, a = hex:sub(1, 2), hex:sub(3, 4), hex:sub(5, 6), hex:sub(7, 8)
        else
            return nil
        end
    else
        local fr, fg, fb, fa = c:match("^%s*([%d%.]+)%s*/%s*([%d%.]+)%s*/%s*([%d%.]+)%s*(?:/%s*([%d%.]+)%s*)?$")
        if not fr then return nil end
        local function h(v)
            return string.format("%02X", math.floor(tonumber(v) * 255 + 0.5))
        end
        r, g, b = h(fr), h(fg), h(fb)
        a = fa and h(fa) or "FF"
    end
    return {
        rgb = (b .. g .. r):upper(),
        a = string.format("%02X", 255 - tonumber(a, 16)),
    }
end

local function ssa_to_ass_align(a)
    if a >= 9 then return a - 5 end  -- 9,10,11 -> 4,5,6 (medio)
    if a >= 5 then return a + 2 end  -- 5,6,7   -> 7,8,9 (arriba)
    return a                         -- 1,2,3   (abajo)
end

-- Posición actual de un \move(x1,y1,x2,y2[,t1,t2]) interpolada al instante
-- actual de reproducción (t1/t2 en centisegundos ASS; start/end en segundos).
-- Devuelve nil si no hay \move. Con \pos explícito no se usa (ASS lo anula).
local function move_position(prefix, ev)
    if not (prefix and ev) then return nil end
    local m = prefix:match("\\move%s*%((.-)%)")
    if not m then return nil end
    local n = {}
    for v in m:gmatch("[%d%.%-]+") do n[#n + 1] = tonumber(v) end
    if #n < 4 then return nil end
    local x1, y1, x2, y2 = n[1], n[2], n[3], n[4]
    local t1, t2 = n[5] or 0, n[6]
    if not t2 then
        t2 = ((ev.end_time or ev.start_time or 0) - (ev.start_time or 0)) * 100
    end
    if t2 < t1 then t1, t2 = t2, t1 end
    local tp = mp.get_property_number("time-pos")
    local ecs = tp and ((tp - (ev.start_time or 0)) * 100) or t2
    if ecs < t1 then ecs = t1 elseif ecs > t2 then ecs = t2 end
    local f = (t2 > t1) and ((ecs - t1) / (t2 - t1)) or 0
    return x1 + (x2 - x1) * f, y1 + (y2 - y1) * f
end

-- Construye las tags ASS para dibujar el texto en edición con el estilo real
local function build_screen_context(cand, prefix)
    local doc, ev = cand.doc, cand.event
    local ctx = {tags = "", help = "", res_x = 1280, res_y = 720}
    local tags = {}

    if doc.kind == "ass" then
        local meta = parse_ass_meta(doc)
        -- El preview se renderiza al tamaño del vídeo, como reproduce mpv la
        -- pista real (libass con storage = vídeo): los valores en píxeles de
        -- PlayRes se escalan con kx/ky. Sin vídeo activo, se cae al PlayRes.
        local pry = meta.playresy or 720
        local prx = meta.playresx or math.floor(pry * 4 / 3)
        local vw = mp.get_property_number("video-params/dw")
        local vh = mp.get_property_number("video-params/dh")
        if vw and vh and vw > 0 and vh > 0 then
            ctx.res_x, ctx.res_y = vw, vh
        else
            ctx.res_y, ctx.res_x = pry, prx
        end
        local kx = ctx.res_x / prx
        local ky = ctx.res_y / pry

        local st = (ev.style ~= "") and meta.styles[ev.style] or nil
        local align, ml, mr, mv = 2, 0, 0, 0
        if st then
            if st[2] and st[2] ~= "" then
                table.insert(tags, "\\fn" .. st[2])
            end
            local fs = tonumber(st[3])
            if fs then table.insert(tags, string.format("\\fs%d", math.floor(fs * ky + 0.5))) end
            local pc = ass_color(st[4])
            if pc then table.insert(tags, "\\1c&H" .. pc.rgb .. "&\\1a&H" .. pc.a .. "&") end
            local oc = ass_color(st[6])
            if oc then table.insert(tags, "\\3c&H" .. oc.rgb .. "&\\3a&H" .. oc.a .. "&") end
            local bc = ass_color(st[7])
            if bc then table.insert(tags, "\\4c&H" .. bc.rgb .. "&\\4a&H" .. bc.a .. "&") end
            if st[8] == "1" or st[8] == "-1" then table.insert(tags, "\\b1") end
            if st[9] == "1" or st[9] == "-1" then table.insert(tags, "\\i1") end
            local sx, sy = tonumber(st[12]), tonumber(st[13])
            if sx and sx ~= 100 then table.insert(tags, string.format("\\fscx%g", sx)) end
            if sy and sy ~= 100 then table.insert(tags, string.format("\\fscy%g", sy)) end
            local sp = tonumber(st[14])
            if sp and sp ~= 0 then table.insert(tags, string.format("\\fsp%g", sp * kx)) end
            local ang = tonumber(st[15])
            if ang and ang ~= 0 then table.insert(tags, string.format("\\frz%g", ang)) end
            -- \bord/\shad solo se escalan con el vídeo si lo exige el header
            -- (ScaledBorderAndShadow: 1; default libass = 0): con 0 o sin línea,
            -- libass los deja en píxeles de PlayRes y el contorno queda fino,
            -- igual que en reproducción.
            local bord = tonumber(st[17])
            if bord and bord ~= 0 then
                local bv = meta.scaledborder and (bord * ky) or bord
                table.insert(tags, string.format("\\bord%g", bv))
            end
            local shad = tonumber(st[18])
            if shad and shad ~= 0 then
                local sv = meta.scaledborder and (shad * ky) or shad
                table.insert(tags, string.format("\\shad%g", sv))
            end
            align = tonumber(st[19]) or 2
            if meta.ssa then align = ssa_to_ass_align(align) end
            ml, mr, mv = tonumber(st[20]) or 0, tonumber(st[21]) or 0, tonumber(st[22]) or 0
        end

        -- Márgenes del propio evento (si son no-cero, tienen prioridad)
        local function evmargin(v)
            local n = tonumber(v)
            if n and n ~= 0 then return n end
            return nil
        end
        ml = evmargin(ev.marginl) or ml
        mr = evmargin(ev.marginr) or mr
        mv = evmargin(ev.marginv) or mv
        ml, mr, mv = ml * kx, mr * kx, mv * ky

        -- Tags iniciales del texto original ({\an8}, {\pos(...)}) mandan
        local px, py
        if prefix and prefix ~= "" then
            local pa = prefix:match("\\an(%d)")
            if pa then align = tonumber(pa) end
            px, py = prefix:match("\\pos%s*%(%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*%)")
        end

        table.insert(tags, "\\an" .. align)

        local x, y
        if px and py then
            x, y = tonumber(px) * kx, tonumber(py) * ky
        else
            local coltype = align % 3
            if coltype == 1 then
                x = ml
            elseif coltype == 0 then
                x = ctx.res_x - mr
            else
                x = ctx.res_x / 2
            end
            if align <= 3 then
                y = ctx.res_y - mv
            elseif align >= 7 then
                y = mv
            else
                y = ctx.res_y / 2
            end
        end

        -- \move sin \pos: quedarse en la posición actual del movimiento
        local mx, my = move_position(prefix, ev)
        if mx and my then
            x, y = mx * kx, my * ky
        end

        table.insert(tags, string.format("\\pos(%d,%d)",
            math.floor(x + 0.5), math.floor(y + 0.5)))

        -- Preservar tags de estilo del prefijo (excepto \pos y \an ya manejados)
        if prefix and prefix ~= "" then
            for block in prefix:gmatch("{(.-)}") do
                local i = 1
                while i <= #block do
                    local tag
                    local c = block:sub(i, i)
                    if c == "\\" then
                        local name = block:match("^([0-9]*[a-z]+)", i + 1)
                        if name then
                            local after_name = i + 1 + #name
                            local val_start = block:sub(after_name, after_name)
                            if val_start == "(" then
                                local paren_end = block:find(")", after_name + 1, true)
                                if paren_end then
                                    if name == "org" then
                                        -- \org(x,y) da el origen de rotación en coordenadas
                                        -- de PlayRes: se escala al lienzo del overlay igual
                                        -- que \pos.
                                        local ox, oy = block:sub(after_name + 1, paren_end - 1)
                                            :match("^%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*$")
                                        if ox and oy then
                                            tag = string.format("\\org(%g,%g)",
                                                tonumber(ox) * kx, tonumber(oy) * ky)
                                        else
                                            tag = "\\" .. name
                                                .. block:sub(after_name, paren_end)
                                        end
                                    else
                                        tag = "\\" .. name .. block:sub(after_name, paren_end)
                                    end
                                    i = paren_end + 1
                                else
                                    i = after_name
                                end
                            elseif val_start == "&" then
                                local amp_end = block:find("&", after_name + 1, true)
                                if amp_end then
                                    tag = "\\" .. name .. block:sub(after_name, amp_end)
                                    i = amp_end + 1
                                else
                                    i = after_name
                                end
                            else
                                local val = block:match("^([^\\{}]+)", after_name)
                                if val then
                                    if name == "fs" then
                                        -- El \fs inline es relativo al PlayRes (como el del
                                        -- estilo): hay que escalarlo al lienzo del overlay
                                        -- (píxeles del vídeo), igual que se hace con el fs
                                        -- del estilo.
                                        local v = tonumber(val)
                                        if v then
                                            tag = string.format("\\fs%d",
                                                math.floor(v * ky + 0.5))
                                        end
                                    elseif name == "fsp" then
                                        -- \fsp (espaciado entre caracteres) es en unidades
                                        -- de PlayRes: se escala como en la línea 1631.
                                        local v = tonumber(val)
                                        if v then
                                            tag = string.format("\\fsp%g", v * kx)
                                        end
                                    elseif (name == "bord" or name == "shad")
                                           and meta.scaledborder then
                                        -- \bord/\shad inline: mismo criterio que el estilo,
                                        -- solo se escalan si ScaledBorderAndShadow lo pide.
                                        local v = tonumber(val)
                                        if v then
                                            tag = string.format("\\%s%g", name, v * ky)
                                        end
                                    else
                                        tag = "\\" .. name .. val
                                    end
                                    i = after_name + #val
                                else
                                    i = after_name
                                end
                            end
                            if tag and name ~= "pos" and name ~= "an" and name ~= "fad"
                                   and name ~= "move" and name ~= "t"
                                   and name ~= "clip" and name ~= "iclip" then
                                table.insert(tags, tag)
                            end
                        else
                            i = i + 1
                        end
                    else
                        i = i + 1
                    end
                end
            end
        end
    else
        -- SRT: aproximación con las opciones de subtítulos de mpv
        local secondary = cand.sub.track["main-selection"] == 1
        local font = mp.get_property("options/sub-font")
        local fs = mp.get_property_number("options/sub-font-size", 55) or 55
        local scale = mp.get_property_number("sub-scale", 1) or 1
        if font and font ~= "" then table.insert(tags, "\\fn" .. font) end
        table.insert(tags, string.format("\\fs%d", math.floor(fs * scale)))
        local pc = mp_color_to_ass(mp.get_property("options/sub-color"))
        if pc then table.insert(tags, "\\1c&H" .. pc.rgb .. "&\\1a&H" .. pc.a .. "&") end
        local bord = mp.get_property_number("options/sub-border-size", 3) or 0
        if bord > 0 then
            table.insert(tags, string.format("\\bord%g", bord))
            local oc = mp_color_to_ass(mp.get_property("options/sub-border-color"))
            if oc then table.insert(tags, "\\3c&H" .. oc.rgb .. "&\\3a&H" .. oc.a .. "&") end
        else
            table.insert(tags, "\\bord0")
        end
        local shad = mp.get_property_number("options/sub-shadow-offset", 0) or 0
        if shad > 0 then
            table.insert(tags, string.format("\\shad%g", shad))
            local sc = mp_color_to_ass(mp.get_property("options/sub-shadow-color"))
            if sc then table.insert(tags, "\\4c&H" .. sc.rgb .. "&\\4a&H" .. sc.a .. "&") end
        end
        local pos = mp.get_property_number(
            secondary and "options/secondary-sub-pos" or "options/sub-pos",
            secondary and 0 or 100)
        if not pos then pos = secondary and 0 or 100 end
        local align = (pos <= 50) and 8 or 2
        table.insert(tags, "\\an" .. align)
        table.insert(tags, string.format("\\pos(%d,%d)",
            math.floor(ctx.res_x / 2), math.floor(pos / 100 * ctx.res_y + 0.5)))
    end

    ctx.tags = "{" .. table.concat(tags) .. "}"

    return ctx
end

-- Overlay ASS estático para dibujar un evento ajeno al editado (misma pista).
-- Cada evento usa su propio overlay (como en el archivo original, cada evento
-- es una línea independiente): el \pos y el dibujo \p1 se respetan.
local function render_editor_screen()
    local ov = edit.overlay
    if not ov or not edit.screen then return end
    local lines = split_lines(edit.buffer)
    local line, col = pos_to_linecol(edit.buffer, edit.cursor)
    local parts = {}
    for i, l in ipairs(lines) do
        if i == line then
            -- Cursor siempre blanco con borde negro fino (visible también en
            -- fondos claros); tras el cursor se vuelven a aplicar los tags
            -- completos del evento para restaurar el estilo original.
            local before = utf8_sub(l, 1, col)
            local after = utf8_sub(l, col + 1)
            local seg = escape_ass(before)
                .. "{\\1c&HFFFFFF&\\3c&H000000&\\3a&H00&\\4a&HFF&\\bord0.5}|"
                .. edit.screen.tags .. escape_ass(after)
            table.insert(parts, seg)
        else
            table.insert(parts, escape_ass(l))
        end
    end
    ov.data = edit.screen.tags .. table.concat(parts, "\\N")
    ov:update()
end

local function render_editor_osd()
    local lines = split_lines(edit.buffer)
    local line, col = pos_to_linecol(edit.buffer, edit.cursor)

    local out = {escape_ass("Editando subtítulo"), ""}
    for i, l in ipairs(lines) do
        if i == line then
            l = utf8_sub(l, 1, col) .. "|" .. utf8_sub(l, col + 1)
        end
        if l == "" then l = " " end
        table.insert(out, escape_ass(l))
    end
    table.insert(out, "")
    table.insert(out, "Enter: guardar · Shift+Enter: salto de línea · Esc: cancelar")
    table.insert(out, "↑/↓: cambiar de línea · ←/→: mover cursor (mantén pulsado para repetir)")
    ui_msg(table.concat(out, "\n"), 100)
end

local function render_editor()
    if state ~= "edit" or not edit then return end
    if edit.render == "screen" and edit.overlay then
        render_editor_screen()
    else
        render_editor_osd()
    end
end

local function save_subtitle()  -- forward declaration (definida más abajo)
end

local kp_chars = {
    KP0 = "0", KP1 = "1", KP2 = "2", KP3 = "3", KP4 = "4",
    KP5 = "5", KP6 = "6", KP7 = "7", KP8 = "8", KP9 = "9",
}

local function handle_edit_key(key)
    if state ~= "edit" or not edit then return end

    local control_keys = {
        ENTER = true, ["SHIFT+ENTER"] = true, ESC = true, BS = true,
        DEL = true, LEFT = true, RIGHT = true, UP = true, DOWN = true,
        HOME = true, END = true,
    }
    if pending_dead ~= "" and control_keys[key] then
        edit.buffer = insert_at(edit.buffer, edit.cursor, pending_dead)
        edit.cursor = edit.cursor + utf8_len(pending_dead)
        pending_dead = ""
    end

    local buffer = edit.buffer
    local text_len = utf8_len(buffer)

    if key == "ENTER" then
        save_subtitle()
        return
    elseif key == "SHIFT+ENTER" then
        edit.buffer = insert_at(buffer, edit.cursor, "\n")
        edit.cursor = edit.cursor + 1
    elseif key == "ESC" then
        cancel_edit()
        return
    elseif key == "BS" then
        if edit.cursor > 0 then
            edit.buffer = utf8_sub(buffer, 1, edit.cursor - 1)
                       .. utf8_sub(buffer, edit.cursor + 1)
            edit.cursor = edit.cursor - 1
        end
    elseif key == "DEL" then
        if edit.cursor < text_len then
            edit.buffer = utf8_sub(buffer, 1, edit.cursor)
                       .. utf8_sub(buffer, edit.cursor + 2)
        end
    elseif key == "LEFT" then
        edit.cursor = math.max(0, edit.cursor - 1)
    elseif key == "RIGHT" then
        edit.cursor = math.min(text_len, edit.cursor + 1)
    elseif key == "HOME" then
        local line, _, lines = pos_to_linecol(buffer, edit.cursor)
        edit.cursor = linecol_to_pos(lines, line, 0)
    elseif key == "END" then
        local line, _, lines = pos_to_linecol(buffer, edit.cursor)
        edit.cursor = linecol_to_pos(lines, line, utf8_len(lines[line]))
    elseif key == "UP" or key == "DOWN" then
        local line, col, lines = pos_to_linecol(buffer, edit.cursor)
        local nl = (key == "UP") and (line - 1) or (line + 1)
        if nl >= 1 and nl <= #lines then
            edit.cursor = linecol_to_pos(lines, nl, math.min(col, utf8_len(lines[nl])))
        end
    else
        local char = key
        if pending_dead ~= "" then
            local combined = accents[pending_dead] and accents[pending_dead][char]
            local ins = combined or (pending_dead .. char)
            edit.buffer = insert_at(buffer, edit.cursor, ins)
            edit.cursor = edit.cursor + utf8_len(ins)
            pending_dead = ""
        elseif accents[char] then
            pending_dead = char
        else
            edit.buffer = insert_at(buffer, edit.cursor, char)
            edit.cursor = edit.cursor + utf8_len(char)
        end
    end

    render_editor()
end

-- Lista de eventos ciclables (misma pista/archivo que el editado, ya visibles
-- en pantalla como contexto) para saltar con Ctrl+↑/↓ sin pasar por el menú.
local function edit_cycle_list()
    local list = {}
    if edit and candidates then
        for _, c in ipairs(candidates) do
            if c.file == edit.cand.file then
                table.insert(list, c)
            end
        end
    end
    return list
end

local function edit_cycle_index(list)
    for i, c in ipairs(list) do
        if c == edit.cand then return i end
    end
    return 1
end

-- Leyenda de controles en la esquina superior izquierda (mismo estilo que el
-- menú selector), con contador "i/n" cuando hay varios subtítulos ciclables.
local function update_help_overlay()
    if not (mp.create_osd_overlay and edit) then return end
    local list = edit_cycle_list()
    local counter = ""
    if #list > 1 then
        counter = edit_cycle_index(list) .. "/" .. #list .. " · "
    end
    local data = osd_corner_style()
        .. escape_ass(counter .. "Enter guardar · Shift+Enter salto de línea · "
                   .. "Esc cancelar · ↑/↓ línea · Ctrl+↑/↓ subtítulo")
    if help_overlay then
        help_overlay.data = data
        help_overlay:update()
    else
        local hov = mp.create_osd_overlay("ass-events")
        if hov then
            hov.res_x = mp.get_property_number("osd-width") or 1280
            hov.res_y = osd_h()
            hov.data = data
            hov:update()
            help_overlay = hov
        end
    end
end

-- Reconstruye la vista de pantalla para el evento en edición: overlay del
-- editor + pista temporal (copia-máscara) que enmascara el evento editado.
-- Reutilizable al cambiar de evento con Ctrl+↑/↓.
local function setup_screen(cand, prefix)
    if not (mp.create_osd_overlay and edit) then return end
    if edit.overlay then
        edit.overlay:remove()
        edit.overlay = nil
    end
    local ok, ctx = pcall(build_screen_context, cand, prefix)
    if not (ok and ctx) then
        msg.warn("No se pudo preparar el modo pantalla, usando OSD")
        return
    end
    get_session_edit_dir()

    if screen and screen.file == edit.file then
        -- Mismo archivo (cambio de evento con Ctrl+↑/↓): solo refrescar máscara.
        refresh_screen_mask()
    else
        cleanup_screen()
        screen = {
            file = edit.file,
            orig_sid = mp.get_property("sid"),
            orig_sid2 = mp.get_property("secondary-sid"),
            temp = screen_temp_path(edit.file),
            tracked = {},
        }
        if not refresh_screen_mask() then
            screen = nil
            return
        end
        mp.commandv("sub-add", screen.temp, "auto")
        screen.tracked = find_track_ids_by_file(screen.temp)
        if #screen.tracked == 0 then
            watch_track(screen.temp, function(id)
                if not screen then return end
                screen.tracked = {id}
                fix_screen_selection(cand)
                refresh_screen_mask()
            end)
        elseif not fix_screen_selection(cand) then
            cleanup_screen()
            return
        end
    end

    local ov = mp.create_osd_overlay("ass-events")
    if not ov then return end
    ov.res_x = ctx.res_x
    ov.res_y = ctx.res_y
    edit.overlay = ov
    edit.screen = ctx
    edit.render = "screen"
    update_help_overlay()
end

-- Cambia el subtítulo en edición sin pasar por el selector. Conserva en
-- memoria (pending) los cambios no guardados de cada evento y los recupera
-- al volver. ENTER guarda el evento actual; ESC descarta todo.
local function switch_edit(dir)
    if state ~= "edit" or not edit then return end
    msg.info("[switch] cambio de línea, dir=" .. tostring(dir))
    local list = edit_cycle_list()
    if #list < 2 then return end
    local idx = edit_cycle_index(list)
    local n = idx + dir
    if n < 1 then n = #list elseif n > #list then n = 1 end
    local cand = list[n]
    if not cand then return end

    pending[edit.cand] = { buffer = edit.buffer, cursor = edit.cursor }

    local raw = cand.event.text
    if cand.doc.kind == "ass" then
        raw = raw:gsub("\\N", "\n"):gsub("\\n", "\n")
    end
    local prefix, buffer, had_inline = "", raw, false
    if cand.doc.kind == "ass" then
        prefix, buffer, had_inline = split_ass_tags(raw)
    end
    local pv = pending[cand]
    if pv then
        buffer = pv.buffer
    end

    edit.cand = cand
    edit.event = cand.event
    edit.doc = cand.doc
    edit.file = cand.file
    edit.sub = cand.sub
    edit.prefix = prefix
    edit.had_inline = had_inline
    edit.buffer = buffer
    edit.cursor = (pv and pv.cursor) or utf8_len(buffer)

    if edit.render == "screen" then
        -- Re-evaluar por línea si hace falta extraer alguna fuente embebida.
        ensure_edit_fonts(cand)
        setup_screen(cand, prefix)
    end
    render_editor()
end

local function build_char_keys()
    local keys = {}
    for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"):gmatch(".") do
        table.insert(keys, c)
    end
    for c in ("!@#$%^&*()-_=+[]{};:',.<>/?\\|`~\""):gmatch(".") do
        table.insert(keys, c)
    end
    for _, c in ipairs(utf8_chars("áéíóúÁÉÍÓÚñÑüÜ¿¡´¨àèìòùâêîôûãõ")) do
        table.insert(keys, c)
    end
    return keys
end

local function register_edit_bindings()
    bind("ENTER", save_subtitle)
    bind("KP_ENTER", save_subtitle)
    bind("Shift+ENTER", function() handle_edit_key("SHIFT+ENTER") end)
    bind("ESC", cancel_edit)
    bind("BS", function() handle_edit_key("BS") end, true)
    bind("DEL", function() handle_edit_key("DEL") end, true)
    bind("LEFT", function() handle_edit_key("LEFT") end, true)
    bind("RIGHT", function() handle_edit_key("RIGHT") end, true)
    bind("UP", function() handle_edit_key("UP") end, true)
    bind("DOWN", function() handle_edit_key("DOWN") end, true)
    bind("Ctrl+UP", function() switch_edit(-1) end, true)
    bind("Ctrl+DOWN", function() switch_edit(1) end, true)
    bind("HOME", function() handle_edit_key("HOME") end)
    bind("END", function() handle_edit_key("END") end)
    bind("SPACE", function() handle_edit_key(" ") end, true)
    for kp, ch in pairs(kp_chars) do
        bind(kp, function() handle_edit_key(ch) end, true)
    end
    -- Caracteres imprimibles: se registran por codepoint (0xNN) para evitar
    -- conflictos con la sintaxis de input.conf (#, ", espacios, etc.)
    for _, ch in ipairs(build_char_keys()) do
        local hex = string.format("0x%X", utf8_codepoint(ch))
        bind(hex, function() handle_edit_key(ch) end, true)
    end
end

start_edit = function(cand)
    unbind_all()
    stop_loading()
    if selector_overlay then
        selector_overlay:remove()
        selector_overlay = nil
    end
    local ev, doc = cand.event, cand.doc
    local buffer, prefix, had_inline = ev.text, "", false
    if doc.kind == "ass" then
        buffer = buffer:gsub("\\N", "\n"):gsub("\\n", "\n")
        prefix, buffer, had_inline = split_ass_tags(buffer)
    end
    edit = {
        cand = cand,
        doc = doc,
        event = ev,
        file = cand.file,
        sub = cand.sub,
        buffer = buffer,
        cursor = utf8_len(buffer),
        prefix = prefix,
        had_inline = had_inline,
        render = "osd",
        overlay = nil,
        screen = nil,
    }
    state = "edit"

    -- Modo pantalla: overlay ASS con el estilo real del evento
    if editor_mode_request == "screen" then
        setup_screen(cand, prefix)
    end

    register_edit_bindings()
    render_editor()
end

--------------------------------------------------------------------------
-- Guardado
--------------------------------------------------------------------------
save_subtitle = function()
    if state ~= "edit" or not edit then return end
    msg.info("[guardar] archivo=" .. tostring(edit.file))

    local doc, ev = edit.doc, edit.event
    local text = edit.buffer
    if doc.kind == "ass" then
        text = edit.prefix .. text:gsub("\n", "\\N")
    end

    apply_event_text(doc, ev, text)

    local content = (doc.bom and "\239\187\191" or "") .. table.concat(doc.lines)
    if not write_file(edit.file, content) then
        msg.warn("[guardar] ERROR al escribir archivo: " .. tostring(edit.file))
        exit_mode("✗ Error al guardar el archivo", 3)
        return
    end
    msg.info("[guardar] OK: " .. tostring(edit.file))
    -- El archivo ya contiene el contenido guardado: ya nunca se borra,
    -- ni siquiera si en una sesión posterior se edita y se cancela.
    script_created_files[norm_path(edit.file)] = nil
    msg.info("[guardar] des-tracking script_created: " .. tostring(edit.file))

    local f = edit.file
    local was_secondary = (edit.sub.track["main-selection"] == 1)

    local extra = ""
    if edit.had_inline then
        extra = " (aviso: tags ASS intermedias descartadas)"
    end
    exit_mode("✓ Subtítulo guardado" .. extra, 2.5)

    -- Recargar la pista real DESPUÉS de restaurar la selección (exit_mode):
    -- sub-reload descarga y re-añade la pista, por lo que su id puede cambiar;
    -- si se recarga mientras está deseleccionada y luego se restaura el id
    -- antiguo, la selección queda apuntando a una pista inexistente (sin subs).
    local ids = find_track_ids_by_file(f)
    local target = ids[1]
    if target then
        mp.commandv("sub-reload", tostring(target))
        local ids2 = find_track_ids_by_file(f)
        local current = (ids2 and ids2[1]) or target
        if was_secondary then
            mp.set_property_number("secondary-sid", current)
        else
            mp.set_property_number("sid", current)
        end
    else
        mp.command("sub-reload")
    end
end

--------------------------------------------------------------------------
-- Recolección de candidatos y entrada principal
--------------------------------------------------------------------------
local function collect_candidates(subs, t)
    local cands, errors = {}, {}
    for _, sub in ipairs(subs) do
        local file, err = resolve_track_file(sub)
        if not file then
            table.insert(errors, sub.role .. ": " .. err)
        else
            local content, rerr = read_file(file)
            if not content then
                table.insert(errors, sub.role .. ": " .. rerr)
            else
                local doc = parse_by_ext(file, content)
                if not doc then
                    table.insert(errors, sub.role .. ": formato no soportado (solo .srt/.ass/.ssa)")
                else
                    for _, ev in ipairs(doc.events) do
                        if t >= ev.start_time - 0.001 and t <= ev.end_time + 0.001 then
                            table.insert(cands, {
                                sub = sub, doc = doc, event = ev, file = file,
                            })
                        end
                    end
                end
            end
        end
    end
    return cands, errors
end

local function edit_subtitle(mode)
    msg.info("[edición] inicio: modo=" .. tostring(mode)
          .. " path=" .. tostring(mp.get_property("path"))
          .. " sid=" .. tostring(mp.get_property("sid"))
          .. " secondary-sid=" .. tostring(mp.get_property("secondary-sid")))
    if state ~= "idle" then
        ui_msg("Ya hay una edición en curso", 1.5)
        return
    end
    if loading then return end

    editor_mode_request = mode or "screen"

    local t = mp.get_property_number("time-pos")
    if not t then
        ui_msg("No hay reproducción activa", 2)
        return
    end

    local subs = get_sub_tracks()
    if #subs == 0 then
        ui_msg("No hay ninguna pista de subtítulos seleccionada", 2.5)
        return
    end

    -- Selección previa a la extracción de pistas embebidas: si al final se
    -- cancela, se restaura aquí para volver a la pista del contenedor.
    session_rollback = {
        sid = mp.get_property("sid") or "no",
        sid2 = mp.get_property("secondary-sid") or "no",
    }

    loading = true
    show_loading()

    -- Se aplaza la búsqueda para que el spinner llegue a pintarse
    -- (collect_candidates puede bloquear extrayendo pistas con ffmpeg).
    -- La carpeta de sesión se crea AQUÍ, antes de esa extracción: al ser el
    -- primer subprocess del tick se evita el fallo transitorio de parseo de mpv
    -- (cubierto de todas formas por el retry de fs_command()).
    mp.add_timeout(0.05, function()
        get_session_edit_dir()
        local ok, cands, errs = pcall(collect_candidates, subs, t)
        stop_loading()
        loading = false
        if not ok then
            cleanup_disposable()
            ui_msg("Error al buscar subtítulos", 3)
            return
        end

        if #cands == 0 then
            cleanup_disposable()
            local extra = ""
            if #errs > 0 then
                extra = " (" .. table.concat(errs, " · ") .. ")"
            end
            ui_msg("No hay subtítulo en este momento" .. extra, 3)
            return
        end

        -- Candidatos para edición (los complejos se filtran; el contexto se
        -- muestra desde la pista real enmascarada, sin reconstrucción).
        local filtered = {}
        for _, c in ipairs(cands) do
            if not is_complex_subtitle(c.event.text) then
                table.insert(filtered, c)
            end
        end
        if #filtered == 0 then
            cleanup_disposable()
            ui_msg("Subtítulo demasiado complejo para edición (tags entre las palabras)", 3)
            return
        end
        cands = filtered

        table.sort(cands, function(a, b)
            local ra = a.sub.track["main-selection"] or 99
            local rb = b.sub.track["main-selection"] or 99
            if ra ~= rb then return ra < rb end
            return a.event.start_time < b.event.start_time
        end)

pause_enter()
        -- Fuentes embebidas para el primer evento en edición (antes de crear
        -- el renderer en setup_screen). Por línea, se re-evalúan en switch_edit.
        ensure_edit_fonts(cands[1])
        -- En modo pantalla se entra directo al primer candidato y se salta
        -- entre eventos con Ctrl+↑/↓; el menú selector queda para el modo OSD.
        candidates = cands
        if editor_mode_request == "screen" then
            start_edit(cands[1])
        elseif #cands == 1 then
            start_edit(cands[1])
        else
            enter_selector(cands)
        end
    end)
end

mp.add_key_binding("Ctrl+z", "edit-subtitle", function()
    edit_subtitle("screen")
end)
mp.add_key_binding("Ctrl+Z", "edit-subtitle-osd", function()
    edit_subtitle("osd")
end)

-- Al cerrar mpv se restaura osd-fonts-dir y se borra TODO el directorio de
-- sesión (incluida la cache de fuentes fonts/). Si mpv se mata por la fuerza
-- quedará una subedit.temp vacía que la próxima sesión reutiliza.
mp.register_event("shutdown", function()
    msg.info("[apagado] cerrar mpv: restore_edit_fonts + remove_session_edit_dir(true)")
    pcall(function()
        restore_edit_fonts()
        remove_session_edit_dir(true)
    end)
end)

msg.info("Editor de subtítulos v2 cargado. Ctrl+z: editar en pantalla · "
      .. "Ctrl+Shift+z: editar en OSD (doble pista, eventos solapados, multi-línea).")
