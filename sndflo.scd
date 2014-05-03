s.boot;

b = Bus.audio(s, 10);
b.index;

SynthDef("SquareWave", {
    arg out=12, freq=440;
    Out.ar(out, SinOsc.ar(freq))
}).send(s);

SynthDef("LowPassFilter", {
    arg in=11, out=14, freq=4400;
    Out.ar(out, BLowPass.ar(In.ar(in), freq))
}).send(s);

SynthDef("AudioOut", {
    arg in=13, out=0;
    Out.ar(out, In.ar(in))
}).send(s);

g = "examples/first.json".parseYAMLFile();
n = SndFloNetwork.new;
n.loadGraph(g);
n.start(true);

n["gen"].get(\freq, { |val| val.postln; } );
n["gen"].set(\freq, 999);

SynthDef.synthDefDir