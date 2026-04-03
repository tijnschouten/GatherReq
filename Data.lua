local addonName, PST = ...

PST = PST or {}
_G[addonName] = PST
PST.Data = PST.Data or {}

PST.Data.Locale = "enUS"

PST.Data.Professions = {
    Herbalism = "Herbalism",
    Lockpicking = "Lockpicking",
    Mining = "Mining",
    Skinning = "Skinning",
}

PST.Data.TrainingRanks = {
    Herbalism = {
        [75] = { rank = "Journeyman", skill = 50, level = 10 },
        [150] = { rank = "Expert", skill = 125, level = 20 },
        [225] = { rank = "Artisan", skill = 200, level = 35 },
        [300] = { rank = "Master", skill = 275, level = 50 },
    },
    Mining = {
        [75] = { rank = "Journeyman", skill = 50, level = 10 },
        [150] = { rank = "Expert", skill = 125, level = 20 },
        [225] = { rank = "Artisan", skill = 200, level = 35 },
        [300] = { rank = "Master", skill = 275, level = 50 },
    },
    Skinning = {
        [75] = { rank = "Journeyman", skill = 50, level = 10 },
        [150] = { rank = "Expert", skill = 125, level = 20 },
        [225] = { rank = "Artisan", skill = 200, level = 35 },
        [300] = { rank = "Master", skill = 275, level = 50 },
    },
}

PST.Data.MiningNodes = {
    ["Copper Vein"] = 1,
    ["Tin Vein"] = 65,
    ["Silver Vein"] = 75,
    ["Iron Deposit"] = 125,
    ["Gold Vein"] = 155,
    ["Mithril Deposit"] = 175,
    ["Truesilver Deposit"] = 230,
    ["Dark Iron Deposit"] = 230,
    ["Small Thorium Vein"] = 245,
    ["Rich Thorium Vein"] = 275,
    ["Hakkari Thorium Vein"] = 245,
    ["Ooze Covered Iron Deposit"] = 125,
    ["Ooze Covered Silver Vein"] = 75,
    ["Ooze Covered Gold Vein"] = 155,
    ["Ooze Covered Mithril Deposit"] = 175,
    ["Ooze Covered Truesilver Deposit"] = 230,
    ["Ooze Covered Thorium Vein"] = 245,
    ["Ooze Covered Rich Thorium Vein"] = 275,
    ["Small Obsidian Chunk"] = 305,
    ["Large Obsidian Chunk"] = 305,
    ["Fel Iron Deposit"] = 275,
    ["Adamantite Deposit"] = 325,
    ["Rich Adamantite Deposit"] = 350,
    ["Khorium Vein"] = 375,
    ["Ancient Gem Vein"] = 375,
}

PST.Data.HerbNodes = {
    ["Peacebloom"] = 1,
    ["Silverleaf"] = 1,
    ["Earthroot"] = 15,
    ["Mageroyal"] = 50,
    ["Briarthorn"] = 70,
    ["Stranglekelp"] = 85,
    ["Bruiseweed"] = 100,
    ["Wild Steelbloom"] = 115,
    ["Grave Moss"] = 120,
    ["Kingsblood"] = 125,
    ["Liferoot"] = 150,
    ["Fadeleaf"] = 160,
    ["Goldthorn"] = 170,
    ["Khadgar's Whisker"] = 185,
    ["Wintersbite"] = 195,
    ["Firebloom"] = 205,
    ["Purple Lotus"] = 210,
    ["Arthas' Tears"] = 220,
    ["Sungrass"] = 230,
    ["Blindweed"] = 235,
    ["Ghost Mushroom"] = 245,
    ["Gromsblood"] = 250,
    ["Golden Sansam"] = 260,
    ["Dreamfoil"] = 270,
    ["Mountain Silversage"] = 280,
    ["Plaguebloom"] = 285,
    ["Icecap"] = 290,
    ["Black Lotus"] = 300,
    ["Felweed"] = 300,
    ["Dreaming Glory"] = 315,
    ["Ragveil"] = 325,
    ["Terocone"] = 325,
    ["Flame Cap"] = 335,
    ["Ancient Lichen"] = 340,
    ["Netherbloom"] = 350,
    ["Nightmare Vine"] = 365,
    ["Mana Thistle"] = 375,
}

PST.Data.Lockboxes = {
    ["Ornate Bronze Lockbox"] = 1,
    ["Battered Junkbox"] = 1,
    ["Heavy Bronze Lockbox"] = 25,
    ["Worn Junkbox"] = 25,
    ["Iron Lockbox"] = 70,
    ["Strong Iron Lockbox"] = 125,
    ["Strong Junkbox"] = 125,
    ["Steel Lockbox"] = 175,
    ["Reinforced Steel Lockbox"] = 225,
    ["Mithril Lockbox"] = 225,
    ["Thorium Lockbox"] = 225,
    ["Eternium Lockbox"] = 225,
    ["Khorium Lockbox"] = 325,
}

PST.Data.LockedObjects = {
    ["Practice Lockboxes"] = 1,
    ["Buccaneer's Strongbox"] = 1,
    ["Burial Chest"] = 1,
    ["Primitive Chest"] = 20,
    ["Cozzle's Footlocker"] = 160,
    ["Scarlet Footlocker"] = 250,
    ["Wicker Chest"] = 300,
}
