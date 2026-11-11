local open = io.open

local showingMessage = false
-- >>> CUSTOM Desuka: persistent toast with source-aware clear <<<
-- New toasts preempt (no queue). Clear only clears our own toast: if another
-- toast replaced us, the next toggle resyncs instead of killing it.
-- NOTE: AJN updater overwrites portable_config/scripts/ on update
-- (manifest.json overlay_paths). After any AJN update: git status, diff this
-- file, re-apply this CUSTOM block. Path tracks v3.10 layout (no core/).
function show_animejanai_stats()
    if showingMessage then
        mp.commandv("script-message-to", "modernx", "modernx-toast-clear", "animejanai")
        showingMessage = false
    else
        local message = ""

        if mp.get_property("vf") == "" then
            message = "Upscaling is disabled"
        else
            local data_file_path = (mp.command_native({'expand-path', "~~/../animejanai/currentanimejanai.log"}))
            message = read_file(data_file_path)

            if message == "" or message == nil then
                message = "Error during upscale; press ~ to view error in console"
            end
        end

        mp.commandv("script-message-to", "modernx", "modernx-toast",
            "persistent", "animejanai", message)
        showingMessage = true
    end
end
-- <<< CUSTOM Desuka >>>

function read_file(path)
    local file = open(path, "r") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end


-- >>> CUSTOM Desuka <<< -- key owned by input.conf (Ctrl+j), keep unbound for upstream diff
mp.add_key_binding(nil, "show_animejanai_stats", show_animejanai_stats)
-- <<< CUSTOM Desuka >>>