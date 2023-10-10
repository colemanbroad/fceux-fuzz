
-- yoshi by coleman broaddus
-- Oct 7 2023


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
  thousands =  memory.readbyte(0x05F0)
  hundreds =  memory.readbyte(0x05F1)
  tens =  memory.readbyte(0x05F2)
  ones =  memory.readbyte(0x05F3)
  score = 1000 * thousands + 100 * hundreds + 10 * tens + 1 * ones

  position = memory.readbyte(0x0440)
  n_eggs = memory.readbyte(0x0532)

  gc = get_grid_count()
  space_score = 10 * (7*4 - gc)^0.5

  grid_height = get_grid_height()
  if (grid_height < 2) then 
    print('score 0')
    return 0 
  end 
  -- space_score = -300 end
  -- if (gc > 20) then space_score = -10 end

  return 100 * n_eggs + score + space_score
end

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
  return make_press(bs)
end

local function has_value (tab, val)
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
  emu.print("g_idx = ", g_idx)
  restart_count = 0
  savestate.load(gstates[g_idx][1])
  score_current = gstates[g_idx][2]
  global_count = gstates[g_idx][3]
end



score_current = 0;
next_current = {0,0,0,0}
global_count = 0
restart_count = 0

gs = {}


-- tracks gamestate, score and global count
-- initialize all states to same root
Nstates = 1
gstates = {}
for i=1,Nstates do
  gstates[i] = {savestate.object(), 0, 0}
  savestate.save(gstates[i][1])
end

g_idx = 1
emu.print("g_idx = ", g_idx)

falling = {0,0,0,0}
in_waiting = {0,0,0,0}
upcoming = {0,0,0,0}

-- next = getupcoming()
-- if (not arrayEqual(next_current, next)) then
--   -- emu.print(next, next_current)
--   next_current = next
-- end

while (true) do

global_count = global_count + 1
restart_count = restart_count + 1

score = getscore()
if (score_current < score) then
  emu.print("score = ", score)
  score_current = score
  savestate.save(gstates[g_idx][1])
  gstates[g_idx][2] = score
  gstates[g_idx][3] = global_count
end


if (dead()) then
  emu.print("GAMEOVER")
  newstate()
  -- restart_count = 1001
end


press = randompress()

toprow = get_grid_toprow()
if (not arrayEqual(upcoming, getupcoming())) then
  falling = in_waiting
  in_waiting = upcoming
  upcoming = getupcoming()
  print(toprow, falling, in_waiting, upcoming)
end

-- if (not arrayEqual(upcoming_falling, upcoming)) then 
-- end

-- The upcoming eventually falls and is replaced by the next upcoming before it hits the toprow.
-- We don't have a way of observing the falling blocks, but we can remember who's falling by remembering
-- the previous toprow. 


for i=1,4 do
  if (falling[i] == toprow[i]) then 
      press = make_press({0,1,0,0,0,0,0,0}) 
      -- countdown = 15
    end -- just down
end

joypad.set(1, press)
emu.frameadvance()

end;
