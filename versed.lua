local gears = require("gears")
local wibox = require("wibox")

local versed = { mt={} }

local function new(args)
    local instance = {}
    instance.widgets   = args.widgets
    instance.init      = args.init
    instance.timeout   = args.timeout

    instance.container = wibox.container.constraint()
    local unpack = table.unpack or unpack
    instance.container.widget = wibox.widget(
    {
        layout = wibox.layout.fixed.horizontal,
        unpack(instance.widgets)
    })

    local __need    = true
    local __visible = instance.container.visible
    local __called  = false

    instance.update = function()
        if (__need) then
            args.update(instance.widgets, instance)
        end
    end

    instance.for_each = function(f)
        for _, v in pairs(instance.widgets) do
            f(v)
        end
    end
    instance.hide           = function()  instance.container.visible = false end
    instance.show           = function()  instance.container.visible = true  end
    instance.toggle_visible = function()  instance.container.visible = not instance.container.visible end
    instance.set_visible    = function(v) instance.container.visible = v  end

    instance.toggle         = function() instance.need = not __need end

    if (args.buttons) then
        for _, v in pairs(instance.widgets) do
            v:buttons(args.buttons)
        end
    end

    if (instance.timeout and instance.timeout > 0) then
        instance.timer = gears.timer({timeout = instance.timeout})
        instance.timer:connect_signal("timeout", instance.update)
    end

    local initial_update_called = false
    setmetatable(instance,
    {
        __call = function(...)
            if (not __called) then
                if instance.init then
                    instance.init(instance.widgets, instance)
                end
                if (not initial_update_called) then
                    instance.update()
                end
                if (instance.timer) then
                    instance.timer:start()
                end
            end
            __called = true
            return instance.container
        end,

        __index = function(t, k)
            if (k == 'need') then
                return __need
            elseif (k == 'versed') then
                return true
            else
                return rawget(t, k)
            end
        end,

        __newindex = function(t, k, v)
            if (k == 'need') then
                __need = v
                if (__need) then
                    t.set_visible(__visible)
                    --t.container.opacity = 1.0
                else
                    __visible = t.container.visible
                    t.set_visible(false)
                    --t.container.opacity = 0.5
                end
                t.update()
                initial_update_called = true
            else
                rawset(t, k, v)
            end
        end,
    })

    return instance
end

function versed.mt:__call(...)
    return new(...)
end

return setmetatable(versed, versed.mt)
