dataFilesLoader = {
    data = {}
}

require("custom/DFL/dependencies/lua_string")
require("custom/DFL/dataFilesLoaderUtilities")

dataFilesLoader.config = {
    -- Whether or not to regenerate DFL files automatically each time the server starts
    -- Very slow with many mods, especially ones editing cells
    -- If false, dataFilesLoader.init() will need to be called manually the first time and when changes to the data files are made
    parseOnServerStart = false, 
    -- The types of records to generate DFL files for
    recordTypesToRead = {"Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Clothing', 'Book', 'Static', 'Probe', 'Light', 'Apparatus', "Lockpick", "RepairTool", "Race", "Activator", "Bodypart", "Cell", "Container", "Region", "Creature", "Npc", "Door"},
}

dataFilesLoader.init = function() 
    local jsonDataFileList = jsonInterface.load("requiredDataFiles.json")

    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, checksumStringArray in pairs(pluginEntry) do
            if string.lower(entryIndex):endswith("esm") then
                jsonDataFileList[listIndex] = string.lower(entryIndex):trimend("esm") .. "json"
            else
                jsonDataFileList[listIndex] = string.lower(entryIndex):trimend("esp") .. "json"
            end
        end
    end
    dataFilesLoader.generateParsedFiles(jsonDataFileList)
    dataFilesLoader.loadParsedFiles()
end

dataFilesLoader.loadParsedFiles = function()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
       if recordType ~= "Cell" then
            tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading DFL_" .. recordType .. ".json")
            dataFilesLoader.data[recordType] = jsonInterface.load("custom/DFL_output/DFL_" .. recordType .. ".json")  
       else
            if dataFilesLoader.data.Interior == nil then
                dataFilesLoader.data.Interior = jsonInterface.load("custom/DFL_output/DFL_Interior.json")
                tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading DFL_Interior.json")
            end
            if dataFilesLoader.data.Exterior == nil then
                dataFilesLoader.data.Exterior = jsonInterface.load("custom/DFL_output/DFL_Exterior.json")
                tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading DFL_Exterior.json")
            end 
       end 
    end
end

dataFilesLoader.generateParsedFiles = function(fileList)
    if tableHelper.containsValue(dataFilesLoader.config.recordTypesToRead, "Cell", false) then
        table.remove(dataFilesLoader.config.recordTypesToRead,tableHelper.getIndexByValue(dataFilesLoader.config.recordTypesToRead, "Cell"))
        table.insert(dataFilesLoader.config.recordTypesToRead, "Cell")
    end

    local hasExistingGeneratedFiles = tes3mp.DoesFileExist(config.dataPath .. "/custom/DFL_output/DFL_Interior.json") and tes3mp.DoesFileExist(config.dataPath .. "/custom/DFL_output/DFL_Exterior.json")
    if hasExistingGeneratedFiles then -- Used to update cell refs to new refnums
        dataFilesLoader.oldInteriorCells = jsonInterface.load("custom/DFL_output/DFL_Interior.json")
        dataFilesLoader.oldExteriorCells = jsonInterface.load("custom/DFL_output/DFL_Exterior.json")
    end

    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading record type" .. recordType)
        for _, file in ipairs(fileList) do
            local ciFilename = tes3mp.GetCaseInsensitiveFilename(config.dataPath .. "/custom/DFL_input", file)
            if tes3mp.DoesFileExist(config.dataPath .. "/custom/DFL_input/" .. ciFilename) then
                --tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Loading file " .. ciFilename)
                for _, entry in ipairs(jsonInterface.load("custom/DFL_input/" .. ciFilename)) do
                    if entry.type == recordType then
                        if entry.type == "Cell" then -- Cells handled differently due to the need to merge them rather than overwrite
                            dataFilesLoader.parseCellEntry(entry) 
                        else
                            dataFilesLoader.parseEntry(entry)
                        end
                    end 
                end
                collectgarbage()
            else
                tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Could not find file \"" .. file .. "\" in folder data/custom/DFL_input")
            end
        end

        
        if recordType == "Cell" then
            jsonInterface.quicksave("custom/DFL_output/DFL_Exterior.json", dataFilesLoader.data["Exterior"])
            tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Saving custom/DFL_output/DFL_Exterior.json")
            jsonInterface.quicksave("custom/DFL_output/DFL_Interior.json", dataFilesLoader.data["Interior"])
            tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Saving custom/DFL_output/DFL_Interior.json")
        else
            tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Saving custom/DFL_output/DFL_" .. recordType .. ".json")
            jsonInterface.quicksave("custom/DFL_output/DFL_" .. recordType .. ".json", dataFilesLoader.data[recordType])
            dataFilesLoader.data[recordType] = {}
        end
        
    end

    tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Generation of DFL files complete")

    if hasExistingGeneratedFiles then
        for cellDescription, cell in pairs(dataFilesLoader.oldInteriorCells) do
            if dataFilesLoader.oldInteriorCells[cellDescription] ~= dataFilesLoader.data.Interior[cellDescription] then 
                dataFilesLoader.updateCellRefs(cellDescription, cell, dataFilesLoader.data.Interior[cellDescription])
            end
        end
        for cellDescription, cell in pairs(dataFilesLoader.oldExteriorCells) do
            if dataFilesLoader.oldExteriorCells[cellDescription] ~= dataFilesLoader.data.Exterior[cellDescription] then 
                dataFilesLoader.updateCellRefs(cellDescription, cell, dataFilesLoader.data.Exterior[cellDescription])
            end
        end
        dataFilesLoader.oldInteriorCells = nil
        dataFilesLoader.oldExteriorCells = nil
    end
end

dataFilesLoader.parseCellEntry = function(entry)
    local isExterior = (entry.data.flags % 2) == 0

    if dataFilesLoader.data.Interior == nil then dataFilesLoader.data.Interior = {} end
    if dataFilesLoader.data.Exterior == nil then dataFilesLoader.data.Exterior = {} end

    if isExterior == false then
        --tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading interior Cell record " .. entry.id)
        if dataFilesLoader.data.Interior[entry.id] == nil then dataFilesLoader.data.Interior[entry.id] = {} end
        local cellRecord = dataFilesLoader.data.Interior[entry.id]

        cellRecord.data = entry.data
        cellRecord.water_height = entry.water_height
        cellRecord.atmosphere_data = entry.atmosphere_data
        cellRecord.region = entry.region 
        cellRecord.id = entry.id

        if cellRecord.references == nil then cellRecord.references = {} end
        for _, reference in ipairs(entry.references) do
            cellRecord.references[reference.refr_index] = reference 
            local ref = cellRecord.references[reference.refr_index]
            ref.refr_index = nil
        end
    else
        --tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading exterior Cell record " .. entry.data.grid[1] .. ", " .. entry.data.grid[2])
        if dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]] == nil then dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]] = {} end
        local cellRecord = dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]]

        cellRecord.data = entry.data
        cellRecord.region = entry.region
        cellRecord.id = entry.id

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
        --tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading " .. entryType .. " record " .. entry.id)

        local recordTable = dataFilesLoader.data[entryType]

        if recordTable[entry.id] == nil then recordTable[entry.id] = {} end

        recordTable[entry.id] = entry
        local newEntry = recordTable[entry.id]
        newEntry.id = nil
        newEntry.type = nil
        newEntry.flags = nil
    else
        if entry.type == "PathGrid" then
            local recordTable = dataFilesLoader.data[entryType]
            if recordTable[entry.cell] == nil then recordTable[entry.cell] = {} end

            recordTable[entry.cell] = entry
            local newEntry = recordTable[entry.cell]
            newEntry.cell = nil
            newEntry.type = nil
            newEntry.flags = nil
        else
            -- I'm not sure what other record types lack ids, but this is here for safety
            --tes3mp.LogMessage(enumerations.log.VERBOSE, "-Loading " .. entryType .. " record ")
            table.insert(dataFilesLoader.data[entryType], entry)

            local recordTable = dataFilesLoader.data[entryType]

            recordTable[#dataFilesLoader.data.entryType].type = nil
            recordTable[#dataFilesLoader.data.entryType].flags = nil
        end
    end
end   

if dataFilesLoader.config.parseOnServerStart == true then
    customEventHooks.registerHandler("OnServerPostInit", dataFilesLoader.init)
else
    customEventHooks.registerHandler("OnServerPostInit", dataFilesLoader.loadParsedFiles)
end