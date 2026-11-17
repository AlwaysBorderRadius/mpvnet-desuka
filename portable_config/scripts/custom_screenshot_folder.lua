--[[
    Per-series screenshot folders with sequential numbering.

    Mix of:
    - https://github.com/zydezu/mpvconfig/blob/main/scripts/screenshotfolder.lua
    - https://github.com/jonniek/mpv-scripts/blob/master/customscreenshot.lua

    Rewritten for mpv Desuka: Series/Season extraction from path, naming modes,
    portable save_location, validated options, custom rules file, quarantine fallback.

    Layouts (save_location = S):
    - naming_mode=series: S/<Series>/<Series> (N).ext
    - naming_mode=season: S/<Series>/<Season>/<Season> (N).ext
    - unmatched files: S/<quarantine>/<Filename> (N).ext
    - sequential_numbering=no uses mpv %n instead of the literal (N)
    Custom rules at the top of this file (custom_rules table, priority order).
--]]

local utils = require 'mp.utils'
local msg = require 'mp.msg'

local options = {
    screenshot_key = 's',
    file_ext = "png",
    save_location = "~~/screenshots/",
    short_saved_message = true,
    include_YouTube_ID = true,
    hide_subtitles = false,  -- hide subs for the shot, then restore
    screenshot_mode = "window",  -- "video" native res, "window" displayed res
    png_compression = 7,  -- 0 (fast, big) to 9 (slow, small)
    jpeg_quality = 95,  -- 0 (worst) to 100 (best)
    sequential_numbering = true,  -- true: keep counting up; false: mpv %n (fills gaps)
    naming_mode = "series",  -- "series" or "season" (separates screenshots by serie or by serie>season)
    quarantine_name = "_sin-clasificar",  -- folder for unmatched files: S/<quarantine>/<Filename> (N).ext
    log_matched_rule = true,  -- log which custom rule matched (mpv.log)
}
(require "mp.options").read_options(options)

local function validate_user_opts()
    if type(options.screenshot_mode) == "string" then
        options.screenshot_mode = options.screenshot_mode:lower()
    end
    if options.screenshot_mode ~= "video" and options.screenshot_mode ~= "window" then
        msg.warn("custom_screenshot_folder: bad screenshot_mode, fallback to 'window'")
        options.screenshot_mode = "window"
    end
    options.file_ext = tostring(options.file_ext or "png"):lower()
    if options.file_ext ~= "png" and options.file_ext ~= "jpg" and options.file_ext ~= "jpeg" then
        msg.warn("custom_screenshot_folder: bad file_ext, fallback to 'png'")
        options.file_ext = "png"
    end
    options.png_compression = math.floor(tonumber(options.png_compression) or 7)
    if options.png_compression < 0 or options.png_compression > 9 then
        msg.warn("custom_screenshot_folder: bad png_compression, fallback to 7")
        options.png_compression = 7
    end
    options.jpeg_quality = math.floor(tonumber(options.jpeg_quality) or 95)
    if options.jpeg_quality < 0 or options.jpeg_quality > 100 then
        msg.warn("custom_screenshot_folder: bad jpeg_quality, fallback to 95")
        options.jpeg_quality = 95
    end
    options.naming_mode = tostring(options.naming_mode or "series"):lower()
    if options.naming_mode ~= "series" and options.naming_mode ~= "season" then
        msg.warn("custom_screenshot_folder: bad naming_mode, fallback to 'series'")
        options.naming_mode = "series"
    end
    if type(options.quarantine_name) ~= "string" or options.quarantine_name == ""
        or options.quarantine_name:find("[/\\]") then
        msg.warn("custom_screenshot_folder: bad quarantine_name, fallback to '_sin-clasificar'")
        options.quarantine_name = "_sin-clasificar"
    end
    if type(options.save_location) ~= "string" or options.save_location == "" then
        msg.warn("custom_screenshot_folder: bad save_location, fallback to '~~/screenshots/'")
        options.save_location = "~~/screenshots/"
    end
    if type(options.screenshot_key) ~= "string" or options.screenshot_key == "" then
        msg.warn("custom_screenshot_folder: bad screenshot_key, fallback to 's'")
        options.screenshot_key = "s"
    end
    -- mp.options leaves unknown strings as-is; coerce booleans strictly
    local function to_bool(v, default)
        if type(v) == "boolean" then return v end
        if type(v) == "string" then
            local s = v:lower()
            if s == "yes" or s == "true" or s == "1" then return true end
            if s == "no" or s == "false" or s == "0" then return false end
        elseif type(v) == "number" then
            return v ~= 0
        end
        msg.warn("custom_screenshot_folder: bad boolean option, fallback to default")
        return default
    end
    options.short_saved_message = to_bool(options.short_saved_message, true)
    options.include_YouTube_ID = to_bool(options.include_YouTube_ID, true)
    options.hide_subtitles = to_bool(options.hide_subtitles, false)
    options.sequential_numbering = to_bool(options.sequential_numbering, true)
    options.log_matched_rule = to_bool(options.log_matched_rule, true)
end
validate_user_opts()

-- ============================ USER RULES ============================
-- Edit here: classification rules, first enabled match wins.
-- Copy a block, set enabled=true, adjust to your naming.
-- Helpers below are shared with the engine; keep them.
local season_suffixes = {
    "%s+%d+%a*%s+[Ss]eason$",  -- " 2nd Season"
    "%s+[Ss]eason%s+%d+%a*$",  -- " Season 2"
    "%s+[Ss]%d+$",             -- " S2"
    "%s+[Tt]%s*%-?%s*%d+$",    -- " T2" / " T-2"
    "%s+[Tt]emporada%s+%d+$",  -- " Temporada 2"
}

local function sanitize_filename(name)
    if not name or name == "" then return "" end
    local s = name:gsub('[\\/:*?"<>|]', '')
    s = s:gsub('[%c]', '')
    s = s:gsub('^%s*(.-)%s*$', '%1')
    s = s:gsub('[%.%s]+$', '')
    if #s > 120 then
        s = s:sub(1, 120):gsub('%s+$', '')
    end
    return s
end

local function strip_season_suffix(name)
    if not name then return "" end
    local s = name:gsub('^%s*(.-)%s*$', '%1')
    for _, pat in ipairs(season_suffixes) do
        local stripped = s:gsub(pat, '')
        if stripped ~= s and stripped ~= '' then return stripped end
    end
    return s
end

local function filename_prefix(fname)
    if not fname then return nil end
    return fname:match('^(.-)%s%-%s%d')
end

local function split_path_parts(path)
    local parts = {}
    if path then
        local dir = utils.split_path(path)
        if dir then
            for part in dir:gmatch('[^\\/]+') do
                parts[#parts + 1] = part
            end
        end
    end
    return parts
end

local function clean_folder(name)
    if not name then return "" end
    local s = name:gsub('^%[.-%]%s*', '')
    s = s:gsub('%s*[%(%[].*$', '')
    return (s:gsub('^%s*(.-)%s*$', '%1'))
end

local function group_of(fname)
    if not fname then return nil end
    return fname:match('^%[.-%]%s*(.-)%s%-%s%d')
end

local custom_rules = {
    {
        -- Naming: Show > Show Season > Show Season - XX - Episode
        -- Ex: Jujutsu Kaisen / Jujutsu Kaisen Shimetsu Kaiyuu Zenpen / Jujutsu Kaisen Shimetsu Kaiyuu Zenpen - 03 - Ep.mkv
        name = "anilist",
        enabled = true,
        match = function(fname, fpath, parts)
            local season_raw = parts and parts[#parts] or nil
            local series_raw = parts and parts[#parts - 1] or nil
            if not season_raw or not series_raw or not fname or fname == "" then return false end
            if season_raw:find(series_raw, 1, true) ~= 1 then return false end
            if fname:find(season_raw, 1, true) == 1 then return true end
            return filename_prefix(fname) == season_raw
        end,
        series = function(fname, fpath, parts) return parts[#parts - 1] end,
        season = function(fname, fpath, parts) return parts[#parts] end,
    },
    {
        -- Naming: [Group] Show S2 [tags]\[Group] Show S2 - 01 [tags].mkv
        -- Ex: [Foxtrot] Vinland Saga S2 [BD 1080p]\[Foxtrot] Vinland Saga S2 - 01 [BD 1080p].mkv
        name = "generic-group-release",
        enabled = false,
        match = function(fname) return group_of(fname) ~= nil end,
        series = function(fname)
            local grouped = group_of(fname)
            if not grouped then return nil end
            local bare = strip_season_suffix(grouped)
            if bare ~= "" then return bare end
            return grouped
        end,
        season = function(fname, fpath, parts)
            local grouped = group_of(fname)
            if not grouped then return nil end
            local bare = strip_season_suffix(grouped)
            if bare ~= "" and bare ~= grouped then return grouped end
            local folder_clean = clean_folder(parts and parts[#parts] or nil)
            if folder_clean ~= "" and folder_clean:find(grouped, 1, true) == 1
                and strip_season_suffix(folder_clean) ~= folder_clean then
                return folder_clean
            end
            return nil
        end,
    },
    {
        -- Naming: Show S01E02
        name = "sxxexx",
        enabled = false,
        match = function(fname)
            if not fname then return false end
            local nogroup = fname:gsub('^%[.-%]%s*', '')
            local show = nogroup:match('^(.-)%s+[Ss]%d+[Ee]%d+')
            return show ~= nil and show ~= ""
        end,
        series = function(fname)
            local nogroup = fname:gsub('^%[.-%]%s*', '')
            local show = nogroup:match('^(.-)%s+[Ss](%d+)[Ee]%d+')
            if not show or show == "" then return nil end
            local bare = strip_season_suffix(show)
            if bare == "" then bare = show end
            return bare
        end,
        season = function(fname)
            local nogroup = fname:gsub('^%[.-%]%s*', '')
            local show, sno = nogroup:match('^(.-)%s+[Ss](%d+)[Ee]%d+')
            if not show or not sno then return nil end
            return show .. " S" .. sno
        end,
    },
}
-- ========================== END USER RULES ==========================

-- bilingual toasts
-- UI language comes from modernx.conf (single source), like update_checker.
local function read_modernx_language()
    local path = mp.find_config_file("script-opts/modernx.conf")
    if path == nil then
        local dir = mp.get_script_directory()
        if dir == nil or dir == "" then return "en" end
        path = dir .. "/../script-opts/modernx.conf"
    end
    local f = io.open(path, "r")
    if f == nil then return "en" end
    local content = f:read("*a")
    f:close()
    if content == nil then return "en" end
    local lang = "en"
    for line in content:gmatch("[^\r\n]+") do
        local v = line:match("^%s*language%s*=%s*(%S+)")
        if v ~= nil then lang = v:gsub('^"(.*)"$', "%1"):gsub("^'(.-)'$", "%1") end
    end
    if lang ~= "en" and lang ~= "es" then lang = "en" end
    return lang
end
local mo = { language = read_modernx_language() }

local STRINGS = {
    en = {
        saved = "Screenshot saved",
        saved_to = "Screenshot saved to: %s",
    },
    es = {
        saved = "Captura guardada",
        saved_to = "Captura guardada en: %s",
    },
}

local function t(key, a)
    local lang_table = STRINGS[mo.language] or STRINGS["en"]
    local fmt = lang_table[key] or STRINGS["en"][key] or ""
    if a == nil then return fmt end
    return string.format(fmt, a)
end

local state = {
    series = "default",
    season = nil,
    dir = nil,
    prefix = "default",
    counter = 1,
    quarantined = false,
    quarantine_prefix = "default",
}

local function try_custom_rules(fname, path)
    if #custom_rules == 0 then return nil, nil, nil end
    local parts = split_path_parts(path)
    for _, rule in ipairs(custom_rules) do
        if type(rule) == "table" and type(rule.match) == "function" and rule.enabled ~= false then
        local ok_match, matched = pcall(rule.match, fname, path, parts)
        if ok_match and matched then
            local series_raw, season_raw = nil, nil
            if type(rule.series) == "function" then
                local ok_series, out_series = pcall(rule.series, fname, path, parts)
                if ok_series and type(out_series) == "string" then series_raw = out_series end
            end
            if type(rule.season) == "function" then
                local ok_season, out_season = pcall(rule.season, fname, path, parts)
                if ok_season and (out_season == nil or type(out_season) == "string") then season_raw = out_season end
            end
            local series = sanitize_filename(series_raw)
            local season = sanitize_filename(season_raw)
            if season == "" then season = nil end
            if series ~= "" then
                if options.log_matched_rule then
                    msg.info("custom_screenshot_folder: rule '" .. tostring(rule.name) .. "' matched")
                end
                return series, season, rule.name
            end
            msg.warn("custom_screenshot_folder: rule '" .. tostring(rule.name) .. "' matched but returned empty series")
            return nil, nil, rule.name
        end
        end
    end
    return nil, nil, nil
end

local function extract_names(path, fname)
    fname = fname or ""
    local comps = {}
    if path then
        local dir = utils.split_path(path)
        if dir then
            for part in dir:gmatch('[^\\/]+') do
                comps[#comps + 1] = part
            end
        end
    end
    local season_raw = comps[#comps]
    local series_raw = comps[#comps - 1]
    local prefix = filename_prefix(fname)

    -- Two-level layout: Serie/Temporada/Temporada - NN - Cap
    if season_raw and series_raw and fname ~= "" then
        local stripped = strip_season_suffix(season_raw)
        local two_level = (stripped == series_raw)
            or (season_raw:find(series_raw, 1, true) == 1)
        if two_level and (fname:find(season_raw, 1, true) == 1
            or (prefix and prefix == season_raw)) then
            local series = sanitize_filename(series_raw)
            local season = sanitize_filename(season_raw)
            if series ~= "" and season ~= "" then return series, season end
        end
    end

    -- Prefix carries season: "Serie 2nd Season - 01 - Cap"
    if prefix and prefix ~= "" then
        local bare = strip_season_suffix(prefix)
        if bare ~= "" and bare ~= prefix then
            return sanitize_filename(bare), sanitize_filename(prefix)
        end
        local clean = sanitize_filename(prefix)
        if clean ~= "" then return clean, nil end
    end

    -- Legacy [Grupo] Serie - NN fallback
    if fname ~= "" then
        local grouped = fname:match('^%[.-%]%s*(.-)%s%-%s%d')
        if grouped and grouped ~= "" then
            local bare = strip_season_suffix(grouped)
            if bare ~= "" and bare ~= grouped then
                return sanitize_filename(bare), sanitize_filename(grouped)
            end
            return sanitize_filename(grouped), nil
        end
        local nogroup = fname:gsub('^%[.-%]%s*', '')
        local show, sno = nogroup:match('^(.-)%s+[Ss](%d+)[Ee]%d+')
        if show and show ~= "" then
            local bare = strip_season_suffix(show)
            if bare == "" then bare = show end
            if sno then
                return sanitize_filename(bare), sanitize_filename(show .. " S" .. sno)
            end
            return sanitize_filename(bare), nil
        end
    end

    local fallback = sanitize_filename(fname)
    if fallback == "" then fallback = "default" end
    return fallback, nil
end

local function extract_youtube_id(filename)
    if not options.include_YouTube_ID then return "" end
    if not filename then return "" end
    return filename:match("[?&]v=([^&]+)")
        or filename:match("([%w_-]+)%?si=")
        or filename:match("youtu%.be/([%w_%-]+)")
        or ""
end

local function escape_pattern(s)
    return (s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function get_highest_screenshot_number(directory, prefix)
    if not directory or not prefix or prefix == "" then return 0 end
    local highest = 0
    local files = utils.readdir(directory, "files")
    if files then
        local head = "^" .. escape_pattern(prefix) .. " %((%d+)%)%."
        for _, filename in ipairs(files) do
            local num = filename:match(head)
            if num then
                num = tonumber(num)
                if num and num > highest then highest = num end
            end
        end
    end
    return highest
end

local function expand_save_location()
    local save = mp.command_native({ "expand-path", options.save_location })
    if not save or save == "" then save = options.save_location end
    return save
end

local function current_target()
    local save = expand_save_location()
    if state.quarantined then
        return utils.join_path(save, state.series), state.quarantine_prefix
    end
    if options.naming_mode == "season" and state.season and state.season ~= "" then
        return utils.join_path(utils.join_path(save, state.series), state.season), state.season
    end
    return utils.join_path(save, state.series), state.series
end

local function refresh_template()
    local dir, prefix = current_target()
    state.dir = dir
    state.prefix = prefix
    mp.set_property("screenshot-format", options.file_ext)
    mp.set_property("screenshot-directory", dir)
    if options.sequential_numbering then
        state.counter = get_highest_screenshot_number(dir, prefix) + 1
        mp.set_property("screenshot-template", prefix .. " (" .. state.counter .. ")")
    else
        mp.set_property("screenshot-template", prefix .. " (%n)")
    end
end

local function init()
    local media = mp.get_property("media-title")
    local fname = mp.get_property("filename/no-ext")
    local full_name = mp.get_property("filename")
    local path = mp.get_property("path")

    if not fname or fname == "" then
        if path then
            fname = path:match("[^\\/]+$") or "default"
            fname = fname:gsub("%.[^%.]*$", "")
        else
            fname = "default"
        end
    end

    if path and path:find("://", 1, true) then
        local base = (media and media ~= "") and media or fname
        base = base:gsub('%s+%- YouTube%s*$', '')
        base = base:sub(1, 100):gsub("^%s*(.-)%s*$", "%1")
        local yid = extract_youtube_id(full_name or path)
        if yid ~= "" then base = base .. " [" .. yid .. "]" end
        state.series = sanitize_filename(base)
        if state.series == "" then state.series = "default" end
        state.season = nil
        state.quarantined = false
    else
        local rule_series, rule_season = try_custom_rules(fname, path)
        if rule_series and rule_series ~= "" then
            state.series = rule_series
            state.season = rule_season
            state.quarantined = false
        else
            local series, season = extract_names(path, fname)
            if not series or series == "" then series = "default" end
            if season == "" then season = nil end
            -- Builtin filename-only fallback means no confident match: quarantine
            if season == nil and series == sanitize_filename(fname) and fname ~= "" then
                state.series = sanitize_filename(options.quarantine_name)
                if state.series == "" then state.series = "_sin-clasificar" end
                state.season = nil
                state.quarantined = true
                state.quarantine_prefix = sanitize_filename(fname)
                if state.quarantine_prefix == "" then state.quarantine_prefix = "default" end
                if options.log_matched_rule then
                    msg.info("custom_screenshot_folder: no rule matched, quarantine")
                end
            else
                state.series = series
                state.season = season
                state.quarantined = false
            end
        end
    end

    refresh_template()
end

local function screenshot_done(oneshot_mode) -- one-shot mode from the message
    if not state.dir or not state.prefix then refresh_template() end

    -- one-shot screenshot mode (OSC button flag)
    -- Native each-frame bursts need %n templates, not (N): rejected, not truncated.
    local mode = options.screenshot_mode
    if type(oneshot_mode) == "string" then
        local base = (oneshot_mode:match("^(%a+)") or ""):lower()
        if base == "video" or base == "window" or base == "subtitles" then
            mode = base
        else
            msg.warn("custom_screenshot_folder: bad shot mode '" .. tostring(oneshot_mode) .. "', using option")
        end
    end

    mp.set_property("screenshot-format", options.file_ext)
    if options.file_ext == "png" then
        mp.set_property_number("screenshot-png-compression", options.png_compression)
    elseif options.file_ext == "jpg" or options.file_ext == "jpeg" then
        mp.set_property_number("screenshot-jpeg-quality", options.jpeg_quality)
    end

    if options.sequential_numbering then
        local highest = get_highest_screenshot_number(state.dir, state.prefix)
        if state.counter <= highest then state.counter = highest + 1 end
        mp.set_property("screenshot-template", state.prefix .. " (" .. state.counter .. ")")
    end
    local shot_n = options.sequential_numbering and state.counter or nil -- number used below, before the bump

    local sub_visibility = nil
    if options.hide_subtitles and mode ~= "subtitles" then -- explicit subtitles mode wins over the global opt-out
        sub_visibility = mp.get_property("sub-visibility")
        mp.set_property("sub-visibility", "no")
    end

    -- mp.commandv blocks until the file is written, so restore after is safe
    mp.commandv("screenshot", mode) -- one-shot or option mode

    if options.hide_subtitles and sub_visibility ~= nil then
        mp.set_property("sub-visibility", sub_visibility)
    end

    if options.sequential_numbering then state.counter = state.counter + 1 end
    -- Republish so an intermediate native shot never reuses the taken number
    if options.sequential_numbering and state.dir and state.prefix then
        mp.set_property("screenshot-template", state.prefix .. " (" .. state.counter .. ")")
    end

    local toast_msg = t("saved")
    if not options.short_saved_message then
        local dir = mp.get_property("screenshot-directory") or state.dir or ""
        if options.sequential_numbering and shot_n then -- full file path when we know the number
            toast_msg = t("saved_to", utils.join_path(dir, state.prefix .. " (" .. shot_n .. ")." .. options.file_ext):gsub("\\", "/"))
        else
            toast_msg = t("saved_to", dir:gsub("\\", "/"))
        end
    end
    -- unified toast via modernx (replaces native OSD)
    mp.commandv("script-message-to", "modernx", "modernx-toast", "success", "screenshot", toast_msg)
end

local function reset_on_unload()
    local save = expand_save_location()
    if save and save ~= "" then mp.set_property("screenshot-directory", save) end
    -- Park template on a generic name so native idle shots never reuse a taken (N)
    mp.set_property("screenshot-template", "%F (%n)")
end

mp.register_event("file-loaded", init)
mp.register_event("end-file", reset_on_unload)
-- All screenshot keys go through input.conf via custom_screenshot_folder-shot,
-- so numbering never collides (see script-opts/custom_screenshot_folder.conf).
-- mp.add_forced_key_binding(options.screenshot_key, "custom_screenshot_folder-shot", screenshot_done)
mp.register_script_message("custom_screenshot_folder-shot", screenshot_done)
