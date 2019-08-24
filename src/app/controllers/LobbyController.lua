
local Controller = require('mvc.Controller')
local LobbyController = class("LobbyController", Controller)
local tools = require('app.helpers.tools')

function LobbyController:ctor()
    self.app = require('app.App'):instance()
    self.app.conn:dumpAllEventListeners()
end

function LobbyController:initialize(  )
    -- bing event here
end

function LobbyController:viewDidLoad()
    self.view:layout()
end

function LobbyController:clickLogout(  )
    self:pop('XXXController')
end

function LobbyController:pop(ctrlName, ...)
    local app = require("app.App"):instance()

    local ctrl = Controller.load(ctrlName, ...)
    ctrl:on("exit", function ()
        tools.showRemind(ctrlName .. ' exit')
        ctrl:delete()
      end)
    self:add(ctrl)

    local root = app.layers.ui
    root:addChild(ctrl.view)

    return ctrl
end

return LobbyController
