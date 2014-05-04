SndFloUiConnection : Object {
    var receiveOscFunc;
    var uiAddr;
    var <>on_message;

    *new { arg listenAddr;
        ^super.new.init(listenAddr)
    }
    init { arg listenAddr;
        uiAddr = NetAddr(listenAddr.ip, listenAddr.port+1);
        receiveOscFunc = OSCFunc.new({ |msg, time, addr, recvPort|
            "received: ".post; msg.postln;
            this.receiveOsc(msg,time,addr,recvPort);
        }, "/fbp/runtime/message");
        on_message = { |a| }; // override
    }

    sendMessage { arg protocol, command, payload;
        var msg = Dictionary[
            "protocol" -> protocol,
            "command" -> command,
            "payload" -> payload
        ];
        var str = JSON.stringify(msg);
        "sending response: ".post; str.postln;
        uiAddr.sendMsg("/fbp/ui/message", str);
    }

    receiveOsc { |msg, time, addr, recvPort|
        var m = msg[1].asString.parseYAML;
        this.handleMessage(m["protocol"], m["command"], m["payload"]);
    }

    handleMessage { arg protocol, cmd, payload;
        "handleMessage :\n".postf(protocol, cmd);
        on_message.value(protocol, cmd, payload);
    }
}


SndFloRuntime : Object {
    var connection;
    var library;
    var <network;

    *new { arg server, listenAddr;
        ^super.new.init(server,listenAddr)
    }
    init { arg server, listenAddr;
        connection = SndFloUiConnection.new(listenAddr);
        connection.on_message = { |pr,cmd,pay|
            this.handleMessage(pr,cmd,pay);
        };
        library = SndFloLibrary.new(server);
    }

    handleMessage { arg protocol, cmd, payload;

        case
        { (protocol == "runtime" && cmd == "getruntime") }
        {
            var info = Dictionary[
                "type" -> "sndflo",
                "version" -> "0.4", // protocol version
                "capabilities" -> ["protocol:component"]
            ];
            connection.sendMessage("runtime", "runtime", info);
        }
        { (protocol == "component" && cmd == "list") }
        {
            library.synthdefs.keysValuesDo({ |key,synthdef|
                var inPorts = List.new;
                var outPorts = List.new;
                var info;
                synthdef.allControlNames.do({ |control|
                    var type = "bus"; // TODO: separate out non-bus params
                    var p = Dictionary[
                        "id" -> control.name,
                        "type" -> type,
                        "description" -> "",
                        "addressable" -> false, // TODO: support multi-channel
                        "required" -> false // TODO: should be true for input busses
                    ];
                    // TODO: support multiple out-ports
                    // FIXME: use something better than heuristics to determine out ports
                    if (control.name.asString == "out", {
                        outPorts.add(p);
                    }, {
                        inPorts.add(p);
                    });

                });

                info = Dictionary[
                    "name" -> key,
                    "description" -> synthdef.metadata.description.asString,
                    "icon" -> "music",
                    "subgraph" -> false,
                    "inPorts" -> inPorts,
                    "outPorts" -> outPorts
                ];

                connection.sendMessage("component", "component", info);
            });
        }
        { (protocol == "graph" && cmd == "clear") }
        {
            network = SndFloNetwork.new();
            network.graph.library = library;
        }
        { (protocol == "graph" && cmd == "addnode") }
        {
            network.graph.addNode(payload["id"], payload["component"]);
        }
        { (protocol == "graph" && cmd == "removenode") }
        {
            network.graph.removeNode(payload["id"]);
        }
        { (protocol == "graph" && cmd == "addinitial") }
        {
            network.graph.addIIP(payload["tgt"]["node"], payload["tgt"]["port"],
                payload["src"]["data"]);
        }
        { (protocol == "graph" && cmd == "removeinitial") }
        {
            network.graph.removeIIP(payload["tgt"]["node"], payload["tgt"]["port"]);
        }
        { (protocol == "graph" && cmd == "addedge") }
        {
            network.graph.addEdge(payload["src"]["node"], payload["src"]["port"],
                payload["tgt"]["node"], payload["tgt"]["port"]);
        }
        { (protocol == "graph" && cmd == "removeedge") }
        {
            network.graph.removeEdge(payload["src"]["node"], payload["src"]["port"],
                payload["tgt"]["node"], payload["tgt"]["port"]);
        }
        { (protocol == "network" && cmd == "start") }
        {
            // TODO: include timestamp
            network.start(true);
            connection.sendMessage("network", "started", Dictionary.new);
        }
        { (protocol == "network" && cmd == "stop") }
        {
            // TODO: include timestamp
            network.start(false);
            connection.sendMessage("network", "stopped", Dictionary.new);
        }
        { true /*default*/ }
        {
            "Unhandled message from UI: procotol=%, cmd=%\n".postf(protocol, cmd);
        };

    }
}