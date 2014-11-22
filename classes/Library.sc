//     sndflo - Flowhub.io sound processing runtime based on SuperCollider
//     (c) 2014 Jon Nordby
//     sndflo may be freely distributed under the MIT license

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

    *silentIn { ^12; }
    *silentOut { ^13; }

    registerSynthDef { arg id, def;
        synthdefs["synth/"++id] = def;
        def.send(server);
    }

    registerDefaults {
        var paths = PathName.new("./components").files;
        paths.do({ |pathobj|
            var path = pathobj.fullPath;
            path.endsWith(".scd").if({
                var file = File.open(path, "r");
                file.isOpen.if({
                    var content = file.readAllString;
                    var def = content.interpret;
                    this.registerSynthDef(def.name, def);
                    file.close;
                });
            });
        });
    }
}