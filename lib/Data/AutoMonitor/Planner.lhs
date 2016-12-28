I know it looks like we're writing a query planner.

And we are, sorry.

We have to (really). Predicate push-down is important to get right. Nobody ever
gets it right! We have to do it ourselves, I don't want to run spark on every
node, I want to use *constant* space (unless I don't want to).


