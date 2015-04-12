function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local CC_INHERITED_FROM_NATIVE_CLASS = 1
local CC_INHERITED_FROM_LUA = 2
function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == CC_INHERITED_FROM_NATIVE_CLASS) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
        end

        cls.ctor = function() end
        cls.dtor = function() end
        cls.__cname = classname
        cls.__ctype = CC_INHERITED_FROM_NATIVE_CLASS

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = clone(super)
            cls.super = super
        end

        cls.ctor = function() end
        cls.dtor = function() end
        cls.__cname = classname
        cls.__ctype = CC_INHERITED_FROM_LUA
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function ripairs(t)
    local max = 1
    while t[max] ~= nil do
        max = max + 1
    end
    local function ripairs_it(t, i)
        i = i-1
        local v = t[i]
        if v ~= nil then
            return i,v
            else
            return nil
        end
    end
    return ripairs_it, t, max
end

function len(t)
    if type(t) == "table" then
        local c = 0
        for _,v in pairs(t) do
            c = c + 1
        end
        return c
    else
        return #t
    end
end

function const(value)
    -- set table member recursively
    table.foreach(value, function(i, v)
                  if type(v) == "table" then
                    const(v)
                  end
              end)

    -- make table readonly
    local t = {}
    local mt = {
        __index = value,
        __newindex = function (t,k,v)
            print("can't update " .. tostring(t) .. "[" .. tostring(k) .. "] = " .. tostring(v))
        end
    }
    return setmetatable(t, mt)
end

table = table or {}

-- join table
function table.join(t, sep)
    local s = ""
    for _,item in ipairs(t) do
        if string.len(s) > 0 then
            s = s .. sep
        end
        s = s .. tostring(item)
    end
    return s
end

string = string or {}

-- safe convert a string to number, never return nil
function string.tonumber(s)
    local n = tonumber(s)
    if n == nil then
        return 0
    else
        return n
    end
end

-- safe convert a string to integer, never return nil
function string.toint(s)
    return math.floor(string.tonumber(s))
end