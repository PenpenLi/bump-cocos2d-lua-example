
local Connection = class('Connection')
local WebSockets = require("WebSockets")
local cjson = require 'cjson'

function Connection:ctor(  )
    cc.bind(self, 'event')
end

function Connection:connect( wsurl )
    local ws = WebSockets.new(wsurl)
    ws:on(WebSockets.MESSAGE_EVENT, function ( event )
        if (event.messageType == 0) then
            local str = ''
            for _,v in ipairs(event.message) do
                str = str .. string.char(v)
            end
            -- print(str) -- server data
            local resp = cjson.decode(str)
            self:emit({name = resp.cmd, data = resp})
        end
    end)
    ws:on(WebSockets.OPEN_EVENT, function ( ... )
        self:emit({name='open'})
    end)
    ws:on(WebSockets.CLOSE_EVENT, function ( ... )
        self:emit({name='close'})
    end)

    self.ws = ws
end

function Connection:send( tbl )
    if not self.ws then return end

    local data = cjson.encode(tbl)
    self.ws:send(data)
end

function Connection:close(  )
    if not self.ws then return end

    self.ws:close()
end

return Connection
