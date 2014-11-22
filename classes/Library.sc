//     sndflo - Flowhub.io sound processing runtime based on SuperCollider
//     (c) 2014 Jon Nordby
//     sndflo may be freely distributed under the MIT license

SndFloLibrary {
    // TODO: use a SynthDescLib?
    var <synthdefs;
    var server;
    var componentDir;
    var componentExtension;
    var >on_component_changed;

    *new { arg server;
        ^super.new.init(server)
    }
    init { arg server;
        server = server;
        synthdefs = Dictionary.new;
        componentDir = "./components";
        componentExtension = ".scd";
        on_component_changed = { |name| }; // override

        this.registerDefaults();
    }

    *silentIn { ^12; }
    *silentOut { ^13; }

    *componentDir {  }

    registerSynthDef { arg id, def;
        synthdefs["synth/"++id] = def;
        def.send(server);
    }

    getSource { arg name;
        var tokens = name.split;
        var ret = nil;
        (tokens.size == 2).if({
            var lib = tokens[0];
            var component = tokens[1];
            // XXX: right now lib is ignored, we only support "synth"
            var path = componentDir+/+component++componentExtension;
            var file = File.open(path, "r");
            file.isOpen.if({
                ret = file.readAllString;
                "GETSOURCE %\n".postf(path);
            });
        });
        ^ret;
    }

    setSource { arg name, code;
        var def = code.interpret;
        if(def.notNil && "synth/"++def.name == name, {
            this.registerSynthDef(def.name, def);
            "SETSOURCE %\n".postf(name);
            on_component_changed.value(name);
        });
    }

    registerDefaults {
        var paths = PathName.new(componentDir).files;
        paths.do({ |pathobj|
            var path = pathobj.fullPath;
            path.endsWith(componentExtension).if({
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