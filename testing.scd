s.boot;

b = Bus.audio(s, 10);
b.index

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

n = Dictionary.new();
g = "examples/first.json".parseYAMLFile();

// FIXME: figure out why bus wiring is order dependent!
/*
g["processes"].keysValuesDo({ |key,value|
    n[key] = Synth.new(value["component"], [], s, \addToTail);
});
*/
// TODO: use newPaused(), and use node.run() on network start
["out", "f", "gen"].do({ |id|:
    var value = g["processes"][id];
    n[id] =  Synth.new(value["component"]).postln;
});

g["connections"].do({ |conn,idx|
    var src = conn["src"];
    var tgtPort = conn["tgt"]["port"];
    var tgtNode = conn["tgt"]["process"];
    if (src.notNil, {
        var srcPort = conn["src"]["port"];
        var srcNode = conn["src"]["process"];
        "% % -> % %\n".postf(srcNode, srcPort.toUpper, tgtPort.toUpper, tgtNode);
        n[srcNode].post; n[tgtNode].postln;

        // Connect edge, by using same Bus number (avoiding the harware ones)
        n[srcNode].set(srcPort.asSymbol, 10+idx);
        n[tgtNode].set(tgtPort.asSymbol, 10+idx);
    }, {
       var data = conn["data"];
       "IIP: '%' -> % %\n".postf(data, tgtPort, tgtNode);
       n[tgtNode].set(tgtPort.asSymbol, data.asFloat);
    });
});

n["gen"].get(\freq, { |val| val.postln; } );
n["gen"].set(\freq, 999);