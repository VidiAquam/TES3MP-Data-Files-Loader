dataFilesLoader.updateCellRefs = function(cellDescription, oldCell, newCell)
    if newCell ~= nil and tes3mp.DoesFileExist(config.dataPath .. "/cell/".. cellDescription .. ".json") then
        serverCellInfo = jsonInterface.load("cell/".. cellDescription .. ".json")
        if serverCellInfo.lastVisit ~= {} then -- Check for a cell having been reset with Urm's cell reset script; if so, don't bother with it
            tes3mp.LogMessage(enumerations.log.INFO, "[DFL] Updating refnums in cell " .. cellDescription)

            for oldRefnum, object in pairs(serverCellInfo.objectData) do -- Get refnum of an object stored in server files
                if oldRefnum:sub(-2, -1) == "-0" and oldCell.references[oldRefnum:sub(1, -3)] ~= nil then -- Is it an object in an esm/esp?

                    local oldRefData = oldCell.references[oldRefnum:sub(1, -3)] -- Get ref data from the old cell entry
                    local newRefnum
                    for refnum, ref in ipairs(newCell.references) do
                        if ref.id == oldRefData.id and ref.translation == oldRefData.translation and ref.rotation == oldRefData.rotation then -- Check if object is same w/ different refnum
                            newRefnum = refnum .. "-0"

                            serverCellInfo.objectData[newRefnum] = serverCellInfo.objectData[oldRefnum] -- Update object data to new refnum
                            serverCellInfo.objectData[oldRefnum] = nil

                            for _, packets in pairs(serverCellInfo.packets) do
                                if tableHelper.containsValue(packets, oldRefnum, true) then
                                    table.remove(packets,tableHelper.getIndexByValue(packets, oldRefnum))
                                    table.insert(packets, newRefnum)
                                end
                            end

                            break
                        end
                    end
                end
            end
            jsonInterface.save("cell/".. cellDescription .. ".json", serverCellInfo, config.cellKeyOrder)
        end
    end
end

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
    return "custom/DFL_output/".. recordType .. "/DFL_" .. recordType .. "_" .. dataFilesLoader.getFilenameID(id) .. ".json"
end

-- Gets the ID attached to a filename
dataFilesLoader.getIDFromFilename = function(filename)
    -- DFL_<recordtype>_<id>
    -- Get everything after the second underscore
    local recordtype = filename:match("DFL_(%a+)_.+") -- Not necessary but nice to have
    local id = filename:match("DFL_%a+_(.+)")
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
    return dataFilesLoader.getRecord(cellDescription, "Interior") or dataFilesLoader.getRecord(cellDescription, "Exterior")
end
