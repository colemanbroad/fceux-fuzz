
local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end


function printQ(Q)
  -- emu.print("PRINTING Q\n")
  local total = 0
  local temp = {}
  local idx = 1
  for st, action_dict in pairs(Q) do
    vprint(2, "--------------------------------")
    for act, valcount in pairs(action_dict) do
      -- print()
      val, count = unpack(valcount)
      -- total = total + count
      -- temp[idx] = (temp[idx] or 0) + count
      emu.print(st, act, val, count)
      if count>1 then vprint(2, st, act, val, count) end
    end
    -- idx = idx + 1
  end
  -- emu.print("Total: ", total)
  -- emu.print("temp", temp)
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


function old_score_extras()
  score = get_score()
  position = memory.readbyte(0x0440)
  n_eggs = memory.readbyte(0x0532)

  gc = get_grid_count()
  grid_count_score = 10 * (7*4 - gc)^0.5

  grid_height = get_grid_height()
  if (grid_height < 3) then 
    print('score 0')
    return 0 
  end 
  -- grid_count_score = -300 end
  -- if (gc > 20) then grid_count_score = -10 end

  return 100 * n_eggs + score + grid_count_score
end



