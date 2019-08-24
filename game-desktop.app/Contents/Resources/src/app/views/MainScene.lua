
local MainScene = class("MainScene", cc.load("mvc").ViewBase)



local function t_lsocket (  )
    local ls = require 'lsocket'
    dump(ls, 'ls')

    -- http client
    local url = 'http://www.baidu.com'
    -- url = 'http://httpstat.us/'

    if not string.find(url, "^http://") then
        error("only http urls supported.")
    end

    local host, port, path = string.match(url, "^http://([^:/]+):?(%d*)(/?.*)$")
    if not host then
        error("invalid url.")
    end
    if #port == 0 then port = 80 end
    if #path == 0 then path = "/" end

    local sock, err = ls.connect(host, port)
    if not sock then
        error(err)
    end

    -- wait for connect() to succeed or fail
    ls.select(nil, {sock})
    local ok, err = sock:status()
    if not ok then
        error(err)
    end

    local rq = "GET " .. path .. " HTTP/1.1\r\n"
    rq = rq .. "Host: " .. host .. ":" .. port .. "\r\n"
    rq = rq .. "Connection: close\r\n"
    rq = rq .. "\r\n"

    -- normally you would not need to be so fussy about such a small data
    -- package, it should be sent in one go anyways. This here is just to
    -- illustrate how data should be sent to a non-blocking socket.
    local sent = 0
    repeat
        ls.select(nil, {sock})
        sent = sent + sock:send(string.sub(rq, sent, -1))
    until sent == #rq

    -- now we read the reply, which can be larger than the max amount of
    -- bytes that will be sent in one tcp packet. So looping really makes
    -- sense here :) We requested the server to close the connection after
    -- the data was sent, so we can just wait for recv() to return nil, and
    -- then consider all data to be received.
    local reply = ""
    repeat
        ls.select({sock})
        local str, err = sock:recv()
        if str then
            reply = reply .. str
        elseif err then
            error(err)
        end
    until not str

    print(reply)
end

local function t_lpack(  )
    require ('pack')
    local num = 0x11
    local _ss = string.pack("b", num)
    print("字节数:",#_ss)
    local neS,valueS = string.unpack(_ss, "b")
    print("解包>>","?:",neS,"原数据",valueS)
    local _tmp = string.pack(">P", "世界那么大，我想去看看!!good!")
    print("字节数:",#_tmp)
    local nesT,valueT = string.unpack(_tmp,">P")
    print("解包>>","?:",nesT,"原数据",valueT)

    print(hex(valueT))
end

local function t_cjson(  )
    local cjson = require ('cjson')
    local data = {hello = 'world'}
    dump(data)
    dump(cjson.decode(cjson.encode({hello='world'})))
end

function MainScene:onCreate()
    -- add background image
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)

    -- add HelloWorld label
    cc.Label:createWithSystemFont("Hello World", "Arial", 40)
        :move(display.cx, display.cy + 200)
        :addTo(self)

    t_lpack()
    t_cjson()

    local lfs = require "lfs"
    print (lfs._VERSION)

    -- t_lsocket()

end

return MainScene
