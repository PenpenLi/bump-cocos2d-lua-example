
local Application = cc.load("mvc").Application
local App = class("App", Application)

local Connection = require('net.Connection')
local Session = require('app.Session')
local LocalSettings = require('app.models.LocalSettings')

local app = nil
function App:ctor(  )
    app = self
    self.conn = Connection()
    self.localSettings = LocalSettings()
end

function App.instance()
    app = app or App.new()
    return app
end

function App:onCreate()
    math.randomseed(os.time())
end

function App:createSession()
    self.session = Session()
end

return App
