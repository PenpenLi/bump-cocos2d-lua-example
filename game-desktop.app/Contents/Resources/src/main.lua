
collectgarbage( "setpause", 130) -- 100
collectgarbage( "setstepmul", 5000)

package.path = '?.lua;src/?.lua;src/packages/?.lua'
local fs = cc.FileUtils:getInstance()
fs:setPopupNotify(false)

-- local STP = require "StackTracePlus"
-- local _traceback = debug.traceback
-- debug.traceback = STP.stacktrace

local winsize = cc.Director:getInstance():getWinSize()
local target = cc.Application:getInstance():getTargetPlatform()

function ismobile(  )
    return (target == 4) or (target == 5)
end
function isdesktop(  )
    return (target == 2) or (target == 3)
end

__G__TRACKBACK__ = function ( msg )

    local message = msg
    local msg, origin_error = debug.traceback(msg, 3)
    print(msg)

    -- report lua exception
    if ismobile() then -- ios
        -- buglyReportLuaException(tostring(message), _traceback())
    else -- desktop
        require('ccdebug')()
    end

    return msg
end

local function main()
    require "config"
    require "cocos.init"

    require 'pack'
    require 'pbc.pbc'
    --
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

    -- require("app.MyApp"):create():run()

    local app = require('app.App'):instance()
    app:run('LoginController')

    -- local xxtea = require 'xxtea'
    -- local s = xxtea.encrypt('abc', 'xx')
    -- print(xxtea.decrypt(s, 'xx') == 'abc')

    -- local md5 = require 'md5'
    -- print(md5.sum('helloworld'))

    -- -- pbc test
    -- require 'test.pbctest'
    -- require 'test.bittest'

    -- --
    -- require 'test.cryptoNumbTest'
    require 'test.t_sproto'
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    -- print(msg)
end
