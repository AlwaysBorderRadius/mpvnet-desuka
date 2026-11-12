-- update-checker.lua
-- Startup update check against GitHub releases/latest.
-- Async fetch + short curl timeouts so a slow network can't freeze the OSD.
-- Manual: script-message-to update_checker check-for-update

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    check_on_startup = true,
    repo = "AlwaysBorderRadius/mpvnet-desuka",
    current_version = "1.2",
    startup_delay = 5,
    curl_max_time = 10,
    curl_connect_timeout = 5,
    notify_up_to_date = false,
}
options.read_options(o, "update-checker")

-- >>> CUSTOM Desuka <<<
-- UI language comes from modernx.conf (single source).
local mo = { language = "en" }
options.read_options(mo, "modernx")

-- Bilingual toast strings, keep en/es keys in sync.
local STRINGS = {
    en = {
        no_network = "Could not check for updates (no network or no curl).",
        update_available = "New update available: %s (current: %s)",
        up_to_date = "You already have the latest version (%s).",
        local_newer = "Local version (%s) is newer than published (%s).",
    },
    es = {
        no_network = "No se pudo comprobar la actualización (sin red o sin curl).",
        update_available = "Nueva actualización disponible: %s (actual: %s)",
        up_to_date = "Ya tienes la última versión (%s).",
        local_newer = "Versión local (%s) más reciente que la publicada (%s).",
    },
}

local function t(key, a, b)
    local lang_table = STRINGS[mo.language] or STRINGS["en"]
    local fmt = lang_table[key] or STRINGS["en"][key] or ""
    if a == nil then return fmt end
    if b == nil then return string.format(fmt, a) end
    return string.format(fmt, a, b)
end
-- <<< CUSTOM Desuka >>>

-- Clamp user opts to safe defaults.
local function validate_user_opts()
    if type(o.check_on_startup) ~= "boolean" then
        msg.warn("update-checker: bad check_on_startup, using true")
        o.check_on_startup = true
    end
    if type(o.notify_up_to_date) ~= "boolean" then
        msg.warn("update-checker: bad notify_up_to_date, using false")
        o.notify_up_to_date = false
    end
    if type(o.repo) ~= "string" or o.repo == "" then
        msg.warn("update-checker: bad repo, using default")
        o.repo = "AlwaysBorderRadius/mpvnet-desuka"
    end
    if type(o.current_version) ~= "string" or o.current_version == "" then
        msg.warn("update-checker: bad current_version, using 1.2")
        o.current_version = "1.2"
    end
    local delay = tonumber(o.startup_delay)
    if delay == nil then
        msg.warn("update-checker: bad startup_delay, using 5")
        delay = 5
    end
    o.startup_delay = delay
    if o.startup_delay < 0 or o.startup_delay > 120 then
        msg.warn("update-checker: bad startup_delay, using 5")
        o.startup_delay = 5
    end
    local max_time = tonumber(o.curl_max_time)
    if max_time == nil then
        msg.warn("update-checker: bad curl_max_time, using 10")
        max_time = 10
    end
    o.curl_max_time = max_time
    if o.curl_max_time < 1 or o.curl_max_time > 60 then
        msg.warn("update-checker: bad curl_max_time, using 10")
        o.curl_max_time = 10
    end
    local conn_time = tonumber(o.curl_connect_timeout)
    if conn_time == nil then
        msg.warn("update-checker: bad curl_connect_timeout, using 5")
        conn_time = 5
    end
    o.curl_connect_timeout = conn_time
    if o.curl_connect_timeout < 1 or o.curl_connect_timeout > 30 then
        msg.warn("update-checker: bad curl_connect_timeout, using 5")
        o.curl_connect_timeout = 5
    end
    if o.curl_connect_timeout > o.curl_max_time then
        msg.warn("update-checker: connect timeout above max time, clamping")
        o.curl_connect_timeout = o.curl_max_time
    end
    if mo.language ~= "en" and mo.language ~= "es" then -- >>> EDIT Desuka <<<
        msg.warn("update-checker: bad language, using en")
        mo.language = "en"
    end
end
validate_user_opts()

-- Strip whitespace, lowercase, leading 'v' ("v1.2" -> "1.2").
local function normalize_version(v)
    if type(v) ~= "string" then
        return ""
    end
    local s = v:match("^%s*(.-)%s*$") or ""
    s = s:lower()
    if s:match("^v[%d%.]") then
        s = s:sub(2)
    end
    return s
end

-- Split "1.2.3-beta" into numeric core {1,2,3} + prerelease "beta".
local function split_version(v)
    local core, pre = v:match("^([^%-]+)%-(.+)$")
    if not core then
        core = v
        pre = ""
    end
    local nums = {}
    for part in core:gmatch("[^.]+") do
        nums[#nums + 1] = tonumber(part) or 0
    end
    return nums, pre
end

-- Returns -1 if a<b, 0 if equal, 1 if a>b. Release beats prerelease.
local function compare_versions(a, b)
    local na, prea = split_version(normalize_version(a))
    local nb, preb = split_version(normalize_version(b))
    local n = math.max(#na, #nb)
    for i = 1, n do
        local xa, xb = na[i] or 0, nb[i] or 0
        if xa < xb then return -1 end
        if xa > xb then return 1 end
    end
    if prea == preb then return 0 end
    if prea == "" then return 1 end
    if preb == "" then return -1 end
    if prea < preb then return -1 end
    return 1
end

-- Fetch latest tag_name from GitHub, async (never blocks the OSD).
-- Calls cb(tag or nil). No -f flag: HTTP errors stay in stdout as
-- JSON with .message, so rate limits and missing releases are logged.
local function fetch_latest_async(cb)
    local api_url = "https://api.github.com/repos/" .. o.repo .. "/releases/latest"
    local args = {
        "curl", "-sSL",
        "--max-time", tostring(o.curl_max_time),
        "--connect-timeout", tostring(o.curl_connect_timeout),
        "--user-agent", "mpvnet-desuka-update-checker",
        api_url,
    }
    msg.verbose("update-checker: curl " .. table.concat(args, " "))

    local cmd = {
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false, -- Allow run at startup, no playback needed.
        stdin_data = "", -- Fix invalid handle on Windows GUI builds.
    }
    local ok, async_err = pcall(mp.command_native_async, cmd, function(success, res, native_err)
        if not success or res == nil then
            msg.error("update-checker: async subprocess failed: " .. tostring(native_err))
            cb(nil)
            return
        end
        if res.error ~= nil then
            msg.error("update-checker: cannot run curl: " .. tostring(res.error))
            cb(nil)
            return
        end
        if res.status ~= 0 then
            local detail = ""
            if type(res.stderr) == "string" and res.stderr ~= "" then
                detail = ": " .. res.stderr:sub(1, 200)
            end
            msg.error("update-checker: curl failed, status " .. tostring(res.status) .. detail)
            cb(nil)
            return
        end
        if res.stdout == nil or res.stdout == "" then
            msg.error("update-checker: empty response from GitHub API")
            cb(nil)
            return
        end
        local data, json_err = utils.parse_json(res.stdout)
        if type(data) ~= "table" then
            msg.error("update-checker: bad JSON: " .. tostring(json_err))
            cb(nil)
            return
        end
        if type(data.tag_name) == "string" and data.tag_name ~= "" then
            cb(data.tag_name)
            return
        end
        if type(data.message) == "string" and data.message ~= "" then
            msg.error("update-checker: GitHub API: " .. data.message) -- Rate limit / no releases.
        else
            msg.error("update-checker: no tag_name in GitHub response")
        end
        cb(nil)
    end)
    if not ok then
        msg.error("update-checker: command_native_async failed: " .. tostring(async_err))
        cb(nil)
    end
end

-- Main check. Manual=true forces feedback even when up to date.
local function check_for_update(manual)
    fetch_latest_async(function(latest)
        if latest == nil then
            if manual then
                mp.commandv("script-message-to", "modernx", "modernx-toast",
                    "error", "update-checker",
                    t("no_network"), -- >>> EDIT Desuka <<<
                    "6000")
            end
            return
        end

        msg.verbose("update-checker: latest=" .. latest .. " current=" .. o.current_version)
        local cmp = compare_versions(latest, o.current_version)
        if cmp > 0 then
            -- Important toast, preempts any toast (no queue).
            mp.commandv("script-message-to", "modernx", "modernx-toast",
                "warn", "update-checker",
                t("update_available", latest, o.current_version), -- >>> EDIT Desuka <<<
                "6000")
            msg.info("update-checker: new version " .. latest .. " (current " .. o.current_version .. ")")
        elseif cmp == 0 then
            msg.info("update-checker: up to date (" .. o.current_version .. ")")
            if manual or o.notify_up_to_date then
                mp.commandv("script-message-to", "modernx", "modernx-toast",
                    "info", "update-checker",
                    t("up_to_date", o.current_version), -- >>> EDIT Desuka <<<
                    "4000")
            end
        else
            msg.verbose("update-checker: local " .. o.current_version .. " newer than remote " .. latest)
            if manual then
                mp.commandv("script-message-to", "modernx", "modernx-toast",
                    "info", "update-checker",
                    t("local_newer", o.current_version, latest), -- >>> EDIT Desuka <<<
                    "4000")
            end
        end
    end)
end
mp.register_script_message("check-for-update", function() check_for_update(true) end)

if o.check_on_startup then
    mp.add_timeout(o.startup_delay, function() check_for_update(false) end)
end
