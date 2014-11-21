SndFloGraph : Object {
    var <nodes;
    var <connections;
    var <>library;
    var nextBusNumber;

    *new {
        ^super.new.init
    }
    init {
        nodes = Dictionary.new;
        connections = Array;
        nextBusNumber = 20; // Avoid hardware busses. FIXME: unhardcode
    }

    addNode { arg id, component;
        var d = library.synthdefs[component];
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
    }
    removeEdge { arg srcId, srcPort, tgtId, tgtPort;
        "DEL % % -> % %\n".postf(srcId, srcPort.toUpper, tgtPort.toUpper, tgtId);
        nodes[srcId].post; nodes[tgtId].postln;

        nodes[srcId].set(srcPort.asSymbol, SndFloLibrary.silentOut);
        nodes[tgtId].set(tgtPort.asSymbol, SndFloLibrary.silentIn);
    }

    addIIP { arg tgtId, tgtPort, data;
        "IIP: '%' -> % %\n".postf(data, tgtPort.toUpper, tgtId);
        // TODO: support other data than floats
        nodes[tgtId].set(tgtPort.asSymbol, data.asFloat);
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

            "DEL IIP -> % %\n".postf(tgtPort.toUpper, tgtId);
        });
    }
}


SndFloNetwork : Object {
    var <graph;

    *new {
        ^super.new.init
    }
    init {
        graph = SndFloGraph.new;
    }

    start { arg run;
        graph.nodes.keysValuesDo({ |key,value|
            value.run(run);
        });
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
    }

}