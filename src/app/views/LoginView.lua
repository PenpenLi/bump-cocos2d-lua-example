local LoginView = {}
local shaders = require 'shaders'

local bump = require 'bump.bump'

function LoginView:ctor()
end

function LoginView:layout()
    local root = self.ui:getChildByName('MainPanel')
    root:setContentSize(cc.size(display.width,display.height))
    root:setPosition(display.cx,display.cy)

    root:getnode('version'):pos(0, display.height)


    local destroyNode = display.newNode()
    cc.bind(destroyNode, 'event')
    destroyNode:onNodeEvent('destroy', function (  )
        print('node destroy event.')
        destroyNode:dispose()
    end)

    local app = require('app.App'):instance()
    local _,handle = app.conn:on('login', function ( ... )
        print('call destroyNode')
        destroyNode:show()
    end, destroyNode)


    -- local webp = display.newSprite('test.webp'):move(display.cx, display.cy):addTo(self.ui)
    -- shaders.roundNode(webp)
    -- local webpLabel = cc.Label:createWithSystemFont('webp=>', 'sans', 28)
    -- webpLabel:anchor(1,0):addTo(webp)

    self:setupPhysicWorld()
end

function LoginView:setupPhysicWorld()
    local world = bump.newWorld(32)

    local drawNode = cc.DrawNode:create()
    self:addChild(drawNode)

    -- Define some colors
    local GREEN       = cc.c4f(0,1,0,1)
    local GREEN_FILL  = cc.c4f(0,1,0,0.3)
    local YELLOW      = cc.c4f(1,1,0,1)
    local YELLOW_FILL = cc.c4f(1,1,0,0.3)
    local RED         = cc.c4f(1,0,0,1)
    local RED_FILL    = cc.c4f(1,0,0,0.3)

    local winSize = cc.Director:getInstance():getWinSize()

    local player = world:add({
        x = 0, y = 0,
        vx = 0, vy = 0,

        draw = function(self, drawNode)
            local x,y,w,h = world:getRect(self)
            drawNode:drawSolidRect(cc.p(x,y),cc.p(x+w,y+h),RED_FILL)
            drawNode:drawRect(cc.p(x,y),cc.p(x+w,y+h),RED)
        end,

        filter = function(self)
            return 'slide'
        end,
        update = function(self,dt)
            local ax,ay,cols,len = world:move(self,self.x + self.vx * dt,self.y + self.vy * dt,self.filter)
            self.x, self.y = ax, ay
            for i=1,len do
                cols[1].other.collide = true
            end
        end,
        center = function(self)
            local x,y,w,h = world:getRect(self)
            return cc.p(x +w/2,y+h/2)
        end
    }, display.cx,winSize.height/2,50,20)

    -- Create the "touch layer"
    local layer = cc.Layer:create()
    local px,py=0,0
    layer:registerScriptTouchHandler(function(event,x,y)
        if event == 'moved' then
            player.x = x
            player.y = y
        end
        --[[
        if event == 'began' or event == 'moved' then
            -- Compute the player's new direction
            local px,py = world:getRect(player)
            local p = cc.pMul(cc.pNormalize(cc.pSub(cc.p(px,py),cc.p(x,y))),100)
            -- update the player velocity
            player.vx = -p.x
            player.vy = -p.y
        end
        --]]
        return true
    end)
    layer:setTouchEnabled(true)
    self:addChild(layer,1)

    math.randomseed(os.time())
    for i=1,20 do
        local ground = world:add({
            collide = false,
            draw = function(self,drawNode)
                local x,y,w,h = world:getRect(self)
                drawNode:drawSolidRect(cc.p(x,y),cc.p(x+w,y+h),self.collide and YELLOW_FILL or GREEN_FILL)
                drawNode:drawRect(cc.p(x,y),cc.p(x+w,y+h),self.collide and YELLOW or GREEN)
            end,
            update = function(self,dt)
                -- Nothing to do
            end
        },math.random(winSize.width),math.random(winSize.height),math.random(100),math.random(100))
    end

    local node = cc.Node:create()

    -- Schedule the "update" function
    node:scheduleUpdateWithPriorityLua(function(dt)
        -- Reset and clear the DrawNode object
        drawNode:clear()
        -- Iterate over all the bump items to update and draw them
        local items, len = world:getItems()
        for i=1,len do
            items[i]:update(dt)
            items[i]:draw(drawNode)
        end
    end,1)
    self:addChild(node)
end

return LoginView
