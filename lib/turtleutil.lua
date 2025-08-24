package.path = "../?.lua;" .. package.path

local tableUtil = require("lib.table")

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

local function safeForward(t)
    tableUtil.fillDefaults(t, {
        doDig = false,
        retries = 1,
        sleepTime = 0
    })

    local doDig = t.doDig
    local retries = t.retries
    local sleepTime = t.sleepTime or 0

    for i = 1, retries do
        if turtle.forward() then
            return true
        end
        if doDig and turtle.dig() and turtle.forward() then
            return true
        end
        if sleepTime > 0 then
            os.sleep(sleepTime)
        end
    end
    return false
end

local function findBlock(placeableBlocks)
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

local function findBlockAndPlace(placeableBlocks)
    if findBlock(placeableBlocks) then
        turtle.place()
        return true
    end
    return false
end

return {
    setDirection = setDirection,
    Direction = Direction,
    safeForward = safeForward,
    findBlock = findBlock
}
