SynthDef("SawWave", {
    arg out=SndFloLibrary.silentOut, freq=440;
    Out.ar(out, Saw.ar(freq))
},
    metadata: (
        description: "",
        specs: (
            freq: ControlSpec(20, 20000, \exp, 0.1, 220, "Hz"),
            out: SndFlo.outAudioBusSpec,
        )
    )
)
