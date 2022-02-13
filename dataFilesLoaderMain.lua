dataFilesLoader = {
    data = {}
}

require("custom/DFL/dependencies/lua_string")

dataFilesLoader.config = {
    -- Whether or not to regenerate DFL files automatically each time the server starts
    -- If false, dataFilesLoader.init() will need to be called manually when changes to the data files are made
    parseOnServerStart = false, 
    -- The types of records to generate DFL files for
    recordTypesToRead = {"Static", "Armor", "Weapon", "Clothing", "Cell"}
}

dataFilesLoader.init = function() 
    local jsonDataFileList = jsonInterface.load("requiredDataFiles.json")

    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, checksumStringArray in pairs(pluginEntry) do
            if entryIndex:endswith("esm") then
                jsonDataFileList[listIndex] = entryIndex:trimend("esm") .. "json"
            else
                jsonDataFileList[listIndex] = entryIndex:trimend("esp") .. "json"
            end
        end
    end
    --tes3mp.LogMessage(enumerations.log.WARN, "[DFL] " .. tableHelper.concatenateArrayValues(jsonDataFileList))
    dataFilesLoader.generateParsedFiles(jsonDataFileList)
end


dataFilesLoader.generateParsedFiles = function(fileList)
    local hasExistingGeneratedFiles = tes3mp.DoesFileExist("custom/DFL_output/DFL_Cell.json")
    if hasExistingGeneratedFiles then
        dataFilesLoader.oldCells = jsonInterface.load("custom/DFL_output/DFL_Cell.json") -- Used to update cell refs to new refnums
    end

    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        for _, file in ipairs(fileList) do
            if tes3mp.DoesFileExist(config.dataPath .. "/custom/DFL_input/" .. file) then
                tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading file " .. file)
                for _, entry in ipairs(jsonInterface.load("custom/DFL_input/" .. file)) do
                    if entry.type == recordType then
                        if entry.type == "Cell" then -- Cells handled differently due to the need to merge them rather than overwrite
                            dataFilesLoader.parseCellEntry(entry) 
                        else
                            dataFilesLoader.parseEntry(entry)
                        end
                    end
                end
            else
                tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Could not find file \"" .. file .. "\" in folder data/custom/DFL_input")
            end
        end

        tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Saving custom/DFL_output/DFL_" .. recordType .. ".json")
        jsonInterface.quicksave("custom/DFL_output/DFL_" .. recordType .. ".json", dataFilesLoader.data[recordType])
        dataFilesLoader.data[recordType] = {}
    end

    tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Generation of DFL files complete")

    if hasExistingGeneratedFiles then
        for _, cell in dataFilesLoader.oldCells do
            dataFilesLoader.updateCellRefs(cell.id, dataFilesLoader.oldCells, dataFilesLoader.data.Cell)
        end
    end
end

dataFilesLoader.parseCellEntry = function(entry)
    local isUnnamed = entry.id == ""
    
    if isUnnamed then
        tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading unnamed Cell record " .. entry.data.grid[1] .. ", " .. entry.data.grid[2])
    else
        tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading Cell record " .. entry.id)
    end

    if dataFilesLoader.data.Cell == nil then dataFilesLoader.data.Cell = {} end

    if isUnnamed == false then
        
        if dataFilesLoader.data.Cell[entry.id] == nil then dataFilesLoader.data.Cell[entry.id] = {} end
        local cellRecord = dataFilesLoader.data.Cell[entry.id]

        cellRecord.data = entry.data
        cellRecord.water_height = entry.water_height
        cellRecord.atmosphere_data = entry.atmosphere_data
        cellRecord.region = entry.region 
        

        if cellRecord.references == nil then cellRecord.references = {} end
        for _, reference in ipairs(entry.references) do
            cellRecord.references[reference.refr_index] = reference 
            local ref = cellRecord.references[reference.refr_index]
            ref.refr_index = nil
        end
    else
        dataFilesLoader.data.Cell[entry.data.grid[1] .. ", " .. entry.data.grid[2]] = {}
        cellRecord = dataFilesLoader.data.Cell[entry.data.grid[1] .. ", " .. entry.data.grid[2]]

        cellRecord.data = entry.data
        cellRecord.region = entry.region

        if cellRecord.references == nil then cellRecord.references = {} end
        for _, reference in ipairs(entry.references) do
            cellRecord.references[reference.refr_index] = reference 
            local ref = cellRecord.references[reference.refr_index]
            ref.refr_index = nil
        end

        
    end
end

dataFilesLoader.parseEntry = function(entry)
    local entryType = entry.type
    if dataFilesLoader.data[entryType] == nil then dataFilesLoader.data[entryType] = {} end

    if entry.id ~= nil then 
        tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading " .. entryType .. " record " .. entry.id)

        local recordTable = dataFilesLoader.data[entryType]

        if recordTable[entry.id] == nil then recordTable[entry.id] = {} end

        recordTable[entry.id] = entry
        newEntry = recordTable[entry.id]
        newEntry.id = nil
        newEntry.type = nil
        newEntry.flags = nil
    else
        -- I'm not sure what record types lack ids, but this is here for safety
        tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading " .. entryType .. " record ")
        table.insert(dataFilesLoader.data[entryType], entry)

        local recordTable = dataFilesLoader.data[entryType]

        recordTable[#dataFilesLoader.data.entryType].type = nil
        recordTable[#dataFilesLoader.data.entryType].flags = nil
    end
end   


dataFilesLoader.updateCellRefs = function(cellDescription, oldCellTable, newCellTable) 
    
end

if dataFilesLoader.config.parseOnServerStart == true then
    customEventHooks.registerHandler("OnServerPostInit", dataFilesLoader.init)
end