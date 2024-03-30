local skynet = require "skynet"
local socket = require "skynet.socket"
local s = require "service"
local runconfig = require "runconfig"

conns = {}  -- [fd] = conn
gplayers = {} --[playerid] = gateplayer


function conn()
    local m = {
        fd = nil,
        playerid = nil,
    }
    return m 
end

function gateplayer()
    local m = {
        playerid = nil,
        agent = nil,
        conn = nil,
    }
    return m 
end

local str_pack = function(cmd, msg)
    return table.concat( msg, ",").."\r\n"
end

local str_unpack = function(msgstr)
    local msg = {}

    while true do
        local arg, rest = string.match( msgstr, "(.-),(.*)")
        if arg then
            msgstr = rest
            table.insert(msg, arg)
        else
            table.insert(msg, msgstr)
            break
        end
    end
    return msg[1], msg
end


local process_msg = function(fd, msgstr)
    local cmd , msg = str_unpack(msgstr)
    local conn = conns[fd]
    local playerid = conn.playerid

    if not playerid  then 
        local node = skynet.getenv("node")
        local nodecfg = runconfig[node]
        local loginid = math.random(1,#nodecfg.login)
        local login = "login".. loginid
        skynet.send( login , "lua" , "client" , fd , cmd , msg)
        print("[gateway process_msg]".. cmd  )
    else
        local gplayer = gplayers[playerid]
        local agent = gplayer.agent
        skynet.send(agent , "lua" , "client" , cmd , msg)
    end

end

local process_buff = function(fd, readbuff)
    while true do
        local msgstr, rest = string.match( readbuff, "(.-)\r\n(.*)")
        if msgstr then
            readbuff = rest
            process_msg(fd, msgstr)
        else
            return readbuff
        end
    end
end


local recv_loop = function(fd)
    socket.start(fd)
    skynet.error("[skynet  recv_loop] -- socket connected " ..fd)
    local readbuff = ""
    while true do
        local recvstr = socket.read(fd)
        if recvstr then
            readbuff = readbuff..recvstr
            readbuff = process_buff(fd, readbuff)
        else
            skynet.error("socket close " ..fd)
			disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

s.resp.send_by_fd = function(source, fd, msg)
    if not conns[fd] then
        return
    end

    local buff = str_pack(msg[1], msg)
    skynet.error("[gateway s.resp.send_by_fd]send  "..fd.." ["..msg[1].."] {"..table.concat( msg, ",").."}")
	socket.write(fd, buff)
end

s.resp.send = function(source, playerid, msg)
	local gplayer = gplayers[playerid]
    if gplayer == nil then
		return
    end
    local c = gplayer.conn
    if c == nil then
		return
    end
    
    s.resp.send_by_fd(nil, c.fd, msg)
end

s.resp.sure_agent = function(source , fd , playerid, agent)
    local conn = conns[fd]
    if not conn then
        skynet.call ("agentmgr","lua", "reqkick" , playerid , "logout before login successful")
        return false
    end

    conn.playerid = playerid

    local gplayer = gateplayer()
    gplayer.playerid = playerid
    gplayer.agent = agent
    gplayer.conn = conn
    gplayers[playerid] = gplayer
    return true
end



local connect = function(fd , addr)
    print("connect from " .. addr .. " " .. fd)
    local c = conn()
    conns[fd] = c
    c.fd = fd
    skynet.fork(recv_loop, fd)
end



function s.init ()
    local node  = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[s.id].port
    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("[gateway init --]" .. s.name .."Listen socket :", "0.0.0.0", port)
    socket.start(listenfd , connect)
end
s.start(...)

