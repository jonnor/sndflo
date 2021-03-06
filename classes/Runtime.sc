//     sndflo - Flowhub.io sound processing runtime based on SuperCollider
//     (c) 2014 Jon Nordby
//     sndflo may be freely distributed under the MIT license

SndFloUiConnection : Object {
    var receiveOscFunc;
    var uiAddr;
    var <>on_message;

    *new { arg listenAddr;
        ^super.new.init(listenAddr)
    }
    init { arg listenAddr;
        uiAddr = NetAddr(listenAddr.ip, listenAddr.port+2);
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
        var str = SndFloJSON.stringify(msg);
        "sending response: ".post; str.postln;
        uiAddr.sendMsg("/fbp/ui/message", str);
    }

    receiveOsc { |msg, time, addr, recvPort|
        var m = msg[1].asString.parseYAML;
        this.handleMessage(m["protocol"], m["command"], m["payload"]);
    }

    handleMessage { arg protocol, cmd, payload;
        "handleMessage: % %\n".postf(protocol, cmd);
        on_message.value(protocol, cmd, payload);
    }
}


SndFloRuntime : Object {
    var connection;
    var <library;
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
        library.on_component_changed = { |name|
            this.sendComponent(name);
        };
    }

    loadDefaultGraphFile { arg path;
        var g = path.parseYAMLFile;
        network = SndFloNetwork.new(this.library);
        network.graph.on_ports_changed = {
            this.sendPorts();
        };
        network.loadGraph(g);
        network.start(true);
    }

    sendPorts {
        var inports = List.new;
        var outports = List.new;
        var payload = Dictionary[
            "graph" -> "default/main", // FIXME: unhardcode
            "inPorts" -> inports,
            "outPorts" -> outports,
        ];
        network.graph.inports.keysValuesDo({ |key,value|
            var p = Dictionary[
                "id" -> key,
                "type" -> "all", // TODO: implement
                "description" -> "", // TODO: implement
                "addressable" -> false,
                "required" -> false,
            ];
            inports.add(p);
        });
        network.graph.outports.keysValuesDo({ |key,value|
            outports.add(Dictionary[
                "id" -> key,
                "type" -> "all", // TODO: implement
                "description" -> "", // TODO: implement
                "addressable" -> false,
                "required" -> false,
            ]);
        });

        connection.sendMessage("runtime", "ports", payload);
    }

    sendComponent { arg name;
        var synthdef = library.synthdefs[name];
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
            "name" -> name,
            "description" -> synthdef.metadata.description.asString,
            "icon" -> "music",
            "subgraph" -> false,
            "inPorts" -> inPorts,
            "outPorts" -> outPorts
        ];

        connection.sendMessage("component", "component", info);
    }

    handleMessage { arg protocol, cmd, payload;

        case
        { (protocol == "runtime" && cmd == "getruntime") }
        {
            var info = Dictionary[
                "type" -> "sndflo",
                "version" -> "0.4", // protocol version
                "capabilities" -> ["protocol:component",
                    "protocol:network",
                    "protocol:graph",
                    "protocol:runtime",
                    "component:getsource",
                    "component:setsource",
                ]
            ];
            if(network.notNil, {
                info["graph"] = "default/main"; // FIXME: unhardcode
            });
            connection.sendMessage("runtime", "runtime", info);
            this.sendPorts(nil);
        }
        { (protocol == "runtime" && cmd == "packet") }
        {
            if(payload["event"] == "data", {
                network.sendPacket(payload["port"], payload["payload"]);
            });
        }
        { (protocol == "component" && cmd == "list") }
        {
            library.synthdefs.keysValuesDo({ |name,synthdef|
                this.sendComponent(name);
            });
        }
        { (protocol == "component" && cmd == "getsource") }
        {
            var name = payload["name"];
            var code = nil;
            (name == "default/main").if({
                var response = Dictionary[
                    "library" -> "default", // https://github.com/noflo/noflo-ui/issues/411
                    "name" -> "main",
                    "language" -> "json",
                    "code" -> this.network.toJSON(),
                ];
                connection.sendMessage("component", "source", response);
            }, {
                var code = library.getSource(name);
                code.notNil.if({
                    var response = Dictionary[
                        "name" -> name,
                        "language" -> "supercollider",
                        "code" -> code,
                    ];
                    connection.sendMessage("component", "source", response);
                });
            });

        }
        { (protocol == "component" && cmd == "source") }
        {
            var name = payload["name"];
            library.setSource(name, payload["code"]);
        }
        { (protocol == "graph" && cmd == "clear") }
        {
            network = SndFloNetwork.new(library);
            network.graph.on_ports_changed = {
                this.sendPorts();
            };
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
        { (protocol == "graph" && cmd == "addinport") }
        {
            network.graph.addPort("in", payload["public"], payload["node"], payload["port"]);
        }
        { (protocol == "graph" && cmd == "removeinport") }
        {
            network.graph.removePort("in", payload["public"]);
        }
        { (protocol == "graph" && cmd == "addoutport") }
        {
            network.graph.addPort("out", payload["public"], payload["node"], payload["port"]);
        }
        { (protocol == "graph" && cmd == "removeoutport") }
        {
            network.graph.removePort("out", payload["public"]);
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