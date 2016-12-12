require "slam"
require "helpers"
require "game"

scale = 4 -- how many screen pixels are the length of one game pixel?
tilesize = 16 -- what is the length of a tile in game pixels?

function love.load()
    boringLoad() -- see helpers.lua

    music.roccow_welcome:setVolume(0.5)
    soundtrack = love.audio.play(music.roccow_welcome)

    setScale(4)

    love.graphics.setFont(fonts.m5x7[16])

    rooms = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("levels")) do
        if string.match(filename, ".txt$") then
            table.insert(rooms, parseRoom("levels/"..filename))
        end
    end

    mode = "title"

    holding = nil
end

function love.keypressed(key)
    if key == "escape" then
        if mode == "game" then
            mode = "menu"
            love.audio.play(sounds.back)
            soundtrack:setVolume(0.5)
        elseif mode == "menu" then
            mode = "title"
            love.audio.play(sounds.back)
        elseif mode == "title" then
            love.audio.play(sounds.back)
            love.event.quit()
        end
    elseif key == "1" then
        setScale(1)
    elseif key == "2" then
        setScale(2)
    elseif key == "3" then
        setScale(4)
    elseif key == "4" then
        setScale(8)
    elseif key == "left" then
        if mode == "game" then
            loadRoom(1 + (((currentRoom-2)) % #rooms))
        end
    elseif key == "right" then
        if mode == "game" then
            loadRoom(1 + (((currentRoom+0)) % #rooms))
        end
    elseif key == "m" then
        if soundtrack:getVolume() > 0 then
            soundtrack:setVolume(0)
        else
            soundtrack:setVolume(0.5)
        end
    end
end

function love.mousepressed(x, y, button, touch)
    if mode == "game" then

        tx = math.floor(x/scale/tilesize)
        ty = math.floor(y/scale/tilesize)-1

        if x/scale >= 106 and x/scale <= 306 and y/scale >= 5 and y/scale <= 25 then
          if room.story[2] ~= nil then
            table.remove(room.story, 1)
          end
        end

        if button == 1 then
            what = occupied(tx, ty)
            if what then
                holding = what[1]
                love.audio.play(sounds.pickup)
            end
        end
        if button == 2 then
            if holding then
                holding.r = (holding.r + 1) % 4
                love.audio.play(sounds.rotate)
            else
                what = occupied(tx, ty)
                if what then
                    for i=1,#what do
                        what[1].r = (what[1].r + 1) % 4
                        love.audio.play(sounds.rotate)
                    end
                end
            end
        end

        checkRules()
    elseif mode == "title" then
        mode = "menu"
        love.audio.play(sounds.menu)
    elseif mode == "menu" then
        if button == 1 then
            if menuIndex() then
                loadRoom(menuIndex())
                mode = "game"
                love.audio.play(sounds.menu)
            end
        end
    end
end

function love.mousereleased(x, y, button, touch)
    if mode == "game" then
        if button == 1 then
            if holding then
                holding.x = round(holding.x)
                holding.y = round(holding.y)
                holding = nil
                love.audio.play(sounds.drop)
            end
        end

        checkRules()
    end
end

function love.mousemoved(x, y, dx, dy, touch)
    if mode == "game" then
        if holding then
            holding.x = round(x/scale/tilesize-0.5)
            holding.y = round(y/scale/tilesize-0.5-1)
        end

        checkRules()
    end
end

function love.draw()
    love.graphics.scale(scale, scale)

    if mode == "game" then

        love.graphics.setColor(50, 50, 50)
        love.graphics.rectangle("fill", 12*tilesize-4, 2*tilesize-4, 7*tilesize+8, 7*tilesize+8)

        if room.solved then
            room.story = {}
            if room.won[1] ~= nil then
        love.graphics.setColor(91, 110, 225)
              love.graphics.rectangle("fill", 106, 5, 200, 20)
              if room.won[2] ~= nil then
	        love.graphics.setColor(0, 0, 0)
                love.graphics.polygon("fill", 295,18, 305, 18, 300, 23) 
              end
              love.graphics.setColor(255, 255, 255)
              love.graphics.print(room.won[1], 110, 8)
            end

            if currentRoom == 1 then
                love.graphics.setColor(91, 110, 225)
                love.graphics.print("Press escape to return to the level selection.", 10, 160)
            end

            local allSolved = true
            for i=1,#rooms do
                if not rooms[i].solved then
                    allSolved = false
                end
            end

            if allSolved then
                love.graphics.setColor(215, 123, 186)
                love.graphics.print("Thanks for playing! <3 Want to design your own levels?", 10, 150)
                love.graphics.print("They are just text files, check out the source code!", 10, 163)
            end

            love.graphics.setColor(0, 200, 0)
        else
            love.graphics.setColor(255, 255, 255)
        end

        love.graphics.print(currentRoom..": "..room.name, 16, 8)

        if room.story[1] ~= nil then
        love.graphics.setColor(91, 110, 225)
          love.graphics.rectangle("fill", 106, 4, 202, 20)
          if room.story[2] ~= nil then
	    love.graphics.setColor(0, 0, 0)
            love.graphics.polygon("fill", 295,17, 305, 17, 300, 22) 
          end
          love.graphics.setColor(255, 255, 255)
          love.graphics.print(room.story[1], 110, 8)
        end

        love.graphics.translate(0, 16)

        drawRoom()
        for i = 1, #objects do
            drawObject(objects[i])

            local w = occupied(objects[i].x,objects[i].y)
            if w and #w > 1 then
                love.graphics.setColor(255, 255, 255)
                love.graphics.print("x"..#w, (objects[i].x+1)*tilesize+2, objects[i].y*tilesize)
            end
        end
        --drawDebug()

        love.graphics.setColor(255, 0, 0)

        tx = math.floor(round(love.mouse.getX())/scale/tilesize)
        ty = math.floor(round(love.mouse.getY())/scale/tilesize)-1

        what = occupied(tx,ty)

        love.graphics.setFont(fonts.m3x6[16])
        if what then
          for i = 1, #what do
            if what[i].errorStr ~= nil then
              for j = 1, #what[i].errorStr do
                love.graphics.print(what[i].errorStr[j], 16, 109 + 10 * i + 10 * j)
              end
            end
          end
        end
        love.graphics.setFont(fonts.m5x7[16])
    elseif mode == "title" then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(images.title, 0, 0)
    elseif mode == "menu" then
        love.graphics.setColor(91, 110, 225)
        love.graphics.printf("SELECT A LEVEL", 0, 8, 320, "center")

        love.graphics.setColor(50, 50, 50)
        love.graphics.setFont(fonts.m3x6[16])
        love.graphics.printf("Music: \"Welcome!\" by RoccoW, cc-by-sa 4.0. Press m to mute. http://freemusicarchive.org/music/RoccoW/_1035/ ", 0, 145, 320, "center")
        love.graphics.setFont(fonts.m5x7[16])

        local x = 16
        local y = 32
        for i=1,#rooms do
            if menuIndex() == i then
                if rooms[i].solved then
                    love.graphics.setColor(0, 200, 0)
                else
                    love.graphics.setColor(255, 255, 255)
                end
            else
                if rooms[i].solved then
                    love.graphics.setColor(0, 100, 0)
                else
                    love.graphics.setColor(100, 100, 100)
                end
            end
            love.graphics.print(i..": "..rooms[i].name, x, y)
                y = y+23
            if y > 140 then
                x = x+85+16
                y = 32
            end
        end
    end
end
