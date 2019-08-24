local Login = class('Login')
local proto = require 'proto.proto'
function Login:ctor(  )
    cc.bind(self, 'event')

    self.app = require("app.App"):instance()
    self.app.conn:on('login', function ( resp )
        if resp.data.code == 0 then
            self:emit('loginSuccess')
        end
    end, self)
end

function Login:login( usr,pwd )
    self.app.localSettings:set('usr', usr)
    self.app.localSettings:set('pwd', pwd)

    self.app.conn:send (proto.login(usr,pwd))
end

return Login
