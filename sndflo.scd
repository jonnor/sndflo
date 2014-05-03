s.boot;

b = Bus.audio(s, 10);
b.index;

g = "examples/first.json".parseYAMLFile();
l = SndFloLibrary.new(s);
n = SndFloNetwork.new;
n.loadGraph(g);
n.start(true);

n["gen"].get(\freq, { |val| val.postln; } );
n["gen"].set(\freq, 999);

SynthDef.synthDefDir