-- Determines if recordtype is a CELL recordtype
dataFilesLoader.isCellRecordType = function(recordType)
    return recordType == "Interior" or recordType == "Exterior"
end

-- Gets the filename of the recordtype and (if interior or exterior) the id
dataFilesLoader.getFilename = function(recordType, id)
    if not tableHelper.containsValue(dataFilesLoader.acceptableRecordTypes, recordType) then
        tes3mp.LogMessage(enumerations.log.ERROR, "[DFL] Provided record type is not in the list of acceptable record types.")
        return nil
    end
    return "custom/DFL_output/".. recordType .. "/" .. dataFilesLoader.getFilenameID(id) .. ".json"
end

-- Gets the ID attached to a filename
dataFilesLoader.getIDFromFilename = function(filename)
    return id:sub(1, -6)
end

-- Gets the filename ID from the id
dataFilesLoader.getFilenameID = function(id)
    id = id:gsub(" ", "_")  -- spaces become underscores
    return id
end

dataFilesLoader.getRefId = function(filenameID)
    filenameID = filenameID:gsub("_", " ")  -- All underscores become spaces
    return filenameID
end

-- Gets the data of items
dataFilesLoader.getItemRecord = function(id)
    id = id:lower()
    local recordTypes = {"Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Clothing', 'Book', 'Light', 'Apparatus', "Lockpick", "RepairTool"}
    for _, recordType in ipairs(recordTypes) do
        if dataFilesLoader.getRecord(id, recordType) ~= nil then
            return dataFilesLoader.getRecord(id, recordType)
        end
    end
end

-- Gets data on item based off its recordType
dataFilesLoader.getRecord = function(id, recordType)
    -- Just the table assoc. with the record type
    if id == nil then
        if dataFilesLoader.data[recordType] ~= nil then return dataFilesLoader.data[recordType] else return nil end
    else
        id = id:lower()
        -- Get the table assoc. with the record type and indexed by the id
        if dataFilesLoader.config.staticLoading then
            if dataFilesLoader.data[recordType] ~= nil then return dataFilesLoader.data[recordType][id] else return nil end
        else
            return dataFilesLoader.loadFilename(recordType, id)
        end
    end
end

-- Gets Record based on if it's a cell
dataFilesLoader.getCellRecord = function(cellDescription)
    cellDescription = cellDescription:lower()
    return dataFilesLoader.getRecord(cellDescription, "Interior") or dataFilesLoader.getRecord(cellDescription, "Exterior")
end
