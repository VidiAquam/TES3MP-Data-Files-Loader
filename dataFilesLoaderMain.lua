dataFilesLoader = {
    data = {}
}

require("custom/dfl/dataFilesLoaderUtilities")

local spellEffectReconvertTable = { WaterBreathing = 0, SwiftSwim = 1, WaterWalking = 2, Shield = 3, FireShield = 4,
    LightningShield = 5, FrostShield = 6, Burden = 7, Feather = 8, Jump = 9, Levitate = 10, SlowFall = 11, Lock = 12,
    Open = 13, FireDamage = 14, ShockDamage = 15, FrostDamage = 16, DrainAttribute = 17, DrainHealth = 18,
    DrainMagicka = 19, DrainFatigue = 20, DrainSkill = 21, DamageAttribute = 22, DamageHealth = 23,
    DamageMagicka = 24, DamageFatigue = 25, DamageSkill = 26, Poison = 27, WeaknessToFire = 28, WeaknessToFrost = 29,
    WeaknessToShock = 30, WeaknessToMagicka = 31, WeaknessToCommonDisease = 32, WeaknessToBlightDisease = 33,
    WeaknessToCorprus = 34, WeaknessToPoison = 35, WeaknessToNormalWeapons = 36, DisintegrateWeapon = 37,
    DisintegrateArmor = 38, Invisibility = 39, Chameleon = 40, Light = 41, Sanctuary = 42, NightEye = 43, Charm = 44,
    Paralyze = 45, Silence = 46, Blind = 47, Sound = 48, CalmHumanoid = 49, CalmCreature = 50, FrenzyHumanoid = 51,
    FrenzyCreature = 52, DemoralizeHumanoid = 53, DemoralizeCreature = 54, RallyHumanoid = 55, RallyCreature = 56,
    Dispel = 57, SoulTrap = 58, Telekinesis = 59, Mark = 60, Recall = 61, DivineIntervention = 62,
    AlmsiviIntervention = 63, DetectAnimal = 64, DetectEnchantment = 65, DetectKey = 66, SpellAbsorption = 67,
    Reflect = 68, CureCommonDisease = 69, CureBlightDisease = 70, CureCorprus = 71, CurePoison = 72,
    CureParalyzation = 73, RestoreAttribute = 74, RestoreHealth = 75, RestoreMagicka = 76, RestoreFatigue = 77,
    RestoreSkill = 78, FortifyAttribute = 79, FortifyHealth = 80, FortifyMagicka = 81, FortifyFatigue = 82,
    FortifySkill = 83, FortifyMagickaMultiplier = 84, AbsorbAttribute = 85, AbsorbHealth = 86, AbsorbMagicka = 87,
    AbsorbFatigue = 88, AbsorbSkill = 89, ResistFire = 90, ResistFrost = 91, ResistShock = 92, ResistMagicka = 93,
    ResistCommonDisease = 94, ResistBlightDisease = 95, ResistCorprus = 96, ResistPoison = 97,
    ResistNormalWeapons = 98, ResistParalysis = 99, RemoveCurse = 100, TurnUndead = 101, SummonScamp = 102,
    SummonClannfear = 103, SummonDaedroth = 104, SummonDremora = 105, SummonGhost = 106,
    SummonSkeleton = 107, SummonLeastBonewalker = 108, SummonGreaterBonewalker = 109, SummonBonelord = 110,
    SummonTwilight = 111, SummonHunger = 112, SummonGoldenSaint = 113, SummonFlameAtronach = 114,
    SummonFrostAtronach = 115, SummonStormAtronach = 116, FortifyAttackBonus = 117, CommandCreature = 118,
    CommandHumanoid = 119, BoundDagger = 120, BoundLongsword = 121, BoundMace = 122, BoundBattleAxe = 123,
    BoundSpear = 124, BoundLongbow = 125, BoundCuirass = 127, BoundHelm = 128, BoundBoots = 129,
    BoundShield = 130, BoundGloves = 131, Corprus = 132, Vampirism = 133, SummonCenturionSphere = 134, SunDamage = 135,
    StuntedMagicka = 136, SummonWolf = 138, SummonBear = 139, SummonBoneWolf = 140 }

dataFilesLoader.config = {
    -- Whether or not to regenerate DFL files automatically each time the server starts
    -- Very slow with many mods, especially ones editing cells
    -- If false, dataFilesLoader.init() will need to be called manually the first time and when changes to the data files are made
    parseOnServerStart = false,
    -- The types of records to generate DFL files for
    recordTypesToRead = { "Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Spell', 'Clothing', 'Book', 'Static',
        'Probe', 'Light', 'Apparatus', "Lockpick", "RepairTool", "Race", "Activator", "Bodypart", "Cell", "Container",
        "Region", "Creature", "Npc", "Door" },
}


local function caseSensitiveFormatting(fileList)
    for i, file in ipairs(fileList) do
        fileList[i] = tes3mp.GetCaseInsensitiveFilename(config.dataPath .. "/custom/DFL_input", file)
    end
    return fileList
end

local function generateInputFilenames()
    local jsonDataFileList = jsonInterface.load("requiredDataFiles.json")

    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, _ in pairs(pluginEntry) do
            jsonDataFileList[listIndex] = string.lower(entryIndex):sub(0, -4) .. "json"
        end
    end
    return caseSensitiveFormatting(jsonDataFileList)
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
        local effectID = spellEffectReconvertTable[effect.magic_effect]
        if effectID ~= nil then effect.magic_effect = effectID end
    end
    return effects
end

local function parseEffectList(effects)
    local newEffects = {}
    for _, effect in ipairs(effects) do
        local effectID = spellEffectReconvertTable[effect]
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

local function loadDFLFiles()
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

local function initDataTable()
    for _, recordType in ipairs(dataFilesLoader.config.recordTypesToRead) do
        if dataFilesLoader.data[recordType] == nil then
            dataFilesLoader.data[recordType] = {}
        end
    end
end

local function generateDFLFiles()
    initDataTable()
    local fileList = generateInputFilenames()

    for _, file in ipairs(fileList) do
        for _, entry in ipairs(jsonInterface.load("custom/DFL_input/" .. file)) do
            if tableHelper.containsValue(dataFilesLoader.config.recordTypesToRead, entry.type) then
                if entry.type == "Cell" then
                    parseCellEntry(entry)
                else
                    parseEntry(entry)
                end
            end
        end
    end
    tes3mp.LogMessage(enumerations.log.WARN, "[DFL] Generation of DFL files complete")
end

if dataFilesLoader.config.parseOnServerStart == true then
    customEventHooks.registerHandler("OnServerPostInit", function()
        generateDFLFiles()
        loadDFLFiles()
    end)
else
    customEventHooks.registerHandler("OnServerPostInit", loadDFLFiles)
end
