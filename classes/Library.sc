SndFloLibrary {
    // TODO: use a SynthDescLib?
    var <synthdefs;
    var server;

    *new { arg server;
        ^super.new.init(server)
    }
    init { arg server;
        server = server;
        synthdefs = Dictionary.new;
        this.registerDefaults();
    }

    registerSynthDef { arg id, def;
        synthdefs["synth/"++id] = def;
        def.send(server);
    }

    registerDefaults {
        var defs = [
            SynthDef("SawWave", {
                arg out=12, freq=440;
                Out.ar(out, Saw.ar(freq))
            },
                metadata: (
                    description: "",
                    specs: (
                        freq: ControlSpec(20, 20000, \exp, 0.1, 220, "Hz")
                    )
                )
            )
            ,
            SynthDef("LowPassFilter", {
                arg in=11, out=14, freq=4400;
                Out.ar(out, BLowPass.ar(In.ar(in), freq))
            },
                metadata: (
                    description: "",
                    specs: (
                        freq: ControlSpec(20, 20000, \exp, 0.1, 2200, "Hz")
                    )
                )
            )
            ,
            SynthDef("AudioOut", {
                arg in=13, out=0;
                Out.ar(out, In.ar(in))
            },
                metadata: (
                    description: "Play out on soundcard"
                )
            )
        ];
        defs.do({ |def|
            this.registerSynthDef(def.name, def);
        });
    }
}