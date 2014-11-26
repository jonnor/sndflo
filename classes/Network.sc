//     sndflo - Flowhub.io sound processing runtime based on SuperCollider
//     (c) 2014 Jon Nordby
//     sndflo may be freely distributed under the MIT license

SndFloGraph : Object {
    var <nodes;
    var <connections;
    var <iips;
    var <inports;
    var <outports;
    var >on_ports_changed;

    var <library;
    var nextBusNumber;

    *new { arg lib;
        ^super.new.init(lib);
    }
    init { arg lib;
        library = lib;
        library.synthdefs.postln;
        nodes = Dictionary.new;
        connections = Dictionary.new; // busNumber -> Dictionary[ src -> .., tgt -> .. ]
        iips = Dictionary.new; // "port src" -> Object
        nextBusNumber = 20; // Avoid hardware busses. FIXME: unhardcode
        inports = Dictionary.new;
        outports = Dictionary.new;
        on_ports_changed = { |inports, outport| }; // override
    }

    addPort { arg direction, name, id, port;
        var ports;
        (direction == "in").if({ ports=inports }, { ports=outports });
        ports[name] = Dictionary[ "port" -> port, "node" -> id];
        "EXPORT %port: % => % %\n".postf(direction, name, port.toUpper, id);
        on_ports_changed.value(this.inports, this.outports);
    }
    removePort { arg direction, name;
        var ports;
        (direction == "in").if({ ports=inports }, { ports=outports });
        ports[name] = nil;
        "UNEXPORT %port: %\n".postf(direction, name);
        on_ports_changed.value(this.inports, this.outports);
    }

    addNode { arg id, component;
        var d = library.synthdefs[component];
        component.postln;
        "%(%)\n".postf(id, d.name);
        nodes[id] = Synth.newPaused(d.name);
    }
    removeNode { arg id;
        nodes[id] = nil;
        "DEL %()".postf(id);
    }

    addEdge { arg srcId, srcPort, tgtId, tgtPort;
        // TODO: recycle busses when edges using it is removed
        var busForEdge = nextBusNumber;
        nextBusNumber = nextBusNumber+1;
        "% % -> % %\n".postf(srcId, srcPort.toUpper, tgtPort.toUpper, tgtId);
        nodes[srcId].post; nodes[tgtId].postln;

        // Connect edge, by using same Bus number
        nodes[srcId].set(srcPort.asSymbol, busForEdge);
        nodes[tgtId].set(tgtPort.asSymbol, busForEdge);
        // Modify order-of-executioon so that target can hear source
        nodes[tgtId].moveAfter(nodes[srcId]);

        // Store state
        connections[busForEdge] = Dictionary[
            "src" -> Dictionary [ "process" -> srcId, "port" -> srcPort ],
            "tgt" -> Dictionary [ "process" -> tgtId, "port" -> tgtPort ],
        ]
    }
    removeEdge { arg srcId, srcPort, tgtId, tgtPort;
        var busForEdge = nil;
        "DEL % % -> % %\n".postf(srcId, srcPort.toUpper, tgtPort.toUpper, tgtId);
        connections.keysValuesDo({ |k, v|
            var found = v["src"]["process"] == srcId &&
                v["src"]["port"] == srcPort &&
                v["tgt"]["process"] == tgtId &&
                v["tgt"]["port"] == tgtPort;
            busForEdge = if(found, { ^k }, { ^nil });
        });
        "BUS: ".post; busForEdge.postln;

        connections[busForEdge] = nil;
        nodes[srcId].set(srcPort.asSymbol, SndFloLibrary.silentOut);
        nodes[tgtId].set(tgtPort.asSymbol, SndFloLibrary.silentIn);
    }

    addIIP { arg tgtId, tgtPort, data;
        "IIP: '%' -> % %\n".postf(data, tgtPort.toUpper, tgtId);
        // TODO: support other data than floats
        nodes[tgtId].set(tgtPort.asSymbol, data.asFloat);
        iips[tgtPort+tgtId] = data.asFloat;
    }
    removeIIP { arg tgtId, tgtPort;
        // sets back default value
        var tgtNode, component, definition, specs, defaultValue;
        tgtNode = nodes[tgtId];
        if (tgtNode.notNil, {
            component = "synth/"++tgtNode.defName;
            definition = library.synthdefs[component];
            specs = definition.metadata.specs;
            defaultValue = specs[tgtPort.asSymbol].default;
            tgtNode.set(tgtPort.asSymbol, defaultValue);
            iips[tgtPort+tgtId] = nil;

            "DEL IIP -> % %\n".postf(tgtPort.toUpper, tgtId);
        });
    }
}


SndFloNetwork : Object {
    var <graph;

    *new { arg library;
        ^super.new.init(library);
    }
    init { arg library;
        graph = SndFloGraph.new(library);
    }

    start { arg run;
        graph.nodes.keysValuesDo({ |key,value|
            value.run(run);
        });
    }

    sendPacket { arg public, value;
        var internal = graph.inports[public];
        var synth = graph.nodes[internal["node"]];
        synth.set(internal["port"].asSymbol, value);
        "PACKET % %\n".postf(public, value);
    }

    loadGraph { arg inputGraph;

        inputGraph["processes"].keysValuesDo({ |key,value|
            graph.addNode(key, value["component"]);
        });

        inputGraph["connections"].do({ |conn,idx|
            var src = conn["src"];
            var tgtPort = conn["tgt"]["port"];
            var tgtNode = conn["tgt"]["process"];
            if (src.notNil, {
                graph.addEdge(conn["src"]["process"], conn["src"]["port"], tgtNode, tgtPort);
            }, {
                graph.addIIP(tgtNode, tgtPort, conn["data"]);
            });
        });
        inputGraph["inports"].keysValuesDo({ |name, internal|
            graph.addPort("in", name, internal["process"], internal["port"]);
            1
        });
        inputGraph["outports"].keysValuesDo({ |name, internal|
            graph.addPort("out", name, internal["process"], internal["port"]);
        });
    }

    saveGraph {
        var root = Dictionary.new();

        root["processes"] = Dictionary.new();

        this.graph.nodes.keysValuesDo({ |name,synth|
            var proc = Dictionary[
                "component" -> ("synth/"++synth.defName);
            ];
            root["processes"][name] = proc;
        });

        root["connections"] = List.new();
        this.graph.connections.keysValuesDo({ |bus,conn|
            root["connections"].add(conn);
        });
        this.graph.iips.keysValuesDo({ |tgtStr, iip|
            var tokens = tgtStr.split($ );
            tokens.postln; tokens[0].postln;
            root["connections"].add(Dictionary[
                "tgt" -> Dictionary["port" -> tokens[0], "process" -> tokens[1]],
                "data" -> iip,
            ]);
        });

        root["inports"] = Dictionary.new();
        this.graph.inports.keysValuesDo({ |name, internal|
            root["inports"][name] = Dictionary[
                "process" -> internal["node"],
                "port" -> internal["port"],
            ];
        });

        root["outports"] = Dictionary.new();
        this.graph.outports.keysValuesDo({ |name, internal|
            root["outports"][name] = Dictionary[
                "process" -> internal["node"],
                "port" -> internal["port"],
            ];
        });

        ^root;
    }

    toJSON {
        ^SndFloJSON.stringify(this.saveGraph());
    }

}