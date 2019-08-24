
local scheduler = require ("cocos.framework.scheduler")
local tcp = require 'cocos.framework.net.SocketTCP'

local headerSize = 2

local NetMgr = class("NetMgr", tcp)

function NetMgr:ctor()
    NetMgr.super.ctor(self)

    self.recvBuffer = ''
    self.process_id = nil
    self.send_task_list = {}

    self:on(tcp.EVENT_CLOSE, handler(self, self.stop))
    self:on(tcp.EVENT_CLOSED, handler(self, self.stop))
    self:on(tcp.EVENT_CONNECTED, function (  )
        print('connected')
        self.process_id = scheduler.scheduleGlobal(function ( dt )
            self:processSocketIO()
        end, 0.1)
    end)
    self:on(tcp.EVENT_DATA, function ( data )
        self.recvBuffer = self.recvBuffer .. data.data
    end)
end

function NetMgr:getInstance()
    if not self.instance_ then
        self.instance_ = NetMgr:new()
    end
    return self.instance_
end

function NetMgr:stop()
    print('> socket close')
    if self.process_id then
        scheduler.unscheduleGlobal(self.process_id)
    end
end

function NetMgr:processSocketIO()
    if not self.isConnected then
        return
    end
    self:processInput()
    self:processOutput()
end

function NetMgr:processInput()
    while true do
        local len = string.len(self.recvBuffer)

        if len == 0 then
            return
        end

        if len < headerSize then
            print('header not full')
            return
        end

        --计算包的长度
        local first, sencond = string.byte(self.recvBuffer, 1, 2)
        local bodySize = first * 256 + sencond --通过位计算长度
        print("收到数据长度 = ", bodySize)

        print(string.len(self.recvBuffer), headerSize + bodySize)

        if string.len(self.recvBuffer) < headerSize + bodySize then
            print('body not full')
            return
        end

        --解析包
        local data = string.sub(self.recvBuffer, 1, headerSize + bodySize)
        local ret, len, pb_head, pb_body, char_data = string.unpack(data, ">HPPb")
        local msg_head = protobuf.decode("PbHead.MsgHead", pb_head)
        local msg_body = protobuf.decode(msg_head.msgname, pb_body)
        print("收到服务器数据", msg_head.msgname)

        dump(msg_head)
        dump(msg_body)

        self.recvBuffer = string.sub(self.recvBuffer, headerSize + bodySize + 1)
        self:dispatchEvent({name = msg_head.msgname, data = msg_body})
    end
end

function NetMgr:processOutput()
    if self.send_task_list  and #self.send_task_list > 0 then
        local data = self.send_task_list[#self.send_task_list]
        if data then
            local _len ,_error = self:send(data)
            -- print("socket send"..#data, "_len:", _len, "error:", _error)
            --发送长度不为空，并且发送长度==数据长度
            if _len ~= nil and _len == #data then
                table.remove(self.send_task_list, #self.send_task_list)
            else

            end
        end
    end
end

function NetMgr:sendPB(msg_name, msg_body)
    --拼装头
    local msg_head={msgtype = 1, msgname = msg_name, msgret = 0}
    local pb_head = protobuf.encode("PbHead.MsgHead", msg_head)
    local pb_body = protobuf.encode(msg_name, msg_body)
    --计算长度
    local pb_head_len = #pb_head
    local pb_body_len = #pb_body
    local pb_len = 2 + pb_head_len + 2 + pb_body_len + 1

    local data = string.pack(">HPPb",pb_len, pb_head, pb_body, string.byte('t'))
    print("GameNet send msg:"..msg_name..":"..string.char(string.byte('t')))

    table.insert(self.send_task_list, 1, data)
end

return NetMgr
