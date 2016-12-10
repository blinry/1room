function parseRoom(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "wall"
    legend["="] = "window"
    legend["^"] = "door_top"
    legend[">"] = "door_right"
    legend["v"] = "door_bottom"
    legend["<"] = "door_left"
    legend["."] = "floor"

    local room = {}
    room.floor = {}
    room.horizontal = {}
    room.vertical = {}
    room.name = string.match(string.match(filename, "[^/]+.txt"), "[^/.]+")

    for i = 1,100 do
        room.floor[i] = {}
        room.horizontal[i] = {}
        room.vertical[i] = {}

        for j = 1,100 do
            room.floor[i][j] = "empty"
            room.horizontal[i][j] = "empty"
            room.vertical[i][j] = "empty"
        end
    end

    local f = io.open(filename)

    local horizontal = true
    local lineNr = 1
    while true do
        local line = f:read()
        if line == nil then noObjectList() end

        if line == "---" then
            break
        end

        if horizontal then
            for i = 2, #line, 2 do
                local c = line:sub(i,i)
                room.horizontal[i/2][1+(lineNr-1)/2] = legend[c]
            end
        else
            for i = 1, #line, 2 do
                local c = line:sub(i,i)
                room.vertical[1+(i-1)/2][lineNr/2] = legend[c]
            end
            for i = 2, #line, 2 do
                local c = line:sub(i,i)
                room.floor[i/2][lineNr/2] = legend[c]
            end
        end
        horizontal = not horizontal
        lineNr = lineNr+1
    end

    room.objects = {}
    local x = 12
    local y = 1
    while true do
        local line = f:read()

        if line == nil then
            break
        end

        amount, what = string.match(line, "([0-9]+) (.+)")

        for j = 1, tonumber(amount) do
            table.insert(room.objects, {what = what, x = x, y = y, r = 1})
        end

        x = x+2
        if x > 18 then
            x = 12
            y = y+3
        end
    end

    return room
end

function loadRoom(i)
    room = rooms[i]
    objects = room.objects
    checkRules()
end

function drawRoom()
    for x = 1,100 do
        for y = 1,100 do
            if room.floor[x][y] == "floor" then
                love.graphics.setColor(255, 255, 255)
                love.graphics.draw(images.parquet, tilesize*x, tilesize*y, 0)
            end

            local top = room.horizontal[x][y]
            if top == "wall" then
                love.graphics.setColor(255, 255, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x+tilesize, tilesize*y)
            elseif top == "window" then
                love.graphics.setColor(0, 0, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x+tilesize, tilesize*y)
            elseif top == "door_top" then
                love.graphics.setColor(255, 0, 0)
                love.graphics.arc("line", tilesize*x, tilesize*y, tilesize, 0, -math.pi/2)
            elseif top == "door_bottom" then
                love.graphics.setColor(255, 0, 0)
                love.graphics.arc("line", tilesize*x, tilesize*y, tilesize, 0, math.pi/2)
            end

            local left = room.vertical[x][y]
            if left == "wall" then
                love.graphics.setColor(255, 255, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
            elseif left == "window" then
                love.graphics.setColor(0, 0, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
            elseif left == "door_right" then
                love.graphics.setColor(255, 0, 0)
                love.graphics.arc("line", tilesize*x, tilesize*y, tilesize, 0, math.pi/2)
                --love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
            elseif left == "door_left" then
                love.graphics.setColor(255, 0, 0)
                love.graphics.arc("line", tilesize*x, tilesize*y, tilesize, math.pi/2, math.pi)
                --love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
            end
        end
    end
end

function drawDebug()
    for x = 1,100 do
        for y = 1,100 do
            if occupied(x, y) then
                love.graphics.setColor(0, 0, 255)
                love.graphics.circle("fill", tilesize*(x+0.5), tilesize*(y+0.5), tilesize/10)
            end
        end
    end
end

function drawObject(object)
    local what = object.what
    local x = object.x
    local y = object.y
    local r = object.r

    love.graphics.push()
    love.graphics.translate(tilesize*(x+0.5), tilesize*(y+0.5))
    love.graphics.rotate(r/2*math.pi)

    if object.dirty then
        love.graphics.setColor(255, 0, 0)
    else
        love.graphics.setColor(255, 255, 255)
    end

    if what == "plant" then
        love.graphics.draw(images.plant, -tilesize/2, -tilesize/2, 0)
    elseif what == "armchair" then
        love.graphics.draw(images.armchair, -tilesize/2, -tilesize/2, 0)
    elseif what == "officechair" then
        love.graphics.draw(images.officechair, -tilesize/2, -tilesize/2, 0)
    elseif what == "table" then
        love.graphics.draw(images.couchtable, -tilesize/2, -tilesize/2, 0)
    elseif what == "shelf" then
        love.graphics.draw(images.bookshelf, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "couch" then
        love.graphics.draw(images.couch, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "desk" then
        love.graphics.draw(images.desk, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "bed" then
        love.graphics.draw(images.bed, -tilesize/2, 3*tilesize/2, -math.pi/2)
    else
        unknownObjectType()
    end
    love.graphics.pop()
end

function checkRules()
    nopeText = ""

    for i=1,#objects do
        objects[i].dirty = not allowed(objects[i])
    end

    for x = 1,100 do
        for y = 1,99 do
            what = occupied(x,y)
            if what then
                if (#what > 1 and room.floor[x][y] == "floor") then
                    for i=1,#what do
                        what[i].dirty = true
                        nope("Objects must not overlap.")
                    end
                else
                    if room.floor[x][y] == "empty" then
                        what[1].dirty = true
                        nope("All objects must be inside of the room.")
                    end
                    -- TODO: degenerate walls
                end
            end
        end
    end
end

function occupies(object, x, y)
    local what = object.what
    local ox = round(object.x)
    local oy = round(object.y)
    local r = object.r

    if what == "plant" or what == "armchair" or what == "officechair" or what == "table"  then
        return ox == x and oy == y
    elseif what == "shelf" or what == "couch" or what == "desk" then
        return (x == ox and y == oy) or
            (r == 0 and x == ox+1 and y == oy) or
            (r == 1 and x == ox and y == oy+1) or
            (r == 2 and x == ox-1 and y == oy) or
            (r == 3 and x == ox and y == oy-1)
    elseif what == "bed" then
        if r == 0 then
            return x >= ox and x <= ox+1 and y >= oy and y <= oy+1
        elseif r == 1 then
            return x >= ox-1 and x <= ox and y >= oy and y <= oy+1
        elseif r == 2 then
            return x >= ox-1 and x <= ox and y >= oy-1 and y <= oy
        elseif r == 3 then
            return x >= ox and x <= ox+1 and y >= oy-1 and y <= oy
        end
    else
        unknownObjectType()
    end
end

function allowed(object)
    local ox = round(object.x)
    local oy = round(object.y)

    if object.what == "armchair" then
        if not (object.r == 1 and accessible(ox+1, oy)
                or object.r == 2 and accessible(ox, oy+1)
                or object.r == 3 and accessible(ox-1, oy)
                or object.r == 0 and accessible(ox, oy-1)) then
            nope("An armchair needs to be accessible from the front.")
            return false
        end

    elseif object.what == "couch" or object.what == "shelf" then
        if not (object.r == 0 and (accessible(ox, oy-1) or accessible(ox+1, oy-1))
                or object.r == 1 and (accessible(ox+1, oy) or accessible(ox+1, oy+1))
                or object.r == 2 and (accessible(ox, oy+1) or accessible(ox-1, oy+1))
                or object.r == 3 and (accessible(ox-1, oy) and accessible(ox-1, oy-1))) then
            nope("A "..object.what.."'s complete front needs to be accessible.")
            return false
        end
    elseif object.what == "officechair" then
        return accessible(ox+1,oy) or accessible(ox-1, oy) or accessible(ox, oy+1)  or accessible(ox,oy-1)  
    elseif object.what == "table" then
        ok = false
        what = occupied(ox+1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 1 then
             ok = true 
          end
        end
        what = occupied(ox-1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 3 then
            ok = true
          end
        end
        what = occupied(ox,oy+1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 0 then
            ok = true
          end
        end
        what = occupied(ox,oy-1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 2 then
            ok = true
          end
        end
        return ok
    elseif object.what == "bed" then
        if not ( object.r == 0 and (accessible(ox, oy-1) or accessible(ox+1, oy-1) or accessible(ox, oy+2) or accessible(ox+1, oy+2))
                 or object.r == 1 and (accessible(ox+1, oy) or accessible(ox+1, oy+1) or accessible(ox-2, oy) or accessible(ox-2, oy+1))
                 or object.r == 2 and (accessible(ox, oy+1) or accessible(ox-1, oy+1) or accessible(ox, oy-2) or accessible(ox-1, oy-2))
                 or object.r == 3 and (accessible(ox-1, oy) or accessible(ox-1, oy-1) or accessible(ox+2, oy) or accessible(ox+2, oy-1))) then
            nope("A bed needs to be accessible from the side.")
            return false
        end
    else
        return true
    end
end

function occupied(x, y)
    o = {}
    if room.horizontal[x][y] == "door_bottom" or room.horizontal[x][y+1] == "door_top" or room.vertical[1][2] == "door_right" then--or room.vertical[x+1][y] == "door_left" then
    return o
    end
    for i = 1, #objects do
        if occupies(objects[i], x, y) then
            table.insert(o, objects[i])
        end
    end
    if #o > 0 then
        return o
    else
        return false
    end
end

function accessible(x, y)
    return x > 0 and y > 0 and room.floor[x][y] == "floor" and not occupied(x,y)
end

function nope(text)
    nopeText = text
end
