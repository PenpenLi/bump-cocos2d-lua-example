
local winsize = cc.Director:getInstance():getWinSize()
local target = cc.Application:getInstance():getTargetPlatform()
local fs = cc.FileUtils:getInstance()
local director = cc.Director:getInstance()
local scheduler = director:getScheduler()


local win,mac = 0,2
local KEY_ESC = 6
local isdesktop = (target <= 2)
local handler = nil

local editor = '"/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"'
if target == win then
    -- editor = ''
end

local function showdebugui( )
    local index = 2 -- 2
    local info = debug.getinfo(index)
    local lines = {}
    while info do
        if info.what == 'Lua' then
            table.insert(lines, info)
        end
        index = index + 1
        info = debug.getinfo(index)
    end

    handler = scheduler:scheduleScriptFunc(function ( ... )
        scheduler:unscheduleScriptEntry(handler)
        handler = nil

        local scene = director:getRunningScene()
        if not scene then
            scene = cc.Scene:create()
            scene:runWithScene(scene)
        end

        local node = scene:getChildByTag(999)
        if node == nil then
            node = cc.CSLoader:createNode('res/views/debugView.csb')
            node:setPosition(winsize.width*0.5, winsize.height*0.5)
            local list = node:getChildByName('panel')
            list:onClick(function (  )
                node:hide()
            end)
            list:setItemModel(list:getItem(0))

            local listener = cc.EventListenerKeyboard:create()
            listener:registerScriptHandler(function(keyCode)
                if isdesktop and (keyCode == KEY_ESC) then
                    node:setVisible(not node:isVisible())
                end
            end, cc.Handler.EVENT_KEYBOARD_RELEASED)
            local dispatcher = cc.Director:getInstance():getEventDispatcher()
            dispatcher:addEventListenerWithFixedPriority(listener, -1)
        end
        node:show()
        local list = node:getChildByName('panel')
        list:removeAllItems()
        for i,v in ipairs(lines) do
            list:pushBackDefaultItem()
            local item = list:getItem(i-1)
            item:setString(string.format('%s:+%d', v.source:sub(v.source:len()-60), v.currentline))
            item:onClick(function (  )
                local cmd = string.format('%s %s:%d', editor, fs:fullPathForFilename(v.source), v.currentline)
                os.execute(cmd)
            end)
        end
        scene:addChild(node, 999, 999)

    end, 0, false)

end

return showdebugui
