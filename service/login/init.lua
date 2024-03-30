local skynet = require "skynet"
local s = require "service"

s.client = {}
s.resp.client = function(source, fd, cmd, msg)

    skynet.error("[login init.lua  ]s.resp.client cmd::::::::", cmd,msg)
    if s.client[cmd] then
        local ret_msg = s.client[cmd]( fd, msg, source)
        skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
    else
        skynet.error("s.resp.client fail", cmd)
    end
end

s.client.login = function(fd, msg, source)
	local playerid = tonumber(msg[2]) -- must be able to convert to a number . 
	if playerid == nil then
		skynet.error("[login init.lua ]  playerid cannt convert to a number")
	end
	local pw = tonumber(msg[3])
	local gate = source
	node = skynet.getenv("node")
    --校验用户名密码
	if pw ~= 123 then
        print("[login client login] -- passwd error")
		return {"login", 1, "passwd error"}
	end
	--发给agentmgr
	local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
	if not isok then
        print("[login client login] -- agent error")
		return {"login", 1, "请求mgr失败"}
	end
	--回应gate
	local isok = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
	if not isok then
        print("[login client login] -- gatway agent register error")
		return {"login", 1, "gateway agent register failed"}
	end
    skynet.error("[login s.client.login]  succ "..playerid)
    return {"login", 0, "login successful"}

end

s.start(...)