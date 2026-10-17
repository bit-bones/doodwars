local debug_helpers = {}

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local raw_print = print

function print(...)
    local count = select("#", ...)
    local values = {}

    for i = 1, count do
        values[i] = tostring(select(i, ...))
    end

    raw_print(string.format("[%s] %s", os.date("%H:%M:%S"), table.concat(values, "\t")))
end

local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if rawget(_G, "lldebugger") then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end

return debug_helpers
