local __xui_conf = function(defaults)
	return "/var/mobile/Media/1ferver/uicfg/"..defaults..".plist"
end

local __xui_read = function(defaults)
	local plist = require("plist")
	return plist.read(__xui_conf(defaults)) or {}
end

local __xui_write = function(defaults, dict)
    local plist = require("plist")
    plist.write(__xui_conf(defaults), dict)
end;

_G['xui'] = {
	reload = xpp.ui_reload;
	dismiss = xpp.ui_dismiss;
	setup = xpp.ui_setup;
	show = xpp.ui_show;
	read = __xui_read;
	write = __xui_write;
    get = function(defaults, key)
    	return __xui_read(defaults)[key]
    end;
    set = function(defaults, key, value)
	    local dict = __xui_read(defaults)
	    dict[key] = value
	    __xui_write(defaults, dict)
    end;
}


local defaultsKey = "com.yourcompany.A-Script-Bundle"

-- 获取 Button 组件 LaunchScript: 额外参数
local operation
local args = utils.launch_args()
if args ~= nil then
    operation = args.envp['operation']
end
if operation == nil then
	operation = 'demo'
end



if operation == 'demo' then
	
    local tab = xui.read(defaultsKey)
    sys.alert(json.encode(tab))
    
elseif operation == 'ntime' then
	
	local ntstr
	local nt = sys.net_time(5)
	
	if nt == 0 then
		sys.alert("获取网络时间失败")
		return
	else
		ntstr = os.date("%Y-%m-%d %H:%M:%S", nt)
	end
    
    xui.set(defaultsKey, "ntime", ntstr)
    xui.reload({defaults = defaultsKey, {key = "ntime", value = ntstr}})
    
elseif operation == 'add-switch' then
	
	local num = xui.get(defaultsKey, "ui-group-num") or 0
	xui.set(defaultsKey, "ui-group-num", num + 1)
	xui.reload()

elseif operation == 'rm-switch' then
	
	local num = xui.get(defaultsKey, "ui-group-num") or 0
	if num <= 0 then
		sys.alert("已经不能减少了")
		return
	end
	xui.set(defaultsKey, "ui-group-num", num - 1)
	xui.reload()
	
end


