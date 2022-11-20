dataFilesLoader.getItemRecord = function(id)
    local recordTypes = { "Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Clothing', 'Book', 'Light',
        'Apparatus', "Lockpick", "Probe", "RepairTool" }
    for _, recordType in ipairs(recordTypes) do
        if dataFilesLoader.getRecord(id, recordType) ~= nil then
            return dataFilesLoader.getRecord(id, recordType)
        end
    end
end

dataFilesLoader.getRecord = function(id, recordType)
    if id == nil then
        return dataFilesLoader.data[recordType]
    end
    if recordType ~= "Cell" then
        if dataFilesLoader.data[recordType] ~= nil then
            if dataFilesLoader.data[recordType][id] ~= nil then
                return dataFilesLoader.data[recordType][id]
            end
            local newId = dataFilesLoader.getCaseInsensitiveKey(id, recordType)
            if newId ~= nil then
                return dataFilesLoader.data[recordType][newId]
            end
        end
        return nil
    else
        return dataFilesLoader.getCellRecord(id)
    end
end

dataFilesLoader.getCaseInsensitiveKey = function(id, recordType)
    for key, _ in pairs(dataFilesLoader.data[recordType]) do
        if key:lower() == id:lower() then return key end
    end
    return nil
end

dataFilesLoader.getCellRecord = function(cellDescription)
    return dataFilesLoader.getRecord(cellDescription, "Interior") or
        dataFilesLoader.getRecord(cellDescription, "Exterior")
end
