
local Session = class('Session')

local Login = require('app.models.Login')

function Session:ctor(  )
    cc.bind(self, 'event')

    self.login = Login()
end

return Session
