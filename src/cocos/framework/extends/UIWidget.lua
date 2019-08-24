--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Widget = ccui.Widget

function Widget:onTouch(callback)
    self:addTouchEventListener(function(sender, state)
        local event = {x = 0, y = 0}
        if state == 0 then
            event.name = "began"
            local pos = sender:getTouchBeganPosition()
            event.x, event.y = pos.x, pos.y
        elseif state == 1 then
            event.name = "moved"
            local pos = sender:getTouchMovePosition()
            event.x, event.y = pos.x, pos.y
        elseif state == 2 then
            event.name = "ended"
            local pos = sender:getTouchEndPosition()
            event.x, event.y = pos.x, pos.y
        else
            event.name = "cancelled"
            local pos = sender:getTouchEndPosition()
            event.x, event.y = pos.x, pos.y
        end
        event.target = sender
        callback(event)
    end)
    return self
end

function Widget:onClick(callback)
    if callback then
        self:addClickEventListener(callback)
    end
    return self
end

--[[
把自身的大小设置为所有子节点包围盒的大小
]]
function Widget:fitContentSize(  )
    local box = self:getBoundingBox()
    self:setContentSize(box.width, box.height)
    return self
end

--[[
模拟按钮效果

1. 当一个按钮由两个图片组成时有用
2. 制作一个动画按钮时有用
]]
function Widget:addButtonAnimation(  )
    self:onTouch(function ( event )
        local p = self:convertToNodeSpace(cc.p(event.x, event.y))
        local s = self:getContentSize()
        if p.x > 0 and p.x < s.width and p.y > 0 and p.y < s.height then
            self:setScale(1.1)
        else
            self:setScale(1.0)
        end

        if event.name == 'ended' then
            self:setScale(1.0)
        end
    end)

    return self
end
