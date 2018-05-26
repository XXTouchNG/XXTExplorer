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

