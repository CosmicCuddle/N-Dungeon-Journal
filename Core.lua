-- Dungeon Journal - Core
-- WoW 3.3.5a (Interface 30300). No retail-only APIs are used in this addon.
local ADDON_NAME = ...

DungeonJournal = DungeonJournal or {}
local SDJ = DungeonJournal

SDJ.ADDON_NAME = ADDON_NAME or "DungeonJournal"
SDJ.VERSION = "0.4.1"
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
