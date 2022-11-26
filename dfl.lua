if dataFilesLoader == nil then
    dataFilesLoader = {
        config = {
            rootDir = debug.getinfo(1, "S").source:match("@(.*/)") or "",
            useMP = false
        },
        data = {}
    }
end

local rootDir = dataFilesLoader.config.rootDir
require(rootDir .. "common/utilities")
require(rootDir .. "common/data")
require(rootDir .. "tes3conv")
local jsonInterface = dataFilesLoader.config.useMP and jsonInterface or require(rootDir .. "jsonInterface")

--- Collects the filenames used as input for the dfl generator
-- @return a list generator of the filenames used as the input for the DFL
local function generateInputFilenames()
    local input_path = dataFilesLoader.config.data_path .. dataFilesLoader.config.dfl_input
    return ListFiles(input_path)
end

--- Collects the case sensitive ESP files which are required for the server
-- @return the case sensitive ESP filepaths and names
local function collectESPs()
    local jsonDataFileList = jsonInterface.load(dataFilesLoader.config.required_esps)
    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, _ in pairs(pluginEntry) do
            jsonDataFileList[listIndex] = dataFilesLoader.config.data_path ..
                dataFilesLoader.config.esp_list .. entryIndex
        end
    end
    return CaseSensitiveFiles(jsonDataFileList)
end

--- Generates DFL's input files by converting ESP data into JSON
local function generateDFLInput()
    local esps = collectESPs()
    ParseESPs(esps)
end

--- Parses data which denote interior cells
-- @param entry is the unit of data representing an interior cell
local function parseInteriorEntry(entry)
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
end

--- Parses data which denote exterior cells
-- @param entry is the unit of data representing an exterior cell
local function parseExteriorEntry(entry)
    if dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]] == nil then
        dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]] = {}
    end
    local cellRecord = dataFilesLoader.data.Exterior[entry.data.grid[1] .. ", " .. entry.data.grid[2]]

    cellRecord.data = entry.data
    cellRecord.region = entry.region
    cellRecord.id = entry.id

    if cellRecord.references == nil then cellRecord.references = {} end
    for _, reference in ipairs(entry.references) do
        cellRecord.references[reference.refr_index] = reference
        local ref = cellRecord.references[reference.refr_index]
        ref.refr_index = nil
        ref.mast_index = nil
        ref.temporary = nil
    end
end

--- Parses data which denotes a cell
-- Determines whether cell should be parsed as an interior or exterior cell
-- @param entry is the unit of data representing a cell
local function parseCellEntry(entry)
    if (entry.data.flags % 2) == 0 then
        parseExteriorEntry(entry)
    else
        parseInteriorEntry(entry)
    end
end

--- Updates the effect ids of a list of magical effects to ids used by tes3mp
-- @param effects is the original json denoting a spell's effects
-- @return tes3mp readable effect json
local function parseMagicEffect_tes3mp(effects)
    for _, effect in ipairs(effects) do
        local effectID = SpellEffectReconvertTable[effect.magic_effect]
        if effectID ~= nil then effect.magic_effect = effectID end
    end
    return effects
end

--- Updates a list of effect ids to ids used by tes3mp
-- @param effects is the original json denoting a list of effect ids
-- @return tes3mp readable effect json
local function parseEffectList_tes3mp(effects)
    local newEffects = {}
    for _, effect in ipairs(effects) do
        local effectID = SpellEffectReconvertTable[effect]
        if effectID ~= nil then table.insert(newEffects, effectID) end
    end
    return newEffects
end

--- Parses a non-cell based entry
-- @param entry is the json of the non-cell data
local function parseEntry(entry)
    local entryType = entry.type
    local recordTable = dataFilesLoader.data[entryType]

    if entry.effects ~= nil then
        entry.effects = parseMagicEffect_tes3mp(entry.effects)
    elseif entry.data ~= nil and entry.data.effects ~= nil then
        entry.data.effects = parseEffectList_tes3mp(entry.data.effects)
    elseif entry.id ~= nil then
        if recordTable[entry.id] == nil then recordTable[entry.id] = {} end
        local k = entry.id
        entry.id = nil
        entry.type = nil
        entry.flags = nil
        recordTable[k] = entry
    else
        if entry.type == "PathGrid" then
            if recordTable[entry.cell] == nil then recordTable[entry.cell] = {} end
            local k = entry.cell
            entry.type = nil
            entry.flags = nil
            entry.cell = nil
            recordTable[k] = entry
        else
            table.insert(dataFilesLoader.data[entryType], entry)
            recordTable[#dataFilesLoader.data.entryType].type = nil
            recordTable[#dataFilesLoader.data.entryType].flags = nil
        end
    end
end

--- Loads a DFL file into lua's memory
function dataFilesLoader.loadDFLFiles()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        Log(1, "[DFL] Loading DFL_" .. recordType .. ".json")
        dataFilesLoader.data[recordType] =
        jsonInterface.load(
            dataFilesLoader.config.dfl_output .. "DFL_" .. recordType .. ".json"
        )
    end
end

--- Initialises the tables for the generator
local function initDataTable()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        if dataFilesLoader.data[recordType] == nil then
            dataFilesLoader.data[recordType] = {}
        end
    end
end

-- Saves the DFL files into their appropriate filenames
local function saveDFLFiles()
    for _, type in ipairs(dataFilesLoader.config.recordTypesToRead) do
        jsonInterface.quicksave(dataFilesLoader.config.dfl_output .. "DFL_" .. type .. ".json",
            dataFilesLoader.data[type])
        Log(1, "[DFL] Generation of " .. type .. " Completed")
    end
end

--- Generates DFL data into json files
function dataFilesLoader.generateDFLFiles()
    initDataTable()
    generateDFLInput()

    for file in generateInputFilenames() do
        for _, entry in ipairs(jsonInterface.load(dataFilesLoader.config.dfl_input .. file)) do
            if ContainsValue(dataFilesLoader.config.recordTypesToRead, entry.type) then
                parseEntry(entry)
            elseif entry.type == "Cell" then
                if ContainsValue(dataFilesLoader.config.recordTypesToRead, "[IE][nx]terior") then -- Ugly regex, but no | regex
                    parseCellEntry(entry)
                end
            end
        end
    end

    saveDFLFiles()
    Log(2, "[DFL] Generation of DFL files complete")
end

--------------------- DEBUG ---------------------
-- if dataFilesLoader.config.parseOnServerStart then
--     generateDFLInput()
--     dataFilesLoader.generateDFLFiles()
-- end
-- dataFilesLoader.loadDFLFiles()
