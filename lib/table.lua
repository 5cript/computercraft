local function saveTable(table, filename)
    local file = fs.open(filename, "w")
    file.write(textutils.serialize(table))
    file.close()
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function fillDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end

return {
    saveTable = saveTable,
    dump = dump,
    fillDefaults = fillDefaults
}
