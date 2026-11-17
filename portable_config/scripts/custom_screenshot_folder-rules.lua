-- Per-user classification rules for custom_screenshot_folder.lua.
-- Ordered by priority: first enabled rule with match() true wins.
-- Copy a block, set enabled=true, adjust patterns to your naming.
-- Only enable what you use; unmatched files go to quarantine.

local season_suffixes = {
    -- Mirror of the main script list; keep in sync.
    "%s+%d+%a*%s+[Ss]eason$", -- " 2nd Season" (S02 covered by %d+)
    "%s+[Ss]eason%s+%d+%a*$", -- " Season 2"
    "%s+[Ss]%d+$",            -- " S2" / " S02"
    "%s+[Tt]%s*%-?%s*%d+$",   -- " T2" / " T-2"
    "%s+[Tt]emporada%s+%d+$", -- " Temporada 2"
}

local function strip_suffix(name)
    if not name then return "" end
    local s = name:gsub('^%s*(.-)%s*$', '%1')
    for _, pat in ipairs(season_suffixes) do
        local cut = s:gsub(pat, '')
        if cut ~= s and cut ~= '' then return cut end
    end
    return s
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

return {
    {
        -- Naming: Serie > Serie Temporada > Serie Temporada - XX - Cap
        -- Ex: Jujutsu Kaisen / Jujutsu Kaisen Shimetsu Kaiyuu Zenpen / Jujutsu Kaisen Shimetsu Kaiyuu Zenpen - 03 - Cap.mkv
        name = "mi-2-niveles",
        enabled = true,
        match = function(fname, fpath, parts)
            local season_raw = parts and parts[#parts] or nil
            local series_raw = parts and parts[#parts - 1] or nil
            if not season_raw or not series_raw or not fname or fname == "" then return false end
            if season_raw:find(series_raw, 1, true) ~= 1 then return false end
            if fname:find(season_raw, 1, true) == 1 then return true end
            local prefix = fname:match('^(.-)%s%-%s%d')
            return prefix ~= nil and prefix == season_raw
        end,
        series = function(fname, fpath, parts) return parts[#parts - 1] end,
        season = function(fname, fpath, parts) return parts[#parts] end,
    },
    {
        -- Naming: [Group] Show S2 [tags]\[Group] Show S2 - 01 [tags].mkv
        -- Ex: [Foxtrot] Vinland Saga S2 [BD 1080p]\[Foxtrot] Vinland Saga S2 - 01 [BD 1080p].mkv
        name = "fansub-Sx",
        enabled = false,
        match = function(fname)
            return group_of(fname) ~= nil
        end,
        series = function(fname, fpath, parts)
            local grouped = group_of(fname)
            if not grouped then return nil end
            local bare = strip_suffix(grouped)
            if bare ~= "" then return bare end
            return grouped
        end,
        season = function(fname, fpath, parts)
            local grouped = group_of(fname)
            if not grouped then return nil end
            local bare = strip_suffix(grouped)
            if bare ~= "" and bare ~= grouped then return grouped end
            -- filename lacks Sx (ex S1 only in folder): reuse folder season
            local folder_raw = parts and parts[#parts] or nil
            local folder_clean = clean_folder(folder_raw)
            if folder_clean ~= "" and folder_clean:find(grouped, 1, true) == 1
                and strip_suffix(folder_clean) ~= folder_clean then
                return folder_clean
            end
            return nil
        end,
    },
    {
        -- Naming: Show S01E02 / Show - S02E05
        -- Ex: Shingeki no Kyojin S01E02.mkv
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
            local bare = strip_suffix(show)
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
