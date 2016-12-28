This repository contains code and accompanying philosophy for querying and
monitoring distributed systems with probes built upon distributed lvish computations.

# Elvish computations are used to model the probes?

LVars are amazing, they give you a nice language like bloom. You just have to
make some promises, and we won't ruin anyone's notion of causality. Nobody
wants to do that, so please read this shamelessly stolen from the bloom
language website:

http://bloom-lang.net/calm/


CALM: consistency as logical monotonicity

                One of the key innovations underlying Bloom is the ability to
                formally guarantee consistency properties of distributed
                programs.  This reasoning is based on the CALM principle, which
                was the subject of recent theoretical results.  This theory
                applies to any programming paradigm, but Bloom’s roots in logic
                make it easy for us to convert the theory into practical tools
                for Bloom programmers.  background

                Informally, a block of code is logically monotonic if it
                satisfies a simple property: adding things to the input can
                only increase the output.  By contrast, non-monotonic code may
                need to “retract” a previous output if more is added to its
                input.

        In general terms, the CALM principle says that:

                logically monotonic distributed code is eventually consistent
                without any need for coordination protocols (distributed locks,
                two-phase commit, paxos, etc.) eventual consistency can be
                guaranteed in any program by protecting non-monotonic
                statements (“points of order”) with coordination protocols.

                It turns out that some of the important design maxims used by
                experienced distributed programmers are in fact techniques for
                minimizing the use of non-monotonic reasoning.  The problem is
                that without language support, code built around these maxims
                is hard to test and hard to trust — especially when it is
                likely to be maintained by groups of developers over time.
                keeping CALM with bloom

                Bloom’s roots in temporal logic make it amenable to simple
                checks for non-monotonicity. This enables us to build automated
                tools that assist Bloom programmers to guarantee consistency
                properties while using a minimum of coordination.  learn more

            An intuitive intro the CALM principle appears in this blog post.  A
            paper in CIDR 2011 provides a more detailed introduction to the
            CALM principle, and shows how it relates to distributed design
            patterns used by experienced developers at Amazon and Microsoft.
            Note: the Bloom examples in this paper were based on an early
            prototype, and syntax has changed since then.  See the bud sandbox
            for working implementations.  The CALM principle was introduced as
            a conjecture in a keynote talk at PODS 2010 [slides] [video], along
            with a number of related conjectures regarding space, time, and
            complexity.  This was written up in a paper in SIGMOD Record on The
            Declarative Imperative.  An upcoming paper in PODS 2011 presents
            formal statements and proof of the CALM Theorem.  A somewhat
            different formalism and proof appears in an upcoming technical
            report from Berkeley.


        Why do we care about this monotonicity? Because if we can have a monotone map
then we can guarantee that we're only *increasing* our certainty factor of say,
an average. We don't then need to wait to be certain that an alert needs to go
out if we've lost a node, but it's possibly only flapping. If, however, we lose
quorum, then we want to trigger a threshold here.

This, effectively, disallows speculation at the edges of the system. It is up
to the users to speculate, but if, as a probe,you recieve input, you shouldn't
have to nullify earlier information that you provided. With this guarantee, we
can keep computations local to where the data is collected much more easily.

So this data type provides us with an abstraction, and my plan is that a
monitoring system can be built out of abstract data types that model things
like groups of chassis, and relations, data-log style almost.

This LVAR abstraction of any-two-writes, just make sure they're monotonically
non-decreasing, makes sense if you consider for example sensor data coming in
from multiple servers. The unified rise in mean of the temperature across a
grouping of servers (perhaps, all the same rack), would take the coordination
of several individual metrics. Consider if this data is sampled at 1 ns
precision, that's a lot of data. Over many sets of metrics at high sample rate
we make a lot of data, most of which is filtered out, we want to be able to
dynamically probe this in the event of anomaly cf steerable computation. So
imagine that local computations periodically chunk together system logs and
metrics and analyze them. Now this computation can find anomalies and condense
means etc to be provided and shared through a global table (that allows plugins
to share state explicitly, deliberately a choice). This state would be
aggregate metrics, that would form a lattice. This would allow ad-hoc queries
e.g. sliding window average of response time of nodes 1-n, please, to be
processed against a distributed steerable computation that caches the last
value seen and somehow hopes to guarantee determinency of your cluster. 

Basic premise: Probes and policies can be run at the source of the data with
predicates pushed out to the edges of the system. This saves resources a lot
whilst still monitoring really well.
 
