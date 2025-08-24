package.path = "../?.lua;" .. package.path

tableUtil = require("lib.table")

-- Set the width and height of each step
local args = {...}

local width = 3
local height = 5
local depth = 0
local lrFlip = false
local udFlip = false
local enderChestModItemNames = {"enderchests:ender_chest", "enderstorage:ender_chest"}
local hasEnderChest = false
local digCounter = 0
local digTillCursorForwardMax = 10
local overflowSlotMax = 8

local saveTable = tableUtil.saveTable
local dump = tableUtil.dump

local function tryPlatform(conditional)
    if (conditional == false) then
        return
    end
    if (turtle.detectDown() == false) then
        for i = 1, 15, 1 do
            local result, why = turtle.placeDown()
            if (result == false) then
                local slot = turtle.getSelectedSlot() + 1
                if (slot > 15) then
                    slot = 1
                end
                turtle.select(slot)
            else
                break
            end
        end
    end
end

local function forwardItemCursor()
    digCounter = digCounter + 1
    if (digCounter == digTillCursorForwardMax) then
        digCounter = 0
    else
        return
    end

    local slot = turtle.getSelectedSlot()
    for i = turtle.getSelectedSlot(), 15, 1 do
        turtle.select(i)
        slot = i
        if (turtle.getItemCount() == 0) then
            break
        end
    end

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
        end
    else
        print("Not overflowing yet")
    end
    turtle.select(1)
end

local function turnLeft()
    if (lrFlip) then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end
end

local function goUp()
    if (not udFlip) then
        return turtle.up()
    else
        return turtle.down()
    end
end

local function goDown()
    if (not udFlip) then
        return turtle.down()
    else
        return turtle.up()
    end
end

local function turnRight()
    if (lrFlip) then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end
end

local function safeDig()
    -- while turtle.detect() do
    --     turtle.dig()
    --     sleep(0.5)
    -- end
    turtle.dig()
    forwardItemCursor()
end

local safeDigDown = nil
local safeDigUp = nil

safeDigUp = function(fromFlip)
    if (udFlip and not fromFlip) then
        return safeDigDown(true)
    end
    -- while turtle.detectUp() do
    --     turtle.digUp()
    --     sleep(0.5)
    -- end
    turtle.digUp()
end

safeDigDown = function(fromFlip)
    if (udFlip and not fromFlip) then
        return safeDigUp(true)
    end
    -- while turtle.detectDown() do
    --     turtle.digDown()
    --     sleep(0.5)
    -- end
    turtle.digDown()
end

local function safeForward()
    local max = 10
    while turtle.forward() == false do
        safeDig()
        max = max - 1
        if max == 0 then
            print("Could not move forward")
            shell.exit()
        end
    end
end

local function safeUp()
    local max = 10
    while goUp() == false do
        safeDigUp(false)
        max = max - 1
        if max == 0 then
            print("Could not move up")
            shell.exit()
        end
    end
end

local function safeDown()
    local max = 10
    while goDown() == false do
        safeDigDown(false)
        max = max - 1
        if max == 0 then
            print("Could not move down")
            shell.exit()
        end
    end
end

local function flipLR()
    lrFlip = not lrFlip
end

local function flipUD()
    udFlip = not udFlip
end

local function turnAround()
    turnRight()
    turnRight()
end

-- forward dig
local function line1(inject, ...)
    for i = 1, width - 1, 1 do
        inject(...)
        safeForward()
    end
end

-- forward and upward dig
local function line2(inject, ...)
    for i = 1, width - 1, 1 do
        inject(...)
        safeDigUp(false)
        safeForward()
    end
    safeDigUp(false)
end

-- forward, upward, and downward dig
local function line3()
    safeUp()
    for i = 1, width - 1, 1 do
        safeDigDown(false)
        safeDigUp(false)
        safeForward()
    end
    safeDigDown(false)
    safeDigUp(false)
end

local function buildLayerPlan()
    local plan = {}
    plan["line3"] = {
        count = math.floor(height / 3),
        func = line3
    }
    plan["line2"] = {
        count = math.max(0, math.floor((height - plan["line3"].count * 3) / 2)),
        func = line2
    }
    plan["line1"] = {
        count = math.max(0, height - plan["line3"].count * 3 - plan["line2"].count * 2),
        func = line1
    }

    -- postLine functions
    if plan["line1"].count > 0 then
        plan["line1"].cont = function()
            if plan["line2"].count + plan["line3"].count > 0 then
                safeUp()
                turnAround()
            else
                turnRight()
            end
            flipLR()
        end
    end
    plan["line1"].postLine = function()
    end

    if plan["line2"].count > 0 then
        plan["line2"].cont = function()
            safeUp()
            turnRight()
            if plan["line3"].count > 0 then
                turnRight()
                safeUp()
            end
            flipLR()
        end
    end
    plan["line2"].postLine = function()
    end

    if plan["line3"].count > 0 then
        plan["line3"].cont = function(isLast)
            if isLast then
                turnRight()
            else
                turnAround()
                safeUp()
            end
            safeUp()
            flipLR()
        end
    end
    plan["line3"].postLine = function()
    end

    return plan
end

-- Function to build a single step
local function boreLayer(plan)
    for i = 1, plan["line1"].count, 1 do
        -- plan["line1"].func(tryPlatform, i == 1 and not udFlip)
        plan["line1"].cont()
    end
    plan["line1"].postLine()
    for i = 1, plan["line2"].count, 1 do
        -- plan["line2"].func(tryPlatform, i == 1 and not udFlip)
        plan["line2"].cont()
    end
    plan["line2"].postLine()
    for i = 1, plan["line3"].count, 1 do
        plan["line3"].func()
        plan["line3"].cont(i == plan["line3"].count)
    end
    plan["line3"].postLine()
end

-- Function to build the entire staircase
local function bore()
    local plan = buildLayerPlan()
    print(dump(plan))
    for i = 1, depth, 1 do
        safeForward()
        turnLeft()
        boreLayer(plan)
        flipUD()
    end

    -- move back down
    if udFlip then
        flipUD()
        for i = 1, height - 1, 1 do
            safeDown()
        end
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

    -- valid input?
    if lor_pre == "r" then
        flipLR()
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
