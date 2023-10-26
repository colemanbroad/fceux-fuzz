
# Todo

-[ ] Allow interactive selection of fuzzing state from best-so-far states, e.g. 
    pressing "3" on the keypad sets fuzzing state to best-so-far score at gridheight 3.
-[ ] Allow for top + bottom egg match (bottom egg should stop making random swaps when it sees that
    top/bottom egg are aligned. Top egg should count as bottom egg number!)


-[ ] A symmetric situation state [1,1] will produce points no matter which action is taken. The greedy policy breaks this symmetry at random and never repairs it.
-[ ] The top-egg + bottom-egg combo produces the largest reward but is not identifiable as a function of our state space, so will reward a random action irreparably.

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


Only need to think about a non-zero action if there is a new upcoming?
No, this is insufficient, because _a full permutation of columns may require multiple frames to execute._

1. allow for _actions that take place over multiple frames_. 
    The max length action is << time between `upcoming` so the bounds shouldn't be a problem.
2. Enforce small L,R,Swap action space and single-frame timesteps.
    The state space in both cases is `top x falling`

----------------------------------------------------------------

Keep track of the recent history so we can backprop the reward to prev value.
The value function will not make sense if we only keep track of the `top` and `falling` block states.

- We don't need any form of long-term memory to do well in yoshi. 
    Just like chess, the entire game state is visible at all times.  
    This means we can learn a policy that ignores or heavily discounts future reward in favor of immediate returns.[^1]

- Further, the actions that we take in yoshi (permuting columns) has only a very minimal effect on the next state, 
    which is primarily determined by the random number generator picking new `top` row blocks. So there isn't that
    much we actually _can_ learn about how action affect the future.


[^1]: With the caveat that it depends on our definition of "future". If every single frame is counted, then we need 
    to take action many frames before the blocks connect and the reward is received. However, if we coarse-grain time
    to only advance when a new `top` row appears then the the action that we take can be in response to a new top row
    appearing, which  


The rough order of operations involved in a single coarse-grained timestep which may take 8s and 8*60 frames.
Maybe we could scale up our memory by having a buffer with n memory slots, where slot n is cleared after 2^n frames.

1. new `top` appears in memory
1. old `top` moves somewhere unknown and begins to fall
2. our `action` aligns columns with falling blocks
3. falling blocks are destined for certain exposed tops because they're too deep
4. blocks hit the exposed tops
4. exploding egg animation runs
5. points are registered 
5. eggs are registered 
6. blocks are redrawn with black borders 
6. falling blocks are added to the grid and become new exposed tops


policy returns an optimal decision for the given current state
by simply looking up for action in state->[]action for reward in (state,action) -> reward
when _off policy_ we make a choice at random / try the smallest untested action.
initially we don't do any clever interpolation or try to break the action down by sub-actions
but we could do that too... add columns for sub-action steps and for sub-state pieces. This additional
granularity gives us better statistics, which we can then use. If some of the pieces live in an ordered or
continuous space we could even interpolate between them! If the newstate and reward is related to the action
by a continuous function we can backprop it!) I'm imagining that we want to break up the state into the 
different yoshi. 

The "action" that we learn to make doesn't necessarily just have to be learning button presses based
on grid states. it could be learning _any code upstream of button presses_ 

# How long should it take?

If we take one action and observer one reward per second...
And our state space is `top x falling x actions = 6^4 x 6^4 x 3 = 5_038_848` it will take an hour 
before the state space is 1/1000 of the way full. This will not do...
- 6^4 x 6^4 = 1_679_616 state space

If our state space is `three pairs of two grid tops and two grid bottoms and 3^3 actions` this doesn't give you
enough info to take a good action.
- two pairs of grid tops and bottoms and two pairs of (binary) actions. either do nothing or permute.
- a 4x4 binary matrix showing relationship between `top` and `falling` blocks (0 = not equal, 1 = equal). 
    - 2^16 = 64k state space (much better!)
    - if we say blank != blank then there are only very few matrices ever seen.
    - remember it's only the distribution over the state space that matters (entropy of that dist), not the
        absolute size of the space.
    - also think that usually there will be zero 1's in M. or a single 1 in M, which already allows us to 
        get some points! we should learn this very quickly!
    - we can then extend the action space to X,R,X,R,X,L,X,L,X where `X` is an optional swap and L/R are left/right movements.
        This gives us access to all 4! permutations of columns using a single pass? No it doesn't. We can't do a full iversion of the order, for instance. ABCD -> No it doesn't. We can't do a full iversion of the order, for instance. ABCD -> DCBA.
- 


# A datastructure for Q learning

Keep a list of tuples 

```python
# a list of tuples database. add a row every frame. if we observe any reward, update the values for the previous rows where time > current time - 60 
history : [(state, action, reward, time)]
# update this whenever a row is updated we have to update the corresponding value of the (state,action) pair
Q : (state,action) -> value
# update this whenever a (state,action) pair's value is updated.
policy : state -> [(action, value), (action, value), ... ] 
```

On every iteration we 
1. choose an action based on sampling a weighted random action from policy.
2. perform the action
3. observe the reward
4. add previous state, action, reward, time to history
5. for every (state,action) pair in recent history, update it's value in Q
6. for every state with an updated value in Q, update it's value in policy

Here's a simplified version that combines Q and policy:


```python
# a list of tuples database. add a row every frame. if we observe any reward, update the values for the previous rows where time > current time - 60 
history : [(state, action, reward, time)]
# update this whenever a row is updated we have to update the corresponding value of the (state,action) pair
Q : state -> action -> value
```

1. choose an action based on sampling a weighted random action from Q
2. perform the action
3. observe the reward
4. add previous state, action, reward, time to history
5. for every state action pair in recent history, update value in Q


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
