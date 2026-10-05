-- DungeonJournal - UI (WoW 3.3.5a)
-- Layout kept from v0.3.0. Only 3.3.5 widget APIs are used: SetBackdrop on
-- plain frames (no template), SetTexture(path) / SetTexture + SetVertexColor
-- for solid colours, UIPanelScrollFrameTemplate, UIPanelButtonTemplate.
local SDJ = DungeonJournal

local frame
local selectedEra = "Vanilla"
local selectedSection = "Dungeons"  -- Dungeons | Raids | WorldBosses
local selectedDungeon
local selectedMode = "trash"
local selectedBoss = 1
local selectedQuest = 1
local selectedMapFloor = 1
local chainExpanded = false
local questFaction = "Alliance"

local COLORS = {
    gold = {1.00, 0.78, 0.20},
    parchment = {0.86, 0.76, 0.56},
    muted = {0.72, 0.67, 0.58},
    border = {0.47, 0.34, 0.16},
    panel = {0.16, 0.12, 0.07, 0.96},
    inset = {0.08, 0.065, 0.045, 0.94},
}

local QUALITY_COLORS = {
    [0]={0.62,0.62,0.62}, [1]={1,1,1}, [2]={0.12,1,0},
    [3]={0.0,0.44,0.87}, [4]={0.64,0.21,0.93}, [5]={1,0.5,0}
}
local QUALITY_HEX = { [0]="9d9d9d", [1]="ffffff", [2]="1eff00", [3]="0070dd", [4]="a335ee", [5]="ff8000" }

local DEFAULT_CROP = {0.04,0.96,0.29,0.73}
local BOOK_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local LOOT_ROW_H, LOOT_ROW_STEP = 40, 44

local H = "|cffffd100"     -- heading colour
local SUB = "|cffc6b58f"   -- sub label colour

local function SetBackdrop(f, bg, edge, edgeSize, inset)
    if not f or not f.SetBackdrop then return end
    f:SetBackdrop({
        bgFile = bg or "Interface\\Buttons\\WHITE8X8",
        edgeFile = edge or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize or 12,
        insets = {left=inset or 3,right=inset or 3,top=inset or 3,bottom=inset or 3},
    })
end

local function SolidTexture(parent, layer, r,g,b,a)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(r or 1,g or 1,b or 1,a or 1)
    return t
end

local function AddParchment(parent, alpha)
    local tex = parent:CreateTexture(nil, "BACKGROUND")
    tex:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
    tex:SetAllPoints(parent)
    tex:SetVertexColor(0.95,0.82,0.58,1)
    tex:SetAlpha(alpha or 0.13)
    return tex
end

local function EraLabel(era)
    if era == "TBC" then return "THE BURNING CRUSADE" end
    if era == "Wrath" then return "WRATH OF THE LICH KING" end
    return "VANILLA"
end

local function BulletLines(values)
    if not values or #values == 0 then return "None recorded." end
    local out = {}
    for _, value in ipairs(values) do table.insert(out, "- " .. tostring(value)) end
    return table.concat(out, "\n")
end

local function SpellIcon(spellID)
    if spellID and GetSpellInfo then
        local _, _, icon = GetSpellInfo(spellID)
        if icon then return "|T" .. icon .. ":14:14:0:0|t " end
    end
    return ""
end

-- ability = "text" (legacy) or {name=, spell=, tag=, desc=}
local function AbilityLine(a)
    if type(a) ~= "table" then return "- " .. tostring(a) end
    local s = SpellIcon(a.spell) .. "|cffffffff" .. tostring(a.name or "?") .. "|r"
    if a.tag then s = s .. " |cffff5a3c[" .. a.tag .. "]|r" end
    if a.desc and a.desc ~= "" then s = s .. " - " .. a.desc end
    return s
end

local function AbilityBlock(list)
    if not list or #list == 0 then return "None recorded." end
    local out = {}
    for _, a in ipairs(list) do table.insert(out, AbilityLine(a)) end
    return table.concat(out, "\n")
end

local function ItemText(it)
    local q = it.quality or 1
    local name = it.name or ("Item " .. tostring(it.id))
    if it.id then
        local n, _, iq, _, _, _, _, _, _, tex = GetItemInfo(it.id)
        if n then name, q = n, iq or q else SDJ:QueueItem(it.id) end
    end
    local icon = it.id and GetItemIcon and GetItemIcon(it.id) or (it.icon and ("Interface\\Icons\\" .. it.icon))
    local s = icon and ("|T" .. icon .. ":16:16:0:0|t ") or ""
    s = s .. "|cff" .. (QUALITY_HEX[q] or "ffffff") .. "[" .. name .. "]|r"
    if it.slot and it.slot ~= "" then s = s .. " |cffb3a894(" .. it.slot .. ")|r" end
    return s
end

-- SetTexture returns nil in 3.3.5 when the file cannot be loaded.
local function TrySetTexture(tex, path)
    if not path then return false end
    return tex:SetTexture(path) and true or false
end

-- v0.3.7: every scrolling text area goes through ScrollFit. The content height is measured
-- after SetText (GetStringHeight), the scroll child is resized, and the scrollbar is shown only
-- when the content is taller than the visible area.
local function TextHeight(fs)
    local h = (fs.GetStringHeight and fs:GetStringHeight()) or 0
    if (not h or h <= 0) and fs.GetHeight then h = fs:GetHeight() or 0 end
    return h or 0
end

local function ScrollFit(sf, content, h)
    h = math.max(1, math.ceil(h or 1))
    content:SetHeight(h)
    if sf.UpdateScrollChildRect then sf:UpdateScrollChildRect() end
    local view = sf:GetHeight() or 0
    local range = math.max(0, h - view)
    local bar = sf:GetName() and _G[sf:GetName().."ScrollBar"]
    sf.sdjRange = range
    if bar then
        if range > 0.5 then bar:Show() else bar:Hide() end
        if bar.SetMinMaxValues then bar:SetMinMaxValues(0, range) end
    end
    local cur = sf:GetVerticalScroll() or 0
    if cur > range then sf:SetVerticalScroll(range); if bar and bar.SetValue then bar:SetValue(range) end end
end

local function FitText(fs, content, pad, sf)
    local h = TextHeight(fs) + (pad or 12)
    if sf then ScrollFit(sf, content, h) else content:SetHeight(math.max(1, h)) end
end

-- mouse wheel scrolling that also works while the scrollbar is hidden
local function SetupScroll(sf)
    sf.scrollBarHideable = 1
    if sf.EnableMouseWheel then sf:EnableMouseWheel(true) end
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = self.sdjRange or 0
        if range <= 0 then return end
        local v = (self:GetVerticalScroll() or 0) - delta * 40
        if v < 0 then v = 0 elseif v > range then v = range end
        self:SetVerticalScroll(v)
        local bar = self:GetName() and _G[self:GetName().."ScrollBar"]
        if bar and bar.SetValue then bar:SetValue(v) end
    end)
    local bar = sf:GetName() and _G[sf:GetName().."ScrollBar"]
    if bar then bar:Hide() end
end

local homeCards, bossRows, questRows, lootRows, trashLootRows = {}, {}, {}, {}, {}

------------------------------------------------------------------ HOME
-- v0.3.7: Blizzard-style expansion tabs. Every path below is checked against a 3.3.5 client
-- listfile (tools/listfile_335.txt, harness). The character-frame tab art is flipped vertically so
-- the tabs rise out of the home panel's top edge. If a texture fails to load, the button falls back
-- to the old flat backdrop style.
local TAB_ACTIVE   = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"
local TAB_INACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"
local TAB_GLOW     = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight-yellow"
local ERA_LOGOS = {
    Vanilla = "Interface\\Glues\\Common\\Glues-WoW-Logo",
    TBC     = "Interface\\Glues\\Common\\Glues-WoW-BCLogo",
    Wrath   = "Interface\\Glues\\Common\\Glues-WoW-WotLKLogo",
}
local ERA_TAB_W, ERA_TAB_H = 256, 38
-- Primary section tabs (Dungeons | Raids | World Bosses) — same Blizzard tab art, slightly shorter
local SEC_TAB_W, SEC_TAB_H = 250, 38

-- three-piece tab (left cap / stretched middle / right cap), texcoords flipped top<->bottom
local function TabPieces(b, layer, path)
    local t = {}
    local l = b:CreateTexture(nil, layer); l:SetWidth(20); l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT")
    local r = b:CreateTexture(nil, layer); r:SetWidth(20); r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT")
    local m = b:CreateTexture(nil, layer); m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
    l:SetTexCoord(0, 0.15625, 1, 0); m:SetTexCoord(0.15625, 0.84375, 1, 0); r:SetTexCoord(0.84375, 1, 1, 0)
    t.l, t.m, t.r = l, m, r
    local ok = TrySetTexture(l, path) and TrySetTexture(m, path) and TrySetTexture(r, path)
    return t, ok
end
local function ShowPieces(t, show) for _,k in ipairs({"l","m","r"}) do if show then t[k]:Show() else t[k]:Hide() end end end

local function MakeEraButton(parent, era, x)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(ERA_TAB_W); b:SetHeight(ERA_TAB_H)
    b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 0)   -- sits on the home panel's top border
    local okA, okI
    b.active, okA = TabPieces(b, "BACKGROUND", TAB_ACTIVE)
    b.inactive, okI = TabPieces(b, "BACKGROUND", TAB_INACTIVE)
    b.textured = okA and okI
    -- permanent gold glow on the selected tab
    b.selGlow = b:CreateTexture(nil, "ARTWORK"); b.selGlow:SetPoint("TOPLEFT", 6, -2); b.selGlow:SetPoint("BOTTOMRIGHT", -6, 2)
    b.selGlow:SetTexCoord(0, 1, 1, 0); b.selGlow:SetBlendMode("ADD")
    if not TrySetTexture(b.selGlow, TAB_GLOW) then b.selGlow:SetTexture(nil) end
    -- hover glow (HIGHLIGHT layer is shown by the client while the mouse is over the button)
    b.hover = b:CreateTexture(nil, "HIGHLIGHT"); b.hover:SetPoint("TOPLEFT", 6, -2); b.hover:SetPoint("BOTTOMRIGHT", -6, 2)
    b.hover:SetTexCoord(0, 1, 1, 0); b.hover:SetBlendMode("ADD"); b.hover:SetAlpha(0.55)
    if not TrySetTexture(b.hover, TAB_GLOW) then b.hover:SetTexture("Interface\\Buttons\\WHITE8X8"); b.hover:SetVertexColor(1,0.82,0.3,0.12) end
    if not b.textured then
        ShowPieces(b.active, false); ShowPieces(b.inactive, false)
        SetBackdrop(b, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 10, 2)
    end
    b.logo = b:CreateTexture(nil, "OVERLAY"); b.logo:SetWidth(46); b.logo:SetHeight(23); b.logo:SetPoint("LEFT", 14, -1)
    b.text = b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.text:SetHeight(14); b.text:SetText(EraLabel(era))
    if TrySetTexture(b.logo, ERA_LOGOS[era]) then
        b.logo:SetTexCoord(0, 1, 0.08, 0.92)
        b.text:SetPoint("LEFT", b.logo, "RIGHT", 4, 1); b.text:SetPoint("RIGHT", -10, 1); b.text:SetJustifyH("CENTER")
    else
        b.logo:Hide(); b.text:SetPoint("CENTER", 0, 1)
    end
    b:SetScript("OnClick", function()
        selectedEra = era
        DungeonJournalDB.lastEra = era
        selectedDungeon = nil
        SDJ:ShowHome()
    end)
    return b
end

local function MakeSectionButton(parent, key, label, x, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width or SEC_TAB_W); b:SetHeight(SEC_TAB_H)
    b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 0)
    local okA, okI
    b.active, okA = TabPieces(b, "BACKGROUND", TAB_ACTIVE)
    b.inactive, okI = TabPieces(b, "BACKGROUND", TAB_INACTIVE)
    b.textured = okA and okI
    b.selGlow = b:CreateTexture(nil, "ARTWORK"); b.selGlow:SetPoint("TOPLEFT", 6, -2); b.selGlow:SetPoint("BOTTOMRIGHT", -6, 2)
    b.selGlow:SetTexCoord(0, 1, 1, 0); b.selGlow:SetBlendMode("ADD")
    if not TrySetTexture(b.selGlow, TAB_GLOW) then b.selGlow:SetTexture(nil) end
    b.hover = b:CreateTexture(nil, "HIGHLIGHT"); b.hover:SetPoint("TOPLEFT", 6, -2); b.hover:SetPoint("BOTTOMRIGHT", -6, 2)
    b.hover:SetTexCoord(0, 1, 1, 0); b.hover:SetBlendMode("ADD"); b.hover:SetAlpha(0.55)
    if not TrySetTexture(b.hover, TAB_GLOW) then b.hover:SetTexture("Interface\\Buttons\\WHITE8X8"); b.hover:SetVertexColor(1,0.82,0.3,0.12) end
    if not b.textured then
        ShowPieces(b.active, false); ShowPieces(b.inactive, false)
        SetBackdrop(b, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 10, 2)
    end
    b.text = b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.text:SetHeight(14); b.text:SetText(label); b.text:SetPoint("CENTER", 0, 1)
    b.section = key
    b:SetScript("OnClick", function()
        selectedSection = key
        selectedDungeon = nil
        SDJ:ShowHome()
    end)
    return b
end

local function UpdateEraButtons()
    for era,b in pairs(frame.eraButtons) do
        local sel = (era == selectedEra)
        if b.textured then
            ShowPieces(b.active, sel); ShowPieces(b.inactive, not sel)
            b:SetHeight(sel and ERA_TAB_H or ERA_TAB_H - 4)
        else
            b:SetBackdropColor(sel and 0.44 or 0.07, sel and 0.25 or 0.06, sel and 0.08 or 0.05, sel and 1 or 0.98)
            b:SetBackdropBorderColor(sel and 0.92 or 0.34, sel and 0.68 or 0.27, sel and 0.18 or 0.16, 1)
        end
        if sel then b.selGlow:Show(); b.selGlow:SetAlpha(0.75); b.text:SetTextColor(1,0.84,0.28) else b.selGlow:Hide(); b.text:SetTextColor(0.72,0.67,0.58) end
        if b.logo:IsShown() then b.logo:SetAlpha(sel and 1 or 0.6) end
    end
end

local function ApplyDungeonArt(tex, dungeon)
    local crop = dungeon.crop or DEFAULT_CROP
    if TrySetTexture(tex, dungeon.art) then
        tex:SetTexCoord(crop[1],crop[2],crop[3],crop[4])
    elseif TrySetTexture(tex, dungeon.artFallback) then
        local c = dungeon.fallbackCrop or {0,1,0,1}
        tex:SetTexCoord(c[1],c[2],c[3],c[4])
    else
        tex:SetTexture(BOOK_ICON)
        tex:SetTexCoord(0.08,0.92,0.08,0.92)
    end
end

local function HomeCard(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(352); b:SetHeight(126)
    SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",12,3)
    b:SetBackdropColor(0.02,0.02,0.02,0.65)
    b:SetBackdropBorderColor(0.34,0.34,0.34,1)

    b.art = b:CreateTexture(nil,"ARTWORK")
    b.art:SetPoint("TOPLEFT",4,-4)
    b.art:SetPoint("BOTTOMRIGHT",-4,4)
    b.art:SetTexture(BOOK_ICON)

    b.shade = SolidTexture(b,"ARTWORK",0,0,0,0.42)
    b.shade:SetPoint("TOPLEFT",4,-4); b.shade:SetPoint("BOTTOMRIGHT",-4,4)
    b.topShade = SolidTexture(b,"ARTWORK",0,0,0,0.54)
    b.topShade:SetPoint("TOPLEFT",4,-4); b.topShade:SetPoint("TOPRIGHT",-4,-4); b.topShade:SetHeight(44)
    b.highlight = SolidTexture(b,"HIGHLIGHT",1,0.84,0.24,0.10)
    b.highlight:SetPoint("TOPLEFT",4,-4); b.highlight:SetPoint("BOTTOMRIGHT",-4,4)

    b.title = b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    b.title:SetPoint("TOPLEFT",16,-14); b.title:SetWidth(225); b.title:SetHeight(44); b.title:SetJustifyH("LEFT"); b.title:SetJustifyV("TOP")
    b.title:SetTextColor(1,0.88,0.24); b.title:SetShadowColor(0,0,0,1); b.title:SetShadowOffset(1,-1)
    if STANDARD_TEXT_FONT then b.title:SetFont(STANDARD_TEXT_FONT,19,"OUTLINE") end

    b.meta = b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.meta:SetPoint("BOTTOMLEFT",14,11); b.meta:SetPoint("RIGHT",-80,0); b.meta:SetHeight(12); b.meta:SetJustifyH("LEFT")
    b.meta:SetTextColor(1,0.95,0.82); b.meta:SetShadowColor(0,0,0,1); b.meta:SetShadowOffset(1,-1)

    b.counts = b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.counts:SetPoint("TOPRIGHT",-14,-12); b.counts:SetJustifyH("RIGHT")
    b.counts:SetTextColor(0.97,0.89,0.54); b.counts:SetShadowColor(0,0,0,1); b.counts:SetShadowOffset(1,-1)

    b.badge = b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.badge:SetPoint("BOTTOMRIGHT",-12,11); b.badge:SetTextColor(0.95,0.79,0.26)

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1,0.76,0.22,1)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(self.dungeon and self.dungeon.name or "Dungeon")
        if self.dungeon then
            GameTooltip:AddLine(self.dungeon.location or "",1,1,1)
            if not self.dungeon.bosses or #self.dungeon.bosses == 0 then
                GameTooltip:AddLine("Journal data for this dungeon is still being populated.",0.8,0.72,0.55,true)
            else
                GameTooltip:AddLine("Click to open the journal entry.",0.8,0.8,0.8,true)
            end
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.34,0.34,0.34,1)
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function(self)
        if self.dungeon then SDJ:OpenDungeon(self.dungeon) end
    end)
    return b
end

local function IsRaidEntry(dungeon)
    return dungeon and (dungeon.tag == "Raid" or dungeon.raid == true)
end

local function IsWorldBossEntry(dungeon)
    return dungeon and (dungeon.tag == "World Boss" or dungeon.worldBoss == true)
end

local function EntryMatchesSection(dungeon)
    if selectedSection == "Raids" then return IsRaidEntry(dungeon) end
    if selectedSection == "WorldBosses" then return IsWorldBossEntry(dungeon) end
    -- Dungeons: everything that is not a raid or world boss
    return not IsRaidEntry(dungeon) and not IsWorldBossEntry(dungeon)
end

local function UpdateSectionButtons()
    if not frame or not frame.sectionButtons then return end
    for key,b in pairs(frame.sectionButtons) do
        local sel = (key == selectedSection)
        if b.textured then
            ShowPieces(b.active, sel); ShowPieces(b.inactive, not sel)
            b:SetHeight(sel and SEC_TAB_H or SEC_TAB_H - 4)
        else
            b:SetBackdropColor(sel and 0.44 or 0.07, sel and 0.25 or 0.06, sel and 0.08 or 0.05, sel and 1 or 0.98)
            b:SetBackdropBorderColor(sel and 0.92 or 0.34, sel and 0.68 or 0.27, sel and 0.18 or 0.16, 1)
        end
        if sel then b.selGlow:Show(); b.selGlow:SetAlpha(0.75); b.text:SetTextColor(1,0.84,0.28) else b.selGlow:Hide(); b.text:SetTextColor(0.72,0.67,0.58) end
    end
    if frame.homeTitle then
        if selectedSection == "Raids" then frame.homeTitle:SetText("Browse Raids")
        elseif selectedSection == "WorldBosses" then frame.homeTitle:SetText("Browse World Bosses")
        else frame.homeTitle:SetText("Browse Dungeons") end
    end
    if frame.homeSub then
        if selectedSection == "Raids" then
            frame.homeSub:SetText("Select a raid cover — same tabs as dungeons (trash, bosses, quests, preparation, maps)")
        elseif selectedSection == "WorldBosses" then
            frame.homeSub:SetText("Select a world boss cover — location, mechanics, loot, preparation and maps")
        else
            frame.homeSub:SetText("Select a dungeon cover to view trash, bosses, quests, preparation and maps")
        end
    end
    if frame.backButton then
        if selectedSection == "Raids" then frame.backButton:SetText("Raids")
        elseif selectedSection == "WorldBosses" then frame.backButton:SetText("World Bosses")
        else frame.backButton:SetText("Dungeons") end
    end
end

local function UpdateEraButtonsSecondary()
    -- era tabs stay Blizzard-style; they are the secondary filter under the section tabs
    UpdateEraButtons()
end

local function RefreshHome()
    UpdateSectionButtons()
    UpdateEraButtonsSecondary()
    local raw = SDJ:GetDungeonList(selectedEra)
    local list = {}
    for _,dungeon in ipairs(raw) do
        if EntryMatchesSection(dungeon) then table.insert(list, dungeon) end
    end
    local width = math.max(700,(frame.homeScroll:GetWidth() or 760)-4)
    local gap = 12
    local cardWidth = math.floor((width-gap)/2)
    frame.homeContent:SetWidth(width)
    local faction = SDJ:PlayerFaction()

    for i,dungeon in ipairs(list) do
        local card = homeCards[i]
        if not card then card = HomeCard(frame.homeContent); homeCards[i] = card end
        local col = (i-1)%2
        local row = math.floor((i-1)/2)
        card:SetWidth(cardWidth)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT",frame.homeContent,"TOPLEFT",col*(cardWidth+gap),-row*138)
        card.dungeon = dungeon
        card.title:SetText(dungeon.name)
        local meta = "LV " .. tostring(dungeon.level or "") .. "  |  " .. tostring(dungeon.location or "")
        if IsRaidEntry(dungeon) and dungeon.players then
            meta = meta .. "  |  " .. tostring(dungeon.players) .. "-PLAYER"
        end
        card.meta:SetText(meta)
        local count = SDJ:GetQuestCount(dungeon,faction)
        if count > 0 then
            local icon = faction == "Horde" and SDJ.HORDE_ICON or SDJ.ALLIANCE_ICON
            card.counts:SetText("|T"..icon..":20:20:0:0|t "..count..(count==1 and " quest" or " quests"))
        else
            card.counts:SetText("")
        end
        if IsRaidEntry(dungeon) then
            card.badge:SetText((dungeon.players or "?") .. "-PLAYER")
        elseif IsWorldBossEntry(dungeon) then
            card.badge:SetText("WORLD")
        elseif dungeon.tag == "Outdoor Dungeon" then
            card.badge:SetText("OUTDOOR")
        else
            card.badge:SetText("")
        end
        ApplyDungeonArt(card.art, dungeon)
        card:Show()
    end
    for i=#list+1,#homeCards do homeCards[i]:Hide() end
    local rows = math.max(1,math.ceil(#list/2))
    ScrollFit(frame.homeScroll, frame.homeContent, rows*138-12)
end

------------------------------------------------------------------ SHARED ROWS
local function ModeButton(parent,text,x)
    local b = CreateFrame("Button",nil,parent)
    b:SetWidth(96); b:SetHeight(27)
    b:SetPoint("TOPRIGHT",x,-18)
    SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",9,2)
    b.text=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    return b
end

local function UpdateModeButtons()
    local modes={trash=frame.trashTab,bosses=frame.bossTab,quests=frame.questTab,preparation=frame.prepTab,map=frame.mapTab}
    for mode,b in pairs(modes) do
        if mode==selectedMode then
            b:SetBackdropColor(0.43,0.23,0.07,1)
            b:SetBackdropBorderColor(0.92,0.68,0.18,1)
            b.text:SetTextColor(1,0.82,0.27)
        else
            b:SetBackdropColor(0.07,0.065,0.055,0.98)
            b:SetBackdropBorderColor(0.34,0.27,0.16,1)
            b.text:SetTextColor(0.77,0.71,0.62)
        end
    end
end

local function BossRow(parent)
    local b=CreateFrame("Button",nil,parent)
    b:SetWidth(300); b:SetHeight(52)
    SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",9,2)
    b:SetBackdropColor(0.08,0.065,0.045,0.94)
    b:SetBackdropBorderColor(0.28,0.22,0.14,1)
    b.badge=b:CreateTexture(nil,"ARTWORK")
    b.badge:SetTexture(SDJ.MEDIA.."BossLevelBadge.tga")
    b.badge:SetWidth(34); b.badge:SetHeight(34)
    b.badge:SetPoint("LEFT",8,0)
    b.level=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    b.level:SetPoint("CENTER",b.badge,0,0)
    b.level:SetTextColor(1,0.88,0.44)
    b.name=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.name:SetPoint("TOPLEFT",b.badge,"TOPRIGHT",9,-2)
    b.name:SetPoint("RIGHT",-8,0); b.name:SetHeight(14)
    b.name:SetJustifyH("LEFT")
    b.flag=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.flag:SetPoint("BOTTOMLEFT",b.badge,"BOTTOMRIGHT",9,2)
    b.flag:SetTextColor(0.75,0.69,0.60)
    b:SetScript("OnClick",function(self)
        if self.index then selectedBoss=self.index; SDJ:RefreshBosses() end
    end)
    return b
end

local function LootRow(parent)
    local b=CreateFrame("Button",nil,parent)
    b:SetWidth(392); b:SetHeight(LOOT_ROW_H)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",8,2)
    b:SetBackdropColor(0.07,0.06,0.045,0.96)
    b:SetBackdropBorderColor(0.26,0.22,0.14,1)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.icon:SetWidth(32); b.icon:SetHeight(32)
    b.icon:SetPoint("LEFT",5,0)
    b.name=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.name:SetPoint("TOPLEFT",b.icon,"TOPRIGHT",8,-1)
    b.name:SetPoint("RIGHT",-64,0); b.name:SetHeight(14)
    b.name:SetJustifyH("LEFT")
    b.slot=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.slot:SetPoint("BOTTOMLEFT",b.icon,"BOTTOMRIGHT",8,1)
    b.slot:SetPoint("RIGHT",-64,0); b.slot:SetHeight(12)
    b.slot:SetJustifyH("LEFT")
    b.slot:SetTextColor(0.70,0.66,0.58)
    b.rate=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.rate:SetPoint("RIGHT",-7,0)
    b.rate:SetWidth(56)
    b.rate:SetJustifyH("RIGHT")
    b.rate:SetTextColor(0.96,0.78,0.28)
    b.hl=SolidTexture(b,"HIGHLIGHT",1,0.84,0.24,0.08); b.hl:SetPoint("TOPLEFT",2,-2); b.hl:SetPoint("BOTTOMRIGHT",-2,2)
    b:SetScript("OnEnter",function(self) if self.item then SDJ:ShowItemTooltip(self,self.item) end end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnClick",function(self) if self.item then SDJ:HandleItemClick(self.item) end end)
    return b
end

local function PopulateLootRows(parent, pool, loot, content, noteString, noLootString, defaultEmpty, sf)
    loot = loot or {}
    for i,item in ipairs(loot) do
        local row=pool[i]
        if not row then row=LootRow(parent); pool[i]=row end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*LOOT_ROW_STEP)
        row.item=item
        local d=SDJ:GetItemDisplay(item)
        row.icon:SetTexture(d.icon)
        row.name:SetText(d.name)
        local c=QUALITY_COLORS[d.quality] or QUALITY_COLORS[1]
        row.name:SetTextColor(c[1],c[2],c[3])
        row.slot:SetText(d.slot or "")
        row.rate:SetText(d.rate ~= "" and d.rate or "|cff8a7f6e--|r")
        row:Show()
    end
    for i=#loot+1,#pool do pool[i]:Hide() end
    local h = #loot*LOOT_ROW_STEP
    -- the note sits in the scroll child under the rows, so a long note scrolls instead of overlapping
    noLootString:ClearAllPoints(); noLootString:SetPoint("TOPLEFT",content,"TOPLEFT",4,-(h+6))
    if noteString and noteString ~= "" then
        noLootString:SetText(noteString); noLootString:Show()
    elseif #loot==0 then
        noLootString:SetText(defaultEmpty or "No loot recorded."); noLootString:Show()
    else
        noLootString:SetText(""); noLootString:Hide()
    end
    if noLootString:IsShown() then h = h + 6 + TextHeight(noLootString) + 6 end
    if sf then ScrollFit(sf, content, h) else content:SetHeight(math.max(1,h)) end
end

local function QuestRow(parent)
    local b=CreateFrame("Button",nil,parent)
    b:SetWidth(296); b:SetHeight(52)
    SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",8,2)
    b:SetBackdropColor(0.08,0.065,0.045,0.94)
    b:SetBackdropBorderColor(0.27,0.22,0.14,1)
    b.faction1=b:CreateTexture(nil,"ARTWORK"); b.faction1:SetWidth(24); b.faction1:SetHeight(24); b.faction1:SetPoint("LEFT",8,0)
    b.both=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); b.both:SetPoint("LEFT",6,0); b.both:SetWidth(34); b.both:SetText("BOTH"); b.both:SetTextColor(0.95,0.79,0.26)
    b.name=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.name:SetPoint("TOPLEFT",42,-9); b.name:SetPoint("RIGHT",-8,0); b.name:SetHeight(14); b.name:SetJustifyH("LEFT")
    b.meta=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    b.meta:SetPoint("BOTTOMLEFT",42,9); b.meta:SetTextColor(0.75,0.69,0.60)
    b:SetScript("OnClick",function(self) if self.index then selectedQuest=self.index; chainExpanded=false; SDJ:RefreshQuests() end end)
    return b
end

local function SetFactionIcons(row,faction)
    row.faction1:Hide(); row.both:Hide()
    if faction=="Alliance" then row.faction1:SetTexture(SDJ.ALLIANCE_ICON); row.faction1:Show()
    elseif faction=="Horde" then row.faction1:SetTexture(SDJ.HORDE_ICON); row.faction1:Show()
    else row.both:Show() end
end

local function HideJournalPanels()
    frame.trashPanel:Hide(); frame.bossPanel:Hide(); frame.questPanel:Hide(); frame.prepPanel:Hide(); frame.mapPanel:Hide()
    if frame.botHelpPanel then frame.botHelpPanel:Hide() end
end


------------------------------------------------------------------ TRASH
local PRIORITY = { [1] = "|cffff5a3cHIGH|r", [2] = "|cffffb030MEDIUM|r", [3] = "|cffb3a894LOW|r" }

function SDJ:RefreshTrash()
    if not selectedDungeon then return end
    UpdateModeButtons(); HideJournalPanels(); frame.trashPanel:Show()
    local trash=selectedDungeon.trash or {}
    local chunks={}
    if trash.note and trash.note ~= "" then table.insert(chunks, H.."Overview|r\n"..trash.note) end
    for _,m in ipairs(trash.mobs or {}) do
        local s=H..tostring(m.name).."|r"
        if m.level then s=s.."  |cffb3a894"..m.level.."|r" end
        if m.priority then s=s.."  "..SUB.."Priority:|r "..(PRIORITY[m.priority] or tostring(m.priority)) end
        s=s.."\n"..AbilityBlock(m.abilities)
        if m.note and m.note~="" then s=s.."\n"..SUB.."Tip:|r "..m.note end
        table.insert(chunks,s)
    end
    for _,g in ipairs(trash.groups or {}) do   -- legacy v0.2/v0.3.0 format
        local s=H..tostring(g.name or "Trash").."|r\n"..BulletLines(g.abilities)
        if g.note and g.note~="" then s=s.."\n"..SUB.."Watch for:|r "..g.note end
        table.insert(chunks,s)
    end
    if #chunks==0 then
        frame.trashText:SetText("Trash ability data for this dungeon has not been populated yet.")
    else
        frame.trashText:SetText(table.concat(chunks,"\n\n"))
    end
    frame.trashTextScroll:SetVerticalScroll(0)
    FitText(frame.trashText, frame.trashTextContent, 12, frame.trashTextScroll)
    frame.trashLootScroll:SetVerticalScroll(0)
    PopulateLootRows(frame.trashLootContent,trashLootRows,trash.loot or {},frame.trashLootContent,trash.lootNote,frame.trashNoLoot,"No dungeon-specific trash loot recorded.",frame.trashLootScroll)
end

------------------------------------------------------------------ BOSSES
local function RefreshBossPortrait(boss)
    local tex = frame.selectedBossPortrait
    if boss and boss.rare then frame.selectedBossRareBorder:Show() else frame.selectedBossRareBorder:Hide() end
    if boss and TrySetTexture(tex, boss.portrait) then
        tex:SetTexCoord(0,1,0,1)
        frame.selectedBossFallback:Hide()
    else
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(0.10,0.07,0.04,1)
        frame.selectedBossFallback:Show()
        return
    end
    tex:SetVertexColor(1,1,1,1)
end

function SDJ:RefreshBosses()
    if not selectedDungeon then return end
    UpdateModeButtons(); HideJournalPanels(); frame.bossPanel:Show()
    local bosses=selectedDungeon.bosses or {}
    if #bosses==0 then
        frame.bossEmpty:Show(); frame.bossEmpty:SetText("Boss data for this dungeon has not been populated yet.")
    else frame.bossEmpty:Hide() end
    if selectedBoss>#bosses then selectedBoss=1 end
    for i,boss in ipairs(bosses) do
        local row=bossRows[i]
        if not row then row=BossRow(frame.bossListContent); bossRows[i]=row end
        row.index=i; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*58)
        row.name:SetText(boss.name or "Boss")
        row.level:SetText(tostring(boss.level or "??"):match("^(%d+)") or "??")
        row.flag:SetText(boss.rare and "|cffffd100RARE|r" or boss.optional and "Optional" or "")
        if i==selectedBoss then row:SetBackdropBorderColor(0.95,0.70,0.18,1); row:SetBackdropColor(0.18,0.11,0.04,0.98)
        else row:SetBackdropBorderColor(0.27,0.22,0.14,1); row:SetBackdropColor(0.08,0.065,0.045,0.94) end
        row:Show()
    end
    for i=#bosses+1,#bossRows do bossRows[i]:Hide() end
    ScrollFit(frame.bossList, frame.bossListContent, #bosses*58)

    local boss=bosses[selectedBoss]
    if not boss then
        frame.selectedBossName:SetText("No boss selected")
        frame.selectedBossLevel:SetText("")
        frame.bossInfo:SetText("")
        RefreshBossPortrait(nil)
        FitText(frame.bossInfo, frame.bossInfoContent, 12, frame.bossInfoScroll)
        PopulateLootRows(frame.lootContent,lootRows,{},frame.lootContent,nil,frame.noLoot,"No boss loot is available yet.",frame.lootScroll)
        return
    end

    frame.selectedBossName:SetText(boss.name or "Boss")
    local lvl = "Level "..tostring(boss.level or "?")
    if boss.subname then lvl = "<"..boss.subname..">  "..lvl end
    if boss.rare then lvl = lvl.."  |  |cffffd100Rare|r" elseif boss.optional then lvl = lvl.."  |  Optional" end
    frame.selectedBossLevel:SetText(lvl)
    RefreshBossPortrait(boss)

    local info=H.."WHO THEY ARE|r\n"..tostring(boss.summary or "No encounter summary recorded yet.")
    info=info.."\n\n"..H.."ABILITIES|r\n"..AbilityBlock(boss.abilities)
    if boss.mechanics and #boss.mechanics>0 then info=info.."\n\n"..H.."KEY MECHANICS|r\n"..BulletLines(boss.mechanics) end
    frame.bossInfo:SetText(info)
    frame.bossInfoScroll:SetVerticalScroll(0)
    FitText(frame.bossInfo, frame.bossInfoContent, 12, frame.bossInfoScroll)
    frame.lootScroll:SetVerticalScroll(0)
    PopulateLootRows(frame.lootContent,lootRows,boss.loot or {},frame.lootContent,boss.lootNote,frame.noLoot,"No boss loot recorded.",frame.lootScroll)
end

------------------------------------------------------------------ QUESTS
local function Place(name, loc)
    if not name then return "Not recorded" end
    if loc and loc ~= "" then return "|cffffffff"..name.."|r - "..loc end
    return "|cffffffff"..name.."|r"
end

local function QuestBody(q)
    local b = {}
    local function add(title, text) if text and text ~= "" then table.insert(b, H..title.."|r\n"..text) end end
    local idline = {}
    if q.id then table.insert(idline, "Quest ID: |cffffffff"..q.id.."|r") end
    if q.level then table.insert(idline, "Level: |cffffffff"..q.level.."|r") end
    if q.minLevel or q.requires then table.insert(idline, "Min level: |cffffffff"..(q.minLevel or q.requires).."|r") end
    if #idline > 0 then table.insert(b, table.concat(idline, "   ")) end
    if q.giver then add("QUEST GIVER", Place(q.giver, q.giverLocation)) else add("QUEST START", q.pickup) end
    add("PREREQUISITES", q.prerequisites)
    add("OBJECTIVE", q.objective)
    if q.requiredItems and #q.requiredItems > 0 then
        local t = {}
        for _, it in ipairs(q.requiredItems) do
            local s = ItemText(it)
            if it.where then s = s.."\n    "..SUB.."Where:|r "..it.where end
            table.insert(t, s)
        end
        add("REQUIRED ITEMS", table.concat(t, "\n"))
    end
    add("WHERE", q.where)
    if q.turnin and q.turninLocation then add("TURN IN", Place(q.turnin, q.turninLocation)) else add("TURN IN", q.turnin) end
    add("FOLLOW-UP", q.followUp)
    local r = q.rewards
    if type(r) == "table" then
        local t = {}
        local money = SDJ:FormatMoney(r.money)
        if money then table.insert(t, "Money: |cffffffff"..money.."|r") end
        if r.reputation then table.insert(t, "Reputation: |cffffffff"..r.reputation.."|r") end
        if r.text then table.insert(t, r.text) end
        if r.choice and #r.choice > 0 then
            if not r.text then table.insert(t, "Choose one of:") end
            for _, it in ipairs(r.choice) do table.insert(t, "  "..ItemText(it)) end
        end
        if r.items then for _, it in ipairs(r.items) do table.insert(t, "  "..ItemText(it)) end end
        add("REWARDS", #t > 0 and table.concat(t, "\n") or "None")
    elseif r then
        add("REWARDS", tostring(r))
    end
    add("SERVER NOTES", q.notes)
    if chainExpanded and q.chain then
        if type(q.chain) == "table" then
            local t = {}
            for i, step in ipairs(q.chain) do
                local cur = (step.id and step.id == q.id)
                local head = i..". "..(cur and "|cffffd100" or "|cffffffff")..tostring(step.name)..(step.id and (" ("..step.id..")") or "").."|r"
                table.insert(t, head..(step.text and ("\n    "..step.text) or ""))
            end
            add("QUEST CHAIN", table.concat(t, "\n"))
        else
            add("QUEST CHAIN", tostring(q.chain))
        end
    end
    return table.concat(b, "\n\n")
end

function SDJ:RefreshQuests()
    if not selectedDungeon then return end
    UpdateModeButtons(); HideJournalPanels(); frame.questPanel:Show()
    local faction=questFaction or SDJ:PlayerFaction()
    local visible={}
    local on, off = frame.allianceQuestButton, frame.hordeQuestButton
    if faction == "Horde" then on, off = off, on end
    on:SetBackdropColor(0.35,0.22,0.07,1); on:SetBackdropBorderColor(0.92,0.68,0.18,1)
    off:SetBackdropColor(0.07,0.06,0.05,1); off:SetBackdropBorderColor(0.30,0.24,0.16,1)
    for _,q in ipairs(selectedDungeon.quests or {}) do
        if SDJ:QuestMatchesFaction(q,faction) then table.insert(visible,q) end
    end
    if selectedQuest>#visible then selectedQuest=1 end
    for i,q in ipairs(visible) do
        local row=questRows[i]
        if not row then row=QuestRow(frame.questListContent); questRows[i]=row end
        row.index=i; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*58)
        row.name:SetText(q.name or "Quest")
        local m = {}
        if q.level then table.insert(m, "Level "..q.level) end
        if q.id then table.insert(m, "ID "..q.id) end
        row.meta:SetText(table.concat(m, "  |  "))
        SetFactionIcons(row,q.faction or "Both")
        if i==selectedQuest then row:SetBackdropBorderColor(0.95,0.70,0.18,1); row:SetBackdropColor(0.18,0.11,0.04,0.98)
        else row:SetBackdropBorderColor(0.27,0.22,0.14,1); row:SetBackdropColor(0.08,0.065,0.045,0.94) end
        row:Show()
    end
    for i=#visible+1,#questRows do questRows[i]:Hide() end
    ScrollFit(frame.questList, frame.questListContent, #visible*58)
    local q=visible[selectedQuest]
    if not q then
        frame.questTitle:SetText("No quests recorded")
        frame.questFaction:SetText("")
        frame.questText:SetText((faction == "Alliance" and "No Alliance" or "No Horde").." quests are recorded for this dungeon.")
        FitText(frame.questText, frame.questDetailContent, 18, frame.questDetail)
        frame.chainButton:Hide()
        return
    end
    frame.questTitle:SetText(q.name or "Quest")
    local iconText
    if q.faction=="Alliance" then iconText="|T"..SDJ.ALLIANCE_ICON..":24:24:0:0|t ALLIANCE"
    elseif q.faction=="Horde" then iconText="|T"..SDJ.HORDE_ICON..":24:24:0:0|t HORDE"
    else iconText="BOTH FACTIONS" end
    frame.questFaction:SetText(iconText)
    frame.questText:SetText(QuestBody(q))
    FitText(frame.questText, frame.questDetailContent, 18, frame.questDetail)
    if q.chain and q.chain~="" then
        frame.chainButton:Show()
        frame.chainButton:SetText(chainExpanded and "Hide Chain" or "Quest Chain")
    else frame.chainButton:Hide() end
end

------------------------------------------------------------------ PREPARATION
function SDJ:RefreshPreparation()
    if not selectedDungeon then return end
    UpdateModeButtons(); HideJournalPanels(); frame.prepPanel:Show()
    local prep=selectedDungeon.preparation or {}
    local out = {}
    for i, entry in ipairs(prep) do
        if type(entry) == "table" then
            table.insert(out, H..tostring(entry.title or "").."|r\n"..BulletLines(entry.lines))
        else
            table.insert(out, H..i..".|r  "..tostring(entry))   -- legacy string list
        end
    end
    local bot = SDJ:GetBotConsumablesPrep(selectedDungeon)
    if bot then
        table.insert(out, H..tostring(bot.title).."|r\n"..BulletLines(bot.lines))
    end
    if #out == 0 then
        frame.prepText:SetText("Preparation notes for this dungeon have not been populated yet.")
    else
        frame.prepText:SetText(table.concat(out, "\n\n"))
    end
    frame.prepScroll:SetVerticalScroll(0)
    FitText(frame.prepText, frame.prepContent, 12, frame.prepScroll)
end


------------------------------------------------------------------ MAP
function SDJ:RefreshMap()
    if not selectedDungeon then return end
    UpdateModeButtons(); HideJournalPanels(); frame.mapPanel:Show()
    local maps=selectedDungeon.maps or {}
    if selectedMapFloor>#maps then selectedMapFloor=1 end
    if selectedMapFloor<1 then selectedMapFloor=math.max(1,#maps) end
    local map = maps[selectedMapFloor]
    local tex = frame.mapTexture
    tex:Hide()
    frame.mapLegend:SetText("")
    frame.mapCredit:SetText("")
    if not map then
        frame.mapUnavailable:Show()
        frame.mapUnavailable:SetText("No map has been bundled for this dungeon yet.")
        frame.mapFloorName:SetText("No map available")
    elseif map.unsupported or not map.texture then
        frame.mapFloorName:SetText(map.name or "Map")
        frame.mapUnavailable:Show()
        frame.mapUnavailable:SetText("This dungeon's map has not been bundled yet (it will come from Atlas in a later batch).")
    elseif not TrySetTexture(tex, map.texture) then
        frame.mapFloorName:SetText(map.name or "Map")
        frame.mapUnavailable:Show()
        frame.mapUnavailable:SetText("Map file missing:\n"..tostring(map.texture))
    else
        local c = map.coords or {0,1,0,1}
        tex:SetTexCoord(c[1],c[2],c[3],c[4])
        tex:Show()
        frame.mapUnavailable:Hide()
        frame.mapFloorName:SetText(map.name or "Map")
        if map.legend then
            local t = {}
            for _, e in ipairs(map.legend) do
                local key = e[1] ~= "" and ((e[3] == "blue" and "|cff6fa8ff" or "|cffffd100")..e[1]..")|r ") or "      "
                table.insert(t, key.."|cffe8d6b3"..e[2].."|r")
            end
            frame.mapLegend:SetText(table.concat(t, "\n"))
        end
        frame.mapCredit:SetText(map.credit or "")
    end
    frame.mapLegendScroll:SetVerticalScroll(0)
    FitText(frame.mapLegend, frame.mapLegendContent, 8, frame.mapLegendScroll)
    if #maps>1 then
        frame.mapPrev:Show(); frame.mapNext:Show(); frame.mapCounter:Show()
        frame.mapCounter:SetText(tostring(selectedMapFloor).." / "..tostring(#maps))
    else
        frame.mapPrev:Hide(); frame.mapNext:Hide(); frame.mapCounter:Hide()
    end
end

------------------------------------------------------------------ NAV
local function SetMode(mode)
    selectedMode=mode
    if mode=="trash" then SDJ:RefreshTrash()
    elseif mode=="bosses" then SDJ:RefreshBosses()
    elseif mode=="quests" then SDJ:RefreshQuests()
    elseif mode=="preparation" then SDJ:RefreshPreparation()
    elseif mode=="map" then SDJ:RefreshMap()
    end
end

-- re-draw the current view when uncached items arrive from the server
SDJ:OnItemsCached(function()
    if frame and frame:IsShown() and selectedDungeon then SetMode(selectedMode) end
end)

function SDJ:OpenDungeon(dungeon)
    if not frame then return end
    selectedDungeon=dungeon
    selectedBoss=1; selectedQuest=1; selectedMapFloor=1; chainExpanded=false; questFaction=SDJ:PlayerFaction()
    frame.homePanel:Hide()
    if frame.botHelpPanel then frame.botHelpPanel:Hide() end
    frame.contentPanel:Show(); frame.backButton:Show()
    if frame.eraHolder then frame.eraHolder:Hide() end
    if frame.sectionHolder then frame.sectionHolder:Hide() end
    frame.dungeonTitle:SetText(dungeon.name)
    local meta="LV "..tostring(dungeon.level or "").."  |  "..tostring(dungeon.location or "")
    if dungeon.tag=="Outdoor Dungeon" then meta=meta.."  |  OUTDOOR DUNGEON"
    elseif dungeon.tag=="World Boss" or dungeon.worldBoss then meta=meta.."  |  WORLD BOSS"
    elseif (dungeon.tag=="Raid" or dungeon.raid) and dungeon.players then meta=meta.."  |  "..tostring(dungeon.players).."-PLAYER RAID" end
    local rl=dungeon.roleLevels
    if type(rl)=="table" and (rl.dps or rl.healer or rl.tank) then
        -- per-role recommended levels (server-supplied values; shown only when a dungeon defines them)
        meta=meta.."\nRecommended:  DPS "..tostring(rl.dps or "-").."  /  Healer "..tostring(rl.healer or "-").."  /  Tank "..tostring(rl.tank or "-")
    end
    frame.dungeonMeta:SetText(meta)
    ApplyDungeonArt(frame.dungeonArt, dungeon)
    SetMode("trash")
end

function SDJ:ShowHome()
    if not frame then return end
    frame.contentPanel:Hide()
    if frame.botHelpPanel then frame.botHelpPanel:Hide() end
    frame.homePanel:Show(); frame.backButton:Hide()
    if frame.eraHolder then frame.eraHolder:Show() end
    if frame.sectionHolder then frame.sectionHolder:Show() end
    selectedDungeon=nil
    RefreshHome()
end

local function NewPanel(parent)
    local p=CreateFrame("Frame",nil,parent)
    p:SetPoint("TOPLEFT",14,-84); p:SetPoint("BOTTOMRIGHT",-14,14)
    return p
end

local function Inset(f)
    SetBackdrop(f,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",12,3)
    f:SetBackdropColor(unpack(COLORS.inset)); f:SetBackdropBorderColor(0.39,0.24,0.08,1)
end

local function TextScroll(name, parent, width, fontObject)
    local sf=CreateFrame("ScrollFrame",name,parent,"UIPanelScrollFrameTemplate")
    local c=CreateFrame("Frame",nil,sf); c:SetWidth(width); c:SetHeight(1); sf:SetScrollChild(c)
    local fs=c:CreateFontString(nil,"OVERLAY",fontObject or "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT",4,-4); fs:SetWidth(width-8); fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
    fs:SetTextColor(0.91,0.84,0.70)
    if fs.SetSpacing then fs:SetSpacing(2) end
    return sf, c, fs
end

------------------------------------------------------------------ BUILD

-- v0.3.7 ESC handling. 3.3.5 path: ESC -> ToggleGameMenu -> CloseAllWindows -> CloseWindows ->
-- CloseSpecialWindows, which hides every shown _G[name] listed in UISpecialFrames.
local FRAME_NAME = "DungeonJournalFrame"
local function RegisterEscape()
    if type(UISpecialFrames) ~= "table" then return end
    for _,n in ipairs(UISpecialFrames) do if n == FRAME_NAME then return end end
    table.insert(UISpecialFrames, FRAME_NAME)
end
SDJ.FRAME_NAME = FRAME_NAME

-- closing (ESC, X button, slash toggle) resets the open state so the next open starts cleanly on home
local function ResetOnClose()
    if not frame then return end
    frame:StopMovingOrSizing()
    local owner = GameTooltip and GameTooltip:GetOwner()
    while owner do
        if owner == frame then GameTooltip:Hide(); break end
        owner = owner:GetParent()
    end
    selectedDungeon = nil; selectedBoss = 1; selectedQuest = 1; selectedMapFloor = 1; chainExpanded = false; selectedMode = "trash"
    selectedSection = "Dungeons"; selectedEra = "Vanilla"
    if DungeonJournalDB then DungeonJournalDB.lastEra = "Vanilla" end
    for _,sf in ipairs({frame.homeScroll, frame.trashTextScroll, frame.trashLootScroll, frame.bossList, frame.bossInfoScroll, frame.lootScroll,
                        frame.questList, frame.questDetail, frame.prepScroll, frame.mapLegendScroll, frame.botHelpScroll}) do
        if sf then sf:SetVerticalScroll(0) end
    end
    if frame.botHelpPanel then frame.botHelpPanel:Hide() end
    if frame.contentPanel then
        frame.contentPanel:Hide(); frame.homePanel:Show(); frame.backButton:Hide()
        if frame.sectionHolder then frame.sectionHolder:Show() end
        if frame.eraHolder then frame.eraHolder:Show() end
    end
end
SDJ.ResetOnClose = ResetOnClose

local function CreateFrameUI()
    frame=CreateFrame("Frame","DungeonJournalFrame",UIParent)
    frame:SetWidth(850); frame:SetHeight(590); frame:SetPoint("CENTER",0,10); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    -- dark stone background (UI-DialogBox-Background ships with 3.3.5; FrameGeneral\UI-Background-Rock does not)
    SetBackdrop(frame,"Interface\\DialogFrame\\UI-DialogBox-Background","Interface\\DialogFrame\\UI-DialogBox-Border",24,6)
    frame:SetBackdropColor(1,1,1,1)
    frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    RegisterEscape()   -- ESC closes (frame is named, top-level, parented to UIParent)
    frame:SetScript("OnShow", RegisterEscape)   -- re-register if another addon rebuilt UISpecialFrames
    frame:SetScript("OnHide", ResetOnClose)
    if hooksecurefunc and ToggleGameMenu and not SDJ.escHooked then
        SDJ.escHooked = true
        -- fallback: if ESC reached the game menu while the journal was still open (its UISpecialFrames
        -- entry was lost), close the journal and the menu that opened instead of it.
        hooksecurefunc("ToggleGameMenu", function()
            if frame and frame:IsShown() and GameMenuFrame and GameMenuFrame:IsShown() then
                frame:Hide(); HideUIPanel(GameMenuFrame)
            end
        end)
    end

    -- v0.3.7 title bar: gold dialog header (3.3.5 UI-DialogBox-Gold-Header, three pieces so it can
    -- stretch) straddling the top border, Huge gold title, tinted dialog divider underneath.
    local HEADER="Interface\\DialogFrame\\UI-DialogBox-Gold-Header"
    local hm=frame:CreateTexture(nil,"ARTWORK"); hm:SetWidth(250); hm:SetHeight(64); hm:SetPoint("TOP",0,10)
    local hl=frame:CreateTexture(nil,"ARTWORK"); hl:SetWidth(40); hl:SetHeight(64); hl:SetPoint("RIGHT",hm,"LEFT")
    local hr=frame:CreateTexture(nil,"ARTWORK"); hr:SetWidth(40); hr:SetHeight(64); hr:SetPoint("LEFT",hm,"RIGHT")
    hl:SetTexCoord(0.19,0.31,0,0.63); hm:SetTexCoord(0.31,0.69,0,0.63); hr:SetTexCoord(0.69,0.81,0,0.63)
    local headerOk=TrySetTexture(hm,HEADER) and TrySetTexture(hl,HEADER) and TrySetTexture(hr,HEADER)
    if not headerOk then
        hl:Hide(); hr:Hide(); hm:SetTexture("Interface\\Buttons\\WHITE8X8"); hm:SetVertexColor(0.14,0.10,0.055,0.96); hm:SetHeight(30); hm:SetPoint("TOP",0,-8)
    end
    local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); title:SetPoint("CENTER",hm,"TOP",0,headerOk and -23 or -15); title:SetWidth(300); title:SetHeight(24); title:SetText("Dungeon Journal"); title:SetTextColor(unpack(COLORS.gold))
    frame.titleText=title
    local subtitle=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); subtitle:SetPoint("TOPRIGHT",-40,-17); subtitle:SetText("Server Edition"); subtitle:SetTextColor(0.78,0.64,0.36)
    local div=frame:CreateTexture(nil,"BORDER"); div:SetPoint("TOPLEFT",24,-36); div:SetPoint("TOPRIGHT",-24,-36); div:SetHeight(16)
    if TrySetTexture(div,"Interface\\DialogFrame\\UI-DialogBox-Divider") then div:SetTexCoord(0,0.71,0,1); div:SetVertexColor(1,0.82,0.42) -- metal bar tinted gold
    else div:SetTexture("Interface\\Buttons\\WHITE8X8"); div:SetVertexColor(0.68,0.52,0.20,0.65); div:SetHeight(1) end
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3)
    frame.backButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); frame.backButton:SetWidth(120); frame.backButton:SetHeight(24); frame.backButton:SetPoint("TOPLEFT",28,-54); frame.backButton:SetText("Dungeons"); frame.backButton:SetScript("OnClick",function() SDJ:ShowHome() end)

    local home=CreateFrame("Frame",nil,frame); frame.homePanel=home; home:SetPoint("TOPLEFT",18,-86); home:SetPoint("BOTTOMRIGHT",-18,18)
    SetBackdrop(home,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",14,4); home:SetBackdropColor(unpack(COLORS.panel)); home:SetBackdropBorderColor(unpack(COLORS.border)); AddParchment(home,0.15)
    local ht=home:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); ht:SetPoint("TOPLEFT",18,-15); ht:SetText("Browse Dungeons"); ht:SetTextColor(unpack(COLORS.gold))
    frame.homeTitle = ht
    local hs=home:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hs:SetPoint("TOPLEFT",ht,"BOTTOMLEFT",1,-5); hs:SetText("Select a dungeon cover to view trash, bosses, quests, preparation and maps"); hs:SetTextColor(unpack(COLORS.muted))
    frame.homeSub = hs
    frame.botHelpButton=CreateFrame("Button",nil,home,"UIPanelButtonTemplate")
    frame.botHelpButton:SetWidth(140); frame.botHelpButton:SetHeight(24)
    frame.botHelpButton:SetPoint("TOPRIGHT",-18,-14)
    frame.botHelpButton:SetText("Bot Consumables")
    frame.botHelpButton:SetScript("OnClick", function() SDJ:ShowBotConsumablesHelp() end)
    -- Secondary expansion filter (Vanilla / TBC / Wrath) under the primary section tabs
    frame.eraHolder=CreateFrame("Frame",nil,home); frame.eraHolder:SetPoint("TOPLEFT",home,"TOPLEFT",8,-52); frame.eraHolder:SetPoint("TOPRIGHT",home,"TOPRIGHT",-160,-52); frame.eraHolder:SetHeight(ERA_TAB_H)
    frame.eraButtons={}
    -- slightly narrower era tabs so three fit as a secondary row
    local function MakeEraButtonSecondary(parent, era, x)
        local b = MakeEraButton(parent, era, x)
        b:SetWidth(200)
        return b
    end
    frame.eraButtons.Vanilla=MakeEraButtonSecondary(frame.eraHolder,"Vanilla",4)
    frame.eraButtons.TBC=MakeEraButtonSecondary(frame.eraHolder,"TBC",210)
    frame.eraButtons.Wrath=MakeEraButtonSecondary(frame.eraHolder,"Wrath",416)
    frame.homeScroll=CreateFrame("ScrollFrame","DungeonJournalHomeScroll",home,"UIPanelScrollFrameTemplate"); frame.homeScroll:SetPoint("TOPLEFT",18,-96); frame.homeScroll:SetPoint("BOTTOMRIGHT",-31,15)
    frame.homeContent=CreateFrame("Frame",nil,frame.homeScroll); frame.homeContent:SetWidth(747); frame.homeContent:SetHeight(1); frame.homeScroll:SetScrollChild(frame.homeContent)
    -- Primary section tabs (DUNGEONS | RAIDS | WORLD BOSSES) sit on the home panel's top edge
    frame.sectionHolder=CreateFrame("Frame",nil,frame); frame.sectionHolder:SetPoint("BOTTOMLEFT",home,"TOPLEFT",0,-4); frame.sectionHolder:SetPoint("BOTTOMRIGHT",home,"TOPRIGHT",0,-4); frame.sectionHolder:SetHeight(SEC_TAB_H); frame.sectionHolder:SetFrameLevel(home:GetFrameLevel()+3)
    frame.sectionButtons={}
    frame.sectionButtons.Dungeons=MakeSectionButton(frame.sectionHolder,"Dungeons","Dungeons",10,240)
    frame.sectionButtons.Raids=MakeSectionButton(frame.sectionHolder,"Raids","Raids",262,240)
    frame.sectionButtons.WorldBosses=MakeSectionButton(frame.sectionHolder,"WorldBosses","World Bosses",514,270)
    local content=CreateFrame("Frame",nil,frame); frame.contentPanel=content; content:SetPoint("TOPLEFT",18,-90); content:SetPoint("BOTTOMRIGHT",-18,18)
    SetBackdrop(content,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",14,4); content:SetBackdropColor(unpack(COLORS.panel)); content:SetBackdropBorderColor(unpack(COLORS.border)); AddParchment(content,0.13)
    frame.dungeonArt=content:CreateTexture(nil,"BACKGROUND"); frame.dungeonArt:SetAllPoints(content); frame.dungeonArt:SetAlpha(0.08)
    local shade=SolidTexture(content,"BACKGROUND",0.08,0.05,0.03,0.72); shade:SetAllPoints(content)

    local header=CreateFrame("Frame",nil,content); header:SetPoint("TOPLEFT",14,-12); header:SetPoint("TOPRIGHT",-14,-12); header:SetHeight(62)
    SetBackdrop(header,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",10,2); header:SetBackdropColor(0.24,0.17,0.09,0.94); header:SetBackdropBorderColor(0.52,0.33,0.11,1); AddParchment(header,0.12)
    frame.dungeonTitle=header:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); frame.dungeonTitle:SetPoint("TOPLEFT",15,-10); frame.dungeonTitle:SetWidth(285); frame.dungeonTitle:SetHeight(22); frame.dungeonTitle:SetJustifyH("LEFT"); frame.dungeonTitle:SetTextColor(1,0.82,0.27)
    frame.dungeonMeta=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); frame.dungeonMeta:SetPoint("TOPLEFT",frame.dungeonTitle,"BOTTOMLEFT",0,-4); frame.dungeonMeta:SetWidth(285); frame.dungeonMeta:SetHeight(24); frame.dungeonMeta:SetJustifyH("LEFT"); frame.dungeonMeta:SetJustifyV("TOP"); frame.dungeonMeta:SetTextColor(0.88,0.80,0.66)

    frame.mapTab=ModeButton(header,"MAP",-10)
    frame.prepTab=ModeButton(header,"PREPARATION",-109)
    frame.questTab=ModeButton(header,"QUESTS",-208)
    frame.bossTab=ModeButton(header,"BOSSES",-307)
    frame.trashTab=ModeButton(header,"TRASH",-406)
    frame.trashTab:SetScript("OnClick",function() SetMode("trash") end)
    frame.bossTab:SetScript("OnClick",function() SetMode("bosses") end)
    frame.questTab:SetScript("OnClick",function() SetMode("quests") end)
    frame.prepTab:SetScript("OnClick",function() SetMode("preparation") end)
    frame.mapTab:SetScript("OnClick",function() SetMode("map") end)

    -- TRASH panel
    frame.trashPanel=NewPanel(content)
    local tleft=CreateFrame("Frame",nil,frame.trashPanel); tleft:SetPoint("TOPLEFT",0,0); tleft:SetPoint("BOTTOMLEFT",0,0); tleft:SetWidth(360); Inset(tleft)
    local tt=tleft:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); tt:SetPoint("TOPLEFT",12,-10); tt:SetText("Dangerous Trash"); tt:SetTextColor(unpack(COLORS.gold))
    frame.trashTextScroll, frame.trashTextContent, frame.trashText = TextScroll("DungeonJournalTrashTextScroll", tleft, 306)
    frame.trashTextScroll:SetPoint("TOPLEFT",12,-38); frame.trashTextScroll:SetPoint("BOTTOMRIGHT",-30,10)

    local tright=CreateFrame("Frame",nil,frame.trashPanel); tright:SetPoint("TOPLEFT",tleft,"TOPRIGHT",10,0); tright:SetPoint("BOTTOMRIGHT",0,0); Inset(tright)
    local trt=tright:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); trt:SetPoint("TOPLEFT",12,-10); trt:SetText("Trash Loot"); trt:SetTextColor(unpack(COLORS.gold))
    local trr=tright:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); trr:SetPoint("TOPRIGHT",-37,-15); trr:SetText("DROP"); trr:SetTextColor(0.82,0.69,0.40)
    frame.trashLootScroll=CreateFrame("ScrollFrame","DungeonJournalTrashLootScroll",tright,"UIPanelScrollFrameTemplate"); frame.trashLootScroll:SetPoint("TOPLEFT",12,-38); frame.trashLootScroll:SetPoint("BOTTOMRIGHT",-30,10)
    frame.trashLootContent=CreateFrame("Frame",nil,frame.trashLootScroll); frame.trashLootContent:SetWidth(392); frame.trashLootContent:SetHeight(1); frame.trashLootScroll:SetScrollChild(frame.trashLootContent)
    frame.trashNoLoot=frame.trashLootContent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); frame.trashNoLoot:SetPoint("TOPLEFT",4,-6); frame.trashNoLoot:SetWidth(384); frame.trashNoLoot:SetJustifyH("LEFT"); frame.trashNoLoot:SetTextColor(0.75,0.69,0.60)

    -- BOSS panel
    frame.bossPanel=NewPanel(content)
    local left=CreateFrame("Frame",nil,frame.bossPanel); left:SetPoint("TOPLEFT",0,0); left:SetPoint("BOTTOMLEFT",0,0); left:SetWidth(320); Inset(left)
    local lt=left:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); lt:SetPoint("TOPLEFT",12,-10); lt:SetText("Bosses"); lt:SetTextColor(unpack(COLORS.gold))
    frame.bossList=CreateFrame("ScrollFrame","DungeonJournalBossScroll",left,"UIPanelScrollFrameTemplate"); frame.bossList:SetPoint("TOPLEFT",10,-38); frame.bossList:SetPoint("BOTTOMRIGHT",-29,10)
    frame.bossListContent=CreateFrame("Frame",nil,frame.bossList); frame.bossListContent:SetWidth(300); frame.bossListContent:SetHeight(1); frame.bossList:SetScrollChild(frame.bossListContent)
    frame.bossEmpty=left:CreateFontString(nil,"OVERLAY","GameFontHighlight"); frame.bossEmpty:SetPoint("TOPLEFT",18,-60); frame.bossEmpty:SetWidth(275); frame.bossEmpty:SetHeight(40); frame.bossEmpty:SetJustifyH("LEFT"); frame.bossEmpty:SetTextColor(0.78,0.72,0.62)

    local right=CreateFrame("Frame",nil,frame.bossPanel); right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0); right:SetPoint("BOTTOMRIGHT",0,0); Inset(right)
    frame.selectedBossName=right:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); frame.selectedBossName:SetPoint("TOPLEFT",16,-13); frame.selectedBossName:SetWidth(310); frame.selectedBossName:SetHeight(18); frame.selectedBossName:SetJustifyH("LEFT"); frame.selectedBossName:SetTextColor(unpack(COLORS.gold))
    frame.selectedBossLevel=right:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); frame.selectedBossLevel:SetPoint("TOPLEFT",frame.selectedBossName,"BOTTOMLEFT",0,-3); frame.selectedBossLevel:SetWidth(310); frame.selectedBossLevel:SetHeight(12); frame.selectedBossLevel:SetJustifyH("LEFT"); frame.selectedBossLevel:SetTextColor(0.80,0.74,0.64)

    -- static portrait (bundled TGA) in a framed holder; replaces the PlayerModel that rendered black
    local holder=CreateFrame("Frame",nil,right); frame.selectedBossPortraitHolder=holder; holder:SetWidth(96); holder:SetHeight(96); holder:SetPoint("TOPRIGHT",-15,-10)
    SetBackdrop(holder,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",10,2); holder:SetBackdropColor(0.025,0.02,0.015,1); holder:SetBackdropBorderColor(0.72,0.52,0.18,1)
    frame.selectedBossPortrait=holder:CreateTexture(nil,"ARTWORK"); frame.selectedBossPortrait:SetPoint("TOPLEFT",4,-4); frame.selectedBossPortrait:SetPoint("BOTTOMRIGHT",-4,4)
    frame.selectedBossFallback=holder:CreateTexture(nil,"OVERLAY"); frame.selectedBossFallback:SetWidth(48); frame.selectedBossFallback:SetHeight(48); frame.selectedBossFallback:SetPoint("CENTER"); frame.selectedBossFallback:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); frame.selectedBossFallback:SetTexCoord(0.08,0.92,0.08,0.92)
    frame.selectedBossRareBorder=holder:CreateTexture(nil,"OVERLAY"); frame.selectedBossRareBorder:SetWidth(124); frame.selectedBossRareBorder:SetHeight(124); frame.selectedBossRareBorder:SetPoint("CENTER",0,0); frame.selectedBossRareBorder:SetTexture(SDJ.MEDIA.."RarePortraitDragonFrame.tga"); frame.selectedBossRareBorder:Hide()

    frame.bossInfoScroll, frame.bossInfoContent, frame.bossInfo = TextScroll("DungeonJournalBossInfoScroll", right, 300)
    frame.bossInfoScroll:SetPoint("TOPLEFT",12,-46); frame.bossInfoScroll:SetPoint("BOTTOMRIGHT",right,"TOPRIGHT",-138,-168)
    local lootTitle=right:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); lootTitle:SetPoint("TOPLEFT",14,-173); lootTitle:SetText("Full Loot Table"); lootTitle:SetTextColor(0.95,0.78,0.25)
    local rateTitle=right:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rateTitle:SetPoint("TOPRIGHT",-37,-178); rateTitle:SetText("DROP"); rateTitle:SetTextColor(0.82,0.69,0.40)
    frame.lootScroll=CreateFrame("ScrollFrame","DungeonJournalLootScroll",right,"UIPanelScrollFrameTemplate"); frame.lootScroll:SetPoint("TOPLEFT",14,-196); frame.lootScroll:SetPoint("BOTTOMRIGHT",-30,10)
    frame.lootContent=CreateFrame("Frame",nil,frame.lootScroll); frame.lootContent:SetWidth(392); frame.lootContent:SetHeight(1); frame.lootScroll:SetScrollChild(frame.lootContent)
    frame.noLoot=frame.lootContent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); frame.noLoot:SetPoint("TOPLEFT",4,-6); frame.noLoot:SetWidth(384); frame.noLoot:SetJustifyH("LEFT"); frame.noLoot:SetTextColor(0.75,0.69,0.60)

    -- QUEST panel
    frame.questPanel=NewPanel(content)
    local qleft=CreateFrame("Frame",nil,frame.questPanel); qleft:SetPoint("TOPLEFT",0,0); qleft:SetPoint("BOTTOMLEFT",0,0); qleft:SetWidth(330); Inset(qleft)
    local qt=qleft:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); qt:SetPoint("TOPLEFT",12,-10); qt:SetText("Quests"); qt:SetTextColor(unpack(COLORS.gold))
    local function FactionButton(icon, x, faction)
        local b=CreateFrame("Button",nil,qleft); b:SetWidth(27); b:SetHeight(27); b:SetPoint("TOPRIGHT",x,-6)
        SetBackdrop(b,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",8,2)
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(20); b.icon:SetHeight(20); b.icon:SetPoint("CENTER"); b.icon:SetTexture(icon)
        b:SetScript("OnClick",function() questFaction=faction; selectedQuest=1; chainExpanded=false; SDJ:RefreshQuests() end)
        return b
    end
    frame.allianceQuestButton=FactionButton(SDJ.ALLIANCE_ICON,-45,"Alliance")
    frame.hordeQuestButton=FactionButton(SDJ.HORDE_ICON,-14,"Horde")
    frame.questList=CreateFrame("ScrollFrame","DungeonJournalQuestScroll",qleft,"UIPanelScrollFrameTemplate"); frame.questList:SetPoint("TOPLEFT",10,-38); frame.questList:SetPoint("BOTTOMRIGHT",-29,10)
    frame.questListContent=CreateFrame("Frame",nil,frame.questList); frame.questListContent:SetWidth(296); frame.questListContent:SetHeight(1); frame.questList:SetScrollChild(frame.questListContent)
    local qright=CreateFrame("Frame",nil,frame.questPanel); qright:SetPoint("TOPLEFT",qleft,"TOPRIGHT",10,0); qright:SetPoint("BOTTOMRIGHT",0,0); Inset(qright)
    frame.questTitle=qright:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); frame.questTitle:SetPoint("TOPLEFT",14,-14); frame.questTitle:SetPoint("RIGHT",-14,0); frame.questTitle:SetHeight(22); frame.questTitle:SetJustifyH("LEFT"); frame.questTitle:SetTextColor(unpack(COLORS.gold))
    frame.questFaction=qright:CreateFontString(nil,"OVERLAY","GameFontNormal"); frame.questFaction:SetPoint("TOPLEFT",frame.questTitle,"BOTTOMLEFT",0,-6); frame.questFaction:SetHeight(24); frame.questFaction:SetTextColor(0.95,0.79,0.26)
    frame.chainButton=CreateFrame("Button",nil,qright,"UIPanelButtonTemplate"); frame.chainButton:SetWidth(142); frame.chainButton:SetHeight(23); frame.chainButton:SetPoint("TOPRIGHT",-14,-50); frame.chainButton:SetText("Quest Chain"); frame.chainButton:SetScript("OnClick",function() chainExpanded=not chainExpanded; SDJ:RefreshQuests() end)
    frame.questDetail, frame.questDetailContent, frame.questText = TextScroll("DungeonJournalQuestDetailScroll", qright, 410, "GameFontHighlightSmall")
    frame.questDetail:SetPoint("TOPLEFT",14,-80); frame.questDetail:SetPoint("BOTTOMRIGHT",-30,12)

    -- PREPARATION panel
    frame.prepPanel=NewPanel(content); Inset(frame.prepPanel)
    local pt=frame.prepPanel:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); pt:SetPoint("TOPLEFT",18,-16); pt:SetText("Preparation"); pt:SetTextColor(unpack(COLORS.gold))
    local ps=frame.prepPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ps:SetPoint("TOPLEFT",pt,"BOTTOMLEFT",0,-5); ps:SetText("Consumables, keys and required items, progression and server rules"); ps:SetTextColor(unpack(COLORS.muted))
    frame.prepScroll, frame.prepContent, frame.prepText = TextScroll("DungeonJournalPrepScroll", frame.prepPanel, 700, "GameFontHighlight")
    frame.prepScroll:SetPoint("TOPLEFT",18,-64); frame.prepScroll:SetPoint("BOTTOMRIGHT",-34,14)

    -- MAP panel (Atlas BLPs are 512x512 and use the whole texture, so the canvas is square)
    frame.mapPanel=NewPanel(content); Inset(frame.mapPanel)
    local mt=frame.mapPanel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); mt:SetPoint("TOPLEFT",16,-10); mt:SetText("Instance Map"); mt:SetTextColor(unpack(COLORS.gold))
    frame.mapCanvas=CreateFrame("Frame",nil,frame.mapPanel); frame.mapCanvas:SetWidth(320); frame.mapCanvas:SetHeight(320); frame.mapCanvas:SetPoint("TOPLEFT",14,-32)
    SetBackdrop(frame.mapCanvas,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",10,2); frame.mapCanvas:SetBackdropColor(0.02,0.02,0.02,1); frame.mapCanvas:SetBackdropBorderColor(0.42,0.27,0.10,1)
    frame.mapTexture=frame.mapCanvas:CreateTexture(nil,"ARTWORK"); frame.mapTexture:SetPoint("TOPLEFT",3,-3); frame.mapTexture:SetPoint("BOTTOMRIGHT",-3,3)
    frame.mapUnavailable=frame.mapCanvas:CreateFontString(nil,"OVERLAY","GameFontHighlight"); frame.mapUnavailable:SetPoint("CENTER"); frame.mapUnavailable:SetWidth(300); frame.mapUnavailable:SetTextColor(0.78,0.72,0.62)
    local mside=CreateFrame("Frame",nil,frame.mapPanel); mside:SetPoint("TOPLEFT",frame.mapCanvas,"TOPRIGHT",16,0); mside:SetPoint("BOTTOMRIGHT",-14,14)
    frame.mapFloorName=mside:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); frame.mapFloorName:SetPoint("TOPLEFT",0,0); frame.mapFloorName:SetPoint("RIGHT",0,0); frame.mapFloorName:SetHeight(18); frame.mapFloorName:SetJustifyH("LEFT"); frame.mapFloorName:SetTextColor(1,0.82,0.27)
    frame.mapPrev=CreateFrame("Button",nil,mside,"UIPanelButtonTemplate"); frame.mapPrev:SetWidth(80); frame.mapPrev:SetHeight(22); frame.mapPrev:SetPoint("TOPLEFT",0,-26); frame.mapPrev:SetText("Prev")
    frame.mapCounter=mside:CreateFontString(nil,"OVERLAY","GameFontHighlight"); frame.mapCounter:SetPoint("LEFT",frame.mapPrev,"RIGHT",10,0); frame.mapCounter:SetTextColor(0.85,0.79,0.68)
    frame.mapNext=CreateFrame("Button",nil,mside,"UIPanelButtonTemplate"); frame.mapNext:SetWidth(80); frame.mapNext:SetHeight(22); frame.mapNext:SetPoint("LEFT",frame.mapPrev,"RIGHT",50,0); frame.mapNext:SetText("Next")
    frame.mapPrev:SetScript("OnClick",function() selectedMapFloor=selectedMapFloor-1; if selectedMapFloor<1 then selectedMapFloor=math.max(1,#(selectedDungeon.maps or {})) end; SDJ:RefreshMap() end)
    frame.mapNext:SetScript("OnClick",function() selectedMapFloor=selectedMapFloor+1; if selectedMapFloor>#(selectedDungeon.maps or {}) then selectedMapFloor=1 end; SDJ:RefreshMap() end)
    local lg=mside:CreateFontString(nil,"OVERLAY","GameFontNormal"); lg:SetPoint("TOPLEFT",0,-58); lg:SetText("Legend"); lg:SetTextColor(unpack(COLORS.gold))
    -- v0.3.7: the legend scrolls inside the side panel; the attribution sits under the map image
    frame.mapLegendScroll, frame.mapLegendContent, frame.mapLegend = TextScroll("DungeonJournalMapLegendScroll", mside, 392, "GameFontHighlight")
    frame.mapLegendScroll:SetPoint("TOPLEFT",0,-76); frame.mapLegendScroll:SetPoint("BOTTOMRIGHT",-26,0)
    frame.mapLegend:SetTextColor(1,1,1)
    if frame.mapLegend.SetSpacing then frame.mapLegend:SetSpacing(4) end
    frame.mapCredit=frame.mapPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); frame.mapCredit:SetPoint("TOPLEFT",frame.mapCanvas,"BOTTOMLEFT",2,-5); frame.mapCredit:SetWidth(316); frame.mapCredit:SetHeight(24); frame.mapCredit:SetJustifyH("LEFT"); frame.mapCredit:SetJustifyV("TOP"); frame.mapCredit:SetTextColor(0.60,0.56,0.50)

    -- Bot Consumables help (home browser); same parchment style, scrolls, ESC closes the journal
    local help=CreateFrame("Frame",nil,frame); frame.botHelpPanel=help
    help:SetPoint("TOPLEFT",18,-86); help:SetPoint("BOTTOMRIGHT",-18,18)
    SetBackdrop(help,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border",14,4)
    help:SetBackdropColor(unpack(COLORS.panel)); help:SetBackdropBorderColor(unpack(COLORS.border)); AddParchment(help,0.15)
    local htitle=help:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); htitle:SetPoint("TOPLEFT",18,-15); htitle:SetText("Bot Consumables"); htitle:SetTextColor(unpack(COLORS.gold))
    local hsub=help:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hsub:SetPoint("TOPLEFT",htitle,"BOTTOMLEFT",1,-5)
    hsub:SetText("Naxxramas Core Playerbot packages — commands and short notes"); hsub:SetTextColor(unpack(COLORS.muted))
    frame.botHelpScroll, frame.botHelpContent, frame.botHelpText = TextScroll("DungeonJournalBotHelpScroll", help, 760, "GameFontHighlight")
    frame.botHelpScroll:SetPoint("TOPLEFT",18,-64); frame.botHelpScroll:SetPoint("BOTTOMRIGHT",-34,14)
    help:Hide()

    for _,sf in ipairs({frame.homeScroll, frame.trashTextScroll, frame.trashLootScroll, frame.bossList, frame.bossInfoScroll, frame.lootScroll,
                        frame.questList, frame.questDetail, frame.prepScroll, frame.mapLegendScroll, frame.botHelpScroll}) do SetupScroll(sf) end
    frame:Hide(); frame.contentPanel:Hide(); frame.backButton:Hide()
end


------------------------------------------------------------------ BOT CONSUMABLES HELP
local function BotHelpBody()
    local C = SDJ.CMD or "|cff69ccf0"
    local function cmd(s) return C .. s .. "|r" end
    local parts = {
        H .. "What it does|r\n" ..
        "Gives Playerbots role-appropriate consumables from class, spec, role, level, dungeon, weapon type, mana use and pet. Long-duration buffs (flasks, elixirs, food, scrolls, juju, protection) are applied as auras. Usable items (healing/mana potions 5, bandages 20, stones, poisons, oils) are topped up to a target — never stacked endlessly.",

        H .. "Roles (examples)|r\n" ..
        "- Tank: defense elixir + Protection scroll.\n" ..
        "- Strength DPS: strength elixir + Strength scroll.\n" ..
        "- Agility DPS: agility elixir + Agility scroll; Grilled Squid at 35+.\n" ..
        "- Healer: intellect/wisdom elixir + Spirit scroll; Nightfin Soup at 35+.\n" ..
        "- Caster DPS: school elixir (shadow/frost/fire, else arcane/wisdom) + Intellect scroll; Nightfin Soup at 35+.\n" ..
        "Every bot gets 5 level-appropriate healing potions. Mana users also get 5 mana potions (not warriors or rogues).",

        H .. "Who is affected|r\n" ..
        "Alt bots and random bots in your group/raid that are inside the correct instance or wing. Random bots are never modified globally. Death Knights and Protection Paladins (MC) are unsupported.",

        H .. "Commands|r\n" ..
        "- " .. cmd(".bot consumables 1-54") .. " — custom level package (1–54).\n" ..
        "- Named: " .. cmd("mara") .. ", " .. cmd("sunken") .. ", " .. cmd("brd") .. ", " .. cmd("scholo") .. ", " .. cmd("stratud") .. ", " .. cmd("dm") .. ", " .. cmd("lbrs") .. ", " .. cmd("ubrs") .. ", " .. cmd("mc") .. ".\n" ..
        "- " .. cmd(".bot consumables status") .. " — active profile, tracked auras, missing buffs, timed sequences.\n" ..
        "- " .. cmd(".bot consumables clear") .. " — remove tracked auras and stop timed sequences.",

        H .. "Tracking|r\n" ..
        "About every 10 seconds the server checks tracked auras and warns once per missing buff (with the command to re-run). Scrolls, Greater Stoneshield and Juju Escape do not warn. Juju Flurry is reapplied automatically 3 times, about 60 seconds apart. Profiles clear when you leave the instance or wing.",

        H .. "Molten Core|r\n" ..
        cmd(".bot consumables mc") .. " works inside MC only. Every bot gets Greater Fire Protection, 5 Major Healing Potions, 20 bandages, 5 LIPs and class reagents, plus class/spec raid consumables (flasks, elixirs, juju, food, weapon stones/oils by equipped weapon). A Cache of Mau'ari is supplied automatically for juju.",

        H .. "MultiBot addon|r\n" ..
        "Left-click the Consumables button for the custom level (1–54). Right-click for the named dungeon bar.",

        H .. "Dungeon profiles|r\n" ..
        "Each dungeon Preparation tab lists the matching command. See mara, sunken, brd, scholo, stratud, dm, lbrs, ubrs; other Vanilla dungeons use " .. cmd(".bot consumables <1-54>") .. ".",
    }
    return table.concat(parts, "\n\n")
end

function SDJ:ShowBotConsumablesHelp()
    if not frame then return end
    frame.contentPanel:Hide()
    frame.homePanel:Hide()
    frame.eraHolder:Hide()
    frame.backButton:Show()
    frame.botHelpPanel:Show()
    frame.botHelpText:SetText(BotHelpBody())
    frame.botHelpScroll:SetVerticalScroll(0)
    FitText(frame.botHelpText, frame.botHelpContent, 12, frame.botHelpScroll)
end

function SDJ:Toggle()
    if not frame then CreateFrameUI() end
    if frame:IsShown() then frame:Hide() else
        selectedEra=DungeonJournalDB.lastEra or "Vanilla"
        frame:Show(); SDJ:ShowHome()
    end
end

function SDJ:Open()
    if not frame then CreateFrameUI() end
    selectedEra=DungeonJournalDB.lastEra or "Vanilla"
    frame:Show(); SDJ:ShowHome()
end
