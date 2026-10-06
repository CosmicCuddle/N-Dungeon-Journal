-- Dungeon Journal - Core
-- WoW 3.3.5a (Interface 30300). No retail-only APIs are used in this addon.
local ADDON_NAME = ...

DungeonJournal = DungeonJournal or {}
local SDJ = DungeonJournal

SDJ.ADDON_NAME = ADDON_NAME or "DungeonJournal"
SDJ.VERSION = "0.6.1"
SDJ.ROOT = "Interface\\AddOns\\DungeonJournal\\"
SDJ.MEDIA = SDJ.ROOT .. "Media\\"
SDJ.MAPS = SDJ.ROOT .. "Maps\\"
SDJ.PORTRAITS = SDJ.ROOT .. "Portraits\\"
SDJ.ALLIANCE_ICON = SDJ.MEDIA .. "Alliance.tga"
SDJ.HORDE_ICON = SDJ.MEDIA .. "Horde.tga"
SDJ.CHAIN_ICON = SDJ.MEDIA .. "QuestChain.tga"
SDJ.QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
SDJ.DUNGEONS = SDJ.DUNGEONS or { Vanilla = {}, TBC = {}, Wrath = {} }
SDJ.BY_ID = SDJ.BY_ID or {}
SDJ.ORDER = SDJ.ORDER or {}

-- Bot Consumables (Naxxramas Core BotRaidConsumables.cpp / MultiBot Chatless – Naxxramas Fork).
-- Command highlight used in Preparation and the help page.
SDJ.CMD = "|cff69ccf0"
local function C(cmd) return SDJ.CMD .. cmd .. "|r" end

-- Per-dungeon Preparation "Bot Consumables" lines (facts from the server owner only).
SDJ.BOT_CONSUMABLES = {
    mara_p = {
        C(".bot consumables mara") .. " — level cap 54; adds Nature Protection (Greater if the bot can use it).",
    },
    mara_o = {
        C(".bot consumables mara") .. " — level cap 54; adds Nature Protection (Greater if the bot can use it).",
    },
    mara_i = {
        C(".bot consumables mara") .. " — level cap 54; adds Nature Protection (Greater if the bot can use it).",
    },
    st = {
        C(".bot consumables sunken") .. " — level cap 54; Nature Protection.",
    },
    brd = {
        C(".bot consumables brd") .. " — level cap 60; Fire Protection.",
    },
    scholo = {
        C(".bot consumables scholo") .. " — Shadow Protection.",
    },
    strat_ud = {
        C(".bot consumables stratud") .. " (alias " .. C("strat") .. ") — Shadow Protection; you must be on the Undead/Service Entrance side.",
    },
    strat_live = {
        "No named Living-side profile. Use " .. C(".bot consumables <level>") .. " (custom levels 1–54 only).",
        "The named Stratholme profile is Undead-side only (" .. C(".bot consumables stratud") .. ").",
    },
    dm_e = {
        C(".bot consumables dm") .. " — server detects the wing. East: Nature Protection.",
    },
    dm_w = {
        C(".bot consumables dm") .. " — server detects the wing. West: Shadow Protection.",
    },
    dm_n = {
        C(".bot consumables dm") .. " — server detects the wing. North: Enhanced profile (bandages 20, Limited Invulnerability Potions 5, Brilliant Wizard Oil 1 for casters, Brilliant Mana Oil 1 for healers, Instant Poison VI 20 / Deadly Poison IV 20 for rogues).",
    },
    lbrs = {
        C(".bot consumables lbrs") .. " — normal level-60 role package; you must be in the Lower section.",
    },
    ubrs = {
        C(".bot consumables ubrs") .. " — Fire Protection plus the Enhanced profile; you must be in the Upper section.",
    },
    mc = {
        C(".bot consumables mc") .. " — works only inside Molten Core.",
        "Common package: Greater Fire Protection aura; Major Healing Potions topped to 5; Heavy Runecloth Bandages to 20; Limited Invulnerability Potions to 5; plus class reagents.",
        "Warrior tank: Flask of the Titans, Mongoose, Elixir of Fortitude, Superior Defense, Greater Stoneshield, Lung Juice Cocktail, Blessed Sunfruit, Juju Power/Might/Escape, Elemental Sharpening Stones (sharp) or Dense Weightstones (blunt) x20.",
        "DPS warrior (Arms/Fury): Titans, Mongoose, R.O.I.D.S., Blessed Sunfruit, Juju Power/Might/Flurry, plus stones.",
        "Holy Paladin: Major Mana Potions 5, Greater Intellect, Sages, Flask of Distilled Wisdom, Cerebral Cortex Compound, Nightfin Soup, Brilliant Mana Oil.",
        "Ret Paladin: Major Mana, Greater Intellect, Sages, Mongoose, Giants, R.O.I.D.S., Blessed Sunfruit, Juju Power/Might/Flurry, plus stones.",
        "Prot Paladin: unsupported.",
        "Hunter: Major Mana, Greater Intellect, Sages, Mongoose, Ground Scorpok Assay, Grilled Squid; active pet gets Juju Power/Might (skipped if no pet).",
        "Rogue: Mongoose, Ground Scorpok Assay, Grilled Squid, Juju Power/Might/Flurry, Instant Poison VI 20, Deadly Poison IV 20.",
        "Shadow Priest: caster package (Major Mana, Greater Intellect, Sages, Flask of Supreme Power, Greater Arcane Elixir, Cerebral Cortex Compound, Nightfin Soup, Brilliant Wizard Oil) + Shadow Power.",
        "Healing Priest: healer package (Major Mana, Greater Intellect, Sages, Flask of Distilled Wisdom, Cerebral Cortex Compound, Nightfin Soup, Brilliant Mana Oil).",
        "Shaman: Enhancement — Major Mana, Greater Intellect, Sages, Mongoose, R.O.I.D.S., Nightfin Soup, Juju Power/Might; Elemental — caster package; Resto — healer package.",
        "Mage: caster package; Frost also gets Frost Power.",
        "Warlock: caster package + Shadow Power, plus Soul Shards.",
        "Druid: Feral Tank — Titans, Mongoose, Lung Juice Cocktail, Greater Stoneshield, Blessed Sunfruit, Juju Power/Might; Feral DPS — Major Mana, Greater Intellect, Sages, Mongoose, Ground Scorpok Assay, Grilled Squid, Juju Power/Might; Balance — caster package; Resto — healer package.",
        "Death Knights: unsupported.",
        "Reagents: Druid Ironwood Seed 20 / Wild Thornroot 20; Mage Rune of Teleportation 10 / Rune of Portals 10 / Arcane Powder 20 / Light Feather 20; Paladin Symbol of Kings 100 / Symbol of Divinity 5; Priest Sacred Candle 20 / Light Feather 20; Rogue Flash Powder 20 / Blinding Powder 20; Shaman one each Earth/Fire/Water/Air Totem, Ankh 5, Shiny Fish Scales 20, Fish Oil 20; Warlock Soul Shard 5.",
        "Juju needs a Cache of Mau'ari (supplied automatically). Juju Flurry is applied 3 times, about 60 seconds apart.",
    },
    onyxia = {
        "Onyxia has no named " .. C(".bot consumables") .. " profile — do not invent one. Use flasks/pots from the raid checklist manually.",
    },
    bwl = {
        "Blackwing Lair has no named " .. C(".bot consumables") .. " profile — do not invent one. Use FR pots / Onyxia Scale Cloak / flasks from the preparation checklist manually.",
    },
    zg = {
        "Zul'Gurub has no named " .. C(".bot consumables") .. " profile (not in mara/sunken/brd/scholo/stratud/dm/lbrs/ubrs/mc).",
        "Custom " .. C(".bot consumables <1-54>") .. " only works inside non-raid dungeons — the system does not cover ZG yet. Do not invent a profile.",
    },
    aq20 = {
        "Ruins of Ahn'Qiraj has no named " .. C(".bot consumables") .. " profile — do not invent one. Use NR pots / flasks from the preparation checklist manually.",
    },
    aq40 = {
        "Temple of Ahn'Qiraj has no named " .. C(".bot consumables") .. " profile — do not invent one. Use NR / frost prep / flasks from the preparation checklist manually.",
    },
    naxx = {
        "Naxxramas has no named " .. C(".bot consumables") .. " profile — do not invent one. Use FR pots / flasks / Frozen Rune gear from the preparation checklist manually.",
    },
    azuregos = {
        "Azuregos has no named " .. C(".bot consumables") .. " profile — do not invent one. Use frost pots / flasks from the preparation checklist manually.",
    },
    kazzak = {
        "Lord Kazzak has no named " .. C(".bot consumables") .. " profile — do not invent one. Use shadow pots / flasks from the preparation checklist manually.",
    },
    emerald = {
        "Emerald Dragons have no named " .. C(".bot consumables") .. " profile — do not invent one. Use nature pots / flasks from the preparation checklist manually.",
    },
}
SDJ.BOT_CONSUMABLES_DEFAULT = {
    C(".bot consumables <1-54>") .. " — role-based package for this dungeon.",
    "Effective level = lowest of the requested level, the bot's level and the dungeon's level cap. Only works inside non-raid dungeons.",
}

function SDJ:GetBotConsumablesPrep(dungeon)
    if not dungeon or not dungeon.id then return nil end
    local lines = self.BOT_CONSUMABLES[dungeon.id] or self.BOT_CONSUMABLES_DEFAULT
    return { title = "Bot Consumables", lines = lines }
end


-- Register a dungeon. Entries are sorted by SDJ.ORDER[era] (list of ids) when
-- the browser is drawn, so per-dungeon data files can load in any order.
function SDJ:AddDungeon(era, data)
    if not era or not data or not data.id then return end
    self.DUNGEONS[era] = self.DUNGEONS[era] or {}
    local list = self.DUNGEONS[era]
    -- replace an existing entry with the same id (a detailed per-dungeon file
    -- may override a placeholder)
    for i, existing in ipairs(list) do
        if existing.id == data.id then
            list[i] = data
            self.BY_ID[data.id] = data
            return
        end
    end
    table.insert(list, data)
    self.BY_ID[data.id] = data
end

function SDJ:GetDungeonList(era)
    local list = self.DUNGEONS[era] or {}
    local order = self.ORDER[era]
    if not order then return list end
    local rank = {}
    for i, id in ipairs(order) do rank[id] = i end
    local sorted = {}
    for i, d in ipairs(list) do sorted[i] = d end
    local base = #order
    local pos = {}
    for i, d in ipairs(list) do pos[d] = i end
    table.sort(sorted, function(a, b)
        local ra = rank[a.id] or (base + pos[a])
        local rb = rank[b.id] or (base + pos[b])
        return ra < rb
    end)
    return sorted
end

function SDJ:PlayerFaction()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Horde" then return "Horde" end
    return "Alliance"
end

function SDJ:QuestMatchesFaction(quest, faction)
    if not quest then return false end
    local qf = quest.faction or "Both"
    return qf == "Both" or qf == faction
end

function SDJ:GetQuestCount(dungeon, faction)
    local count = 0
    if not dungeon or not dungeon.quests then return count end
    for _, quest in ipairs(dungeon.quests) do
        if self:QuestMatchesFaction(quest, faction) then count = count + 1 end
    end
    return count
end

-- Copper -> "1g 2s 3c"
function SDJ:FormatMoney(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then return nil end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local out = {}
    if g > 0 then table.insert(out, g .. "g") end
    if s > 0 then table.insert(out, s .. "s") end
    if c > 0 then table.insert(out, c .. "c") end
    return table.concat(out, " ")
end

------------------------------------------------------------------------
-- Tiny timer helper (3.3.5 has no C_Timer): one shared OnUpdate frame.
------------------------------------------------------------------------
local timers = {}
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local i = 1
    while i <= #timers do
        local t = timers[i]
        t.left = t.left - elapsed
        if t.left <= 0 then
            table.remove(timers, i)
            local ok, err = pcall(t.func)
            if not ok and geterrorhandler then geterrorhandler()(err) end
        else
            i = i + 1
        end
    end
    if #timers == 0 then self:Hide() end
end)

function SDJ:After(seconds, func)
    if type(func) ~= "function" then return end
    table.insert(timers, { left = seconds or 0, func = func })
    timerFrame:Show()
end

------------------------------------------------------------------------
-- SavedVariables (DungeonJournalDB - independent of any other addon)
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == SDJ.ADDON_NAME then
        if type(DungeonJournalDB) ~= "table" then DungeonJournalDB = {} end
        -- One-time migrate from the pre-rename SavedVariables (ServerDungeonJournalDB).
        if not DungeonJournalDB._migratedFromServerDungeonJournalDB
           and type(ServerDungeonJournalDB) == "table" then
            for k, v in pairs(ServerDungeonJournalDB) do
                if DungeonJournalDB[k] == nil then DungeonJournalDB[k] = v end
            end
            DungeonJournalDB._migratedFromServerDungeonJournalDB = true
        end
        DungeonJournalDB.lastEra = DungeonJournalDB.lastEra or "Vanilla"
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if type(DungeonJournalDB) ~= "table" then DungeonJournalDB = { lastEra = "Vanilla" } end
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Dungeon Journal|r v" .. SDJ.VERSION .. " loaded. Type |cffffffff/dj|r to open.")
        end
    end
end)

SLASH_DUNGEONJOURNAL1 = "/dj"
SLASH_DUNGEONJOURNAL2 = "/dungeonjournal"
SlashCmdList["DUNGEONJOURNAL"] = function(msg)
    if SDJ.Toggle then SDJ:Toggle() end
end
