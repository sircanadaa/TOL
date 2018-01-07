function init()
 rc= dbkt:exec([[
  		  CREATE TABLE mobkills(
          mk_id INTEGER NOT NULL PRIMARY KEY autoincrement,
          name TEXT default "Unknown",
          room_id INTEGER default 0); 
  		]])
 
 if rc ~= 0 then
 note (DatabaseError('dbkt'))
  end--if
end

function Add_Kill_Table( kill_table )
  if dbkt:isopen()== false then
    print ('table not open')
    return
  end --if 
   DebugNote(kill_table.name)
   DebugNote(kill_table.room_id)
  if dbkt:isopen() then
   -- print ("database is open")
  end--if
  rc = nil
  stmt1 = 'select name, room_id, count(*) as count from mobkills where name = %s and room_id = %s order by count'
  stmt1 = string.format(stmt1, fixsql(kill_table.name), fixsql(kill_table.room_id))
  for rows in dbkt:nrows(stmt1) do
    if tonumber(rows.count) >20 then
      DebugNote(true)
      DebugNote(rows.count)
      return
    else
      DebugNote('count ='..rows.count)
    end--if
  end -- for
  room_id = tonumber(kill_table.room_id)
	stmt="INSERT INTO mobkills(name, room_id) VALUES(%s,%s);"
  stmt = string.format(stmt, fixsql(kill_table.name), fixsql(kill_table.room_id))
  DebugNote(kill_table.name)
	rc= dbkt:exec(stmt)
	--print (rc)
  if rc ~= 0 then
  Note ( DatabaseError('dbkt'))
  end--if
end

function Clean_Kill_Table( )
  local stmt = {
  --stmt1 = 'select room_id, name , count(*) as count from mobkills group by name, room_id   having count(*) > 10 order by count',
    "delete from mobkills where name=''",
    "delete from mobkills where name like 'oes%'",
    "delete from mobkills where name like 'eteor%'",
    "delete from mobkills where name like 'unders%'",
    "delete from mobkills where name like 'xter%'",
    "delete from mobkills where name like 'unknown%'",
    "delete from mobkills where name like '%UNBelievable%'",
    "delete from mobkills where name like '%unthi%'",
    "delete from mobkills where name like 'up%'",
    "delete from mobkills where name like'nnih%'",
    "delete from mobkills where name like'vapor%'",
    "delete from mobkills where name like'upt%'",
    "delete from mobkills where name like'hatter%'",
    "delete from mobkills where name like'laughters%'",
    "delete from mobkills where name like'vapor%'",
    "delete from mobkills where name like'astes%'",
    "delete from mobkills where name like'remat%'"}
  for i,v in pairs(stmt) do
    print ('Running: '..v)
    rc= dbkt:exec(v)
    --print (rc)
    if rc ~= 0 then
      Note ( DatabaseError('dbkt'))
    end--if
  end
end

function fixsql (s)
   if s then
      return "'" .. (string.gsub (s, "'", "''")) .. "'" -- replace single quotes with two lots of single quotes
   else
      return "NULL"
   end -- if
end -- fixsql

