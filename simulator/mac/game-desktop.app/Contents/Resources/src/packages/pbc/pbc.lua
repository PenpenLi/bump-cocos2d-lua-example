require("pbc.protobuf")

function read_file_c( filename )
    return cc.FileUtils:getInstance():read(filename)
end

protobuf.register_pb = function(filename)
    print("parse proto file:", filename)
    local buffer = read_file_c(filename)
    protobuf.register(buffer)
end

local proto_conf = {
    "proto/pbhead.pb",
    "proto/pblogin.pb",
}

protobuf.load_proto = function()
    for _,v in pairs(proto_conf) do
        protobuf.register_pb(v)
    end
end

protobuf.load_proto()

