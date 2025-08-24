-- Ask user for width and depth of the bridge
print("Enter the width of the bridge:")
local width = tonumber(read())
print("Enter the depth of the bridge:")
local depth = tonumber(read())
print("Left or Right? (l/r)")
local targetDirection = read()
print("Place railings? (y/n)")
local placeRailings = read()

print("Building bridge with width " .. width .. " and depth " .. depth)
local Direction = {
    FORWARD = 0,
    RIGHT = 1,
    BACKWARD = 2,
    LEFT = 3
}

-- Keeps track of the turtle's current direction, just relative to initial position facing down the bridge
local currentDirection = Direction.FORWARD

function setDirection(targetDirection)
    -- Calculate the number of turns needed
    local turnDifference = (targetDirection - currentDirection + 4) % 4

    -- Perform the minimal number of turns
    if turnDifference == 1 then
        turtle.turnRight()
    elseif turnDifference == 2 then
        turtle.turnRight()
        turtle.turnRight()
    elseif turnDifference == 3 then
        turtle.turnLeft()
    end

    -- Update the current direction
    currentDirection = targetDirection
end

local function safeForward()
    if turtle.forward() then
        return true
    elseif turtle.dig() and turtle.forward() then
        return true
    end
    return false
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
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            local detail = turtle.getItemDetail(slot)
            if detail and detail.name then
                for _, block in ipairs(placeableBlocks) do
                    if detail.name == block then
                        turtle.select(slot)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function placeDigAction()
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
