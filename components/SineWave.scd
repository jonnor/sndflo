SynthDef("SineWave", {
    arg out=SndFloLibrary.silentOut, freq=4400;
    
    Out.ar(out, SinOsc.ar(freq, 0, 0.5))
},
    metadata: (
        description: "my filter",
        specs: (
            freq: ControlSpec(20, 20000, \exp, 0.1, 2200, "Hz"),
            out: SndFlo.outAudioBusSpec,
        )
    )
)
