local proto = {}

function proto.login(usr,pwd)
    return { LoginMsg = {
        Cmd = 'login',
        Req = {
            Account = usr,
            Password = pwd,
        }
    }}
end

return proto
