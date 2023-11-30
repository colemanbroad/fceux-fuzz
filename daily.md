# Thu Oct 26 00:08:07 EDT 2023

After slowing down the game to 30% speed and carefully observing every `top` and `falling` state 
I've observed that the visual game state is often inconsistent with the state we've read from memory.

1. Upon game restart we don't have the correct `falling` because it requires waiting for the two ancestor states to populate.
    We should save these ancestor states as a part of the overall game state in the Strategy and refresh them when we load a game state after death.
2. Sometimes `falling` takes on a value that is never observed visually. It is just skipped. 

How can we learn despite these flaws.
What if we can't observe the _current_ state, but instead only the state at some point in the future?
Or, what if there is serious time delay between the state changes, the actions we need to take, and the rewards we observe?

# Debugging FCEUX segfaults
-- Sun Oct 29 15:53:10 EDT 2023

- The segfault still appears if I don't run my script.
- The segfault always points to the same locaiton: (see lines starting with `fceux`). 
- The game doesn't appear to speed up unless i'm pressing the down button. The sprite animation
speeds up, but the falling does not. I guess the falling is based on _real time_ and not the 
core event loop counter. I guess fceux doesn't fake speed-up the real time?

```
thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_ACCESS (code=2, address=0x16f603ff8)
  * frame #0: 0x00000001c4ab30cc libsystem_pthread.dylib`___chkstk_darwin + 60
    frame #1: 0x00000001cbb6b8dc QuartzCore`CA::Context::commit_transaction(CA::Transaction*, double, double*) + 5248
    frame #2: 0x00000001cb9ff4cc QuartzCore`CA::Transaction::commit() + 704
    frame #3: 0x00000001cbb98b20 QuartzCore`CA::Transaction::flush_as_runloop_observer(bool) + 136
    frame #4: 0x00000001c4b84254 CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 36
    frame #5: 0x00000001c4b840a4 CoreFoundation`__CFRunLoopDoObservers + 592
    frame #6: 0x00000001c4b82b88 CoreFoundation`CFRunLoopRunSpecific + 684
    frame #7: 0x00000001cd7c2338 HIToolbox`RunCurrentEventLoopInMode + 292
    frame #8: 0x00000001cd7c1fc4 HIToolbox`ReceiveNextEventCommon + 324
    frame #9: 0x00000001cd7c1e68 HIToolbox`_BlockUntilNextEventMatchingListInModeWithFilter + 72
    frame #10: 0x00000001c76ea51c AppKit`_DPSNextEvent + 860
    frame #11: 0x00000001c76e8e14 AppKit`-[NSApplication(NSEvent) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 1328
    frame #12: 0x0000000101b41a68 libSDL2-2.0.0.dylib`Cocoa_PumpEventsUntilDate + 84
    frame #13: 0x0000000101b41c18 libSDL2-2.0.0.dylib`Cocoa_PumpEvents + 56
    frame #14: 0x0000000101abcad4 libSDL2-2.0.0.dylib`SDL_PumpEventsInternal + 64
    frame #15: 0x0000000101abcbf4 libSDL2-2.0.0.dylib`SDL_WaitEventTimeout_REAL + 96
    frame #16: 0x000000010030d96c fceux`UpdatePhysicalInput() + 52
    frame #17: 0x000000010030d5fc fceux`FCEUD_UpdateInput() + 56
    frame #18: 0x00000001001a9ed4 fceux`consoleWin_t::emuFrameFinish() + 96
    frame #19: 0x000000010000b158 fceux`consoleWin_t::qt_static_metacall(QObject*, QMetaObject::Call, int, void**) + 1908
    frame #20: 0x00000001049f21cc QtCore`QObject::event(QEvent*) + 596
    frame #21: 0x0000000103d07618 QtWidgets`QWidget::event(QEvent*) + 4128
    frame #22: 0x0000000103e04b88 QtWidgets`QMainWindow::event(QEvent*) + 248
    frame #23: 0x0000000103cce8d8 QtWidgets`QApplicationPrivate::notify_helper(QObject*, QEvent*) + 292
    frame #24: 0x0000000103ccfc7c QtWidgets`QApplication::notify(QObject*, QEvent*) + 548
    frame #25: 0x00000001049c7e78 QtCore`QCoreApplication::notifyInternal2(QObject*, QEvent*) + 292
    frame #26: 0x00000001049c9340 QtCore`QCoreApplicationPrivate::sendPostedEvents(QObject*, int, QThreadData*) + 1404
    frame #27: 0x000000010742de80 libqcocoa.dylib`___lldb_unnamed_symbol2620 + 288
    frame #28: 0x000000010742e658 libqcocoa.dylib`___lldb_unnamed_symbol2632 + 164
    frame #29: 0x00000001c4b85044 CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 28
    frame #30: 0x00000001c4b84f90 CoreFoundation`__CFRunLoopDoSource0 + 208
    frame #31: 0x00000001c4b84c90 CoreFoundation`__CFRunLoopDoSources0 + 268
    frame #32: 0x00000001c4b83610 CoreFoundation`__CFRunLoopRun + 828
    frame #33: 0x00000001c4b82b34 CoreFoundation`CFRunLoopRunSpecific + 600
    frame #34: 0x00000001cd7c2338 HIToolbox`RunCurrentEventLoopInMode + 292
    frame #35: 0x00000001cd7c20b4 HIToolbox`ReceiveNextEventCommon + 564
    frame #36: 0x00000001cd7c1e68 HIToolbox`_BlockUntilNextEventMatchingListInModeWithFilter + 72
    frame #37: 0x00000001c76ea51c AppKit`_DPSNextEvent + 860
    frame #38: 0x00000001c76e8e14 AppKit`-[NSApplication(NSEvent) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 1328
    frame #39: 0x0000000101b41a68 libSDL2-2.0.0.dylib`Cocoa_PumpEventsUntilDate + 84
```

----------------------------------------------------------------

So, what should I do... I want to keep pushing on RL. Yoshi is nice because we already know some of memory.
I can try _learning_ past this messy issue where I don't know if the game state and actions are being
coupled correctly.... We can keep a list of game states and a list of actions and just feed in the 
whole game state history and hope the actions can make use of it... This state space quickly becomes
too large and sparse to learn anything. 

Let's just try again. Maybe the coupling isn't as bad as it looks. Maybe I can measure progress on
my policy by looking at policy entropy? Or by frequent pauses... 

Or I can rebuild Yoshi in Zig. Including a stupid GUI.

Or I can do pitsworld in zig.

Lua is too frustrating an environment and fceux keeps crashing on me! Let's RL something more interesting
in Zig... Can I do RL in the cell tracking world? I can try to write a policy that links cells together.
Given a cell and a bunch of options for it's potential connections we could learn a policy for connecting them.
But whatever policy we learn should be re-run from scratch on the whole dataset. Fundamentally this is just
not a problem where an agent explores an environment and has to learn to explore well in finite time. 


# Wed Nov 29 

I'm learning more important stuff.
When should we hold "down"? When should we execute a new action? 

I want a nice discrete space where a set of blocks fall and a single action permutes the columns and takes us into the next state, ready for the next set of blocks.
But this is hard to do.
Actions take time, states don't.
We decide on the `action boundaries` that split time up into discrete actions!
If you use `toprow` change as action boundary then it will fire after the first hit, when we want to wait until the last hit!
If you use the arrival of a new `upcoming` as your action boundary then you might have a boundary in between blocks landing on columns?
In practice waiting for new `upcoming` doesn't seem so bad.

1. state definition (one that collapses equivalent states as much as possible)
2. action boundary definition (clean separation between actions is key to learning!)
3. what constitutes an action? (how many button presses should I take? variable or fixed time? Should I wait for external condition?)
3. set of metrics and strategy for saving states / replaying from states
4. identify death, ability to respawn on death to avoid wasting time
5. functions to build and execute actions


```lua
-- am i dead? respawn
get_grid_count()
get_grid_toprow()
get_grid_height()
get_upcoming()
get_score()
am_i_dead()

-- update state storage based on metrics
updateStrategy()
newstate()

-- utils (mostly for state equivalence)
are_arrays_equal(a1, a2)
has_value(tab, val)
l2s(lizt)
s2l(str)

-- construct and execute actions
random_seq(n)
make_press(button_array)
randompress() 
press_from_bit(updown)
takeAction(Q,state)
advanceFrames(n)

-- Q functions for sampling actions and updating Q
-- sample an action given game state
maxQAction(Q, state)
updateQ(Q, state, press, reward)


main()
```

```lua

-- utils
vprint(level, ...)
are_arrays_equal(a1, a2)

-- serialize state and action (unique string representation is also a hash)
l2s(lizt)
s2l(str)

-- convert memory into game state
get_grid_count()
get_grid_toprow()
get_grid_height()
get_upcoming()
get_score()
am_i_dead()

-- construct actions
make_press(button_array)
randompress() 
random_seq(n)
press_from_bit(updown)

-- execute actions
take_action(state, action)
run_until_action_boundary(state)

-- 
new_fresh_state()
load_random_state()

update_state_collection(state)
update_state(state)

determine_action(Q, state)
update_Q(Q, state, action, reward)

main()
```


-[ ] instead of just pulling `toprow` as list of gumbas we should look at list of "column descriptors" that include `{toprow:GumbaType, containsEgg:bool, height:[0..8]}`

16 bits of for grid state and 3 bits of action = 19 = less than a million in size! but we only get to try one action / s. This will take > 6 days! 
The great hope is that the actual distribution over states is low entropy... And I think it is! counts are
State 2 468 and others were... 56,16,20,4,20,45,7,5,8,2,29,15,31,17,2,32,5,30,8,50,61,20,9,4,7l,438,14,18,16,3,21.

!!! TODO: Don't attempt random actions. Learn to do science! You can rewind to the prior state and try all possible actions! Then you know what's best and can always do that!
You only need to do this science on states you haven't seen.
And if we can be more efficient we can expand the state space to include the "column descriptors" above...  

--- I've just refactored every part of the codebase. ---

-[ ] After the refactor I can see that my actions are usually being executed correctly, but not when we have {1,1,x} for all x. The second twiddle is skipped!
-[ ] The action boundary isn't long enough! Sometimes the matching gumbas don't disappear until after the subsequent action begins.

Nasty bugs.
-[ ] I have a theory about he diffenent amount of time it takes to perform a twiddle action: Taller towers need longer to move! There top lags behind the bottom.
-[ ] The state_collection is in trouble. Somehow the deepcopy is failing. The states are aliased and the scores are wrong. 

