package.path = "../?.lua;" .. package.path

tableUtil = require("lib.table")
turtleUtil = require("lib.turtleutil")

-- Set the width and height of each step
local args = {...}

local saveTable = tableUtil.saveTable
local dump = tableUtil.dump

local setRotation = turtleUtil.setRotation
local Rotation = turtleUtil.Rotation
local Direction = turtleUtil.Direction

local width = 3
local height = 5
local depth = 0
local enderChestModItemNames = {"enderchests:ender_chest", "enderstorage:ender_chest"}
local hasEnderChest = false
local hasDeployInventory = false
local overflowSlotMax = 13
--local overflowSlotMax = 3
local retries = 5
local moveRotation = Rotation.LEFT

local movedAlongLayer = 0
local movedUpInLayer = 0
local movedInDepth = 0

local function returnToStart()    
    if moveRotation == turtleUtil.currentRotation() then
        turtleUtil.turnAround()        
    end

    for i = 1, movedAlongLayer, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = turtleUtil.currentRotation()
        })
    end
    for i = 1, movedUpInLayer, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = Direction.DOWN
        })
    end
    setRotation(Rotation.BACKWARD)
    for i = 1, movedInDepth, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = Direction.FORWARD
        })
    end
end

local function returnToPosition()
    setRotation(Rotation.FORWARD)
    for i = 1, movedInDepth, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = false,
            direction = Direction.FORWARD
        })
    end
    for i = 1, movedUpInLayer, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = Direction.UP
        })
    end
    setRotation(moveRotation)
    for i = 1, movedAlongLayer, 1 do
        turtleUtil.safeMove({
            doDig = false,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = turtleUtil.currentRotation()
        })
    end
end

local function dropAll()
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

local function forwardItemCursor()
    local slot = turtle.getSelectedSlot()
    for i = turtle.getSelectedSlot(), 15, 1 do
        slot = i
        turtle.select(slot)
        if (turtle.getItemCount() == 0) then
            break
        end
    end
    turtle.select(1)

    if (slot > overflowSlotMax) then
        if (hasEnderChest) then
            print("Deploying ender chest")
            local maxDig = 10
            while turtle.detect() do
                turtle.dig()
                sleep(0.5)
                maxDig = maxDig - 1
                if maxDig == 0 then
                    print("Could not dig forward to place ender chest")
                    shell.exit()
                end
            end

            turtle.select(16)
            turtle.place()
            for i = 1, 16, 1 do
                turtle.select(i)
                turtle.drop()
            end
            turtle.select(16)
            turtle.dig()
            turtle.select(1)
        elseif hasDeployInventory then
            print("Dropping inventory")
            returnToStart()
            dropAll()
            returnToPosition()
        else
            -- do nothing, just overflow
        end
    else
        -- not overflowing yet
    end
end

-- forward dig
local function height1Line(moveRotation)
    for i = 1, width, 1 do
        turtleUtil.safeMove({
            doDig = true,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = moveRotation
        })
        movedAlongLayer = movedAlongLayer + 1
        forwardItemCursor()
    end
end

-- forward and upward dig
local function height2Line(moveRotation)
    for i = 1, width, 1 do
        turtleUtil.ensureDig({
            direction = Direction.UP,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true
        })
        turtleUtil.safeMove({
            doDig = true,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = moveRotation
        })
        movedAlongLayer = movedAlongLayer + 1
        forwardItemCursor()
    end
    turtleUtil.ensureDig({
        direction = Direction.UP,
        retries = retries,
        sleepTime = 0.5,
        errorOut = true
    })
    forwardItemCursor()
end

-- forward, upward, and downward dig
local function height3Line(moveRotation)
    turtleUtil.safeMove({
        doDig = true,
        retries = retries,
        sleepTime = 0.5,
        errorOut = true,
        direction = Direction.UP
    })
    movedUpInLayer = movedUpInLayer + 1
    forwardItemCursor()
    for i = 1, width, 1 do
        movedAlongLayer = movedAlongLayer + 1
        turtleUtil.ensureDig({
            direction = Direction.DOWN,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true
        })
        turtleUtil.ensureDig({
            direction = Direction.UP,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true
        })
        turtleUtil.safeMove({
            doDig = true,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = moveRotation
        })
        forwardItemCursor()
    end
    turtleUtil.ensureDig({
        direction = Direction.DOWN,
        retries = retries,
        sleepTime = 0.5,
        errorOut = true
    })
    turtleUtil.ensureDig({
        direction = Direction.UP,
        retries = retries,
        sleepTime = 0.5,
        errorOut = true
    })
    forwardItemCursor()
end

local function moveUp()
    turtleUtil.safeMove({
        doDig = true,
        retries = retries,
        sleepTime = 0.5,
        errorOut = true,
        direction = Direction.UP
    })
    movedUpInLayer = movedUpInLayer + 1
    forwardItemCursor()
end

local function buildLayerPlan()
    local height3Amount = math.floor(height / 3)
    local height2Amount = 0
    local height1Amount = 0
    local remainder = height % 3
    if remainder == 2 then
        height2Amount = 1
    elseif remainder == 1 then
        height1Amount = 1
    end

    print("Height 3 lines: " .. height3Amount)
    print("Height 2 lines: " .. height2Amount)
    print("Height 1 lines: " .. height1Amount)

    local lineSum = height3Amount + height2Amount + height1Amount
    local onOppositeSide = lineSum % 2 == 1
    local plan = {}

    if onOppositeSide then
        print("Ending on opposite side")
    else
        print("Ending on starting side")
    end

    table.insert(plan, function() 
        movedAlongLayer = 0
        movedUpInLayer = 0
    end)

    table.insert(plan, function() 
        turtleUtil.safeMove({
            doDig = true,
            retries = retries,
            sleepTime = 0.5,
            errorOut = true,
            direction = Direction.FORWARD
        }) 
        movedInDepth = movedInDepth + 1
    end)

    table.insert(plan, function() setRotation(moveRotation) end)

    if (height3Amount > 0) then
        table.insert(plan, function() 
            for i = 1, height3Amount do 
                height3Line(turtleUtil.currentRotation())
                turtleUtil.turnAround()

                -- go up if there is more height 3 lines to do
                if i < height3Amount then
                    moveUp()
                    moveUp()
                    -- last move up is done by heigh3Line
                end
            end
        end)
    end

    if (height2Amount > 0) then
        table.insert(plan, function() 
            if (height3Amount > 0) then
                moveUp()
                moveUp()
            end

            height2Line(turtleUtil.currentRotation())
            turtleUtil.turnAround()

            if (height1Amount > 0) then
                moveUp()
            end
        end)
    end

    if (height1Amount > 0) then
        table.insert(plan, function() 
            if (height3Amount > 0 and height2Amount == 0) then
                moveUp()
                moveUp()
            elseif (height2Amount > 0) then
                moveUp()
            end

            height1Line(turtleUtil.currentRotation())
            turtleUtil.turnAround()
        end)
    end

    table.insert(plan, function() 
        -- Move back down to the base of the layer
        print("Moving down " .. (height - 1 + height1Amount) .. " times")
        for i = 1, height - 2 do
            turtleUtil.safeMove({
                doDig = true,
                retries = retries,
                sleepTime = 0.5,
                errorOut = true,
                direction = Direction.DOWN
            })
            movedUpInLayer = movedUpInLayer - 1
        end
        if height1Amount == 1 then
            turtleUtil.safeMove({
                doDig = true,
                retries = retries,
                sleepTime = 0.5,
                errorOut = true,
                direction = Direction.DOWN
            })
            movedUpInLayer = movedUpInLayer - 1
        end
    end)

    -- Move back to the starting side
    if onOppositeSide then
        table.insert(plan, function() 
            for i = 1, width do
                turtleUtil.safeMove({
                    doDig = true,
                    retries = retries,
                    sleepTime = 0.5,
                    errorOut = true,
                    direction = turtleUtil.currentRotation()
                })
            end
        end)
    end

    table.insert(plan, function() setRotation(Rotation.FORWARD) end)

    return plan
end

-- Function to build a single step
local function boreLayer(plan)
    for _, operation in ipairs(plan) do
        operation()
    end
end

-- Function to build the entire staircase
local function bore()
    local plan = buildLayerPlan()
    for d = 1, depth, 1 do
        print("Boring layer " .. d .. " of " .. depth)
        boreLayer(plan)
    end
end

local function askParameters()
    write("Width: ")
    width = tonumber(read())

    if width < 1 then
        print("width must be at least 1")
        shell.exit()
    end

    write("Height: ")
    height = tonumber(read())

    if height < 1 then
        print("Height must be at least 1")
        shell.exit()
    end

    write("Depth: ")
    depth = tonumber(read())

    if depth < 1 then
        print("Depth must be at least 1")
        shell.exit()
    end

    write("Left or Right (l/r)?")
    local lor_pre = read()

    write("Has deploy inventory (y/n)?")
    local deploy_pre = read()
    if deploy_pre == "y" then
        hasDeployInventory = true
    elseif deploy_pre == "n" then
        hasDeployInventory = false
    else
        print("invalid input")
        shell.exit()
    end

    -- valid input?
    if lor_pre == "r" then
        moveRotation = Rotation.RIGHT
    elseif lor_pre == "l" then
        -- do nothing
    else
        print("invalid input")
        shell.exit()
    end
end

-- Search for ender chest
local function findEnderChest()
    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)
        if item ~= nil then
            for j = 1, #enderChestModItemNames, 1 do
                if item.name == enderChestModItemNames[j] then
                    return true
                end
            end
        end
    end
    return false
end

hasEnderChest = findEnderChest()
if hasEnderChest then
    print("Found ender chest")
end

askParameters()
bore()
