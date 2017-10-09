# XXTouch UI (XUI) 界面库使用手册

标签（空格分隔）： XXTouch XXTouchApp XUI


----------


*此文档是为测试版编写的，不适用于线上正式版本。*

 - 适用于 **v1.2.0-1** 及以上平台版本
 - 支持 iPhone/iPad 横竖屏，支持 iOS 7 及以上系统版本
 - XUI 不与原有的对话框 (dialog) 和 WebView UI 冲突


----------


## 目录

[TOC]


----------


## 前言

XUI 用于在 XXTouch 上提供配置界面，采用 iOS 系统原生组件。本手册提供了 XUI 界面布局的规范。

XUI 是 XPP 脚本包的一部分，用来为脚本包创建配置，不能独立使用，**无法在脚本运行的时候启动 XUI 界面**。

如需使用 XUI，您需要创建指定格式的 xui 文件，在脚本包中激活。保存的配置项，可以通过 plist 库进行读取。


----------


## 示例

![SolveRR.xpp(2).zip-68.9kB][1]

脚本开发者可以下载示例包，在 XXTExplorer 中解压并运行。

![IMG_0716.JPG-152.2kB][2]


----------


## 创建

xui 是一种特定格式的 lua 文件，使用这种格式创建 XUI 界面，需要使 lua 执行后返回一个包含各组件及属性的表。


----------


### 根

XUI 配置的根（顶层）为字典。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|导航栏标题|可选|
|header|字符串|主标题|可选|
|subheader|字符串|副标题|可选|
|items|包含字典的数组|组件列表|\-|

**items** 是组件列表数组，所有的组件字典按顺序存放在该数组中，即可在界面上显示。关于组件的说明，后文将会详细介绍。

``` lua
return {
    subheader = "Elegant App UI provided by XXTouchApp.";
    header = "Example";
    title = "Demo";
    items = {};
};
```

![CFE17DA4-C299-4533-A0E9-E1E2F9734C8D.png-32.9kB][3]


----------


### 通用属性

各组件均可使用如下通用属性，为组件添加标题，图标，指定配置保存位置等。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|cell|字符串|组件类型|\-|
|label|字符串|显示标签|可选|
|defaults|字符串|配置标识符|\-|
|key|字符串|配置键名|defaults != nil|
|default|字符串|配置默认值|\-|
|icon|字符串|图标文件名|可选|
|enabled|布尔型|是否启用组件|\-|
|height|数值|组件的高度|\-|

**icon** 若设置为 res/16.png，建议同时准备 res/16@2x.png 和 res/16@3x.png，实际尺寸须分别为原来的 2 倍和 3 倍。

配置完成后，在 **defaults** 指定的保存位置，读取 plist 中键 **switch1** 的值，即为开关的状态。

``` lua
local plist = require 'plist'
local tab = plist.read('uicfg/com.yourcompany.yourscript.plist')
print(tabenabled)
```


----------


### Group 分组

此组件在界面上显示一个分组区域 Section，包含到下一个相同组件类型之间的所有组件。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|footerText|字符串|在当前组之后添加一行小字|可选|

*此组件不支持 **label/icon/height***

``` lua
{
    items = {
        {
            cell = "Group";
            label = "Switch";
        };
        {
            defaults = "com.yourcompany.yourscript";
            default = true;
            label = "Enabled";
            cell = "Switch";
            key = "enabled";
            icon = "res/16.png";
        };
        {
            cell = "Group";
            label = "Button";
        };
        {
            url = "https://www.xxtouch.com";
            cell = "Link";
            label = "Open XXTouch.com";
        };
        {
            cell = "Button";
            action = "OpenURL:";
            label = "Contact i.82@me.com";
            kwargs = {
                "mailto://i.82@me.com";
            };
        };
    };
};
```

![QQ20170914-191445.png-44.5kB][4]


----------


### Link 链接子界面

此组件在界面上显示一个子菜单项，用于链接子界面。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|url|字符串|子界面文件名|\-|

**url** 可以为普通文件名、XUI 文件名或网络地址。普通文件将使用默认打开方式打开，XUI 文件将作为子界面打开，网络地址将使用内置浏览器打开。

``` lua
{
    url = "sub/xui-sub.xui";
    cell = "Link";
    label = "Load another pane";
};
```

![QQ20170914-191746.png-51.9kB][5]


----------


### Switch 开关

此组件在界面上显示一个开关。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|negate|布尔型|反转开关显示情况|可选|

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = true;
    label = "Enabled";
    cell = "Switch";
    key = "enabled";
    icon = "res/16.png";
};
```

![CFC04C38-FFBE-46B9-BE86-AE8470342DAD.png-19.2kB][6]


----------


### Button 动作按钮

此组件在界面上显示一个按钮，用于执行某些动作。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|action|选择器|指定按钮的操作类型|\-|
|kwargs|包含字符串的数组|数组，传递给选择器的参数|\-|

| action | 描述 | 参数数量 | 参数类型 | 返回值类型 |
|--------|------|----------|----------|------------|
|LaunchScript:|运行脚本|1|String<br>脚本所在路径|Bool<br>脚本是否存在|
|OpenURL:|打开URL|1|String<br>欲打开的 URL|Bool<br>URL 是否合法|
|ScanQRCode:|扫描二维码|0|\-|String/Dictionary<br>扫描结果|

**ScanQRCode:** 动作会调起带扫码界面的相机，扫描二维码。
*暂时只支持这些 action*

``` lua
{
    cell = "Button";
    action = "OpenURL:";
    label = "Contact i.82@me.com";
    kwargs = {
        "mailto://i.82@me.com";
    };
};
```

![QQ20170914-191854.png-23kB][7]


----------


### TextField / SecureTextField 单行普通文本框 / 单行安全文本框

此组件在界面上显示一个文本框，用于字符串输入。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|keyboard|字符串|键盘类型|可选|
|autoCaps|字符串|自动大写模式|可选|
|placeholder|字符串|文本框占位符|可选|
|noAutoCorrect|布尔型|关闭自动更正|可选|
|isIP|布尔型|IP地址类型，使用 Numbers 键盘|可选|
|isURL|布尔型|URL类型，使用 URL 键盘|可选|
|isNumeric|布尔型|数值类型，使用 NumberPad 键盘|可选|
|isDecimalPad|布尔型|小数类型，使用 DecimalPad 键盘|可选|
|isEmail|布尔型|电子邮箱类型，使用 EmailAddress 键盘|可选|

**isIP/isURL/isNumeric/isDecimalPad/isEmail** 至多只能有一项为 YES。

**SecureTextField** 控件与 **TextField** 不同的是，会将输入的内容显示为小圆点。

*此组件不支持 **label/icon***

| keyboard | 描述 |
|--------|------|
|ascii|标准 ASCII 键盘|
|numbers|数字小键盘|
|phone|电话号码键盘|

| autoCaps | 描述 |
|--------|------|
|sentences|按句自动大写|
|words|按单词自动大写|
|all|全部大写|

``` lua
{
    noAutoCorrect = true;
    defaults = "com.yourcompany.yourscript";
    default = "";
    label = "Username";
    cell = "TextField";
    key = "username";
    keyboard = "default";
    placeholder = "Enter the username";
};
{
    noAutoCorrect = true;
    defaults = "com.yourcompany.yourscript";
    default = "";
    label = "Password";
    cell = "SecureTextField";
    key = "password";
    keyboard = "ascii";
    placeholder = "Enter the password";
};
```

![QQ20170914-192018.png-30kB][8]


----------


### Radio / Checkbox 单选框 / 复选框组

此组件在界面上显示若干单选框 / 复选框。

点选**单选框**会选中当前选择的单选框，取消同组其它单选框的选中状态。
点选**复选框**会切换其选中 / 未选状态。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|alignment|字符串|对齐方式|\-|
|options|包含字典的数组|选项列表数组|\-|
|minCount|整数|最少选择项目数|复选框有效|
|maxCount|整数|最多选择项目数|复选框有效|

| alignment | 描述 |
|--------|------|
|left|左对齐|
|center|居中|
|right|右对齐|
|natural|扩展空白部分使两边对齐|
|justified|扩展标签宽度使两边对齐|

**options** 包含若干可选项，选项为字典，有如下属性：

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|选项标题|\-|

*此组件不支持 **label/icon/height***

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = {
        "Red";
        "Green";
    };
    cell = "Checkbox";
    key = "checkbox";
    maxCount = 4;
    options = {
        {
            title = "Red";
        };
        {
            title = "Green";
        };
        {
            title = "Blue";
        };
        {
            title = "Yellow";
        };
        {
            title = "Purple";
        };
        {
            title = "Black";
        };
        {
            title = "White";
        };
    };
};
{
    defaults = "com.yourcompany.yourscript";
    default = "Fifth; please!";
    cell = "Radio";
    key = "radio";
    options = {
        {
            title = "First";
        };
        {
            title = "Second";
        };
        {
            title = "Third";
        };
        {
            title = "Fourth";
        };
        {
            title = "Fifth; please!";
        };
        {
            title = "Zero";
        };
    };
};
```

![QQ20170916-182221@2x.png-185.2kB][9]


----------


### Segment 适合少量选项的单项选择

此组件在界面上显示一个选项组。用于选择单个选项 (总选项数一般少于 6 个)。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|options|包含字典的数组|选项列表数组|\-|

**options** 包含若干可选项，选项为字典，有如下属性：

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|选项标题|\-|

*此组件不支持 **label/icon***

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = "Green";
    label = "List of Options";
    cell = "Segment";
    key = "list-segment";
    options = {
        {
            title = "Red";
        };
        {
            title = "Green";
        };
        {
            title = "Blue";
        };
    };
};
```

![QQ20170914-192102.png-14.5kB][10]


----------


### Option 单项选择列表

此组件在界面上显示一个子菜单项，用于链接包含一些选项的子菜单。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|options|包含字典的数组|选项列表数组|\-|
|staticTextMessage|字符串|显示在列表选项下方的小字|\-|

**options** 包含若干可选项，选项为字典，有如下属性：

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|选项标题|\-|
|shortTitle|字符串|显示在父级菜单右侧的标题|可选|
|icon|字符串|选项图标文件名|可选|

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = {
        "Green; it's green!"
    };
    label = "List of Options";
    cell = "Option";
    key = "list-1";
    options = {
        {
            title = "Red; it's red!";
            shortTitle = "Red";
        };
        {
            title = "Green; it's green!";
            shortTitle = "Green";
        };
        {
            title = "Blue; great color!";
            shortTitle = "Blue";
        };
    };
};
```

![QQ20170916-182546@2x.png-23.3kB][11]


----------


### MultipleOption 多项选择列表

此组件在界面上显示一个子菜单项，用于链接包含一些选项的子菜单。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|options|包含字典的数组|选项列表数组|\-|
|staticTextMessage|字符串|显示在列表选项下方的小字|\-|
|maxCount|整数|最多选择项目数|\-|

**options** 包含若干可选项，选项为字典，有如下属性：

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|选项标题|\-|
|icon|字符串|选项图标文件名|可选|

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = {
        "Red; it's red!"; "Green; it's green!"
    };
    label = "List of Multiple Options";
    cell = "MultipleOption";
    key = "list-2";
    maxCount = 2;
    options = {
        {
            title = "Red; it's red!";
        };
        {
            title = "Green; it's green!";
        };
        {
            title = "Blue; great color!";
        };
    };
};
```

![QQ20170916-182611@2x.png-25.2kB][12]


----------


### OrderedOption 多项有序选择列表

此组件在界面上显示一个子菜单项，用于链接包含一些选项的子菜单。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|options|包含字典的数组|选项列表数组|\-|
|staticTextMessage|字符串|显示在列表选项下方的小字|\-|
|minCount|整数|最少选择项目数|\-|
|maxCount|整数|最多选择项目数|\-|

**options** 包含若干可选项，选项为字典，有如下属性：

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|title|字符串|选项标题|\-|
|icon|字符串|选项图标文件名|可选|

``` lua
{
    defaults = "com.yourcompany.yourscript";
    default = {
        "Red";
    };
    label = "List of Ordered Options";
    cell = "OrderedOption";
    key = "list-3";
    maxCount = 2;
    minCount = 1;
    options = {
        {
            title = "Red";
        };
        {
            title = "Green";
        };
        {
            title = "Blue";
        };
    };
};
```

![QQ20170916-182729@2x.png-34kB][13]


----------


### Slider 数值拖拽滑块

此组件在界面上显示一个滑块，用于数值的选择和调整。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|min|数值|滑块最小值|\-|
|max|数值|滑块最大值|\-|
|showValue|布尔型|是否显示当前滑块的值|可选|

*此组件不支持 **label/icon***

``` lua
{
    showValue = true;
    defaults = "com.yourcompany.yourscript";
    min = 1;
    default = 5;
    max = 10;
    label = "Slider";
    cell = "Slider";
    key = "slider";
    isSegmented = true;
};
```

![QQ20170914-192324.png-9.1kB][14]


----------


### Stepper 数值调节按钮

此组件在界面上显示一个调节器，用于数值的选择和调整。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|min|数值|调节最小值|\-|
|max|数值|调节最大值|\-|
|step|数值|调节歩长|\-|
|isInteger|布尔型|值是否显示为整数|\-|
|autoRepeat|布尔型|长按是否连续调整|\-|

``` lua
{
    defaults = "com.yourcompany.yourscript";
    min = 1;
    default = 5;
    max = 10;
    autoRepeat = true;
    label = "Stepper";
    cell = "Stepper";
    key = "stepper";
    isInteger = true;
};
```

![QQ20170914-192349.png-10.8kB][15]


----------


### DateTime 时间日期选择器

此组件在界面上显示一个时间日期选择器，用于日期、时间的选择及时间间隔的调整。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|min|数值|时间间隔最小值|可选|
|max|数值|时间间隔最大值|可选|
|minuteInterval|整数|时间间隔歩长，单位分钟|可选|
|mode|字符串|选择器模式|可选|

*此组件不支持 **label/icon***

| mode | 描述 |
|--------|------|
|datetime|日期时间选择器|
|date|日期选择器|
|time|时间选择器|
|interval|时间间隔选择器|

``` lua
{
    cell = "DateTime";
    key = "datetime1";
    defaults = "com.yourcompany.yourscript";
};
```

![QQ20170917-000929@2x.png-77.9kB][16]


----------


### TitleValue 键值对显示; 代码片段选择器

此组件在界面上显示 key - value 对，类似 设置 -> 通用 -> 关于中系统参数键值对的显示。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|value|字符串|右侧显示值|\-|
|snippet|字符串|代码片段文件名|\-|

如果为此组件设置了 **defaults** 和 **key**，则此组件可用来显示配置项的实际值；同时设置 **snippet** 属性，则能够为此组件增加 XUI 内代码片段的功能，激活代码片段选择器组，并将返回结果存入该组件的配置项内。

``` lua
{
    default = true;
    cell = "Switch";
    key = "switch1";
    defaults = "com.yourcompany.yourscript";
    label = "Sosh!";
};
{
    cell = "TitleValue";
    label = "Version";
    value = "1.1.3";
};
{
    cell = "TitleValue";
    label = "Dynamic";
    key = "switch1";
    defaults = "com.yourcompany.yourscript";
};
{
    cell = "TitleValue";
    label = "Application";
    key = "applications";
    defaults = "com.yourcompany.yourscript";
    snippet = "snippets/app.snippet";
};
```

![QQ20170914-192446.png-36.5kB][17]


----------


### StaticText 静态文本框

此组件在界面上显示一段静态文本，即其 label 属性中的文本。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|alignment|字符串|对齐方式|\-|

| alignment | 描述 |
|--------|------|
|left|左对齐|
|center|居中|
|right|右对齐|
|natural|扩展空白部分使两边对齐|
|justified|扩展标签宽度使两边对齐|

*暂不支持更改文本字体、尺寸等属性*

*此组件不支持 **label/icon/height***

``` lua
{
    cell = "StaticText";
    label = "This specifier uses the label key as text content. Dynamic height of this cell is enabled.";
};
```

![QQ20170914-192523.png-30.6kB][18]


----------


### Textarea 多行文本域


此组件在界面上显示一个子菜单项，用于链接到一个多行文本输入界面。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|maxLength|整数|最大文本长度|\-|

*暂不支持更改文本字体、尺寸等属性*

``` lua
{
    default = "You can enter any text here...";
    cell = "Textarea";
    key = "textarea";
    defaults = "com.yourcompany.yourscript";
    label = "Textarea Cell";
};
```


----------


### Image 图片

此组件在界面上显示图片。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|path|字符串|本地图片名称|\-|

设定通用属性 **height** 可定义图片高度，宽度将保持比例自动适应。

``` lua
{
    cell = "Image";
    path = "res/bd_logo1_31bdc765.png";
    height = 128.0;
};
```

![QQ20170918-022558.png-31kB][19]


----------


### File 文件选择器

此组件在界面上显示文件选择区域，可显示文件类型图标、文件名称与文件修改时间，点击可选择新文件。

|   键   |   类型   |   描述   |   条件   |
|--------|----------|----------|----------|
|initialPath|字符串|文件选择初始顶层目录|可选|
|allowedExtensions|包含字符串的数组|允许的文件扩展名列表|\-|

**initialPath** 若不填，则为当前脚本包路径。**allowedExtensions** 中包含允许选择的文件名列表，不符合扩展名要求的项目将不会被显示。

``` lua
{
    cell = "File";
    key = "file1";
    defaults = "com.yourcompany.yourscript";
    allowedExtensions = { "lua"; "xxt"; "xpp" };
};
```

![QQ20170918-022520.png-31.5kB][20]

----------


  [1]: http://static.zybuluo.com/xxtouch/8dgttx0tufbj3d5q60xty941/SolveRR.xpp%282%29.zip
  [2]: http://static.zybuluo.com/xxtouch/yp88j1ws4na1r8enodb7ydhl/IMG_0716.JPG
  [3]: http://static.zybuluo.com/xxtouch/hxvpaqv424u4b4gjjg98aw2d/CFE17DA4-C299-4533-A0E9-E1E2F9734C8D.png
  [4]: http://static.zybuluo.com/xxtouch/8taro66htfohfw09hryyl0hv/QQ20170914-191445.png
  [5]: http://static.zybuluo.com/xxtouch/ac1u7v1ix272uvkgvg6j9qk7/QQ20170914-191746.png
  [6]: http://static.zybuluo.com/xxtouch/jm8gc462xjyi62gwiguzbzfa/CFC04C38-FFBE-46B9-BE86-AE8470342DAD.png
  [7]: http://static.zybuluo.com/xxtouch/rjklx5duv3eh0bkx24vxpcf9/QQ20170914-191854.png
  [8]: http://static.zybuluo.com/xxtouch/qoakjz7jg94iktgg2w0g1jdg/QQ20170914-192018.png
  [9]: http://static.zybuluo.com/xxtouch/tommwf1shji1gs6oc43k0sfo/QQ20170916-182221@2x.png
  [10]: http://static.zybuluo.com/xxtouch/cg54nkdvmezr1t8j4ef8nr8l/QQ20170914-192102.png
  [11]: http://static.zybuluo.com/xxtouch/x2uld8468nmcsvz2j3i08tn6/QQ20170916-182546@2x.png
  [12]: http://static.zybuluo.com/xxtouch/kgt4wil6flrisgpzvdza62gt/QQ20170916-182611@2x.png
  [13]: http://static.zybuluo.com/xxtouch/do6m93m2gjrcklyi12g4utke/QQ20170916-182729@2x.png
  [14]: http://static.zybuluo.com/xxtouch/z7wpczvqy0ilw9xbu9mpjh9l/QQ20170914-192324.png
  [15]: http://static.zybuluo.com/xxtouch/719ucx2zpm1jzxwxu7gexjeb/QQ20170914-192349.png
  [16]: http://static.zybuluo.com/xxtouch/p1oneomh57ftv97vu819xls8/QQ20170917-000929@2x.png
  [17]: http://static.zybuluo.com/xxtouch/k3mvmdkeweg91zejrz2g7usd/QQ20170914-192446.png
  [18]: http://static.zybuluo.com/xxtouch/0emxjk45iceyk1fufog7000g/QQ20170914-192523.png
  [19]: http://static.zybuluo.com/xxtouch/6jhlork14eat0w2xej0x6hj5/QQ20170918-022558.png
  [20]: http://static.zybuluo.com/xxtouch/keg9dr84ef52tc6cboq64nqi/QQ20170918-022520.png