local SDJ = DungeonJournal
local function Add(data) SDJ:AddDungeon("Vanilla", data) end

local DEFAULT_CROP = {0.04, 0.96, 0.29, 0.73}
local function Map(name, prefix, zone)
    -- These old definitions came from later-client WorldMap tile paths. They are
    -- kept as migration references, but are deliberately disabled until each
    -- dungeon receives a bundled 3.3.5-compatible map asset.
    return {name=name, prefix=prefix, zone=zone and true or false, unsupported=true}
end

-- Ragefire Chasm now lives in Data\Vanilla\RagefireChasm.lua (loaded after this file).
-- Browser order for the Vanilla tab (ids not listed keep their load order after these).
SDJ.ORDER.Vanilla = {"rfc","deadmines","wailing","sfk","stockade","bfd","gnomer","rfk","smgy","smlib","smarm","smcat","rfd","ulda","zf","jintha","mara_p","mara_o","mara_i","st","brd","dm_e","dm_n","dm_w","lbrs","ubrs","scholo","strat_live","strat_ud","mc","onyxia","bwl","zg","aq20","aq40","naxx","azuregos","kazzak","emerald"}

-- The Deadmines, Wailing Caverns, Shadowfang Keep and The Stockade now live in
-- Data\Vanilla\<Dungeon>.lua (v0.3.2, loaded after this file); the old v0.2 entries were removed.
-- Blackfathom Deeps, Gnomeregan, Razorfen Kraul and the four Scarlet Monastery wings
-- (Graveyard, Library, Armory, Cathedral) moved the same way in v0.3.3.
-- Razorfen Downs, Uldaman, Zul'Farrak and Jintha'Alor moved in v0.3.4 (the old v0.2 Jintha'Alor
-- entry and the three placeholders were removed).
-- Maraudon (Purple Side, Orange Side, Inner Maraudon) and Sunken Temple moved in v0.3.5
-- (their placeholders were removed).
-- Blackrock Depths moved in v0.3.6 (its placeholder was removed).
-- Dire Maul East, North and West moved in v0.3.7 (their placeholders were removed).
-- Lower and Upper Blackrock Spire moved in v0.3.8 (their placeholders were removed).
-- Scholomance and Stratholme (Living / Undead) moved in v0.4.0 (their placeholders were removed).
-- Vanilla dungeon set is complete. Raids: v0.5.0 mc+onyxia; v0.5.1 Zul'Gurub; v0.5.3 Blackwing Lair; v0.5.4 AQ20+AQ40; v0.6.0 Naxx40 (order …→aq40→naxx; Vanilla raids complete).
-- World bosses: v0.5.2 azuregos, kazzak, emerald (four dragons).
