local msg = require("mp.msg")
local opts = require("mp.options")
local utils = require("mp.utils")

function detect_platform() --function to detect platform
	local o = {}
	if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
		return "windows"
	elseif mp.get_property_native('options/input-app-events', o) ~= o then
		return "darwin"
	end
	return "linux"
end

local options = {
	key = "c",
	active = true,
	client_id = "737663962677510245",
	binary_path = "",
	socket_path = (detect_platform() ~= "windows" and "/tmp/" or "") .. "mpvsocket",
	autohide_threshold = 0,
}
opts.read_options(options, "discord")

-- >>> CUSTOM Desuka: portable path (~~/) support for binary/socket <<<
local function expand_portable(path)
    if type(path) ~= "string" or path == "" then return path end
    if path:sub(1, 2) ~= "~~" then return path end
    local ok, expanded = pcall(mp.command_native, { "expand-path", path })
    if ok and type(expanded) == "string" and expanded ~= "" then
        return expanded
    end
    return path
end
options.binary_path = expand_portable(options.binary_path)
options.socket_path = expand_portable(options.socket_path)
-- <<< CUSTOM Desuka >>>

if options.binary_path == "" then
	msg.fatal("Missing binary path in config file.")
	os.exit(1)
end

function file_exists(path) -- fix(#23): use this instead of utils.file_info
	local f = io.open(path, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

if not file_exists(options.binary_path) then
	msg.fatal("The specified binary path does not exist.")
	os.exit(1)
end

local version = "1.6.1"
msg.info(("mpv-discord v%s by tnychn"):format(version))

local socket_path = options.socket_path
socket_path = socket_path:gsub("{pid}", utils.getpid())
if socket_path == "" then
	msg.fatal "Missing socket path in config file."
	os.exit(1)
end
msg.info(("(mpv-ipc): %s"):format(socket_path))
mp.set_property("input-ipc-server", socket_path)

local cmd = nil

-- >>> CUSTOM Desuka: route through modernx toast (single slot, preemptive) <<<
local function notify(kind, text)
    mp.commandv("script-message-to", "modernx", "modernx-toast", kind, "discord", text)
end
-- <<< CUSTOM Desuka >>>

local function start()
	if cmd == nil then
		cmd = mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			args = {
				options.binary_path,
				socket_path,
				options.client_id,
			},
		}, function() end)
		msg.info("launched subprocess")
		notify("info", "Discord Rich Presence: Started")
	end
end

function stop()
	mp.abort_async_command(cmd)
	cmd = nil
	msg.info("aborted subprocess")
	notify("info", "Discord Rich Presence: Stopped")
end

if options.active then
	mp.register_event("file-loaded", start)
end

-- >>> CUSTOM Desuka <<< -- key owned by input.conf (d), keep unbound
mp.add_key_binding(nil, "toggle-discord", function()
-- <<< CUSTOM Desuka >>>
	if cmd ~= nil then
		stop()
	else
		start()
	end
end)

mp.register_event("shutdown", function()
	if cmd ~= nil then
		stop()
	end
	if detect_platform() ~= "windows" then
		os.remove(socket_path)
    end
end)

if options.autohide_threshold > 0 then
	local timer = nil
	local t = options.autohide_threshold
	mp.observe_property("pause", "bool", function(_, value)
		if value == true then
			timer = mp.add_timeout(t, function()
				if cmd ~= nil then
					stop()
				end
			end)
		else
			if timer ~= nil then
				timer:kill()
				timer = nil
			end
			if options.active and cmd == nil then
				start()
			end
		end
	end)
end
