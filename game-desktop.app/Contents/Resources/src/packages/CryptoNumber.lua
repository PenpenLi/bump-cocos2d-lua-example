
-- https://blog.justbilt.com/2015/04/05/phone-game-AND-watchdog/

local base64decode = require('base64').from_base64
local base64encode = require('base64').to_base64

local CryptoNumber = class("CryptoNumber")

function CryptoNumber:ctor(value)
    self:setValue(value)
end

function CryptoNumber:setValue(value)
     self._data = value
     self._encryptData = self:_encode(value)
end

function CryptoNumber:getValue()
    if not self:check() then
        print("**WARNING** SB modify memory value!") -- handle the hook
        self:setValue(self:_decode())
    end
    return self._data
end

function CryptoNumber:check()
    return self._data == self:_decode()
end

--- private
function CryptoNumber:_decode()
    return tonumber(base64decode(self._encryptData))
end

function CryptoNumber:_encode(value)
    return base64encode(value)
end

return CryptoNumber
