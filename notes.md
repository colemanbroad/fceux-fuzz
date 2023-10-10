# Sat Oct  7 15:41:31 EDT 2023

yoshi.lua looks great and plays with a restricted set of random movements, 
but I keep crashing the game! The segfaults are killing me.

we don't need to compute a single numerical score, we just 
have to implement a (total?) order `<` on game states, which will
allow us to keep the top-k states in memory to explore. This means
we don't have to figure exactly how to balance the
1. numerical score
2. egg count
3. number of grid spaces available
together into a single number, we can instead use e.g. #3 as a tie breaker.

But I think in general this approach makes sense where we keep track of a few
key metrics and save the top few game states for exploration.
The Monte-Carlo method (and all methods we've been exploring based on curiosity)
count on having a single key numerical metric that allows us to evaluate a state.
Reducing this from a number to a (partial?) order makes this easier. 



Does a hard cutoff on the number of used grid squares prevent us from dying?
or does it just make the whole grid artificially smaller and so we just "die" sooner.
(die means get stuck in infinite loop).

- What fraction of the games end in a loop vs continue on past 100 eggs?
- What does the distribution of scores look like? Is it 1/x or exponential?
- How could we automatically extract the score from memory for an arbitrary game?
- What if we could specify the pixels that correspond to the score?
How could 

- Detect infinite loops?
- Prove that loops are impossible?
- Calculate probability of loops given n_columns, n_enemy_types, etc..
- _Learn tactics_. Q learning in state+action space that was (toprow + falling + action) = (5^4 * 6^4 * 3) = 2.4 mil.
Then we have 10frames/sec * 1hr = 36k observations. So the space is still sparse, but we should be able to model it and reduce it.