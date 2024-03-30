local skynet = require "skynet"
local s = require "service"

s.client = {}
s.gate = nil

s.resp.client = function(source , cmd , msg)
    s.gate = source
    if s.client[cmd] then
        local ret_msg = s.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source , "lua", "send" , s.id , ret_msg)
        end
    else
        skynet.error ("s.resp.client fail", cmd)
    end
end

s.init = function ()
    skynet.error(" [agent init.lua] s.init")
    skynet.sleep(2)
    s.data = {
        coin = 100,
        hp = 200,
    }
end

s.resp.kick = function(source)
    skynet.error(" [agent init.lua] s.resp.kick")
	-- s.leave_scene() #todo
	skynet.sleep(2)
end

s.resp.exit = function(source)
    skynet.error(" [agent init.lua] s.resp.exit")
	skynet.exit()
end

s.client.work = function(msg)
    s.data.coin = s.data.coin + 1
    return {"work", s.data.coin}
end

s.start(...)