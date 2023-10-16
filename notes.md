
# Todo

-[ ] Allow interactive selection of fuzzing state from best-so-far states, e.g. 
    pressing "3" on the keypad sets fuzzing state to best-so-far score at gridheight 3.
-[ ] Allow for top + bottom egg match (bottom egg should stop making random swaps when it sees that
    top/bottom egg are aligned. Top egg should count as bottom egg number!)


----------------------------------------------------------------

# Overview

yoshi.lua looks great and plays with a restricted set of random movements, 
but I keep crashing the game! The segfaults are killing me.

The first thing I tried was a single numerical score, and to save the state whenever we increase
that score. This approach makes very rapid progress, but is susceptible to infinite loops when we
save state just prior to death. Reduce the maximum possible  height allowed to save state doesn't
prevent inflooping, but it does take longer before a (more interesting) path to infloop is found
[Q:1,2,5..7]. The single numerical score requires hyperparams, which are chosen by intuition, to
balance the multiple variables we can read from memory. This is undesireable without having an
obvious way to tune them.

The next idea was to keep track of muliple states according to this score so that if one got stuck
the others would continue. This is susceptible to lack of diversity that makes us vulnerable.

Then we tried using a Pareto-style approach to keeping multiple states alive and obviating the 
many hyperparameters used to balance concerns. We can instead keep track of the best state (by 
a simple score) _for each gridheight_. Thus we include score and gridheight in the strategy,
but still not egg_count or n_grid_total. 

For all strategies employed so far we've been sampling new states
1. only on death of the current state
2. from a flat dist over all states in the sampler. 

For Pareto this approach seemed to spend a lot of time exploring states from low grid height
that were very far behind their higher-height peers. This usually led nowhere. [Q:8,9]
It's unclear which of the variables we should be using in the Pareto strategy.


----------------------------------------------------------------

We don't need to compute a single numerical score, we just 
have to implement a partial order `<` on game states, which will
allow us to keep the top-k diverse states in memory to explore. This means
we don't have to figure exactly how to balance the
1. numerical score
2. egg count
3. number of grid spaces available
together into a single number, we can instead use e.g. #3 as a tie breaker.

The danger with keeping the top-k states according to a single metric is that 
they may not be diverse enough to avoid catastrophic looping, i.e. when all the states
get stuck in an infinite and we can't make progress.

The more likely failure mode is the rate of progress (rate at which max score is increased),
slows down over time, and lack of state diversty will probably make this problem worse.



- _Learn tactics_. Q learning in state+action space that was (toprow + falling + action) = (5^4 * 6^4 * 3) = 2.4 mil.
Then we have 10frames/sec * 1hr = 36k observations. So the space is still sparse, but we should be able to model it and reduce it.
We can reduce the environment space by shrinking the `falling` list and the `toprow` list. We can 

A CNN that looked at game pixels could learn to associate.

----------------------------------------------------------------


# Pareto Strategy

My Pareto strategy samples _flat_ across states, and this is inefficient. The states with height=1 are often _way_ behind states with height=2.
A state is interesting if it improves upon itself or other states quickly! We can 
1. Sample states with higher scores and taller heights preferentially.
2. We can sample states according to the mean-time-to-improvement as a function of height?

We can also add _egg count_ as a hash input, in addition to _height_.  

The max height states progress the fastest, but also have the highest risk of getting caught in an infinite loop!

Variables that should be included in reward, but we don't know how to compare them.

1. grid height
2. total grid count
3. score
4. egg count
5. n_eggs on bottom? 
6. diversity of top row blocks?

We could throw our hands up, admit that we don't know anything, and store all states ever.
Then we could sample a new state on death.
The next most ignorant idea would be to make a list of all the things we care about above, and whenever 
we improve on any feature we save the state. Of course some metrics only make sense as a combination of
features. For example it doesn't make sense to compare states by their grid height alone, but it does 
make sense to compare their scores, conditioned on the grid height. Likewise we know that two states
with the same grid height and score we prefer the one with better egg count. And if the grid height 
and egg count are the same then we prefer the one with better score. 
We're defining a partial order. If two states don't have the same grid height, then we don't know how
to compare them and should consider them equal.

Which states should we choose to explore from? What is our _strategy_?

We could make a larger pareto hashmap by storing the grid height as a function of the score. This would
lead to way more states in memory, and probably too many. We're pretty sure that a score of 500 with grid
height 3 is much better than a score of 505 with gridheight 8, but in this setup we would store and explore
both of them. This 


# Policy learning






# Questions

1. What fraction of the games end in a loop vs continue on past 100 eggs?
2. What does the distribution of scores look like? Is it 1/x or exponential?
3. How could we automatically extract the score from memory for an arbitrary game?
4. What if we could specify the pixels that correspond to the score?
5. Detect infinite loops?
6. Prove that loops are impossible?
7. Calculate probability of loops given n_columns, n_enemy_types, etc..
8. How should we be sampling new states?
9. How can we keep track of state trajectories and plot scores over time?
