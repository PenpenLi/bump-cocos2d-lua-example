
local Controller = require('mvc.Controller')
local LoginController = class("LoginController", Controller)

local cjson = require 'cjson'
local conf = require 'config'


function LoginController:ctor()
    LoginController.super.ctor(self)
    self.app = require('app.App'):instance()
end

function LoginController:viewDidLoad()
    self.view:layout()

    self.app.conn:close()
    self.app:createSession()
    self.app.conn:connect(conf.ws)

    local login = self.app.session.login

    login:on('loginSuccess', function (  )
        self.app:switch('LobbyController')

        local tools = require('app.helpers.tools')
        tools.showRemind('登录成功')
    end, self)
end

function LoginController:finalize()
    print('LoginController:finalize')
end

function LoginController:clickLogin( ... )
    print('clickLogin')
    -- local app = require('app.App'):instance()
    -- app:switch('LobbyController')

    local user = self.app.localSettings:get('usr', 'jimi')
    local pwd = self.app.localSettings:get('usr', '123456')
    self.app.session.login:login(user,pwd)
end

function LoginController:clickTouristLogin( )
    print('clickTouristLogin')
end

-- event binding end ~~

return LoginController
