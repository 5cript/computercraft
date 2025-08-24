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

for i = 1, 64 do
    turtle.forward()
    local res = turtle.down()
    if not res then
        break
    end
    findBlock()
    turtle.placeDown()
end
