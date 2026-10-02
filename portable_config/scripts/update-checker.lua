-- update-checker.lua
-- Colócalo en portable_config\scripts\update-checker.lua

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    check_on_startup = true,
}
options.read_options(o, "update-checker")

local repo = "AlwaysBorderRadius/mpvnet-desuka"
local current_version = "1.2"

-- Función para obtener la última versión de GitHub
function get_latest_version()
    local api_url = "https://api.github.com/repos/" .. repo .. "/releases/latest"
    local args = { 'curl', '--silent', api_url }
    msg.info("Intentando ejecutar curl con args: " .. table.concat(args, " "))
    
    local res = utils.subprocess({
        args = args,
        capture_stdout = true,     -- Captura salida en memoria (sin archivo)
        playback_only = false,     -- Permite correr al inicio, sin playback
        stdin_data = "",           -- Fix para handle inválido en Windows GUI
    })
    
    if res.status ~= 0 then
        msg.error("Fallo al ejecutar curl. Status: " .. res.status .. ", Error: " .. (res.error or "desconocido"))
        return nil
    end
    
    if not res.stdout or res.stdout == "" then
        msg.error("No se recibió salida de curl (stdout vacío).")
        return nil
    end
    
    msg.info("Salida cruda de curl (primeros 200 chars): " .. string.sub(res.stdout, 1, 200))  -- Para depurar el JSON
    
    local data = utils.parse_json(res.stdout)
    if not data then
        msg.error("Fallo al parsear JSON.")
        return nil
    end
    
    if not data.tag_name then
        msg.error("No se encontró 'tag_name' en el JSON.")
        return nil
    end
    
    return data.tag_name
end

-- Chequeo principal
function check_for_update()
    local latest = get_latest_version()
    msg.info("Versión latest obtenida: " .. (latest or "nil"))
    
    if latest then
        if latest ~= current_version then
            mp.osd_message("¡Nueva actualización de mpvnet-desuka disponible! \nVersión: " .. latest .. "\nActual: " .. current_version .. "\nVisita el repo en GitHub.", 5)
            msg.info("Nueva versión detectada: " .. latest)
        else
            msg.info("La versión actual es la más reciente.")
        end
    else
        msg.error("No se pudo obtener la versión latest de GitHub. Revisa tu conexión o curl.")
    end
end

if o.check_on_startup then
    mp.add_timeout(2, check_for_update)
end