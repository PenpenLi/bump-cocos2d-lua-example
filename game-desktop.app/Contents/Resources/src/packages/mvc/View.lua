
local View = class("View", cc.Node)

local function mixin(self, script)
    for k, v in pairs(script) do
        self[k] = v
    end
end

local function loadUI( csb )
    print('Loading "'..csb..'"...')
    if not cc.FileUtils:getInstance():isFileExist(csb) then
        print('Not exists. Skippd.')
        return cc.Node:create()
    end

    local node = cc.CSLoader:createNode(csb)
    if not node then
        print(string.format('Failed to load View node from "%s" ', csb))
        return cc.Node:create()
    end

    return node
end

View.loadUI = loadUI

function View:ctor(name, ...)
    cc.bind(self, 'event')

    self:enableNodeEvents()
    self.name = name
    self.ui = loadUI('views/'..name..'.csb')
    self:addChild(self.ui)

    -- load lua script and event view callbacks...

    if RELOAD_VIEW then package.loaded['app.views.'..name] = nil end
    local ok, script = pcall(require, 'app.views.'..name)
    if ok then
        mixin(self, script)
    else
        print('not found the view script file',name)
    end

    if self.ctor then
      self:ctor(...)
    end
end

return View
