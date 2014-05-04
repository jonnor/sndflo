
s.boot;
r = SndFloRuntime.new(s, NetAddr.localAddr);
NetAddr.localAddr

a = SynthDef("SawWave", {
    arg out=12, freq=440;
    Out.ar(out, Saw.ar(freq))
});

s.scope(20);
s.makeGui;

r.network.graph.nodes["out"].get(\out, { |val| val.postln; });
r.network.start(false);