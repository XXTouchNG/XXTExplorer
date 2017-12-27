
-- xpp.resource_path 用于获取脚本包的某个文件的路径（文件不存在返回 nil ）
-- xpp.ui_setup 用于初始化脚本包内某个 xui 的配置（生成默认配置）
-- xpp.info 获取当前脚本包的元信息
-- xpp.show_ui 从脚本唤起一个当前脚本包中的 xui，如果第二个参数是 true 那么唤起需要按 home 退出
-- xuic 是加密的 xui 格式，在安装了 1.2-1 或以上版本的 XXTouch 的设备的远程管理页面的加密子页面中可以拖入扩展名为 xui 的文件加密

xpp.show_ui('another_ui.xui', true)

repeat
	sys.toast('正在调起一个 UI ...')
	sys.msleep(100)
until app.front_bid() == 'com.xxtouch.XXTExplorer' -- 等待 XXTouch 的 App 切换至前台

repeat
	sys.msleep(100)
	sys.toast('按 Home 键配置完成以继续脚本')
until app.front_bid() ~= 'com.xxtouch.XXTExplorer' -- 等待 XXTouch 的 App 离开前台

sys.alert('配置完成')

sys.alert(table.deep_dump(xpp.info()))
sys.alert(xpp.resource_path('res/16.png'))

xpp.ui_setup('interface.xui')
xpp.ui_setup('sub/xui-sub.xui')

local defaults = 'com.yourcompany.A-Script-Bundle'
local uicfg = plist.read("/var/mobile/Media/1ferver/uicfg/"..defaults..".plist") or {}

sys.alert(uicfg['list-1'])