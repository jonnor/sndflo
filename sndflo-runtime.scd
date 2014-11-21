var run = {
    "starting".postln;
    r = SndFloRuntime.new(s, NetAddr.localAddr);
    NetAddr.localAddr;

    if (thisProcess.argv.size == 1, {
        // Load first arg as default graph
        r.network = SndFloNetwork.new(r.library);
        g = thisProcess.argv[0].parseYAMLFile;
        r.network.loadGraph(g);
        r.network.start(true);
    });
};

Server.killAll();
run.value;
//s.waitForBoot(run);
