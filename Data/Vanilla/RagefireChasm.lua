-- Ragefire Chasm (Vanilla batch 1)
--
-- Sources (see README.txt for full credits / licences):
--  * Map + map legend: Atlas 1.17.0 for 3.3.5 (Dan Gilbert; map art by Niflheim), GPLv2,
--    TrinityCore/wow_335a_addons Atlas/Atlas/Images/Maps/RagefireChasm.blp + AtlasMaps.lua
--  * Boss loot + drop %: AtlasLoot_OriginalWoW/originalwow.lua, AtlasLoot_Data["RagefireChasm"], GPL
--  * Quests: AtlasQuest (nanderson11/AtlasQuest, GPLv2) Data/Quests.lua + Locales/enUS.lua,
--    cross-checked with the AzerothCore world DB (quest_template, quest_template_addon,
--    creature_queststarter/questender) for IDs, chain order and rewards.
--  * Creature abilities: server notes (restored Vanilla AI) + AzerothCore smart_scripts.
--  * Creature levels / elite rank: AzerothCore creature_template.
-- No drop rate is invented: an item without a recorded rate has rate = nil.
local SDJ = DungeonJournal
local P = SDJ.PORTRAITS

SDJ:AddDungeon("Vanilla", {
    id = "rfc",
    name = "Ragefire Chasm",
    level = "12-18",          -- Atlas LevelRange
    minLevel = "8",           -- Atlas MinLevel
    location = "Orgrimmar - Cleft of Shadow",
    tag = "Dungeon",
    art = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenRagefireChasm",
    artFallback = SDJ.MAPS .. "RagefireChasm",
    crop = {0.04, 0.96, 0.29, 0.73},
    fallbackCrop = {0.0, 1.0, 0.25, 0.70},

    ------------------------------------------------------------------ MAP
    maps = {
        {
            name = "Ragefire Chasm",
            texture = SDJ.MAPS .. "RagefireChasm",   -- 512x512 BLP, whole texture is the map (as Atlas uses it)
            coords = {0, 1, 0, 1},
            legend = {
                {"A", "Entrance", "blue"},
                {"1", "Maur Grimtotem"},
                {"", "Oggleflint <Ragefire Chieftain>"},
                {"2", "Taragaman the Hungerer"},
                {"3", "Jergosh the Invoker"},
                {"", "Zelemar the Wrathful (summon)"},
                {"4", "Bazzalan"},
            },
            credit = "Map: Atlas (Dan Gilbert, map by Niflheim) - GPL",
        },
    },

    ------------------------------------------------------------------ TRASH
    trash = {
        mobs = {
            {
                name = "Ragefire Shaman", npc = 11319, level = "13-15 Elite", priority = 1,
                abilities = {
                    {spell = 11986, name = "Healing Wave", tag = "HEAL", desc = "Heals an injured ally."},
                    {spell = 9532,  name = "Lightning Bolt", desc = "3 sec cast Nature nuke."},
                    {name = "Flees for help", tag = "FLEE", desc = "Runs at 15% health to pull more troggs."},
                },
                note = "Kill first. Interrupt Healing Wave; stop runners.",
            },
            {
                name = "Searing Blade Warlock", npc = 11324, level = "13-15 Elite", priority = 1,
                abilities = {
                    {spell = 12746, name = "Summon Voidwalker", tag = "SUMMON", desc = "Has a Voidwalker out before the pull."},
                    {spell = 20791, name = "Shadow Bolt", desc = "Frequent 3 sec cast."},
                    {name = "Flees for help", tag = "FLEE", desc = "Runs at 15% health."},
                },
                note = "Kill the Warlock before its Voidwalker; stop it fleeing.",
            },
            {
                name = "Searing Blade Cultist", npc = 11322, level = "13-15 Elite", priority = 2,
                abilities = {
                    {spell = 18266, name = "Curse of Agony", tag = "CURSE", desc = "Shadow damage over 15 sec on a random target."},
                },
                note = "Drops Spells of Shadow / Incantations from the Nether (quest).",
            },
            {
                name = "Searing Blade Enforcer", npc = 11323, level = "13-15 Elite", priority = 2,
                abilities = {
                    {spell = 8242, name = "Shield Slam", tag = "STUN", desc = "Damage plus a 2 sec stun."},
                },
                note = "Hits the tank hard; don't let a stunned tank drop threat.",
            },
            {
                name = "Earthborer", npc = 11320, level = "13-14 Elite", priority = 3,
                abilities = {
                    {spell = 18070, name = "Earthborer Acid", desc = "Stacking armour reduction (5 stacks, 30 sec)."},
                },
                note = "Avoid double pulls while the tank carries Acid stacks.",
            },
            {
                name = "Molten Elemental", npc = 11321, level = "13 Elite", priority = 3,
                abilities = {
                    {spell = 18268, name = "Fire Shield", desc = "Permanent fire damage shield (hurts melee)."},
                    {spell = 7942,  name = "Immunity: Fire", tag = "IMMUNE", desc = "Immune to Fire."},
                },
                note = "Fire mages/warlocks: use Frost/Shadow.",
            },
        },
        -- AtlasLoot 3.3.5 has no RFC trash table. Only the quest drops that
        -- AtlasQuest ties to RFC trash are listed; no rate is known for them.
        loot = {
            {id = 14395, name = "Spells of Shadow", slot = "Quest Item - The Power to Destroy...", quality = 1, icon = "INV_Misc_Book_01",
             note = "Dropped by Searing Blade Cultists and Warlocks (AtlasQuest)."},
            {id = 14396, name = "Incantations from the Nether", slot = "Quest Item - The Power to Destroy...", quality = 1, icon = "INV_Misc_Book_06",
             note = "Dropped by Searing Blade Cultists and Warlocks (AtlasQuest)."},
        },
        lootNote = "AtlasLoot has no RFC trash table; only trash quest drops are listed (no recorded %).",
    },

    ------------------------------------------------------------------ BOSSES
    bosses = {
        {
            name = "Oggleflint", subname = "Ragefire Chieftain", npc = 11517, level = "16 Elite",
            optional = true, portrait = P .. "Oggleflint",
            summary = "Chieftain of the Ragefire troggs. Found beside Maur Grimtotem's body [1] in the trogg caves. Not needed for any quest, but he sits next to the Lost Satchel objective.",
            abilities = {
                {spell = 40505, name = "Cleave", desc = "110% weapon damage to the target and the nearest ally."},
            },
            mechanics = {
                "Optional kill. Clear or pull the nearby troggs first.",
                "Only the tank stands in front of him.",
            },
            loot = {},
            lootNote = "No boss-specific drops in AtlasLoot 3.3.5 (world drops only).",
        },
        {
            name = "Taragaman the Hungerer", npc = 11520, level = "16 Elite",
            portrait = P .. "TaragamanTheHungerer",
            summary = "Felguard on the central lava platform [2]. Neeru Fireblade names him leader of the Searing Blade; his heart is needed for Slaying the Beast.",
            abilities = {
                {spell = 18072, name = "Uppercut", desc = "Damage plus knock-back (10 yd)."},
                {spell = 11970, name = "Fire Nova", desc = "2 sec cast, Fire damage to nearby enemies."},
            },
            mechanics = {
                "Tank him away from the lava edge: Uppercut knocks back.",
                "Healers and ranged stay out of Fire Nova range.",
                "Clear the nearby packs before pulling.",
                "Slaying the Beast: everyone on the quest must loot the Heart.",
            },
            loot = {
                {id = 14149, name = "Subterranean Cape", slot = "Back", quality = 3, icon = "INV_Misc_Cape_18", rate = "31.59%"},
                {id = 14148, name = "Crystalline Cuffs", slot = "Wrist, Cloth", quality = 3, icon = "INV_Bracer_13", rate = "33.91%"},
                {id = 14145, name = "Cursed Felblade", slot = "One-Hand, Sword", quality = 3, icon = "INV_Weapon_ShortBlade_12", rate = "15.98%"},
                {id = 14540, name = "Taragaman the Hungerer's Heart", slot = "Quest Item - Slaying the Beast", quality = 1, icon = "INV_Misc_Organ_01", rate = "100%",
                 note = "Quest drop: only for players on Slaying the Beast."},
            },
        },
        {
            name = "Jergosh the Invoker", npc = 11518, level = "16 Elite",
            portrait = P .. "JergoshTheInvoker",
            summary = "Orc warlock and one of the two real leaders of the Searing Blade [3]. Kill target for Hidden Enemies.",
            abilities = {
                {spell = 20800, name = "Immolate", desc = "2 sec cast, Fire damage plus a DoT (21 sec)."},
                {spell = 18267, name = "Curse of Weakness", desc = "Reduces physical damage dealt for 30 sec."},
            },
            mechanics = {
                "Clear the surrounding Cultists and Enforcers first.",
                "Interrupt Immolate where you can; decurse Curse of Weakness on the tank.",
            },
            loot = {
                {id = 14150, name = "Robe of Evocation", slot = "Chest, Cloth", quality = 3, icon = "INV_Chest_Cloth_24", rate = "36.40%"},
                {id = 14147, name = "Cavedweller Bracers", slot = "Wrist, Mail", quality = 3, icon = "INV_Bracer_07", rate = "34.35%"},
                {id = 14151, name = "Chanting Blade", slot = "One-Hand, Dagger", quality = 3, icon = "INV_Weapon_ShortBlade_25", rate = "17.10%"},
            },
        },
        {
            name = "Zelemar the Wrathful", npc = 17830, level = "20 Elite",
            optional = true, portrait = P .. "ZelemarTheWrathful",
            summary = "Doomguard summoned at the Blood Filled Orb near Jergosh [3] for the Blood Elf paladin quest The Path of the Adept.",
            abilities = {},
            mechanics = {
                "Optional summon: only for Blood Elf paladins on The Path of the Adept.",
                "Level 20 Elite - much stronger than the other RFC bosses.",
            },
            loot = {
                {id = 24225, name = "Blood of the Wrathful", slot = "Quest Item - The Path of the Adept", quality = 1, icon = "INV_Potion_55", rate = "100%"},
            },
        },
        {
            name = "Bazzalan", npc = 11519, level = "16 Elite",
            portrait = P .. "Bazzalan",
            summary = "Satyr and the other real leader of the Searing Blade, at the end of the dungeon [4]. Kill target for Hidden Enemies.",
            abilities = {
                {spell = 2818, name = "Deadly Poison", desc = "Nature damage over time on melee hits."},
                {spell = 14873, name = "Sinister Strike", desc = "Instant extra melee damage."},
            },
            mechanics = {
                "Tank-and-spank. Cure poison on the tank if you can.",
            },
            loot = {},
            lootNote = "No boss-specific drops in AtlasLoot 3.3.5 (world drops only).",
        },
    },

    ------------------------------------------------------------------ QUESTS (Horde; AtlasQuest RFC list)
    quests = {
        {
            id = 5723, name = "Testing an Enemy's Strength", faction = "Horde", level = 15, minLevel = 9,
            giver = "Rahauro", giverLocation = "Thunder Bluff - Elder Rise (70.4, 32.2)",
            prerequisites = "None.",
            objective = "Search Orgrimmar for Ragefire Chasm, then kill 8 Ragefire Troggs and 8 Ragefire Shaman before returning to Rahauro in Thunder Bluff.",
            where = "The troggs and shamans are at the start of the dungeon.",
            turnin = "Rahauro", turninLocation = "Thunder Bluff - Elder Rise (70.4, 32.2)",
            rewards = {money = 700, reputation = "Thunder Bluff"},
            notes = "Ragefire Shamans heal and flee on this server: interrupt and finish runners.",
        },
        {
            id = 5725, name = "The Power to Destroy...", faction = "Horde", level = 16, minLevel = 9,
            giver = "Varimathras", giverLocation = "Undercity - Royal Quarter (56.2, 92.6)",
            prerequisites = "None.",
            objective = "Bring the books Spells of Shadow and Incantations from the Nether to Varimathras in Undercity.",
            requiredItems = {
                {id = 14395, name = "Spells of Shadow", where = "Searing Blade Cultists and Searing Blade Warlocks"},
                {id = 14396, name = "Incantations from the Nether", where = "Searing Blade Cultists and Searing Blade Warlocks"},
            },
            turnin = "Varimathras", turninLocation = "Undercity - Royal Quarter (56.2, 92.6)",
            rewards = {
                reputation = "Undercity",
                choice = {
                    {id = 15449, name = "Ghastly Trousers", slot = "Legs, Cloth", quality = 2, icon = "INV_Pants_14"},
                    {id = 15450, name = "Dredgemire Leggings", slot = "Legs, Leather", quality = 2, icon = "INV_Pants_07"},
                    {id = 15451, name = "Gargoyle Leggings", slot = "Legs, Mail", quality = 2, icon = "INV_Pants_03"},
                },
            },
            notes = "Both books are unique quest drops; no drop rate is recorded in the sources.",
        },
        {
            id = 5722, name = "Searching for the Lost Satchel", faction = "Horde", level = 16, minLevel = 9,
            giver = "Rahauro", giverLocation = "Thunder Bluff - Elder Rise (70.4, 32.2)",
            prerequisites = "None.",
            objective = "Search Ragefire Chasm for Maur Grimtotem's corpse and search it for any items of interest.",
            where = "Maur Grimtotem is at map point [1], next to Oggleflint.",
            turnin = "Maur Grimtotem (corpse)", turninLocation = "Ragefire Chasm [1]",
            followUp = "Returning the Lost Satchel (5724)",
            chain = {
                {id = 5722, name = "Searching for the Lost Satchel", text = "Rahauro -> find Maur Grimtotem in RFC [1]."},
                {id = 5724, name = "Returning the Lost Satchel", text = "Accepted from Maur Grimtotem (Grimtotem Satchel). Take the Grimtotem Satchel to Rahauro in Thunder Bluff. Reward: choice of Featherbead Bracers or Savannah Bracers, Thunder Bluff reputation."},
            },
            rewards = {
                text = "No reward for this step; the rewards come from the follow-up Returning the Lost Satchel:",
                choice = {
                    {id = 15452, name = "Featherbead Bracers", slot = "Wrist, Cloth", quality = 2, icon = "INV_Bracer_08"},
                    {id = 15453, name = "Savannah Bracers", slot = "Wrist, Leather", quality = 2, icon = "INV_Bracer_07"},
                },
            },
            notes = "Rahauro also gives Testing an Enemy's Strength - take both.",
        },
        {
            id = 5728, name = "Hidden Enemies", faction = "Horde", level = 16, minLevel = 9,
            giver = "Thrall", giverLocation = "Orgrimmar - Valley of Wisdom (32.0, 37.8)",
            prerequisites = "Hidden Enemies (5726) and Hidden Enemies (5727) from Thrall.",
            objective = "Kill Bazzalan and Jergosh the Invoker before returning to Thrall in Orgrimmar.",
            where = "Jergosh the Invoker [3], Bazzalan [4].",
            turnin = "Thrall", turninLocation = "Orgrimmar - Valley of Wisdom (32.0, 37.8)",
            followUp = "Hidden Enemies (5729)",
            chain = {
                {id = 5726, name = "Hidden Enemies", text = "Thrall: bring a Lieutenant's Insignia from the Burning Blade in Skull Rock (east of Orgrimmar). Lvl 12."},
                {id = 5727, name = "Hidden Enemies", text = "Take the Insignia to Neeru Fireblade (Cleft of Shadow), speak to him, then return to Thrall. Lvl 12."},
                {id = 5728, name = "Hidden Enemies", text = "RFC: kill Bazzalan and Jergosh the Invoker, return to Thrall. (this quest)"},
                {id = 5729, name = "Hidden Enemies", text = "Thrall: speak to Neeru Fireblade in Orgrimmar."},
                {id = 5730, name = "Hidden Enemies", text = "Neeru Fireblade -> speak to Thrall. Reward: choice of Kris, Hammer, Axe or Staff of Orgrimmar."},
            },
            rewards = {
                money = 800, reputation = "Orgrimmar",
                text = "The weapon choice is awarded at the end of the chain (5730):",
                choice = {
                    {id = 15443, name = "Kris of Orgrimmar", slot = "One-Hand, Dagger", quality = 2, icon = "INV_Weapon_ShortBlade_05"},
                    {id = 15445, name = "Hammer of Orgrimmar", slot = "One-Hand, Mace", quality = 2, icon = "INV_Hammer_23"},
                    {id = 15424, name = "Axe of Orgrimmar", slot = "Two-Hand, Axe", quality = 2, icon = "INV_Axe_04"},
                    {id = 15444, name = "Staff of Orgrimmar", slot = "Two-Hand, Staff", quality = 2, icon = "INV_Staff_GoldFeathered_01"},
                },
            },
            notes = "AtlasQuest lists the Orgrimmar weapons under this quest; in the AzerothCore DB they are the reward of the final step (5730).",
        },
        {
            id = 5761, name = "Slaying the Beast", faction = "Horde", level = 16, minLevel = 9,
            giver = "Neeru Fireblade", giverLocation = "Orgrimmar - Cleft of Shadow (49.6, 50.4)",
            prerequisites = "None.",
            objective = "Enter Ragefire Chasm and slay Taragaman the Hungerer, then bring his heart back to Neeru Fireblade in Orgrimmar.",
            requiredItems = {
                {id = 14540, name = "Taragaman the Hungerer's Heart", where = "Loot it from Taragaman the Hungerer [2]"},
            },
            turnin = "Neeru Fireblade", turninLocation = "Orgrimmar - Cleft of Shadow (49.6, 50.4)",
            rewards = {money = 800},
            notes = "Kill credit is not enough: every player on the quest must loot the Heart.",
        },
    },

    ------------------------------------------------------------------ PREPARATION
    preparation = {
        {title = "Level", lines = {
            "Dungeon level 12-18; entry from level 8 (Atlas). Quests from level 9.",
        }},
        {title = "Consumables", lines = {
            "Food, water and level-appropriate healing / mana potions.",
            "Cure Poison and Remove Curse help (Bazzalan, Cultists, Jergosh).",
        }},
        {title = "Keys & required items", lines = {
            "No key or attunement. Entrance: Cleft of Shadow, Orgrimmar.",
            "Hidden Enemies needs 5726 + 5727 done first (Skull Rock insignia).",
        }},
        {title = "Server rules (restored Vanilla AI)", lines = {
            "Ragefire Shamans cast Healing Wave and flee at low health.",
            "Searing Blade Warlocks bring a Voidwalker and flee at low health.",
            "Interrupt heals and kill runners before they pull more packs.",
        }},
    },
})
