--[[
    mix de:
    - https://github.com/zydezu/mpvconfig/blob/main/scripts/screenshotfolder.lua
    - https://github.com/jonniek/mpv-scripts/blob/master/customscreenshot.lua

    Place screenshots into folders for each serie/anime/movie with sequential numbering

    Modified to incorporate features: 
    - Parse series name from anime-style filenames for folder and screenshot names,
    - use sequential numbering like "Series Name (1).png",
    - capture screenshots in configurable mode (video/window).
    - Fixed options to toggle subtitle hiding and screenshot mode.
--]]

local options = {
    screenshot_key = 's',
    file_ext = "png",
    save_location = "D:/Imagenes/mpv screenshots/",
    short_saved_message = true,
    include_YouTube_ID = true,
    hide_subtitles = false,  -- Toggle to hide subtitles during screenshot (true) or keep them (false)
    screenshot_mode = "window",  -- "video" for native video res, "window" for displayed screen/window res
    png_compression = 7,  -- PNG compression level: 0 (no compression, larger file, fast) to 9 (max lossless compression, smaller file, slower)
    jpeg_quality = 95,  -- JPEG quality: 0 (worst) to 100 (best)
    sequential_numbering = true  -- If true, continues from highest number; if false, uses mpv's %n (fills gaps)
}
(require "mp.options").read_options(options)

local title = "default"  -- Global variable to store the parsed/sanitized show/video title for folder and filename
local current_format = options.file_ext
local screenshot_counter = 1  -- Counter for sequential numbering

-- Patterns for parsing series names from anime-style filenames
-- patterns are in priority order, first match will be used for screenshot
local patterns = {
    -- Rule 1: For formats like: [Grupo] NombreSerie T-1 - 03 [...]
    {
        ['match'] = function(fn)
            -- detecta '[Grupo]' y la temporada 'T + todo lo posterior'
            return fn:match('^%[.*%]') and fn:match('%sT%s*%-?%s*%d+') and true or false
        end,
        ['extract'] = function(fn)
            -- captura solo el nombre de la serie, parando antes de la temporada
            return fn:match('%]%s(.-)%sT%s*%-?%s*%d+')
        end,
    },
    -- Rule 2: ...
}

local function sanitize_filename(name)
    return name and name:gsub('[\\/:*?"<>|]', '') or ""
end

local function extract_youtube_id(filename)
    if not options.include_YouTube_ID then return "" end
    return filename:match("[?&]v=([^&]+)")
        or filename:match("([%w_-]+)%?si=")
        or ""
end

local function get_highest_screenshot_number(directory, prefix)
    local highest = 0
    
    -- Use mpv's utils to read directory without opening terminal
    local utils = require 'mp.utils'
    local files = utils.readdir(directory, "files")
    
    if files then
        for _, filename in ipairs(files) do
            -- Match pattern: "prefix (number).ext"
            local num = filename:match("^" .. prefix:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1") .. " %((%d+)%)%.")
            if num then
                num = tonumber(num)
                if num and num > highest then
                    highest = num
                end
            end
        end
    end
    
    return highest
end

local function set_screenshot_template()
    mp.set_property("screenshot-format", current_format)
    local directory = options.save_location .. title .. "/"
    mp.set_property("screenshot-directory", directory)
    
    if options.sequential_numbering then
        -- Find highest existing number and set counter
        screenshot_counter = get_highest_screenshot_number(directory, title) + 1
        mp.set_property("screenshot-template", title .. " (" .. screenshot_counter .. ")")
    else
        -- Use mpv's default %n (fills gaps)
        mp.set_property("screenshot-template", title .. " (%n)")
    end
end

local function init()
    local media = mp.get_property("media-title")
    local filename = mp.get_property("filename/no-ext")
    local path = mp.get_property("path")
    
    -- Handle YouTube URLs
    if path:match("^[%w]+://") then
        local youtube_id = extract_youtube_id(mp.get_property("filename"))
        filename = media:sub(1, 100):gsub("^%s*(.-)%s*$", "%1") .. (youtube_id ~= "" and (" [" .. youtube_id .. "]") or "")
    end
    
    -- Try to match and extract series name using patterns
    local extracted = false
    for _, pattern in ipairs(patterns) do
        if pattern.match(filename) then
            local head_dir = pattern.extract(filename)
            if head_dir then
                title = sanitize_filename(head_dir)
                extracted = true
                break
            end
        end
    end
    
    -- Fall back to sanitized filename if no pattern matched
    if not extracted then
        title = sanitize_filename(filename)
    end
    
    set_screenshot_template()
end

local function screenshot_done()
    -- Force screenshot format and quality settings before taking the screenshot
    mp.set_property("screenshot-format", options.file_ext)
    if options.file_ext == "png" then
        mp.set_property_number("screenshot-png-compression", options.png_compression)
    elseif options.file_ext == "jpg" or options.file_ext == "jpeg" then
        mp.set_property_number("screenshot-jpeg-quality", options.jpeg_quality)
    end
    
    -- Update template with current counter if using sequential numbering
    if options.sequential_numbering then
        mp.set_property("screenshot-template", title .. " (" .. screenshot_counter .. ")")
    end
    
    local sub_visibility = nil
    if options.hide_subtitles then
        sub_visibility = mp.get_property("sub-visibility")
        mp.set_property("sub-visibility", "no")
    end
    
    mp.commandv("screenshot", options.screenshot_mode)
    
    if options.hide_subtitles then
        mp.set_property("sub-visibility", sub_visibility)
    end
    
    -- Increment counter for next screenshot
    if options.sequential_numbering then
        screenshot_counter = screenshot_counter + 1
    end
    
    local msg = options.short_saved_message
        and "Screenshot saved"
        or "Screenshot saved to: " .. mp.command_native({"expand-path", mp.get_property("screenshot-directory")}):gsub("\\", "/")
    mp.osd_message(msg)
end

mp.observe_property("screenshot-format", "string", function(_, value)
    if value then current_format = value end
end)

mp.register_event("file-loaded", init)
mp.add_key_binding(options.screenshot_key, "screenshot_done", screenshot_done)