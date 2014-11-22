var f = {
    "sndflo-runtime starting".postln;
    r = SndFloRuntime.new(s, NetAddr.localAddr);

    Task.new({
        s.sync; // make sure library is loaded
        if (thisProcess.argv.size == 1, {
            // Load first arg as default graph
            r.network = SndFloNetwork.new(r.library);
            g = thisProcess.argv[0].parseYAMLFile;
            r.network.loadGraph(g);
            r.network.start(true);
        });
        "sndflo-runtime running on port %\n".postf(NetAddr.localAddr.port);
    }).play;
};

Server.killAll();
Task.new({
    1.wait;
    //s.waitForBoot(f);
    s.boot;
    s.doWhenBooted(f);
}).play;
