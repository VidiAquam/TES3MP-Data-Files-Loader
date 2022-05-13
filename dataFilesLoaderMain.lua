dataFilesLoader = {
    data = {}
}

dataFilesLoader.acceptableRecordTypes = {"Activator", "Alchemy", "Apparatus", "Armor", "Bodypart", "Book", "Clothing", "Container",
"Creature", "Door", "Exterior", "Ingredient", "Interior", "Light", "Lockpick", "MiscItem", "Npc", "PathGrid", "Probe", "Race", "Region",
"RepairTool", "Static", "Weapon"}

require("custom/DFL/dependencies/fileHelperDFL")
require("custom/DFL/dataFilesLoaderUtilities")

-- ISSUES:
-- Windows files are weird with colons
-- Linux overwrites files but surrounds the filename with quotation marks

dataFilesLoader.config = {
    -- Whether or not to regenerate DFL files automatically each time the server starts
    -- Very slow with many mods, especially ones editing cells
    -- If false, dataFilesLoader.init() will need to be called manually the first time and when changes to the data files are made
    parseOnServerStart = true,
    -- Loads them on start up
    staticLoading = false,
    -- The types of records to generate DFL files for
    recordTypesToRead = {"Interior", "Exterior"}
}

-- Loads and decodes the file
dataFilesLoader.loadFilename = function(recordType, id)
    local fname = dataFilesLoader.getFilename(recordType, id)
    if fname == nil then
        return nil
    end
    if not dataFilesLoader.config.staticLoading then
        tes3mp.LogMessage(enumerations.log.INFO, "[DFL] Loading " .. fname)
    end
    return jsonInterface.load(fname)
end

-- Generates the names of the input filenames
dataFilesLoader.generateInputFilenames = function()
    local jsonDataFileList = jsonInterface.load("requiredDataFiles.json")
    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, _  in pairs(pluginEntry) do
            jsonDataFileList[listIndex] = string.lower(entryIndex):sub(1, -4) .. "json"
        end
    end
    return jsonDataFileList
end

dataFilesLoader.addTableEntry = function(recordType, entry, tableID)
    if  dataFilesLoader.data[recordType][tableID] == nil then dataFilesLoader.data[recordType][tableID] = {} end

    -- Add to table
    if recordType == "Interior" then
        dataFilesLoader.data[recordType][tableID].data = entry.data
        dataFilesLoader.data[recordType][tableID].water_height = entry.water_height
        dataFilesLoader.data[recordType][tableID].atmosphere_data = entry.atmosphere_data
        dataFilesLoader.data[recordType][tableID].region = entry.region
        dataFilesLoader.data[recordType][tableID].id = entry.id
    elseif recordType == "Exterior" then
        dataFilesLoader.data[recordType][tableID].data = entry.data
        dataFilesLoader.data[recordType][tableID].region = entry.region
        dataFilesLoader.data[recordType][tableID].id = entry.id
    else
        dataFilesLoader.data[recordType][tableID] = {} -- Removes unnecessary fields
        dataFilesLoader.data[recordType][tableID] = entry
    end

    -- update references
    if recordType == "Interior" or recordType == "Exterior" then
        if dataFilesLoader.data[recordType][tableID].references == nil then dataFilesLoader.data[recordType][tableID].references = {} end
        for refr_index, reference in pairs(entry.references) do
            dataFilesLoader.data[recordType][tableID].references[refr_index] = reference
        end
    end

    return dataFilesLoader.data[recordType][tableID]
end

dataFilesLoader.isInteriorCell = function(entry)
    return entry.data ~= nil and entry.data.flags ~= nil and (entry.data.flags % 2) == 1
end

dataFilesLoader.parseExteriorEntry = function(entry)
    local cellID = entry.data.grid[1] .. ", " .. entry.data.grid[2]

    -- Index by refr_index
    local newRefs = {}
    if entry.references == nil then entry.references = {} end
    for _, reference in ipairs(entry.references) do
        newRefs[reference.refr_index] = reference
        reference.refr_index = nil
    end
    entry.references = newRefs

    return cellID, entry
end

dataFilesLoader.parseInteriorEntry = function(entry)
    entry.id = entry.id
    local tableID = entry.id

    -- Index by refr_index
    local newRefs = {}
    if entry.references == nil then entry.references = {} end
    for _, reference in ipairs(entry.references) do
        newRefs[reference.refr_index] = reference
        reference.refr_index = nil
    end
    entry.references = newRefs

    return tableID, entry
end


dataFilesLoader.parseEntry = function(entry)
    local tableID = -1
    if entry.id ~= nil then
        tableID = entry.id
        entry.id = nil
        entry.type = nil
        entry.flags = nil
    else
        if entry.type == "PathGrid" then
            tableID = entry.cell
            entry.cell = nil
            entry.type = nil
            entry.flags = nil
        end
    end

    return tableID, entry
end

-- Generates Vidi JSON Files based on a list of G7 JSON files
dataFilesLoader.generateParsedFiles = function(fileList)

    -- Init tables based on recordTypes to Read
    if dataFilesLoader.config.staticLoading then
        dataFilesLoader.data = {}
        for _, recordtype in pairs(dataFilesLoader.config.recordTypesToRead) do
            dataFilesLoader.data[recordtype] = {}
        end
    else
        dataFilesLoader.data["Interior"] = {}
        dataFilesLoader.data["Exterior"] = {}
    end

    -- Could use dataFilesLoader.data[entry.type] ~= nil instead if we could better distinguish between staticLoading

    -- Go through each entry in the file and parse it
    for _, file in ipairs(fileList) do
        file = tes3mp.GetCaseInsensitiveFilename(config.dataPath .. "/custom/DFL_input", file)
        if tes3mp.DoesFileExist(config.dataPath .. "/custom/DFL_input/" .. file) then
            local fileJSON = jsonInterface.load("custom/DFL_input/" .. file)
            for _, entry in ipairs(fileJSON) do
                local tableID = -1
                local recordtype = entry.type
                if recordtype == "Cell" then
                    if dataFilesLoader.isInteriorCell(entry) and tableHelper.containsValue(dataFilesLoader.config.recordTypesToRead, "Interior") then
                        recordtype = "Interior"
                        tableID, entry = dataFilesLoader.parseInteriorEntry(entry)
                    elseif tableHelper.containsValue(dataFilesLoader.config.recordTypesToRead, "Exterior") then
                        recordtype = "Exterior"
                        tableID, entry = dataFilesLoader.parseExteriorEntry(entry)
                    end
                elseif tableHelper.containsValue(dataFilesLoader.config.recordTypesToRead, entry.type) then
                    tableID, entry = dataFilesLoader.parseEntry(entry)
                end

                if tableID ~= -1 then
                    -- Save to table if permissible
                    if dataFilesLoader.config.staticLoading then
                        entry = dataFilesLoader.addTableEntry(recordtype, entry, tableID)
                    elseif recordtype == "Interior" or recordtype == "Exterior" then
                        entry = dataFilesLoader.addTableEntry(recordtype, entry, tableID)
                    end

                    -- Save to JSON
                    local fname = dataFilesLoader.getFilename(recordtype, tableID)
                    if fname ~= nil then
                        -- Add tableID to entry
                        entry.tableID = tableID

                        -- Save
                        tes3mp.LogMessage(enumerations.log.INFO, "[DFL] Saving " .. fname)    -- Comment out log to improve speeds
                        jsonInterface.save(fname, entry)
                    end
                end
            end
        else
            tes3mp.LogMessage(enumerations.log.ERROR, "[DFL] Could not find file \"" .. file .. "\" in folder data/custom/DFL_input")
        end
    end

    if not dataFilesLoader.config.staticLoading then dataFilesLoader.data = {} end -- Reset data

    tes3mp.LogMessage(enumerations.log.INFO, "[DFL] Generation of DFL files complete")
end

-- General logic for saving G7 Input data into Vidi Data
dataFilesLoader.generateOutputFiles = function()
    local jsonDataFileList = dataFilesLoader.generateInputFilenames()
    dataFilesLoader.generateParsedFiles(jsonDataFileList)
end

-- Loads the files into the data table
dataFilesLoader.loadParsedFiles = function()
    -- Ensures the function can only continue if staticLoading is called
    if not dataFilesLoader.config.staticLoading then
        tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Can't load files into data table when staticLoading isn't set.")
        return
    end

    -- List of recordtypes that require swapping underscores with spaces
    for _, recordType in pairs(dataFilesLoader.config.recordTypesToRead) do
        dataFilesLoader.data[recordType] = {}

        local dir = config.dataPath .. "/custom/DFL_output/" .. recordType .. "/"
        local filenames = fileHelperDFL.dir(dir)
        for _, filename in pairs(filenames) do
            -- Get entry and id
            local entry = jsonInterface.load("/custom/DFL_output/" .. recordType .. "/" .. filename)
            local id = entry.tableID

            -- Clean tableID
            entry.tableID = nil
            tableHelper.cleanNils(entry)

            -- Add to data table
            dataFilesLoader.data[recordType][id] = entry
        end
    end
    tes3mp.LogMessage(enumerations.log.INFO, "DFL files have loaded successfully")
end

-- Logic for Server Init handler
customEventHooks.registerHandler("OnServerPostInit", function()
    if dataFilesLoader.config.parseOnServerStart then
        dataFilesLoader.generateOutputFiles()
    elseif dataFilesLoader.config.staticLoading then
        dataFilesLoader.loadParsedFiles()
    end
end)
