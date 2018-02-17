require "DBUtils"

local db_str = GetPluginInfo (GetPluginID (), 20) .. 'KillTable.db'
local aard_db_str = GetInfo (66) ..'Aardwolf.db'


function area_table_builder(name, line, wildcards, styles)
    --tprint(wildcards)
    local area_row = {
    afrom = Trim(wildcards[1]),
    ato = Trim(wildcards[2]),
    alock = wildcards[3],
    builder = Trim(wildcards[4]),
    name = Trim(wildcards[5])
    }
    local count = check_area_exists(area_row.name)
    if count == 0 then
        insert_area_row(area_row)
    end
end


function check_area_exists(area)
    local query = string.format('select count(1) as count from areas where name = %s',
        fixsql(area))
    local count = 0
    for _, row in ipairs(db_query(db_str, query)) do 
        count = row.count
        --print(count)
    end
    return tonumber(count)
end


function insert_area_row(area_table)
    local keyword = ''
    local query = string.format('select uid from areas where lower(name) like %s',
     fixsql(string.lower('%'..area_table.name..'%')))
    print(fixsql(string.lower('%'..area_table.name..'%')))
    for _, row in ipairs(db_query(aard_db_str, query)) do
        keyword = row.uid
        print(keyword)
    end
    ins_stmt = string.format(
        [[INSERT INTO areas (keyword, name, afrom, ato, alock, builder)
        VALUES
        (%s,%s,%s,%s,%s,%s)]], fixsql(keyword) or '', fixsql(area_table.name),
        fixsql(area_table.afrom), fixsql(area_table.ato),
        fixsql(area_table.alock), fixsql(area_table.builder) )
    print(ins_stmt)
    db_exec(db_str, ins_stmt)
end


function check_area_table()
    print('checking table')
        rc = db_exec(db_str,'select count(1) from areas')
        if rc~= 0 then 
            print('need to build table')
            build_area_table()
        end
end


function build_area_table()
rc = db_exec(db_str, [[
    drop table if exists areas;
    CREATE TABLE areas (
    area_id   INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    keyword   TEXT NOT NULL ,
    name  TEXT NOT NULL ,
    afrom INTEGER DEFAULT 1,
    ato  INTEGER DEFAULT 1,
    alock INTEGER DEFAULT 0,
    builder   TEXT);]])
end