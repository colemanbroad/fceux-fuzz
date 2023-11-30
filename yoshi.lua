
-- yoshi by coleman broaddus
-- Oct 7 2023

-- 0 empty
-- 1 Goomba
-- 2 Piranha Plant
-- 3 Boo
-- 4 Blooper
-- 5 Shell (top)
-- 6 Shell (bottom)

-- 0440 Mario's Postion. 0 Left, 1 Center, 2 Right
-- 0532 Egg counter

-- emu.loadrom("/Users/broaddus/Downloads/Yoshi-USA-1696646140336.nes")
-- start_state = savestate.load("/Users/broaddus/yoshi-start-fceux.sav")

verbose = 1
emu.pause()



function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function vprint(level, ...)
  if verbose >= level then
    for i,text in ipairs(arg) do
      emu.print(text)
    end
  end
end

function get_grid_count()
  grid = {}
  gridcount = 0
  for row=0,7 do
    col = {}
    for column=0,3 do
        gridval = memory.readbyte(0x0490 + 9*column + row)
        col[column + 1] = gridval
        if (gridval ~= 0) then gridcount = gridcount + 1 end
    end
  end
  return gridcount
end
  
function get_grid_toprow()
  gridcount = 0
  toprow = {}
  for column=0,3 do
    continue = true
    toprow[column + 1] = 0
    for row=0,7 do
        gridval = memory.readbyte(0x0490 + 9*column + row)
        if (gridval ~= 0 and continue) then 
          toprow[column + 1] = gridval 
          continue = false
        end
    end
  end
  return toprow
end

function get_grid_height()
  minrow = 8
  for column=0,3 do
    continue = true
    for row=0,7 do
        gridval = memory.readbyte(0x0490 + 9*column + row)
        if (gridval ~= 0 and continue) then 
          continue = false
          if (row < minrow) then minrow = row end
        end
    end
  end
  return minrow
end

function get_upcoming()
  local upcoming = {}
  upcoming[1] = memory.readbyte(0x0475)
  upcoming[2] = memory.readbyte(0x0476)
  upcoming[3] = memory.readbyte(0x0477)
  upcoming[4] = memory.readbyte(0x0478)
  return upcoming
end

function get_score()
  hun_thousands =  memory.readbyte(0x05E8)
  ten_thousands =  memory.readbyte(0x05E9)
  thousands =  memory.readbyte(0x05F0)
  hundreds =  memory.readbyte(0x05F1)
  tens =  memory.readbyte(0x05F2)
  ones =  memory.readbyte(0x05F3)
  myscore = 100000 * hun_thousands + 10000 * ten_thousands + 1000 * thousands + 100 * hundreds + 10 * tens + 1 * ones
  return myscore
end

function am_i_dead()
  d = memory.readbyte(0x01E0)
  -- print("dead", d)
  if (d == 174 or d == 188) then return true end
  -- if (memory.readbyte(0x01E0) == 0) then return false end
  return false
  -- local r,g,b,p = emu.getscreenpixel(1,1,true)
  -- if (r==130 and g==211 and b==16) then return true end
  -- return false
end
  

function are_arrays_equal(a1, a2)

  -- Check length, or else the loop isn't valid.
  if #a1 ~= #a2 then
    return false
  end

  -- Check each element.
  for i, v in ipairs(a1) do
    if v ~= a2[i] then
      return false
    end
  end
  
  return true
end

function make_press(button_array)
  local button =  { 
    'up',
    'down',
    'left',
    'right',
    'A',
    'B',
    'start',
    'select',
  }

  local action = {}
  for i,b in ipairs(button_array) do
    if (b==1) then 
      action[button[i]] = true 
    else
      action[button[i]] = false
    end
  end
  return action
end

function random_seq(n)
  -- local bs = {0,0,0,0,0}
  local bs = {}
  for i=1,n do
    local v = 0
    if math.random(10) < 5 then v = 1 end
    bs[i] = v
  end
  return bs
end



-- sample a new state and refresh 
function load_random_state()

  for i=0,8 do
    local s = state_collection[i]
    emu.print("i=",i," score=", s.state.score)
  end
  
  local height = math.random(0,8)
  local s = state_collection[height]
  savestate.load(s.gamestate)
  -- emu.frameadvance()
  local state = deepcopy(s.state)
  vprint(1, "Reload game height", height, "with score", state.score)
  return state
end


function press_from_bit(down_button)
  local p = {0,0,0,0,0,0,0,0}
  if down_button == 1 then p[5] = 1 end
  return p
end

-- exits = {0,0,0,0}
  
function determine_action(Q, state)

  local action = random_seq(3)
  local state_string = l2s(state.m)

  -- explore ! with a constant prob
  if math.random(10) < 2 then 
  --   emu.print("exit 1")
    return action 
  end

  if state_string=="0000000000000000" then 
    vprint(2, "All-zero state => Random action.")
  --   emu.print("exit 2")
    return action 
  end

  vprint(2, "l2s(state) = ", state_string)

  local action_set = Q[state_string] or nil
  if action_set==nil then
    vprint(2,"No existing action => Random action.") 
  --   emu.print("exit 3")
    return action
  end

  max_expval = 0
  for a,vc in pairs(action_set) do
      v,c = unpack(vc)
      -- vprint(1, "Action, Value, Count", a,v,c)
      if v/c > max_expval then 
        -- temp_val = v 
        max_expval = v/c
        action = s2l(a)
      end
  end
  
  vprint(2, "State is:", state_string, "count", state_count[state_string], "action", action, "max_expval", max_expval, "------")
  -- vprint(1, "Previous action_set exist in Q!", action_set)
  -- emu.print("exit 4")
  return action

end


function l2s(lizt)
  local s = ""
  for i, li in ipairs(lizt) do
    s = s .. tostring(li)
  end
  return s
end

function s2l(str)
  local lizt = {}
  for i = 1, #str do
    v = 0
    if str:sub(i,i)=='1' then v = 1 end
    lizt[i] = v
  end
  return lizt
end
    

function update_Q(Q, state, action, reward)

  if reward > 0 then vprint(2, "update Q ", state.m, action, reward) end
  local s = l2s(state.m)
  local a = l2s(action)
  local action_set = Q[s] or {}
  v_ct = action_set[a] or {0,0} -- value, count
  v,ct = unpack(v_ct)
  -- print("v_ct = ", v_ct, v, ct)
  action_set[a] = {v + reward, ct + 1}
  Q[s] = action_set

end


function update_state_collection(state)

  height = get_grid_height()
  local s = state_collection[height]
  local best_state = s.state
  if (state.score > best_state.score) then
    vprint(1, "New best score", state.score, " for height", height)
    savestate.save(s.gamestate)
    s.state = deepcopy(state)
    state_collection[height] = s
  end
end


function take_action(state, action)

  -- actions = {1,1,1}

  left = make_press({0,0,1,0,0,0,0,0})
  right = make_press({0,0,0,1,0,0,0,0})
  down = make_press({0,1,0,0,0,0,0,0})

  vprint(2, "action : ", action )

  twiddle_time = {[0] = 0, [1] = 16}

  for n=1,12 do emu.frameadvance() end

  joypad.set(1, make_press(press_from_bit(action[1])))
  t = twiddle_time[action[1]]
  for n=1,t do emu.frameadvance() end

  joypad.set(1, right)
  for n=1,4 do emu.frameadvance() end

  joypad.set(1, make_press(press_from_bit(action[2])))
  t = twiddle_time[action[2]]
  for n=1,t do emu.frameadvance() end

  joypad.set(1, right)
  for n=1,4 do emu.frameadvance() end

  joypad.set(1, make_press(press_from_bit(action[3])))
  t = twiddle_time[action[3]]
  for n=1,t do emu.frameadvance() end

  joypad.set(1, left)
  for n=1,4 do emu.frameadvance() end

  joypad.set(1, left)
  for n=1,4 do emu.frameadvance() end

  -- Partial state update ?
  state.upcoming = get_upcoming()
  state.toprow = get_grid_toprow()

  state = run_until_action_boundary(state)
  return state
end

-- Hold the down button until we get a new `upcoming` or until death. These are our action boundaries!
function run_until_action_boundary(state)

  while (true) do

    if (am_i_dead()) then
      state = load_random_state()
      return state
    end

    test0 = are_arrays_equal(state.upcoming, get_upcoming())
    -- if (test0 and test1) then
    -- test1 = are_arrays_equal(state.toprow, get_grid_toprow())

    if (test0) then
      joypad.set(1, make_press({0,1,0,0,0,0,0,0}))
      emu.frameadvance()
      -- emu.print("frame advance ", state.global_count)
    else 
      -- emu.print("Action Complete! ", state.global_count)
      return state
    end

  end
 
end

function update_state_from_memory(state)

  state.toprow = get_grid_toprow()
  state.falling = state.in_waiting
  state.in_waiting = state.upcoming
  state.upcoming = get_upcoming()

  if verbose >= 2 then 
    emu.print("upcoming : ", state.upcoming)
    emu.print("in_waiting : ", state.in_waiting)
    emu.print("falling : ", state.falling)
    emu.print("toprow : ", state.toprow)
    emu.print('pause 1')
    emu.pause()
  end

  -- state = {falling, toprow}
  falling = state.falling
  toprow = state.toprow

  state.m = {}
  yes_egg = false
  for i=1,4 do
    for j=1,4 do 
      b0 = falling[i] == toprow[j]
      b1 = falling[i] ~= 0 
      s = 0
      -- emu.print("b0, b1", b0, b1)
      if b0 and b1 then s = 1 end
      b2 = falling[i] == 5 -- topegg (never matches with anything!)
      b3 = toprow[j] == 6
      if b2 then yes_egg = true end
      -- if b2 and b3 then s = 3 end

      state.m[4*(i-1) + j] = s
    end
  end
  if yes_egg then state.m = {2} end -- ignore all state iff topegg

  local count = state_count[l2s(state.m)] or 0
  state_count[l2s(state.m)] = count + 1
  state.global_count = state.global_count + 1

  vprint(2, "state : ", state.m)

end

function new_fresh_state()
  local state = {}
  state.score = 0
  state.global_count = 0
  state.falling = {0,0,0,0}
  state.in_waiting = {0,0,0,0}
  state.upcoming = get_upcoming()
  -- state.upcoming = {0,0,0,0}
  state.toprow = get_grid_toprow()
  -- state.toprow = {0,0,0,0}
  state.m = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  return state
end




function main()
  local current_state = state_collection[1].state
  update_state_from_memory(current_state)

  while (true) do -- mainloop

    local action = determine_action(Q, current_state)
    emu.print("action = ", action)
    emu.pause()
    current_state = take_action(current_state, action)
    update_state_from_memory(current_state)
    local newscore = get_score()
    current_state.score = newscore
    local reward = newscore - current_state.score
    update_Q(Q, current_state, action, reward)
    update_state_collection(current_state)

  end; -- mainloop
end -- main()


-- Initialize the global vars

Nstates = 9 -- one for each height we could reach
state_collection = {}
for height = 0, Nstates do
  local s = {}
  s.gamestate = savestate.object()
  savestate.save(s.gamestate)
  s.state = new_fresh_state()
  state_collection[height] = s
end

state_count = {}
Q = {}

main()
