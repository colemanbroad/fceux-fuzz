
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

emu.pause()

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

function getupcoming()
  local upcoming = {}
  upcoming[1] = memory.readbyte(0x0475)
  upcoming[2] = memory.readbyte(0x0476)
  upcoming[3] = memory.readbyte(0x0477)
  upcoming[4] = memory.readbyte(0x0478)
  return upcoming
end

function getscore()
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
--   score = getscore()
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

function arrayEqual(a1, a2)
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

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end


function dead()
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
  emu.print("Reload game height", g_idx - 1, "with score", score_current)
end


function press_from_bit(updown)
  local p = {0,0,0,0,0,0,0,0}
  if updown == 1 then p[5] = 1 end
  return p
end
  

function getPressFromQ(state) 


  local falling = falling[1]
  local toprow = falling[2]
  
  -- default random
  press = randompress()

  for i=1,4 do
    c1 = falling[i] == toprow[i]
    c2 = falling[i] == 5 and toprow[i] == 6
    c3 = falling[i] == 5 and toprow[i] == 5 -- both shell bottoms
    if ((c1 and not c3) or c2) then 
        press = {0,1,0,0,0,0,0,0}
    end -- just down
  end

  return press

end

function maxQAction(Q, state)

  press = random_seq(2)

  if l2s(state)=="0000000000000000" then 
    emu.print("No Matches => Random action.")
    return press 
  end

  actions = Q[l2s(state)] or nil
  if actions==nil then
    emu.print("No existing action => Random action.")
    return press
  end

  emu.print("Action exist!", actions)
  max_val = 0
  for a,vc in pairs(actions) do
      v,c = unpack(vc)
      emu.print("Action, Value, Count", a,v,c)
      if v > max_val then 
        temp_val = v
        press = s2l(a)
      end
  end
  emu.print("Best action = ", a, ", i.e. ", press)
  return press
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

  if reward > 0 then
    emu.print("update Q ", state, press, reward)
  end
  local s = l2s(state)
  local a = l2s(press)
  actions = Q[s] or {}
  v_ct = actions[a] or {0,0} -- value, count
  v,ct = unpack(v_ct)
  -- print("v_ct = ", v_ct, v, ct)
  actions[a] = {v + reward, ct + 1}
  Q[s] = actions
  
  -- N = 6
  -- history_idx = history_idx + 1
  -- history[(history_idx % N) + 1] = {l2s(state), l2s(press), }

  -- idx = 0
  -- while idx < N do
  --   h_idx = (history_idx - idx) % N + 1
  --   sarc = history[h_idx] or nil
  --   idx = idx + 1

  --   if not (sarc == nil) then
  --     s,a = unpack(sarc)
  --     actions = Q[s] or {}
  --     v_ct = actions[a] or {0,0} -- value, count
  --     print("v_ct = ", v_ct)
  --     v,ct = unpack(v_ct)
  --     actions[a] = {v + reward, ct + 1}
  --     Q[s] = actions
  --   end
  -- end
end

function updateStrategy()
  height = get_grid_height()
  gs = gstates[height + 1]
  if (score_current > gs[2]) then
    emu.print("New best score", score_current, " for height", height)
    savestate.save(gs[1])
    gs[2] = score_current
    gs[3] = global_count
    gstates[height + 1] = gs
  end
end

function printQ(Q)
  -- emu.print("PRINTING Q\n")
  local total = 0
  local temp = {}
  local idx = 1
  for st, action_dict in pairs(Q) do
    emu.print("--------------------------------")
    for act, valcount in pairs(action_dict) do
      -- print()
      val, count = unpack(valcount)
      -- total = total + count
      -- temp[idx] = (temp[idx] or 0) + count
      emu.print(st, act, val, count)
      if count>1 then  emu.print(st, act, val, count) end
    end
    -- idx = idx + 1
  end
  -- emu.print("Total: ", total)
  -- emu.print("temp", temp)
end

function takeAction(Q, state)
  -- ACTION SPACE

  press = maxQAction(Q, state)

  left = make_press({0,0,1,0,0,0,0,0})
  right = make_press({0,0,0,1,0,0,0,0})

  joypad.set(1, make_press(press_from_bit(press[1])))
  advanceFrames(3)
  joypad.set(1, right)
  advanceFrames(3)
  joypad.set(1, make_press(press_from_bit(press[2])))
  advanceFrames(3)
  joypad.set(1, left)

  return press

  -- -- joypad.set(1, make_press(press_from_bit(press[2])))
  -- -- advanceFrames(3)
  -- joypad.set(1, right)
  -- advanceFrames(3)
  -- joypad.set(1, make_press(press_from_bit(press[2])))
  -- advanceFrames(3)
  -- joypad.set(1, left)
  -- advanceFrames(3)
  -- -- joypad.set(1, make_press(press_from_bit(press[4])))
  -- -- advanceFrames(3)
  -- joypad.set(1, left)
  -- advanceFrames(3)
  -- -- joypad.set(1, make_press(press_from_bit(press[5])))
  -- -- advanceFrames(3)
  -- return press

end

function advanceFrames(n)
  for i=1,n do
    emu.frameadvance()
  end
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
-- emu.print("g_idx = ", g_idx)

history = {}

falling = {0,0,0,0}
in_waiting = {0,0,0,0}
upcoming = {0,0,0,0}
score_current = 0;
global_count = 0
-- restart_count = 0

Q = {}

-- Begin main loop
-- Begin main loop
-- Begin main loop
-- Begin main loop
-- Begin main loop
-- Begin main loop

while (true) do -- mainloop


if (dead()) then
  emu.print("GAMEOVER")
  newstate()
  emu.print(reward, score, score_current)
end

-- The upcoming eventually falls and is replaced by the next upcoming before it hits the toprow.
-- We don't have a way of observing the falling blocks, but we can remember who's falling by remembering
-- the previous toprow.
if (arrayEqual(upcoming, getupcoming())) then
  press = {0,1,0,0,0,0,0,0}
  joypad.set(1, make_press(press))
  emu.frameadvance()
else -- doeverything

emu.print("---- NEW UPCOMING ----")
global_count = global_count + 1

if global_count % 15 == 0 then 
  printQ(Q)
end

falling = in_waiting
in_waiting = upcoming
upcoming = getupcoming()
toprow = get_grid_toprow()
-- print(toprow, falling, in_waiting, upcoming)

-- state = {falling, toprow}
state = {}
yes_egg = false
print("fall, top", falling, toprow)
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

-- print("STATE IS ", state)

emu.pause()
press = takeAction(Q,state)

-- observe score/reward and update values
score = getscore()

-- strategy 
reward = 0
if (score_current < score) then
  reward = score - score_current
  emu.print('reward,score,current', reward, score, score_current)
  score_current = score
  updateStrategy()
end
  
-- update Q based on observations
updateQ(Q, state, press, reward)

end -- doeverything
end; -- mainloop


