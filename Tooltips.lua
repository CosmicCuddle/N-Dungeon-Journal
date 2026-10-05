-- DungeonJournal - item display, tooltips, chat links and item cache
-- 3.3.5a notes:
--  * GetItemInfo(id) returns nil until the client has the item cached.
--  * GET_ITEM_INFO_RECEIVED does not exist in 3.3.5, so pending items are
--    polled with an OnUpdate frame and the visible view is refreshed once
--    they arrive.
--  * GetItemIcon(id) reads the client DBC and works for uncached items.
local SDJ = DungeonJournal

local pending = {}      -- [itemID] = true
local pendingCount = 0
local requested = {}    -- [itemID] = time of last request
local listeners = {}

local scanTip = CreateFrame("GameTooltip", "DungeonJournalScanTooltip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local function RequestItem(itemID)
    local now = GetTime and GetTime() or 0
    if requested[itemID] and now - requested[itemID] < 5 then return end
    requested[itemID] = now
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink("item:" .. itemID .. ":0:0:0:0:0:0:0")
    scanTip:Hide()
end

local poll = CreateFrame("Frame")
poll:Hide()
poll.elapsed = 0
poll:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.5 then return end
    self.elapsed = 0
    local arrived = false
    local asked = 0
    for itemID in pairs(pending) do
        if GetItemInfo(itemID) then
            pending[itemID] = nil
            pendingCount = pendingCount - 1
            arrived = true
        elseif asked < 4 then
            RequestItem(itemID)
            asked = asked + 1
        end
    end
    if arrived then
        for _, fn in ipairs(listeners) do pcall(fn) end
    end
    if pendingCount <= 0 then pendingCount = 0; self:Hide() end
end)

-- fn() is called whenever one or more pending items become cached.
function SDJ:OnItemsCached(fn)
    table.insert(listeners, fn)
end

function SDJ:QueueItem(itemID)
    itemID = tonumber(itemID)
    if not itemID or pending[itemID] then return end
    pending[itemID] = true
    pendingCount = pendingCount + 1
    poll:Show()
end

-- Returns a normalised display table for a loot entry. Stored data is used as
-- a fallback while the item is not cached yet.
function SDJ:GetItemDisplay(item)
    if not item then return nil end
    local itemID = tonumber(item.id or item[1])
    local fallbackName = item.name or item[2] or (itemID and ("Item " .. itemID)) or "Unknown Item"
    local name, link, quality, icon
    if itemID then
        local n, l, q, _, _, _, _, _, _, tex = GetItemInfo(itemID)
        name, link, quality, icon = n, l, q, tex
        if not n then self:QueueItem(itemID) end
        if not icon and GetItemIcon then icon = GetItemIcon(itemID) end
    end
    if not icon and item.icon then
        icon = "Interface\\Icons\\" .. item.icon
    end
    return {
        id = itemID,
        name = name or fallbackName,
        link = link,
        cached = name ~= nil,
        quality = quality or item.quality or 1,
        icon = icon or SDJ.QUESTION_ICON,
        slot = item.slot or item[3] or "",
        rate = item.rate or "",
        note = item.note,
    }
end

function SDJ:ShowItemTooltip(owner, item)
    if not owner or not item then return end
    local d = self:GetItemDisplay(item)
    if not d then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if d.id then
        GameTooltip:SetHyperlink("item:" .. d.id .. ":0:0:0:0:0:0:0")
        if not d.cached then
            GameTooltip:AddLine(d.name, 1, 1, 1)
            GameTooltip:AddLine("Item not cached yet - querying server...", 0.7, 0.7, 0.7)
            -- re-show once the server answers, if the mouse is still there
            self:After(0.6, function()
                if owner:IsVisible() and GameTooltip:IsOwned(owner) and GetItemInfo(d.id) then
                    SDJ:ShowItemTooltip(owner, item)
                end
            end)
        end
    else
        GameTooltip:SetText(d.name)
    end
    if d.note and d.note ~= "" then
        GameTooltip:AddLine(d.note, 1, 0.82, 0.2, true)
    end
    GameTooltip:Show()
end

-- Shift-click: put the item link in chat. Links are only built from
-- GetItemInfo (never hand-made), so an uncached item is requested first.
function SDJ:HandleItemClick(item)
    local d = self:GetItemDisplay(item)
    if not d or not d.id then return end
    if not d.link then
        self:QueueItem(d.id)
        RequestItem(d.id)
        if IsShiftKeyDown() and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Dungeon Journal:|r item not cached yet, shift-click again in a moment.")
        end
        return
    end
    if HandleModifiedItemClick and HandleModifiedItemClick(d.link) then return end
    if IsShiftKeyDown() then
        if not (ChatEdit_InsertLink and ChatEdit_InsertLink(d.link)) and ChatFrame_OpenChat then
            ChatFrame_OpenChat(d.link)
        end
    end
end
