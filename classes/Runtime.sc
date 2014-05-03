SndFloUiConnection : Object {
    var receiveOscFunc;
    var uiAddr;

    *new { arg listenAddr;
        ^super.new.init(listenAddr)
    }
    init { arg listenAddr;
        uiAddr = NetAddr(listenAddr.ip, listenAddr.port+1);
        receiveOscFunc = OSCFunc.new({ |msg, time, addr, recvPort|
            "received: ".post; msg.postln;
            this.receiveOsc(msg,time,addr,recvPort);
        }, "/fbp/runtime/message");
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
        "handleMessage :".post; protocol.post; cmd.postln;

        case
        { (protocol == "runtime" && cmd == "getruntime") }
        {
            var info = Dictionary[
                "type" -> "scflo",
                "version" -> "0.4", // protocol version
                "capabilities" -> ["protocol:component"]
            ];
            this.sendMessage("runtime", "runtime", info);
        }
        { (protocol == "component" && cmd == "list") }
        {
            // TODO: actually respond with proper components
            var info = Dictionary.new;
            this.sendMessage("component", "component", info);
        };
    }

}
