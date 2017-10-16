--
--  XUIAdapter_xui.lua
--  XXTExplorer
--
--  Created by Soze on 14/09/2017.
--  Copyright © 2017 Soze. All rights reserved.
--

-- opt = {
--  event = 'load',
--  bundlePath = 'xxx',
--  rootPath = '/var/mobile/Media/1ferver',
--  XUIPath = '/var/mobile/interface.xui',
-- }

-- opt = {
--  event = 'save',
--  bundlePath = 'xxx',
--  rootPath = '/var/mobile/Media/1ferver',
--  XUIPath = '/var/mobile/interface.xui',
--  defaultsId = 'com.yourcompany.yourscript',
--  key = 'key',
--  value = 'value',
-- }

local opt = ...

local __G = _G
local _ENV = {
    math = {
        floor = math.floor;
        type = math.type;
    };
    string = {
        format = string.format;
        match = string.match;
        gsub = string.gsub;
        lower = string.lower;
    };
    plist = {
        read = plist.read;
        write = plist.write;
    };
    json = {
        decode = json.decode;
        encode = json.encode;
    };
    table = {
        insert = table.insert;
        remove = table.remove;
    };
    os = {
        execute = os.execute;
        time = os.time;
    };
    io = {
        popen = io.popen;
        open = io.open;
    };
    error = error;
    loadfile = loadfile;
    type = type;
    next = next;
    pairs = pairs;
    ipairs = ipairs;
    tostring = tostring;
    tonumber = tonumber;
}

local function _isEqual(a, b)
    if (a == b) then
        return true
    elseif type(a)=="table" and type(b)=="table" then
        if (#a ~= #b) then
            return false
        else
            local k, v
            for k, v in next, a, k do
                if (not _isEqual(b[k], v)) then
                    return false
                end
            end
            for k, v in next, b, k do
                if (not _isEqual(a[k], v)) then
                    return false
                end
            end
            return true
        end
    else
        return false
    end
end
isEqual = _isEqual

local function isValueInArray(array, value)
    for _,v in ipairs(array) do
        if isEqual(value, v) then
            return true
        end
    end
    return false
end

local function removeValueInArrayIf(array, condition)
    local needRemoveIndexes = {}
    for i,v in ipairs(array) do
        if condition(v) then
            table.insert(needRemoveIndexes, i)
        end
    end
    for i = #needRemoveIndexes, 1, -1 do
        table.remove(array, needRemoveIndexes[i])
    end
end

local XUITableBuilder, err = loadfile(opt.XUIPath, 'bt', __G)

if type(XUITableBuilder) == 'function' then
    opt.XUITable = XUITableBuilder()
else
    opt.XUITable = plist.read(opt.XUIPath)
    if type(opt.XUITable) ~= 'table' then
        local f0, ferr = io.open(opt.XUIPath, 'r+b')
        if not f0 then
            error(ferr)
        end
        local ctx = f0:read('*a')
        f0:close()
        opt.XUITable = json.decode(ctx)
        if type(opt.XUITable) ~= 'table' then
            error(err)
        end
    end
end

if type(opt.XUITable) ~= 'table' then
    error(string.format('%q', XUIPath))
end

local function getDefaultsPath(defaults)
    return string.format(opt.rootPath.."/uicfg/%s.plist", defaults)
end

local DefaultsCaches = {}

local function sh_escape(path)
    path = string.gsub(path, "([ \\()<>'\"`#&*;?~$])", "\\%1")
    return path
end

local function fixPermission(path)
    io.popen(opt.rootPath..'/bin/add1s chmod -R 644 '..sh_escape(path))
    io.popen(opt.rootPath..'/bin/add1s chown -R mobile:mobile '..sh_escape(path))
end

local function loadDefaultsAndCache(defaultsId)
    if not DefaultsCaches[defaultsId] then
        local defaultsPath = getDefaultsPath(defaultsId)
        DefaultsCaches[defaultsId] = plist.read(defaultsPath) or {}
    end
    return DefaultsCaches[defaultsId]
end

local function saveCachedDefaults()
    for defaultsId, defaultsCache in pairs(DefaultsCaches) do
        local defaultsPath = getDefaultsPath(defaultsId)
        fixPermission(defaultsPath)
        plist.write(defaultsPath, defaultsCache)
    end
end

local ValueCheckers = {}

function ValueCheckers.Switch(item, value, index)
    if type(item.default) ~= 'boolean' then
        item.default = false
    end
    if type(value) == 'boolean' then
        return value
    else
        return item.default
    end
end

function ValueCheckers.Textarea(item, value, index)
    if type(item.default) ~= 'string' then
        item.default = ''
    end
    if type(value) == 'string' then
        return value
    else
        return item.default
    end
end

function ValueCheckers.TitleValue(item, value, index)
    if item.default == nil then
        item.default = ''
    end
    if value ~= nil then
        return value
    else
        return item.default
    end
end

function ValueCheckers.EditableList(item, value, index)
    if type(item.default) ~= 'table' then
        item.default = {}
    end
    item.default.isArray = true
    if type(value) ~= 'table' then
        value = item.default
    end
    return value
end

function ValueCheckers.Option(item, value, index)
    if type(item.options) ~= 'table' then
        item.options = {isArray = true}
    end

    local values = {isArray = true}
    local options = {isArray = true}
    for _, option in ipairs(item.options) do
        if type(option) == 'table' then
            if type(option.title) == 'string' then
                if type(option.shortTitle) ~= 'string' then
                    option.shortTitle = option.title
                end
                if option.value == nil then
                    option.value = option.title
                end
                table.insert(values, option.value)
                table.insert(options, option)
            end
        elseif type(option) == 'string' then
            table.insert(options, {
                title = option,
                shortTitle = option,
                value = option,
            })
            table.insert(values, option)
        end
    end
    item.options = options

    if isValueInArray(values, value) then
        return value
    else
        if isValueInArray(values, item.default) then
            return item.default
        else
            return values[1]
        end
    end
end

function ValueCheckers.MultipleOption(item, value, index)
    if type(item.options) ~= 'table' then
        item.options = {isArray = true}
    end

    local values = {isArray = true}
    local options = {isArray = true}
    for _, option in ipairs(item.options) do
        if type(option) == 'table' then
            if type(option.title) == 'string' then
                if type(option.shortTitle) ~= 'string' then
                    option.shortTitle = option.title
                end
                if option.value == nil then
                    option.value = option.title
                end
                table.insert(values, option.value)
                table.insert(options, option)
            end
        elseif type(option) == 'string' then
            table.insert(options, {
                title = option,
                shortTitle = option,
                value = option,
            })
            table.insert(values, option)
        end
    end
    item.options = options

    if item.maxCount == nil then
        item.maxCount = #options
    end

    if math.type(item.maxCount) ~= 'integer' then
        error(string.format('%q: items[%d](%q).maxCount (integer expected got %s)', opt.XUIPath, index, item.key, math.type(item.maxCount) or type(item.maxCount)))
    end

    if item.maxCount < 1 then
        error(string.format('%q: items[%d](%q).maxCount (maxCount < 1)', opt.XUIPath, index, item.key))
    end

    if type(item.default) ~= 'table' then
        item.default = {}
    end

    if #(item.default) <= item.maxCount then
        removeValueInArrayIf(item.default, function(v)
            return not isValueInArray(values, v)
        end)
    else
        item.default = {}
    end

    item.default.isArray = true

    if type(value) ~= 'table' then
        value = item.default
    else
        removeValueInArrayIf(value, function(v)
            return not isValueInArray(values, v)
        end)
    end

    value.isArray = true

    return value
end

function ValueCheckers.OrderedOption(item, value, index)
    if type(item.options) ~= 'table' then
        item.options = {isArray = true}
    end

    local values = {isArray = true}
    local options = {isArray = true}
    for _, option in ipairs(item.options) do
        if type(option) == 'table' then
            if type(option.title) == 'string' then
                if type(option.shortTitle) ~= 'string' then
                    option.shortTitle = option.title
                end
                if option.value == nil then
                    option.value = option.title
                end
                table.insert(values, option.value)
                table.insert(options, option)
            end
        elseif type(option) == 'string' then
            table.insert(options, {
                title = option,
                shortTitle = option,
                value = option,
            })
            table.insert(values, option)
        end
    end
    item.options = options

    if item.maxCount == nil then
        item.maxCount = #options
    end

    if math.type(item.maxCount) ~= 'integer' then
        error(string.format('%q: items[%d](%q).maxCount (integer expected got %s)', opt.XUIPath, index, item.key, math.type(item.maxCount) or type(item.maxCount)))
    end

    if item.maxCount < 1 then
        error(string.format('%q: items[%d](%q).maxCount (maxCount < 1)', opt.XUIPath, index, item.key))
    end

    if item.minCount == nil then
        item.minCount = 0
    end

    if math.type(item.minCount) ~= 'integer' then
        error(string.format('%q: items[%d](%q).minCount (integer expected got %s)', opt.XUIPath, index, item.key, math.type(item.minCount) or type(item.minCount)))
    end

    if item.minCount >= item.maxCount then
        error(string.format('%q: items[%d](%q).minCount (maxCount <= minCount)', opt.XUIPath, index, item.key))
    end

    if type(item.default) ~= 'table' then
        item.default = {}
    end

    if #(item.default) <= item.maxCount then
        removeValueInArrayIf(item.default, function(v)
            return not isValueInArray(values, v)
        end)
    else
        item.default = {}
    end

    item.default.isArray = true

    if type(value) ~= 'table' then
        value = item.default
    else
        removeValueInArrayIf(value, function(v)
            return not isValueInArray(values, v)
        end)
    end

    value.isArray = true

    return value
end

ValueCheckers.Checkbox = ValueCheckers.OrderedOption
ValueCheckers.Radio = ValueCheckers.Option
ValueCheckers.Segment = ValueCheckers.Option

function ValueCheckers.Slider(item, value, index)
    if type(item.min) ~= 'number' then
        error(string.format('%q: items[%d](%q).min (number expected got %s)', opt.XUIPath, index, item.key, type(item.min)))
    end
    if type(item.max) ~= 'number' then
        error(string.format('%q: items[%d](%q).max (number expected got %s)', opt.XUIPath, index, item.key, type(item.max)))
    end
    if item.max <= item.min then
        error(string.format('%q: items[%d](%q).max (max <= min)', opt.XUIPath, index, item.key))
    end
    if item.default == nil then
        item.default = item.min
    end
    if type(item.default) ~= 'number' then
        error(string.format('%q: items[%d](%q).default (opt.number expected got %s)', opt.XUIPath, index, item.key, type(item.default)))
    end
    if item.default < item.min then
        error(string.format('%q: items[%d](%q).default (default < min)', opt.XUIPath, index, item.key))
    end
    if item.default > item.max then
        error(string.format('%q: items[%d](%q).default (default > max)', opt.XUIPath, index, item.key))
    end
    value = tonumber(value) or item.default
    if value < item.min or value > item.max then
        value = item.default
    end
    return value
end

function ValueCheckers.Stepper(item, value, index)
    if item.step == nil then
        item.step = 1
    end
    if type(item.step) ~= 'number' then
        error(string.format('%q: items[%d](%q).step (number expected got %s)', opt.XUIPath, index, item.key, type(item.step)))
    end
    if item.step <= 0 then
        error(string.format('%q: items[%d](%q).step (step <= 0)', opt.XUIPath, index, item.key))
    end
    if type(item.min) ~= 'number' then
        error(string.format('%q: items[%d](%q).min (number expected got %s)', opt.XUIPath, index, item.key, type(item.min)))
    end
    if type(item.max) ~= 'number' then
        error(string.format('%q: items[%d](%q).max (number expected got %s)', opt.XUIPath, index, item.key, type(item.max)))
    end
    if item.max - item.step < item.min then
        error(string.format('%q: items[%d](%q).max (max - step < min)', opt.XUIPath, index, item.key))
    end
    if item.default == nil then
        item.default = item.min
    end
    if type(item.default) ~= 'number' then
        error(string.format('%q: items[%d](%q).default (opt.number expected got %s)', opt.XUIPath, index, item.key, type(item.default)))
    end
    if item.default < item.min then
        error(string.format('%q: items[%d](%q).default (default < min)', opt.XUIPath, index, item.key))
    end
    if item.default > item.max then
        error(string.format('%q: items[%d](%q).default (default > max)', opt.XUIPath, index, item.key))
    end
    value = tonumber(value) or item.default
    if value < item.min or value > item.max then
        value = item.default
    end
    return value
end

function ValueCheckers.TextField(item, value, index)
    if item.default == nil then
        item.default = ''
    else
        item.default = tostring(item.default)
    end
    if not value then
        value = item.default
    end
    return value
end

ValueCheckers.SecureTextField = ValueCheckers.TextField

function ValueCheckers.DateTime(item, value, index)
    if item.minuteInterval ~= nil and type(item.minuteInterval) ~= 'integer' then
        error(string.format('%q: items[%d](%q).minuteInterval (opt.integer expected got %s)', opt.XUIPath, index, item.key, type(item.minuteInterval)))
    end
    if item.min ~= nil and type(item.min) ~= 'number' then
        error(string.format('%q: items[%d](%q).min (opt.number expected got %s)', opt.XUIPath, index, item.key, type(item.min)))
    end
    if item.max ~= nil and type(item.max) ~= 'number' then
        error(string.format('%q: items[%d](%q).max (opt.number expected got %s)', opt.XUIPath, index, item.key, type(item.max)))
    end
    if item.default == nil then
        item.default = os.time()
    end
    if item.default ~= nil and type(item.default) ~= 'number' then
        error(string.format('%q: items[%d](%q).default (opt.number expected got %s)', opt.XUIPath, index, item.key, type(item.default)))
    end
    if item.min ~= nil and item.default < item.min then
        error(string.format('%q: items[%d](%q).default (default < min)', opt.XUIPath, index, item.key))
    end
    if item.max ~= nil and item.default > item.max then
        error(string.format('%q: items[%d](%q).default (default > max)', opt.XUIPath, index, item.key))
    end
    value = tonumber(value) or item.default
    if (item.min ~= nil and value < item.min) or (item.max ~= nil and value > item.max) then
        value = item.default
    end
    return value
end

function ValueCheckers.File(item, value, index)
    if item.allowedExtensions and type(item.allowedExtensions) ~= 'table' then
        item.allowedExtensions = {isArray = true}
    end
    if item.initialPath and type(item.initialPath) ~= 'string' then
        item.initialPath = ''
    end
    value = value or item.default
    return value
end

function ValueCheckers.Button(item, value, index)
    if type(item.action) ~= 'string' then
        error(string.format('%q: items[%d](%q).action (string expected got %s)', opt.XUIPath, index, item.key, type(item.action)))
    end
    if type(item.args) ~= 'table' then
        item.args = {}
    end
    return value
end

local function checkCellValue(item, value, index)
    local checker = ValueCheckers[tostring(item.cell)]
    if type(checker) == 'function' then
        return checker(item, value, index)
    else
        return nil
    end
end

local cellNameMap = {
    button          = 'Button';
    file            = 'File';
    datetime        = 'DateTime';
    securetextfield = 'SecureTextField';
    textfield       = 'TextField';
    stepper         = 'Stepper';
    slider          = 'Slider';
    multipleoption  = 'MultipleOption';
    orderedoption   = 'OrderedOption';
    option          = 'Option';
    checkbox        = 'Checkbox';
    radio           = 'Radio';
    segment         = 'Segment';
    textarea        = 'Textarea';
    titlevalue      = 'TitleValue';
    switch          = 'Switch';
    group           = 'Group';
    link            = 'Link';
    statictext      = 'StaticText';
    image           = 'Image';
    animatedimage   = 'AnimatedImage';
    editablelist    = 'EditableList';
}

local events = {}

function _loadDefaults(opt)
    local XUITable = opt.XUITable
    if (type(XUITable.items) ~= 'table') or (#(XUITable.items) == 0) then
        return XUITable
    end
    local globalDefaults = XUITable.defaults
    for idx, item in ipairs(XUITable.items) do
        if type(item) ~= 'table' then
            error(string.format('%q: items (table expected got %s)', opt.XUIPath, type(item)))
        end
        local itemKey = item.key
        local itemCell = string.lower(tostring(item.cell))
        if cellNameMap[itemCell] ~= nil then
            itemCell = cellNameMap[itemCell]
            item.cell = itemCell
        end
        if type(itemKey) == 'string' and type(ValueCheckers[itemCell]) == 'function' then
            item.defaults = item.defaults or globalDefaults
            local itemDefaultsId = item.defaults
            if type(itemDefaultsId) == 'string' then
                local defaultsTable = loadDefaultsAndCache(itemDefaultsId)
                if type(defaultsTable) == 'table' then
                    if defaultsTable[itemKey] == nil then
                        defaultsTable[itemKey] = item.default
                    end
                    item.value = checkCellValue(item, defaultsTable[itemKey], idx)
                end
            end
        end
    end
    return XUITable
end

function events.load(opt)
    local XUITable = _loadDefaults(opt)
    saveCachedDefaults()
    return XUITable
end

function events.save(opt)
    _loadDefaults(opt)
    local defaultsTable = loadDefaultsAndCache(opt.defaultsId)
    defaultsTable[opt.key] = opt.value
    saveCachedDefaults()
end

function events.reset(opt)
    DefaultsCaches = {}
    saveCachedDefaults()
end

if type(events[opt.event]) == 'function' then
    return events[opt.event](opt)
else
    error(string.format('Bad event %q', opt.event))
end
