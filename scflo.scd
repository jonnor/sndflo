var handleMessage, sendMessage;

//s.boot;

// TODO: move code into one/more classes
sendMessage = { |addr,protocol,command,payload|
    var response = Dictionary[
        "protocol" -> protocol,
        "command" -> command,
        "payload" -> payload
    ];
    var str = JSON.stringify(response);
    "sending response: ".post; str.postln;
    addr.sendMsg("/fbp/ui/message", str);
};

handleMessage = { |msg, time, addr, recvPort|
    var ui = NetAddr(addr.ip, recvPort+1);
    var m = msg[1].asString.parseYAML;
    var protocol = m["protocol"];
    var cmd = m["command"];
    "got message: ".post; m.postln;

    case
    { (protocol == "runtime" && cmd == "getruntime") }
    {
        var info = Dictionary[
            "type" -> "scflo",
            "version" -> "0.4", // protocol version
            "capabilities" -> ["protocol:component"]
        ];
        sendMessage.value(ui, "runtime", "runtime", info);
    }
    { (protocol == "component" && cmd == "list") }
    {
        // TODO: actually respond with proper components
        var info = Dictionary.new;
        sendMessage.value(ui, "component", "component", info);
    };

};

OSCdef(\handleMessage).clear;
OSCdef(\handleMessage, handleMessage, "/fbp/runtime/message");

