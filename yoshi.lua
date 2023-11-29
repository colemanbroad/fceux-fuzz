
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

-- function old_score_extras()
--   score = get_score()
--   position = memory.readbyte(0x0440)
--   n_eggs = memory.readbyte(0x0532)

--   gc = get_grid_count()
--   grid_count_score = 10 * (7*4 - gc)^0.5

--   grid_height = get_grid_height()
--   if (grid_height < 3) then 
--     print('score 0')
--     return 0 
--   end 
--   -- grid_count_score = -300 end
--   -- if (gc > 20) then grid_count_score = -10 end

--   return 100 * n_eggs + score + grid_count_score
-- end



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

function randompress() 
  local lra = {3,4,5}
  local x = lra[math.random(3)]
  local bs = {0,1,0,0,0,0,0,0}
  bs[x] = 1
  return bs
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

-- sample a new state and refresh 
function newstate()
  g_idx = math.random(Nstates)
  -- restart_count = 0
  savestate.load(gstates[g_idx][1])
  score_current = gstates[g_idx][2]
  score = score_current
  global_count = gstates[g_idx][3]
  vprint(2, "Reload game height", g_idx - 1, "with score", score_current)
end


function press_from_bit(updown)
  local p = {0,0,0,0,0,0,0,0}
  if updown == 1 then p[5] = 1 end
  return p
end
  
function maxQAction(Q, state)

  local action = random_seq(3)

  -- explore ! with a constant prob
  if math.random(10) < 2 then return action end

  if l2s(state)=="0000000000000000" then 
    vprint(2, "All-zero state => Random action.")
    return action 
  end

  vprint(2, "l2s(state) = ", l2s(state))

  local action_set = Q[l2s(state)] or nil
  if action_set==nil then
    vprint(2,"No existing action => Random action.") 
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

  
  vprint(1, "State is:", l2s(state), "count", state_count[l2s(state)], "action", action, "max_expval", max_expval, "------")
  -- vprint(1, "Previous action_set exist in Q!", action_set)
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
    

history_idx = 0
function updateQ(Q, state, press, reward)

  if reward > 0 then vprint(2, "update Q ", state, press, reward) end
  local s = l2s(state)
  local a = l2s(press)
  local action_set = Q[s] or {}
  v_ct = action_set[a] or {0,0} -- value, count
  v,ct = unpack(v_ct)
  -- print("v_ct = ", v_ct, v, ct)
  action_set[a] = {v + reward, ct + 1}
  Q[s] = action_set

end

function updateStrategy()
  height = get_grid_height()
  gs = gstates[height + 1]
  if (score_current > gs[2]) then
    vprint(2, "New best score", score_current, " for height", height)
    savestate.save(gs[1])
    gs[2] = score_current
    gs[3] = global_count
    gstates[height + 1] = gs
  end
end


function takeAction(Q,state)
  -- ACTION SPACE

  local action = maxQAction(Q, state)

  left = make_press({0,0,1,0,0,0,0,0})
  right = make_press({0,0,0,1,0,0,0,0})
  down = make_press({0,1,0,0,0,0,0,0})

  vprint(2, "press : ", action )

  for n=1,6 do emu.frameadvance() end

  joypad.set(1, make_press(press_from_bit(action[1])))
  for n=1,6 do emu.frameadvance() end

  joypad.set(1, right)
  for n=1,6 do emu.frameadvance() end


  joypad.set(1, make_press(press_from_bit(action[2])))
  for n=1,6 do emu.frameadvance() end

  joypad.set(1, right)
  for n=1,6 do emu.frameadvance() end

  joypad.set(1, make_press(press_from_bit(action[3])))
  for n=1,6 do emu.frameadvance() end

  joypad.set(1, left)
  for n=1,6 do emu.frameadvance() end

  joypad.set(1, left)
  for n=1,6 do emu.frameadvance() end

  return action

end

function advanceFrames(n)
  emu.frameadvance()
  emu.frameadvance()
  emu.frameadvance()
  emu.frameadvance()
  press = {0,1,0,0,0,0,0,0}
  joypad.set(1, make_press(press))
  emu.frameadvance()
  emu.frameadvance()
  emu.frameadvance()
  emu.frameadvance()
  -- for i=2,n do
  --   emu.frameadvance()
  -- end
end

-- Initialize the global vars
-- Initialize the global vars
-- Initialize the global vars
-- Initialize the global vars
-- Initialize the global vars
-- Initialize the global vars

-- tracks gamestate, score and global count
-- initialize all states to same root
Nstates = 8
gstates = {}
for i=1,Nstates do
  gstates[i] = {savestate.object(), 0, 0}
  savestate.save(gstates[i][1])
end

g_idx = 1

history = {}
Q = {}
state_count = {}

falling = {0,0,0,0}
in_waiting = {0,0,0,0}
upcoming = {0,0,0,0}
toprow = {0,0,0,0}
score_current = 0;
global_count = 0
-- restart_count = 0


function main()

while (true) do -- mainloop

if (am_i_dead()) then
  vprint(2, "GAMEOVER")
  newstate()
  vprint(2, reward, score, score_current)
  vprint(2, 'pause 3')
--   emu.pause()
end

-- Hold the down button if `upcoming` and `toprow` haven't changed.
test0 = are_arrays_equal(upcoming, get_upcoming())
-- test1 = are_arrays_equal(toprow, get_grid_toprow())
-- if (test0 and test1) then
if (test0) then
  press = {0,1,0,0,0,0,0,0}
  joypad.set(1, make_press(press))
  emu.frameadvance()
else -- doeverything

vprint(2,"---- NEW UPCOMING ----")
global_count = global_count + 1

-- if global_count % 15 == 0 then 
--   printQ(Q)
-- end

toprow = get_grid_toprow()
falling = in_waiting
in_waiting = upcoming
upcoming = get_upcoming()


if verbose >= 2 then 
vprint(2, "upcoming : ", upcoming)
vprint(2, "in_waiting : ", in_waiting)
vprint(2, "falling : ", falling)
vprint(2, "toprow : ", toprow)

vprint(2, 'pause 1')
emu.pause()
end

-- Define and build state 
-- state = {falling, toprow}
state = {}
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

    state[4*(i-1) + j] = s
  end
end
if yes_egg then state = {2} end -- ignore all state iff topegg

local count = state_count[l2s(state)] or 0
state_count[l2s(state)] = count + 1

vprint(2, "state : ", state)

press = takeAction(Q,state)

-- observe score/reward and update values
score = get_score()

-- strategy 
reward = 0
if (score_current < score) then
  reward = score - score_current
  vprint(2, 'reward, score, current', reward, score, score_current)
  score_current = score
  updateStrategy()
end
  
-- update Q based on observations
updateQ(Q, state, press, reward)

vprint(2, 'pause 2')
-- emu.pause()

-- down = make_press({0,1,0,0,0,0,0,0})
-- for n=1,6 do 
--   joypad.set(1, down)
--   emu.frameadvance() 
-- end

upcoming = get_upcoming()
toprow = get_grid_toprow()

-- emu.pause()

end -- doeverything
end; -- mainloop


end -- main()

main()
