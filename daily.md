# Thu Oct 26 00:08:07 EDT 2023

After slowing down the game to 30% speed and carefully observing every `top` and `falling` state 
I've observed that the visual game state is often inconsistent with the state we've read from memory.

1. Upon game restart we don't have the correct `falling` because it requires waiting for the two ancestor states to populate.
    We should save these ancestor states as a part of the overall game state in the Strategy and refresh them when we load a game state after death.
2. Sometimes `falling` takes on a value that is never observed visually. It is just skipped. 

