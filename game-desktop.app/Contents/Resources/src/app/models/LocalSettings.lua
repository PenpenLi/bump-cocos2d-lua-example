
local LocalSettings = class('LocalSettings')
local cjson = require('cjson')

local function savename()
  return cc.FileUtils:getInstance():getWritablePath() .. '.LocalSettings'
end

local function merge(dst, src)
  if dst == nil or src == nil then return end

  for k,v in pairs(src) do
    if type(dst[k]) == 'table' and type(v) == 'table' then
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end
end

function LocalSettings:ctor()
  cc.bind(self, 'event')

  local fu = cc.FileUtils:getInstance()
  local s = fu:getStringFromFile(savename())
  self.values = {}
  if #s > 2 then
    local loaded = cjson.decode(s)
    merge(self.values, loaded)
  end
end


function LocalSettings:get(key)
  return self.values[key]
end

function LocalSettings:set(key, value,dontSave)
  self.values[key] = value

  if not dontSave then
    self:save()
  end
end

function LocalSettings:save()
  local f = io.open(savename(), 'wb')
  f:write(cjson.encode(self.values))
  f:close()
end

function LocalSettings:setEffectFlag(flag)
	self.effectOn = flag
	self.emitter:emit('effectSettingChg')
end

function LocalSettings:setMusicFlag(flag)
	self.musicOn = flag

	self.emitter:emit('musicSettingChg')
end

return LocalSettings
