return {
    -- cluster ip setting ,this cluster has two node , the nodes communicate by ip address
    cluster = {
        node1 = "127.0.0.1:7771",
        node2 = "127.0.0.1:7772",
    },
    
    -- there is only one  global agentmgr node locates at node 1 . 
    agentmgr = { node = "node1"},  

    scene = {
        node1 = {1001, 1002},
    },

    node1 = {
        gateway = {
            [1] = {port=8004},
            [2] = {port=8002},
        },
        login  = {
            [1] = {},
            [2] = {},
        },
    },
    node2 = {
        gateway = {
            [1] = {port=8011},
            [2] = {port=8012},
        },
        login  = {
            [1] = {},
            [2] = {},
        },
    },


}