-- Minimal CallbackHandler-1.0 compatible implementation
local CallbackHandler = LibStub:NewLibrary("CallbackHandler-1.0", 1)
if not CallbackHandler then
    return
end

local function CreateDispatcher()
    local registry = {}

    local dispatcher = {}

    function dispatcher:RegisterCallback(handler, event, method)
        if type(handler) ~= "table" then
            error("RegisterCallback(handler, event, method): handler must be a table", 2)
        end
        if type(event) ~= "string" then
            error("RegisterCallback(handler, event, method): event must be a string", 2)
        end

        if method == nil then
            method = event
        end

        local methodType = type(method)
        if methodType ~= "string" and methodType ~= "function" then
            error("RegisterCallback(handler, event, method): method must be a function or method name", 2)
        end

        registry[event] = registry[event] or {}
        registry[event][handler] = method
    end

    function dispatcher:UnregisterCallback(handler, event)
        local callbacks = registry[event]
        if callbacks then
            callbacks[handler] = nil
            if not next(callbacks) then
                registry[event] = nil
            end
        end
    end

    function dispatcher:UnregisterAllCallbacks(handler)
        for event, callbacks in pairs(registry) do
            callbacks[handler] = nil
            if not next(callbacks) then
                registry[event] = nil
            end
        end
    end

    function dispatcher:Fire(event, ...)
        local callbacks = registry[event]
        if not callbacks then
            return
        end

        for handler, method in pairs(callbacks) do
            if type(method) == "string" then
                local fn = handler[method]
                if type(fn) == "function" then
                    fn(handler, event, ...)
                end
            else
                method(handler, event, ...)
            end
        end
    end

    return dispatcher
end

function CallbackHandler:New(target)
    if type(target) ~= "table" then
        error("CallbackHandler-1.0:New(target) target must be a table", 2)
    end

    local dispatcher = CreateDispatcher()

    target.RegisterCallback = function(handler, event, method)
        dispatcher:RegisterCallback(handler, event, method)
    end

    target.UnregisterCallback = function(handler, event)
        dispatcher:UnregisterCallback(handler, event)
    end

    target.UnregisterAllCallbacks = function(handler)
        dispatcher:UnregisterAllCallbacks(handler)
    end

    return dispatcher
end
