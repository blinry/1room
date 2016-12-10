function loadRoom(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "wall"
    legend["="] = "window"
    legend["^"] = "door_top"
    legend["."] = "floor"

    local room = {}
    room.floor = {}
    room.horizontal = {}
    room.vertical = {}

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
        if line == nil then break end

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

    return room
end

function drawRoom(room)
    for x = 1,100 do
        for y = 1,100 do
            if room.floor[x][y] == "floor" then
                love.graphics.setColor(100, 100, 100)
                love.graphics.rectangle("fill", tilesize*x, tilesize*y, tilesize, tilesize)
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
            end

            local left = room.vertical[x][y]
            if left == "wall" then
                love.graphics.setColor(255, 255, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
            elseif left == "window" then
                love.graphics.setColor(0, 0, 255)
                love.graphics.line(tilesize*x, tilesize*y, tilesize*x, tilesize*y+tilesize)
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
    if what == "plant" then
        love.graphics.setColor(0, 200, 0)
        love.graphics.circle("fill", 0, 0, tilesize/2)
    elseif what == "shelf" then
        love.graphics.setColor(50, 50, 50)
        love.graphics.rectangle("fill", -tilesize/2+tilesize/10, -tilesize/2+tilesize/10, tilesize*2-2*tilesize/10, tilesize-2*tilesize/10)
    else
        unknownObjectType()
    end
    love.graphics.pop()
end

function occupies(object, x, y)
    local what = object.what
    local ox = object.x
    local oy = object.y
    local r = object.r

    if what == "plant" then
        return ox == x and oy == y
    elseif what == "shelf" then
        return (x == ox and y == oy) or
            (r == 0 and x == ox+1 and y == oy) or
            (r == 1 and x == ox and y == oy+1) or
            (r == 2 and x == ox-1 and y == oy) or
            (r == 3 and x == ox and y == oy-1)
    else
        unknownObjectType()
    end
end

function occupied(x, y)
    for i = 1, #objects do
        if occupies(objects[i], x, y) then
            return objects[i]
        end
    end
    return false
end
