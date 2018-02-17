require "DBUtils"
function lookup(name1, line, wildcards)--Looks up mobs from the CPmobs database based off of name, level, area, or room
  local modifiers = {'name', 'level', 'area', 'room'}
  local ptr = 0
  local ptrkeep = 1
  local mobbuff ={}
  local decideQ = 0
  local level = 0
  local modanddata = {}
  for i, p in pairs (modifiers) do
    local x, a = 0
   a,x = string.find(wildcards[1], p.." ")
    if a ~= nil and x ~= nil then 
      
        
        tmp = string.sub (wildcards[1], x)
        ptr = string.len(tmp)
        for j, k in pairs(modifiers) do
          y, w = string.find(tmp, k.." ")
          if y~= nil and y< ptr then
            -- print (y)
            ptr = y -2
          end
        end
        modanddata[i] = string.sub(tmp, 2, ptr)
        ptr = 1
      if x ~= nil and x > ptr then 
        ptr = x 
      end
       ptr = 0
    else 
      modanddata [i] = ""
    end
  end
  -- modanddata will always be in the form 1 = name, 2 = level, 3 = area, 4 = room

  if modanddata[2] ~= "" and tonumber(modanddata[2]) == nil then
    Note("Level must be a number.")
    return
  end
  
  query = "SELECT * FROM CpMobs"
  first = true
  for i=1,#modifiers do
    if modanddata[i] ~= "" then
      if not first then
        query = query .. " and "
      else
        query = query .. " where "
        first = false
      end
      if modifiers[i] == "name" then
        query = query .. "name like " .. fixsql(modanddata[i])
      elseif modifiers[i] == "level" then
        query = query .. "level <= " .. (modanddata[i]+11) .. " and level >= " .. (modanddata[i]-11)
      elseif modifiers[i] == "area" then
        query = query .. "area_name like " .. fixsql(modanddata[i])
      elseif modifiers[i] == "room" then
        query = query .. "room_name like " .. fixsql(modanddata[i])
      end
    end
  end
  
  DebugNote("tlookup query: " .. query)

  mobbuff = db_query(dbkt, query) 
  if #mobbuff<1 and modanddata[1] ~= "" and modanddata[2] == "" and modanddata[3] == "" and modanddata[4] == "" then
    DebugNote("No mobs found! Checking mobkills table...")
    q = "SELECT * FROM mobkills where name like " .. fixsql(modanddata[1]) .. " group by room_id"
    for _, p in ipairs(db_query(dbkt, q)) do
      table.insert(mobbuff, p)
    end
  end
  if #mobbuff<1 then
    Note("OKYDOKY BOSS NOTHING TO SEE HERE")
    Note("seriously though we found nothing")
    return
  end
end