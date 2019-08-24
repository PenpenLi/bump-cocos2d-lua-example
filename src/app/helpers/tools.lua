--local proto = require('app.net.proto')

local tools = {}
local display = require('cocos.framework.display')

function tools.showRemind(text)
  local layer = cc.LayerColor:create(cc.c4b(0,0,0,0))
  layer:setIgnoreAnchorPointForPosition(false)
  layer:setAnchorPoint(cc.p(0.5, 0.5))
  local label = cc.Label:createWithTTF(text,'views/font/fangzheng.ttf',35, cc.size(620,0),cc.TEXT_ALIGNMENT_CENTER)
  label:setOpacity(0)
  local size = label:getContentSize()
  layer:setContentSize(cc.size(size.width + 10, size.height + 10))
  layer:setPosition(cc.p(display.cx, display.cy + 50))
  label:setPosition(cc.p((size.width + 10) / 2, (size.height + 10) / 2))
  layer:addChild(label)
  layer:runAction(cc.Sequence:create({
    cc.CallFunc:create(function()
      layer:runAction(cc.FadeTo:create(0.4, 190))
      label:runAction(cc.FadeIn:create(0.4))
    end),
    cc.DelayTime:create(0.4),
    cc.DelayTime:create(1.5),
    cc.CallFunc:create(function()
      layer:runAction(cc.MoveTo:create(0.4, cc.p(display.cx, display.height + 20)))
    end),
    cc.FadeOut:create(0.2),
    cc.RemoveSelf:create()
  }))


  require('app.App'):instance().layers.top:addChild(layer)
  return label
end

return tools
