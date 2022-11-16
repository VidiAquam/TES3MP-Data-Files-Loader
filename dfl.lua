local rootDir = debug.getinfo(1, "S").source:match("@(.*/)") or ""
require(rootDir .. "common/utilities")
require(rootDir .. "common/data")
require(rootDir .. "tes3conv")
local jsonInterface = require(rootDir .. "jsonInterface")


local function generateInputFilenames()
    -- TODO: Just use dir on the dfl_input
end

local function collectESPs()
    local jsonDataFileList = jsonInterface.load(dataFilesLoader.config.required_esps)
    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, _ in pairs(pluginEntry) do
            jsonDataFileList[listIndex] = dataFilesLoader.config.esp_list .. entryIndex
        end
    end
    return CaseSensitiveFormatting(jsonDataFileList)
end

local function generateInput()
    local esps = collectESPs()
    ParseESPs(esps)
end

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

local function parseCellEntry(entry)
    if (entry.data.flags % 2) then
        parseExteriorEntry(entry)
    else
        parseInteriorEntry(entry)
    end
end

local function parseMagicEffect(effects)
    for _, effect in ipairs(effects) do
        local effectID = SpellEffectReconvertTable[effect.magic_effect]
        if effectID ~= nil then effect.magic_effect = effectID end
    end
    return effects
end

local function parseEffectList(effects)
    local newEffects = {}
    for _, effect in ipairs(effects) do
        local effectID = SpellEffectReconvertTable[effect]
        if effectID ~= nil then table.insert(newEffects, effectID) end
    end
    return newEffects
end

local function parseEntry(entry)
    local entryType = entry.type
    local recordTable = dataFilesLoader.data[entryType]

    if entry.effects ~= nil then
        entry.effects = parseMagicEffect(entry.effects)
    elseif entry.data ~= nil and entry.data.effects ~= nil then
        entry.data.effects = parseEffectList(entry.data.effects)
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

function dataFilesLoader.loadDFLFiles()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        if recordType ~= "Cell" then
            Log(2, "[DFL] Loading DFL_" .. recordType .. ".json")
            dataFilesLoader.data[recordType] = jsonInterface.load(dataFilesLoader.config.dfl_output ..
                "DFL_" .. recordType .. ".json")
        else
            if dataFilesLoader.data.Interior == nil then
                dataFilesLoader.data.Interior = jsonInterface.load(dataFilesLoader.config.dfl_output ..
                    "DFL_Interior.json")
                Log(2, "[DFL] Loading DFL_Interior.json")
            end
            if dataFilesLoader.data.Exterior == nil then
                dataFilesLoader.data.Exterior = jsonInterface.load(dataFilesLoader.config.dfl_output ..
                    "DFL_Exterior.json")
                Log(2, "[DFL] Loading DFL_Exterior.json")
            end
        end
    end
end

local function initDataTable()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        if dataFilesLoader.data[recordType] == nil then
            dataFilesLoader.data[recordType] = {}
        end
    end
end

function dataFilesLoader.generateDFLFiles()
    initDataTable()
    local fileList = generateInputFilenames()

    for _, file in ipairs(fileList) do
        for _, entry in ipairs(jsonInterface.load(file)) do
            if ContainsValue(dataFilesLoader.config.recordTypesToRead, entry.type) then
                if entry.type == "Cell" then
                    parseCellEntry(entry)
                else
                    parseEntry(entry)
                end
            end
        end
    end
    Log(2, "[DFL] Generation of DFL files complete")
end

if dataFilesLoader.config.parseOnServerStart then
    generateInput()
    dataFilesLoader.generateDFLFiles()
end
dataFilesLoader.loadDFLFiles()
