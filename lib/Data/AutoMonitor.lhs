This is the main library.
This, you will have to fetch at runtime and, if it becomes out-of-sync, you
will have to re-compile your program with the new version. This is so that we
can statically ensure that your request for billy's HDFS data actually makes
sense, as we're not sure what billy is unless we agree on some kind of
heirarchical cluster structure.

This is why you should simply add these programs as policies, through the
easy-to-use interface that is yet to be invented. Good luck.

> module Data.AutoMonitor ( module Data.Automonitor
>                         , module Data.AutoMonitor.Planner
>                         , module Data.AutoMonitor.Computation ) where
> import Prelude ()
> import Data.Automonitor.Planner
> import Data.Automonitor.Computation
> import Data.Propogator.Name
	

First magic trick: We can observe our own Haskell code. I assume you
understand cons lists.

http://www.ittc.ku.edu/~andygill/papers/reifyGraph.pdf

I want to embed deeply, so that queries for data is handled on the edges of the
system transparently.

Here, you can make queries of your cluster, so long as you've compiled your
query against the latest cluster definition! This is so that we can plan your
queries. The idea here is that I will have a list of type-level strings that
are nodes. And these type-level strings will have constraints (instances). This
would be known statically at compile time.

We need a graph abstraction to proceed. This is confusing at first I know.

> class MuRef a where
>   type DeRef a = :: a -> a
>   mapDeRef :: (Applicative f)
>            => (a -> f u)
>            -> a
>            -> f (DeRef a u)

A type family is a thing we can extend later, lke type classes, where we have
asscociated types that are also type families. All the types are family, you
get it.

It's applicative because McBride and Patterson 2006. The threading of the
effect of unique name generation.

Which I claim has been done at the type level! 

DeRef records the graph structure of our computation. It allows us to
recursively descend into madness.

What does sharing mean in this madness? Well it can be explicitly static, or,
say, historical queries from pcp. 

Bounds and things

> data Query = Bool
> data Result = Bool
> 
> getHist :: Query -> NodeID -> Process Result
> getHist query here = do
>     call' here (makeFilteringDecoder query)
>   where
>     makeFilteringDecoder :: Query -> Static (ByteString -> Result)

Note: This makeFilteringDecoder code gets shipped out to nodes statically.

Given an temporal index (not range, this is probably an un-needed limitation
already), we can provide niceity. 

instance MuRef (Computation a)

How do you use this thing? Make a closure !

> createPolicy :: forall f argtuple a closuref.
>                  (Curry (argtuple -> Closure a) closuref, 

This sounds like poetry of a vogon kind.

These probes can share magic constants etc and those will be shipped off in
their closures.

>                 MkTDict result,
>                 Uncurry HTrue argTuple func result,
>                 Typeable result,
>                 Serializable argTuple,
>                 IsFunction f HTrue)
>               => func -> (closureFunction, remoteregister)
> createPolicy = mkClosureVal (unsafePerformIO fresh)

This is how queries shuffle between nodes:

Note that we return a Closure, which is a (\f msg -> user_code $ f msg) thing

> mkQuery :: -> Process (Closure a)
> mkQuery = closure decodePCP 
>   where

we need to decode our metrics this code gets shipped out to nodes and
predicates pushed out to edges of system. that's important.
Note that we can switch to arrows now. Let's keep it explicit not to blow
people's minds:

cp :: Closure (a -> Process b)
cp = cpIntro

>     decodePCP :: Static (ByteString -> a) -> 

LA DA DA some kind of thing represents some causal event of measurement with a
timestamp, whatever man. Everything is a thunk. Your rules do not apply here.

Stealing some ekmett foo, because we don't like his rigid definition of ST man!

https://github.com/ekmett/propagators/blob/master/src/Data/Propagator/Cell.hs

A Change is something that is sometimes good. It's one of the borders of our
network, or lattice. We will check at this point whether to push information
forwards, or not.

The boolean is simply an updated flag. Similar flags exist in signal networks
to only re-compute if information actually changes. This can be done on means
over time windows, this is the central hypothesis of this monitoring
framework.

> data Change a = !Bool a | Contradiction !(HashSet Name) String

Also we store a thing that represents a globally unique name! Maybe it is
globally unique, good luck hashes! This is so that we can explode nicely if the
user lies to us and doesn't write the same value twice, or tries to re-write
history. Now we can write them a really stern letter... The address would be 

Ekmett says: a Cell is information about a value but not a value itself. Hope
that helps.

> data Cell s a = (a -> a -> Change a) (References Process (Change a)

So a Cell s a simply takes two possible answers, and results in a change. NB,
Cell can be lazy in *either* argument, we can always "decorate" the functions
as they have guarantees. In our case, we're already shipping them around the
network. But those processes promise only to take the data that *you* decide to
send to them! How do you decide where the information should flow next?
Modelling it as a lattice!

> data AutoMonitor s a where
>

A propogator is this thing, right. It is nothing, given a place to exist.

> type Comp s a = Process a-> Change s a)

We wish to say that if we inject information into the network, it can't know
about the present computation, all sharing should have been done before! Does it?

TODO: picture
    
A propogation is just a mapping which is monotonically preserving BLAH.....
It's like a tree of metrics ok? But sideways, it's a lattice. And we want to
map connections between nodes: 
Anyway, here's a type ekmett had:

-- | This type allows us to write seemingly normal functional code and glue it together out of smaller
-- propagator templates. Evaluation of these expressions uses <www.ittc.ku.edu/~andygill/papers/reifyGraph.pdf Observable Sharing>.
--
-- * 'Nullary' lifts a computation that will produce a 'Cell' into a 'Prop'.
--
-- * 'Unary' lifts a relationship between 2 cells into 'Prop'.
--
-- * 'Binary' lifts a relationship between 3 cells into 'Prop'.
data Prop s a where
  Nullary :: ST s (Cell s a) -> Prop s a
  Unary   :: Propagated b => (Cell s a -> Cell s b -> ST s ()) -> Prop s a -> Prop s b
  Binary  :: Propagated c => (Cell s a -> Cell s b -> Cell s c -> ST s ()) -> Prop s a -> Prop s b -> Prop s c

> type Computation s a = Process a
> data Prop s a where
>   Nullary :: Computation s (Cell s a) -> Prop s a
>   Unary :: Propagated b => (Cell s a -> Cell s b -> Computation s ()) -> Prop s a -> Prop s b

SUSPEND YOUR DISBELIEF. We are just building a tree in abstract space.

>   Binary  :: Propagated c => (Cell s a -> Cell s b -> Cell s c -> Computation s ()) -> Prop s a -> Prop s b -> Prop s c

We will de-construct this structure later, and it will tell us how the
computation is wired up.

If we want local performance metrics avaliable as shared-state across a
cluster-wide computation, we need to encode a relationship into the (join
semi)-lattice! Lattice from now on.


\quote{
    We can also use a 2 watched literal scheme to kill a propagator and garbage
    collect it. If we use a covering relation to talk about 'immediate descendants
    of a node' in our lattice, we can look for things covered by our _|_
    contradiction node. These are 'maximal' entries in our lattice. If your input
    is maximal you'll never get another update from that input. So if we take our
    (+) node as an example, once two of the 3 inputs are maximal this propagator
    has nothing more to say and can be removed from the network.
}

Note, this could also be read: time to alert!

We can weave niceities like:

instance (PropagatedNum a, Eq a, Num a) => Num (Prop s a) where

A sensor collection point, a distributed computation collaborator

Question: How do we adress peers? I trust cloud haskell's solution, not so much
hashing.

> data Node = 

> data NamedChunk = NamedChunk Name ByteString -- E.G. chunk of PCP (performance co-pilot) metrics. We can transform this for the user to provide history lookups, but want to track these computations themselves in the language (not our meta-language).


> distribute cluster computation =
>   let tgt = maximumBy (intersectLocalState (getEnv computation)) cluster
>   in send tgt 


Here's what we basically have to do:

Take a list of computations, work out what they refer to (mutually recursive
loops, etc). Now pick an optimal location on which to run this computation that
shuffles data around the least.

Obviously, this means that computations *must* be structured such that they
re-use shared data and outputs are connected to inputs correctly. cf observable sharing.


We abstract over a clean remote monad interface, hiding an underlying
cloud-haskell implementation. We only wish to be able to install a new root computation

meanDeviation :: [Process Double] -> Int -> Process a
meanDeviation ps n 
