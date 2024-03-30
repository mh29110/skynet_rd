local skynet = require "skynet"
local skynet_manager = require "skynet.manager"
local runconfig = require "runconfig"
local cluster = require "skynet.cluster"


skynet.start(function()
	skynet.error("start main")

	local mynode = skynet.getenv("node")
	local nodecfg = runconfig[mynode]
	--节点管理
	local nodemgr = skynet.newservice("nodemgr","nodemgr", 0)
	skynet.name("nodemgr", nodemgr)
	--集群
	cluster.reload(runconfig.cluster)
	cluster.open(mynode)
	--gate
	for i, v in pairs(nodecfg.gateway or {}) do
		local srv = skynet.newservice("gateway","gatewayname", i)
		skynet.name("gateway"..i, srv)
	end
	--login
	for i, v in pairs(nodecfg.login or {})  do
	local srv = skynet.newservice("login","loginname", i)
		skynet.name("login"..i, srv)
	end

	--agentmgr
	local anode = runconfig.agentmgr.node
	if mynode == anode then
		local srv = skynet.newservice("agentmgr", "agentmgr", 0)
		skynet.name("agentmgr", srv)
	else
		local proxy = cluster.proxy(anode, "agentmgr")
		skynet.name("agentmgr", proxy)
	end

	
	--退出自身
    skynet.exit()

end)
