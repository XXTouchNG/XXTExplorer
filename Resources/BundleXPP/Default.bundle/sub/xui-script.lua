function read_xui_conf(defaults)
	local plist = require("plist")
	return plist.read("/var/mobile/Media/1ferver/uicfg/"..defaults..".plist") or {}
end

local tab = read_xui_conf('com.yourcompany.A-Script-Bundle')

sys.alert(json.encode(tab))