local dataDir = dataFilesLoader.config.useMP and "" or
    dataFilesLoader.config.rootDir .. "data/"

--- Gets the path to the data folder
-- @return the OS path to the data folder
local function getDataPath()
    if (dataFilesLoader.config.useMP) then
        return config.dataPath .. "/"
    end
    return ""
end

dataFilesLoader.config = {
    -- Copy over existing config
    -- Can be avoided by having this in the dfl.lua folder
    useMP = dataFilesLoader.config.useMP,
    rootDir = dataFilesLoader.config.rootDir,

    parseOnServerStart = true,
    recordTypesToRead = { "Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Spell', 'Clothing', 'Book', 'Static',
        'Probe', 'Light', 'Apparatus', "Lockpick", "RepairTool", "Race", "Activator", "Bodypart", "Interior", "Exterior",
        "Container", "Region", "Creature", "Npc", "Door" },
    required_esps = dataDir .. "requiredDataFiles.json",
    esp_list = dataDir .. "custom/ESP/",
    dfl_input = dataDir .. "custom/DFL_input/",
    dfl_output = dataDir .. "custom/DFL_output/",
    data_path = getDataPath()
}

SpellEffectReconvertTable = { WaterBreathing = 0, SwiftSwim = 1, WaterWalking = 2, Shield = 3, FireShield = 4,
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
    StuntedMagicka = 136, SummonWolf = 138, SummonBear = 139, SummonBoneWolf = 140
}
