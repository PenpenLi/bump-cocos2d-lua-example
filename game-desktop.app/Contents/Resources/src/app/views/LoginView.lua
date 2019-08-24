local LoginView = {}
local shaders = require 'shaders'

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
end

return LoginView
