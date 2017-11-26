function read_xui_conf(bid)
	local plist = require("plist")
	return plist.read("/var/mobile/Media/1ferver/uicfg/"..bid..".plist") or {}
end

local tab = read_xui_conf('com.yourcompany.yourscript')

sys.alert(json.encode(tab))