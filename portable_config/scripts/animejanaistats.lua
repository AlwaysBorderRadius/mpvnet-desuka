local open = io.open

local showingMessage = false

local function read_file(path)
    local file = open(path, "r") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

-- Function to be called when the custom action is triggered
-- >>> CUSTOM desuka: persistent toast with source-aware clear <<<
-- New toasts preempt (no queue). Clear only clears our own toast, so if an
-- important toast replaced us, the next toggle just resyncs instead of
-- killing someone else's message.
function show_animejanai_stats()
    if showingMessage then
        mp.commandv("script-message-to", "modernx", "modernx-toast-clear", "animejanai")
        showingMessage = false
    else
        local message = ""

        if mp.get_property("vf") == "" then
            message = "Upscaling is disabled"
        else
            local data_file_path = (mp.command_native({'expand-path', "~~/../animejanai/core/currentanimejanai.log"}))
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
-- <<< CUSTOM desuka >>>


-- Register the custom action to a key binding (e.g., "Ctrl+Shift+C")
-- >>> CUSTOM AlwaysBorderRadius <<< -- key owned by input.conf (Ctrl+j), keep unbound for upstream diff
mp.add_key_binding(nil, "show_animejanai_stats", show_animejanai_stats)
-- <<< CUSTOM AlwaysBorderRadius >>>
