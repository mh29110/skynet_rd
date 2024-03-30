local skynet = require "skynet"
local s = require "service"

s.resp.newservice = function(source, name, ...)
	local srv = skynet.newservice(name, ...)
    print("[nodemgr resp newservice]")
	return srv
end

s.start(...)