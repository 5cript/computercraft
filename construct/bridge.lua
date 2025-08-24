package.path = "../?.lua;" .. package.path

-- Ask user for width and depth of the bridge
local turtleUtil = require("lib.turtleutil")

print("Enter the width of the bridge:")
local width = tonumber(read())
print("Enter the depth of the bridge:")
local depth = tonumber(read())
print("Left or Right? (l/r)")
local targetDirection = read()
print("Place railings? (y/n)")
local placeRailings = read()

print("Building bridge with width " .. width .. " and depth " .. depth)

local setDirection = turtleUtil.setDirection
local Direction = turtleUtil.Direction

local function safeForward()
    return turtleUtil.safeForward({
        doDig = true,
        retries = 2
    })
end

-- Moves the turtle away from the rim
local function moveToSafeLocation()
    local moves = math.min(3, width / 2)

    setDirection(Direction.BACKWARD)
    for i = 1, moves do
        if not safeForward() then
            return
        end
    end
    if targetDirection == "l" then
        setDirection(Direction.LEFT)
    else
        setDirection(Direction.RIGHT)
    end
    for i = 1, moves do
        if not safeForward() then
            return
        end
    end

    setDirection(Direction.FORWARD)
end

local placeableBlocks = {"minecraft:stone", "minecraft:cobblestone", "minecraft:oak_planks"}

local function findBlock()
    return turtleUtil.findBlock(placeableBlocks)
end

local function placeDigAction()
    findBlock()
    turtle.placeDown()
    turtle.digUp()
end

local function placeBlock()
    if not findBlock() then
        print("Out of blocks!")
        moveToSafeLocation()
        return false
    end

    placeDigAction()
    return safeForward()
end

local function checkFuel()
    if turtle.getFuelLevel() < (width * 3) then
        print("Low on fuel!")
        moveToSafeLocation()
        return false
    end
    return true
end

local function setTargetDirection(opposite)
    if opposite then
        if targetDirection == "l" then
            setDirection(Direction.RIGHT)
        else
            setDirection(Direction.LEFT)
        end
    else
        if targetDirection == "l" then
            setDirection(Direction.LEFT)
        else
            setDirection(Direction.RIGHT)
        end
    end
end

local function doBridgeLine()
    if not checkFuel() then
        return false
    end

    setDirection(Direction.FORWARD)
    if not safeForward() then
        return false
    end

    if placeRailings == "y" then
        setTargetDirection(true)
        findBlock()
        turtle.place()
    end

    setTargetDirection(false)

    for i = 1, width - 1 do
        if not placeBlock() then
            return false
        end
        placeDigAction()
    end

    if targetDirection == "l" then
        targetDirection = "r"
    else
        targetDirection = "l"
    end

    if placeRailings == "y" then
        findBlock()
        turtle.place()
    end

    return true
end

for i = 1, depth do
    if not doBridgeLine() then
        break
    end
end

setDirection(Direction.FORWARD)
