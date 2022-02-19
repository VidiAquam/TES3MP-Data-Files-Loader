dataFilesLoader.updateCellRefs = function(cellDescription, oldCell, newCell)
    if newCell ~= nil and tes3mp.DoesFileExist(config.dataPath .. "/cell/".. cellDescription .. ".json") then
        serverCellInfo = jsonInterface.load("cell/".. cellDescription .. ".json")
        if serverCellInfo.lastVisit ~= {} then -- Check for a cell having been reset with Urm's cell reset script; if so, don't bother with it
            tes3mp.LogMessage(enumerations.log.INFO, "[DFL] Updating refnums in cell " .. cellDescription)

            for oldRefnum, object in pairs(serverCellInfo.objectData) do -- Get refnum of an object stored in server files
                if oldRefnum:endswith("-0") and oldCell.references[oldRefnum:trimend("-0")] ~= nil then -- Is it an object in an esm/esp?

                    local oldRefData = oldCell.references[oldRefnum:trimend("-0")] -- Get ref data from the old cell entry

                    for refnum, ref in ipairs(newCell.references) do
                        if ref.id == oldRefData.id and ref.translation == oldRefData.translation and ref.rotation == oldRefData.rotation then -- Check if object is same w/ different refnum
                            local newRefnum = refnum

                            serverCellInfo.objectData[newRefnum] = serverCellInfo.objectData[oldRefnum] -- Update object data to new refnum
                            serverCellInfo.objectData[oldRefnum] = nil
                            break
                        end
                    end
                end
            end
            jsonInterface.save("cell/".. cellDescription .. ".json", serverCellInfo, config.cellKeyOrder) 
        end 
    end
end

dataFilesLoader.getItemRecord = function(id) 
    local recordTypes = {"Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Clothing', 'Book', 'Light', 'Apparatus', "Lockpick", "RepairTool"}
    for _, recordType in ipairs(recordTypes) do
        if dataFilesLoader.getRecord(id, recordType) ~= nil then
            return dataFilesLoader.getRecord(id, recordType)
        end
    end
end

dataFilesLoader.getRecord = function(id, recordType)
    if recordType ~= "Cell" then
        if dataFilesLoader.data[recordType] ~= nil then return dataFilesLoader.data[recordType].id else return nil end
    else
        return dataFilesLoader.getCellRecord(id)
    end
end

dataFilesLoader.getCellRecord = function(cellDescription) 
    return dataFilesLoader.getRecord(cellDescription, "Interior") or dataFilesLoader.getRecord(cellDescription, "Exterior")
end