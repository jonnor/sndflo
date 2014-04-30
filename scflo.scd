s.boot

(
var listComponents = { |msg, time, addr, recvPort|
    "got message: ".post; msg.postln;
    a = NetAddr(addr.ip, recvPort+1);
    // TODO: send entire component list
    a.sendMsg("/fbp/component/component", "{}");
};
OSCdef(\componentList).clear;
OSCdef(\componentList, listComponents, "/fbp/component/list");
)


(
var getRuntime = { |msg, time, addr, recvPort|
    "got message: ".post; msg.postln;
    a = NetAddr(addr.ip, recvPort+1);
    // TODO: send actual data back
    a.sendMsg("/fbp/runtime/runtime", "{}");
};
OSCdef(\getRuntime).clear;
OSCdef(\getRuntime, getRuntime, "/fbp/runtime/getruntime");
)