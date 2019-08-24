local Controller = class("Controller")
local View = import('.View')

local callbackTypeToRegisterMethod = {
    ["Click"] = 'addClickEventListener',
    ["Touch"] = 'addTouchEventListener',
    ["Event"] = 'addCCSEventListener',
}

local function bindSignal(target, node)
    if not node.getCallbackName then return end -- Only Widget has this method

    local f, t = node:getCallbackName(), node:getCallbackType()
    local m = callbackTypeToRegisterMethod[t]
    if not m or not f or #f == 0 then return false end
    -- call the addXXXListener() function...
    node[m](node, function(sender, ...)
        if target[f] then
        target[f](target, sender, ...)
    else
        print('> No callback for:'..f)
        -- target:emit(f, sender, ...)
    end
  end)
end

local function bindSignalForTree(target, node)
    bindSignal(target, node)
    for _, v in ipairs(node:getChildren()) do
        bindSignalForTree(target, v)
    end
end


function Controller.load(name, ...)
    assert(type(name) == 'string', 'Controller.loadController is a static method')

    if RELOAD_CTRL then package.loaded['app.controllers.'..name] = nil end

    local Klass = require('app.controllers.'..name)
    assert(type(Klass) ~= 'boolean', '"app/controllers/'..name..'" must return a class')
    local c = Klass(...)

    cc.bind(c, 'event')
    c:initialize()

    c.view = assert(c:loadView(), name)
    c.view:retain()
    if c.viewDidLoad then
        c:viewDidLoad()
    end
    return c
end

-- ctor -> init -> loadView ->

function Controller:loadView()
    local viewName = self.__cname:gsub('Controller', 'View')
    print('Controller:loadView', viewName)
    local view = View:create(viewName, self)
    bindSignalForTree(self, view.ui)
    return view
end

function Controller:initialize(  )
    -- This function is intend to be overwrite by subclass
    -- DO NOT ADD CODE HERE
end

function Controller:finalize() -- called before controller removed from stage
    -- This function is intend to be overwrite by subclass
    -- DO NOT ADD CODE HERE
end

function Controller:viewDidLoad()
    -- This function is intend to be overwrite by subclass
    -- DO NOT ADD CODE HERE
end

function Controller:add(controller)
    assert(controller, 'contoller should not be nil')
    assert(iskindof(controller, 'Controller'), 'arg #2 requires a contoller') -- luacheck: ignore iskindof
    self.children = self.children or {}
    self.children[controller] = controller
    controller._parent = self
end

function Controller:clearView()
    if not self.view then
        return
    end

    if self.view:getParent() then
        self.view:removeFromParent()
    end
    self.view:release()
    self.view = nil
end

function Controller:delete()
    self:dispose()
    self:finalize()

    if self.children then
        for k, _ in pairs(self.children) do
            k:delete()
        end
        self.children = nil
    end

    self:clearView()

    if self._parent then
        self._parent.children[self] = nil
        self._parent = nil
    end
end

return Controller
