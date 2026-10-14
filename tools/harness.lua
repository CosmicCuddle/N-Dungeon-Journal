-- Minimal WoW 3.3.5 API mock: loads the addon per .toc and drives every view.
-- Any call to a method that does not exist on 3.3.5 widgets raises an error.
local ADDON_DIR = arg[1]
local log = {}
local textures_set = {}
local existing_files = {}  -- filled from the addon dir (for SetTexture return values)
for line in io.popen('cd "'..ADDON_DIR..'" && find . -type f'):lines() do
  local p = line:gsub("^%./",""):gsub("/","\\"):gsub("%.%w+$",""):lower()
  existing_files["interface\\addons\\dungeonjournal\\"..p] = true
end
-- v0.3.7: client textures are checked against a 3.3.5 (12340) Interface listfile
-- (tools/listfile_335.txt, generated from the file tree of s0h2x/WoTLK-3.3.5-UI-Source, blp branch)
CLIENT_FILES = {}
do local dir = debug.getinfo(1,"S").source:match("^@(.*[/\\])") or "./"
  for l in io.lines(dir.."listfile_335.txt") do CLIENT_FILES[l]=true end end
local MOCK_TEX = {["interface\\icons\\inv_test"]=1, ["interface\\icons\\inv_misc_test"]=1, ["interface\\icons\\spell_test"]=1}
CLIENT_MISSING = {}
local function file_exists(path)
  local p = path:lower():gsub("%.%w+$","")
  if p:find("^interface\\addons\\dungeonjournal\\") then return existing_files[p] end
  return CLIENT_FILES[p] or false
end

-- 3.3.5 widget method allowlist (subset relevant to this addon)
local common = {"SetPoint","ClearAllPoints","SetAllPoints","SetWidth","SetHeight","SetSize","GetWidth","GetHeight","Show","Hide","IsShown","IsVisible","SetAlpha","GetName","GetParent","SetParent"}
local frameM = {"SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetScript","GetScript","HookScript","RegisterEvent","UnregisterEvent","CreateTexture","CreateFontString","SetFrameStrata","SetFrameLevel","GetFrameLevel","GetOwner","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetScrollChild","SetVerticalScroll","GetVerticalScroll","UpdateScrollChildRect","GetVerticalScrollRange","SetMinMaxValues","SetValue","GetValue","RegisterForClicks","SetText","GetText","SetOwner","SetHyperlink","AddLine","SetText","IsOwned","ClearLines","EnableMouseWheel"}
local texM = {"SetTexture","SetTexCoord","SetVertexColor","SetBlendMode","SetDrawLayer"}
local fsM = {"SetText","GetText","SetFont","SetTextColor","SetJustifyH","SetJustifyV","SetShadowColor","SetShadowOffset","SetSpacing","GetStringHeight","GetStringWidth","SetWordWrap","SetNonSpaceWrap","SetFontObject"}
local function mkset(...) local s={} for _,l in ipairs({...}) do for _,m in ipairs(l) do s[m]=true end end return s end
local FRAME_OK, TEX_OK, FS_OK = mkset(common,frameM), mkset(common,texM), mkset(common,fsM)

-- ---- v0.3.7 layout model: anchors, sizes, fonts and scroll children, so the harness can
-- compute where every piece of text ends and flag text that runs past its panel.
local ALL_FS, ALL_FRAMES = {}, {}
local FONT = { GameFontHighlightSmall={5.6,12}, GameFontNormalSmall={5.6,12}, GameFontHighlight={6.6,14},
  GameFontNormal={6.6,14}, GameFontNormalLarge={8.6,18}, GameFontNormalHuge={10.6,22} }
local function plain(t)
  t = tostring(t or "")
  t = t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t","XXX")
  return t
end
local function metrics(o) local f=o.__fontsize and {o.__fontsize*0.56,o.__fontsize+3} or FONT[o.__font or "GameFontNormal"] or {6.6,14}; return f[1], f[2]+(o.__spacing or 0) end
local function textlines(o, width)
  local cw = metrics(o)
  local n, maxw = 0, 0
  for line in (plain(o.__text).."\n"):gmatch("(.-)\n") do
    if not width or width<=0 then n=n+1; maxw=math.max(maxw,#line*cw)
    else
      local cur=0; n=n+1
      for word in line:gmatch("%S+") do
        local w=(#word+1)*cw
        if cur>0 and cur+w>width then n=n+1; cur=w else cur=cur+w end
      end
      maxw=width
    end
  end
  return n, maxw
end
local rect
local function sidex(r,p) if p:find("LEFT") then return r.l elseif p:find("RIGHT") then return r.r else return (r.l+r.r)/2 end end
local function sidey(r,p) if p:find("TOP") then return r.t elseif p:find("BOTTOM") then return r.b else return (r.t+r.b)/2 end end
rect = function(o, depth)
  depth=(depth or 0)+1; assert(depth<60,"anchor loop")
  if o.__name=="UIParent" then return {l=0,r=1920,t=1080,b=0} end
  if o.__scrollParent then
    local p=rect(o.__scrollParent,depth); local w=o.__wset and o.__w or (p.r-p.l); local h=o.__hset and o.__h or 0
    return {l=p.l, r=p.l+w, t=p.t, b=p.t-h}
  end
  local pts=o.__points or {}
  if #pts==0 and o.__parent then pts={{"TOPLEFT",o.__parent,"TOPLEFT",0,0}} end
  local L,R,T,B,CX,CY
  for _,pt in ipairs(pts) do
    local rr=rect(pt[2] or o.__parent or UIParent,depth)
    local ax, ay = sidex(rr,pt[3])+(pt[4] or 0), sidey(rr,pt[3])+(pt[5] or 0)
    local p=pt[1]
    if p:find("LEFT") then L=ax elseif p:find("RIGHT") then R=ax else CX=ax end
    if p:find("TOP") then T=ay elseif p:find("BOTTOM") then B=ay else CY=ay end
  end
  local w
  if L and R then w=R-L elseif o.__wset then w=o.__w elseif o.__kind=="FontString" then local _,mw=textlines(o,nil); w=mw else w=0 end
  if not L then if R then L=R-w elseif CX then L=CX-w/2 else L=0 end end
  R=L+w
  local h
  if T and B then h=T-B elseif o.__hset then h=o.__h elseif o.__kind=="FontString" then local n=textlines(o,w); local _,lh=metrics(o); h=n*lh else h=0 end
  if not T then if B then T=B+h elseif CY then T=CY+h/2 else T=0 end end
  B=T-h
  return {l=L,r=R,t=T,b=B}
end
local function newobj(kind, name, allow, parent)
  local o = {__kind=kind, __shown=true, __scripts={}, __name=name, __w=100, __h=20, __parent=parent, __points={}}
  if kind=="FontString" then table.insert(ALL_FS,o) elseif kind~="Texture" then table.insert(ALL_FRAMES,o) end
  return setmetatable(o, {__index=function(t,k)
    if allow[k] then
      return function(self, ...)
        local a = {...}
        if k=="Show" then local was=self.__shown; self.__shown=true; if not was and self.__scripts.OnShow then self.__scripts.OnShow(self) end
        elseif k=="Hide" then local was=self.__shown; self.__shown=false; if was and self.__scripts.OnHide then self.__scripts.OnHide(self) end
        elseif k=="IsShown" or k=="IsVisible" then return self.__shown
        elseif k=="SetScript" then self.__scripts[a[1]]=a[2]
        elseif k=="GetScript" then return self.__scripts[a[1]]
        elseif k=="SetText" then self.__text=a[1]
        elseif k=="GetText" then return self.__text
        elseif k=="SetWidth" then self.__w=a[1]; self.__wset=true elseif k=="SetHeight" then self.__h=a[1]; self.__hset=true
        elseif k=="GetWidth" then local r=rect(self); return r.r-r.l
        elseif k=="GetHeight" then local r=rect(self); return r.t-r.b
        elseif k=="GetStringHeight" then local r=rect(self); local w=(self.__wset or #self.__points>1) and (r.r-r.l) or nil; local n=textlines(self,w); local _,lh=metrics(self); return n*lh
        elseif k=="GetStringWidth" then local _,mw=textlines(self,nil); return mw
        elseif k=="SetFont" then self.__fontsize=a[2]
        elseif k=="SetFontObject" then self.__font=a[1]
        elseif k=="SetSpacing" then self.__spacing=a[1]
        elseif k=="SetPoint" then
          local p, a2, a3, a4, a5 = a[1], a[2], a[3], a[4], a[5]
          local rel, rp, x, y
          if type(a2)=="number" or a2==nil then rel, rp, x, y = self.__parent, p, a2, a3
          else rel = type(a2)=="string" and _G[a2] or a2
            if type(a3)=="string" then rp, x, y = a3, a4, a5 else rp, x, y = p, a3, a4 end end
          table.insert(self.__points, {p, rel, rp, x or 0, y or 0})
        elseif k=="ClearAllPoints" then self.__points={}
        elseif k=="SetAllPoints" then local rel=a[1] or self.__parent; self.__points={{"TOPLEFT",rel,"TOPLEFT",0,0},{"BOTTOMRIGHT",rel,"BOTTOMRIGHT",0,0}}
        elseif k=="SetScrollChild" then a[1].__scrollParent=self; self.__child=a[1]
        elseif k=="SetVerticalScroll" then self.__vs=a[1] elseif k=="GetVerticalScroll" then return self.__vs or 0
        elseif k=="GetParent" then return self.__parent
        elseif k=="GetName" then return self.__name
        elseif k=="CreateTexture" then return newobj("Texture",nil,TEX_OK,self)
        elseif k=="CreateFontString" then local fs=newobj("FontString",nil,FS_OK,self); fs.__font=a[3]; return fs
        elseif k=="SetTexture" then
          if type(a[1])=="string" and not a[1]:find("WHITE8X8") then table.insert(textures_set, a[1]) end
          if type(a[1])=="string" then local ok=file_exists(a[1])
            local lp=a[1]:lower():gsub("%.%w+$","")
            if not ok and not lp:find("^interface\\addons\\") and not MOCK_TEX[lp] then CLIENT_MISSING[a[1]]=true end
            return ok and 1 or nil end
          return 1
        elseif k=="IsOwned" then return true
        elseif k=="SetBackdrop" then assert(type(a[1])=="table" and a[2]==nil, "SetBackdrop must take exactly one table (3.3.5)")
          for _,key in ipairs({"bgFile","edgeFile"}) do local f=a[1][key]; if f and not file_exists(f) then CLIENT_MISSING[f]=true end end
        elseif k=="SetFrameLevel" then self.__lvl=a[1] elseif k=="GetFrameLevel" then return self.__lvl or 1
        elseif k=="SetOwner" then self.__owner=a[1] elseif k=="GetOwner" then return self.__owner
        end
      end
    end
    if type(k)=="string" and k:match("^[A-Z]") then error(kind.." has no 3.3.5 method '"..tostring(k).."'", 2) end
    return nil
  end})
end

_G.UIParent = newobj("Frame","UIParent",FRAME_OK)
_G.WorldFrame = newobj("Frame","WorldFrame",FRAME_OK)
_G.GameTooltip = newobj("GameTooltip","GameTooltip",FRAME_OK)
_G.DEFAULT_CHAT_FRAME = {AddMessage=function(_,m) table.insert(log,m) end}
_G.UISpecialFrames = {"ItemRefTooltip","ColorPickerFrame"}
_G.GameMenuFrame = newobj("Frame","GameMenuFrame",FRAME_OK); GameMenuFrame.__shown=false
function HideUIPanel(f) if f then f:Hide() end end
function ShowUIPanel(f) if f then f:Show() end end
function CloseSpecialWindows()
  local found
  for index, value in pairs(UISpecialFrames) do
    local frame = _G[value]
    if ( frame and frame:IsShown() ) then frame:Hide(); found = 1 end
  end
  return found
end
function ToggleGameMenu()   -- reduced 3.3.5 ToggleGameMenu: menu open -> close; windows open -> close; else open menu
  if GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame)
  elseif CloseSpecialWindows() then
  else ShowUIPanel(GameMenuFrame) end
end
function hooksecurefunc(name, fn) local orig=_G[name]; _G[name]=function(...) local r=orig(...); fn(...); return r end end
_G.SlashCmdList = {}
_G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
local frames = {}
function CreateFrame(kind, name, parent, template)
  assert(kind=="Frame" or kind=="Button" or kind=="ScrollFrame" or kind=="GameTooltip", "unexpected frame type "..tostring(kind))
  if template then assert(({UIPanelScrollFrameTemplate=1,UIPanelButtonTemplate=1,UIPanelCloseButton=1,GameTooltipTemplate=1})[template], "template not in 3.3.5: "..template) end
  if template=="UIPanelScrollFrameTemplate" then assert(name, "UIPanelScrollFrameTemplate needs a global name in 3.3.5") end
  local f = newobj(kind,name,FRAME_OK,parent or UIParent)
  table.insert(frames,f)
  if name then _G[name]=f end
  if template=="UIPanelScrollFrameTemplate" then
    local bar=newobj("Slider",name.."ScrollBar",FRAME_OK,f); _G[name.."ScrollBar"]=bar
    bar:SetPoint("TOPLEFT",f,"TOPRIGHT",6,-16); bar:SetPoint("BOTTOMLEFT",f,"BOTTOMRIGHT",6,16)
  end
  return f
end
function UnitFactionGroup() return FACTION or "Horde" end
local cached = {}
function GetItemInfo(id) id=tonumber(id); if cached[id] then return "Cached "..id, "|cff0070dd|Hitem:"..id..":0:0:0:0:0:0:0:80|h[Cached]|h|r", 3, 18, 13, "Armor", "Cloth", 1, "INVTYPE_WRIST", "Interface\\Icons\\INV_Test" end return nil end
function GetItemIcon(id) return "Interface\\Icons\\INV_Misc_Test" end
function GetSpellInfo(id) return "Spell"..id, "", "Interface\\Icons\\Spell_Test" end
function GetTime() return os.clock() end
function IsShiftKeyDown() return SHIFT end
function HandleModifiedItemClick(link) table.insert(log,"LINK "..link); return true end
function geterrorhandler() return function(e) error(e) end end
unpack = unpack or table.unpack

-- load files from the toc
local ns = {}
for line in io.lines(ADDON_DIR.."/DungeonJournal.toc") do
  line = line:gsub("\r","")
  if line ~= "" and not line:find("^##") then
    local path = ADDON_DIR.."/"..line:gsub("\\","/")
    local chunk = assert(loadfile(path))
    chunk("DungeonJournal", ns)
  end
end

-- ---- v0.3.7 layout check: text must end inside its panel, or sit in a scroll child whose
-- height (set by the addon from measured text) covers it.
local OVERFLOWS, CHECKS = {}, 0
SCROLLBARS_SHOWN = {}
local function visible(o) while o do if o.__shown==false then return false end; o=o.__parent end; return true end
local function label(o) local n={} ; local x=o; while x do if x.__name then table.insert(n,1,x.__name) break end; x=x.__parent end; return table.concat(n,"/") end
local function check_layout(ctx)
  CHECKS=CHECKS+1
  local main=_G.DungeonJournalFrame
  local function check(o, what)
    local r=rect(o)
    local a=o.__parent
    while a and a~=UIParent do
      local ar=rect(a)
      if a.__scrollParent then
        if r.b < ar.b-1 then OVERFLOWS[ctx.." | "..what.." ends "..math.floor(ar.b-r.b).."px below its scroll child (content height not updated)"]=true end
        return
      end
      if r.b < ar.b-1 or r.t > ar.t+1 then
        OVERFLOWS[ctx.." | "..what.." runs "..math.floor(math.max(ar.b-r.b, r.t-ar.t)).."px outside its panel with no scroll parent"]=true
        return
      end
      if a==main then return end
      a=a.__parent
    end
  end
  for _,fs in ipairs(ALL_FS) do
    if fs.__text and plain(fs.__text):find("%S") and visible(fs) then check(fs, "text '"..plain(fs.__text):sub(1,40):gsub("\n"," ").."'") end
  end
  for _,f in ipairs(ALL_FRAMES) do
    if f.__hset and visible(f) and f.__parent and f.__parent.__scrollParent then check(f, "row in "..label(f)) end
  end
  -- scrollbars: shown only when the scroll child is taller than the visible area
  for _,f in ipairs(ALL_FRAMES) do
    if f.__child and f.__name and visible(f) then
      local bar=_G[f.__name.."ScrollBar"]
      local over=(f.__child.__h or 0) > (rect(f).t-rect(f).b)+0.5
      if bar and (bar.__shown and true or false)~=over then OVERFLOWS[ctx.." | "..f.__name.." scrollbar "..(over and "hidden although content overflows" or "shown although content fits")]=true end
      if over then SCROLLBARS_SHOWN[f.__name]=true end
    end
  end
  -- v0.6.2: pages opened from home must never overlap the section tab row, and a shown
  -- tab row must not cover any visible page or the Back button
  local Fm=_G.DungeonJournalFrame
  if Fm and Fm.sectionHolder then
    local tr=rect(Fm.sectionHolder)
    local function hit(r) return r.l<tr.r and r.r>tr.l and r.b<tr.t and r.t>tr.b end
    for nm,o in pairs({help=Fm.botHelpPanel, content=Fm.contentPanel}) do
      if o and visible(o) and hit(rect(o)) then OVERFLOWS[ctx.." | "..nm.." page overlaps the tab row ("..math.floor(rect(o).t-tr.b).."px)"]=true end
    end
    if visible(Fm.sectionHolder) then
      for nm,o in pairs({help=Fm.botHelpPanel, content=Fm.contentPanel, back=Fm.backButton}) do
        if o and visible(o) and hit(rect(o)) then OVERFLOWS[ctx.." | tab row is shown over the "..nm] =true end
      end
    end
    TABROW_CHECKS=(TABROW_CHECKS or 0)+1
  end
  -- the map attribution must not overlap the legend or the map image
  local F=_G.DungeonJournalFrame
  if F and F.mapCredit and visible(F.mapCredit) and F.mapCredit.__text and F.mapCredit.__text~="" then
    local c=rect(F.mapCredit)
    for _,o in ipairs({F.mapLegendScroll or F.mapLegend, F.mapCanvas}) do
      if o and visible(o) then local r=rect(o)
        if c.l<r.r and c.r>r.l and c.b<r.t and c.t>r.b then OVERFLOWS[ctx.." | map attribution overlaps "..(o==F.mapCanvas and "the map" or "the legend")]=true end end
    end
  end
end
local function fire(ev, ...) for _,f in ipairs(frames) do local s=f.__scripts.OnEvent; if s then s(f, ev, ...) end end end
local function tick(n) for i=1,n or 1 do for _,f in ipairs(frames) do local s=f.__scripts.OnUpdate; if s and f.__shown then s(f, 0.6) end end end end
fire("ADDON_LOADED","DungeonJournal"); fire("PLAYER_LOGIN")
local SDJ = DungeonJournal
assert(DungeonJournalDB and DungeonJournalDB.lastEra=="Vanilla")
assert(SlashCmdList.DUNGEONJOURNAL and SLASH_DUNGEONJOURNAL1=="/dj" and SLASH_DUNGEONJOURNAL2=="/dungeonjournal")

SlashCmdList.DUNGEONJOURNAL("")
local list = SDJ:GetDungeonList("Vanilla")
assert(list[1].id=="rfc", "RFC must be first in the Vanilla browser, got "..list[1].id)
print("Vanilla dungeons:", #list, "first:", list[1].name)
for _,era in ipairs({"Vanilla","TBC","Wrath"}) do
  for _,d in ipairs(SDJ:GetDungeonList(era)) do
    SDJ:OpenDungeon(d)
    for _,m in ipairs({"trash","bosses","quests","preparation","map"}) do
      if m=="trash" then SDJ:RefreshTrash() elseif m=="bosses" then SDJ:RefreshBosses() elseif m=="quests" then SDJ:RefreshQuests() elseif m=="preparation" then SDJ:RefreshPreparation() else SDJ:RefreshMap() end
      check_layout(d.name.." "..m)
    end
  end
  SDJ:ShowHome(); check_layout("home "..era)
end
-- v0.4.2 Bot Consumables help page
do
  local F = DungeonJournalFrame
  assert(F.botHelpButton and F.botHelpButton.__scripts.OnClick, "Bot Consumables home button missing")
  F.botHelpButton.__scripts.OnClick(F.botHelpButton)
  assert(F.botHelpPanel.__shown and not F.homePanel.__shown, "Bot Consumables help did not show")
  assert(F.botHelpText.__text:find("What it does",1,true), "help body missing What it does")
  assert(F.botHelpText.__text:find(".bot consumables",1,true), "help body missing commands")
  check_layout("bot consumables help")
  assert(not F.sectionHolder.__shown and F.backButton.__shown, "help page must hide the tab row and show Back")
  if os.getenv("SDJ_DUMP") then   -- layout dump for the preview renderer (rects from the layout model)
    local out=io.open(os.getenv("SDJ_DUMP"),"w")
    local function w(nm,o) local r=rect(o); out:write(string.format("RECT\t%s\t%s\t%.1f\t%.1f\t%.1f\t%.1f\n",nm,tostring(visible(o)),r.l,r.t,r.r,r.b)) end
    w("frame",F); w("tabs",F.sectionHolder); w("back",F.backButton); w("help",F.botHelpPanel); w("scroll",F.botHelpScroll)
    for k,o in pairs(F.sectionButtons) do w("tab:"..k,o) end
    out:write("BACKTEXT\t"..tostring(F.backButton.__text).."\n")
    out:write("BODY\n"..F.botHelpText.__text); out:close()
  end
  F.backButton.__scripts.OnClick(F.backButton)
  assert(F.homePanel.__shown and F.sectionHolder.__shown and not F.botHelpPanel.__shown, "Back from help must restore home + tabs")
  F.botHelpButton.__scripts.OnClick(F.botHelpButton)
  -- ESC from help closes journal
  ToggleGameMenu()
  assert(not F.__shown, "ESC from Bot Consumables help did not close journal")
  SDJ:Open(); assert(F.homePanel.__shown and not F.botHelpPanel.__shown, "reopen after help ESC should be home")
end

-- drive RFC fully
local rfc = SDJ.BY_ID.rfc
SDJ:OpenDungeon(rfc)
local F = DungeonJournalFrame
print("TRASH TEXT:\n"..F.trashText.__text)
SDJ:RefreshBosses()
local function clickRows(n, textfs)
  local out = {}
  for _,f in ipairs(frames) do if f.index and f.__scripts.OnClick and f.__shown and f.__kind=="Button" then table.insert(out,f) end end
  return out
end
for _,row in ipairs(clickRows()) do row.__scripts.OnClick(row); print("BOSS:", F.selectedBossName.__text, "|", F.selectedBossLevel.__text, "| portrait fallback shown:", F.selectedBossFallback.__shown, "| noLoot:", F.noLoot.__shown and F.noLoot.__text or "-") end
print("BOSS INFO (last):\n"..F.bossInfo.__text)
SDJ:RefreshMap()
print("MAP:", F.mapTexture.__shown, F.mapFloorName.__text, "prev shown:", F.mapPrev.__shown, "counter shown:", F.mapCounter.__shown)
print("LEGEND:\n"..F.mapLegend.__text)
SDJ:RefreshPreparation(); print("PREP:\n"..F.prepText.__text)
-- quest detail with chain expanded
SDJ:RefreshQuests()
for _,row in ipairs(clickRows()) do if row.meta then row.__scripts.OnClick(row); if F.chainButton.__shown then F.chainButton.__scripts.OnClick() end; print("QUEST:", F.questTitle.__text, F.questFaction.__text) end end
print("QUEST TEXT (last, chain expanded):\n"..F.questText.__text)
-- item cache path: uncached -> cached -> listener refresh
tick(3); cached[14149]=true; cached[14395]=true; tick(2)
-- shift click
SHIFT=true; SDJ:HandleItemClick({id=14149,name="Subterranean Cape"}); SDJ:HandleItemClick({id=14148,name="Crystalline Cuffs"}); tick(1)
SDJ:ShowItemTooltip(F, {id=14148,name="Crystalline Cuffs"}); tick(2)
-- alliance view of RFC quests
FACTION="Alliance"; SDJ:OpenDungeon(rfc); SDJ:RefreshQuests(); print("ALLIANCE:", F.questText.__text)
-- ===== v0.3.2 batch 2: Deadmines, Wailing Caverns, Shadowfang Keep, Stockade
FACTION="Horde"
-- v0.3.6: Blackrock Depths (brd) added.
-- v0.3.7: Dire Maul East / North / West (dm_e, dm_n, dm_w) added.
-- v0.4.0: Scholomance + Stratholme Living/Undead added; scholo and strat_ud show server role levels.
local order = {"rfc","deadmines","wailing","sfk","stockade","bfd","gnomer","rfk","smgy","smlib","smarm","smcat","rfd","ulda","zf","jintha","mara_p","mara_o","mara_i","st","brd","dm_e","dm_n","dm_w","lbrs","ubrs","scholo","strat_live","strat_ud"}
for i,id in ipairs(order) do assert(list[i].id==id, "Vanilla order slot "..i.." expected "..id..", got "..list[i].id) end
local ROLE = {deadmines="Recommended:  DPS 16  /  Healer 18  /  Tank 18", wailing="Recommended:  DPS 16  /  Healer 18  /  Tank 18", ubrs="Recommended:  DPS 60  /  Healer 60  /  Tank 60", scholo="Recommended:  DPS 60  /  Healer 60  /  Tank 60", strat_ud="Recommended:  DPS 60  /  Healer 60  /  Tank 60"}
-- v0.3.3 batch 3 ids are checked by the same loop (no role levels, 2-map wrap)
-- v0.3.4 batch 4 ids added (rfd, ulda, zf, jintha)
-- v0.3.5 batch 5 ids added (mara_p, mara_o, mara_i, st)
for _,id in ipairs({"deadmines","wailing","sfk","stockade","bfd","gnomer","rfk","smgy","smlib","smarm","smcat","rfd","ulda","zf","jintha","mara_p","mara_o","mara_i","st","brd","dm_e","dm_n","dm_w","lbrs","ubrs","scholo","strat_live","strat_ud","mc","onyxia","zg","aq20","aq40","naxx"}) do
  local d = SDJ.BY_ID[id]; assert(d and not d.unsupported, id.." missing or placeholder")
  SDJ:OpenDungeon(d)
  local meta = F.dungeonMeta.__text
  if ROLE[id] then assert(meta:find(ROLE[id],1,true), id.." header lacks role levels: "..meta)
  else assert(not meta:find("Recommended",1,true), id.." must not show role levels: "..meta) end
  print("== "..d.name.." | META: "..meta:gsub("\n"," // "))
  SDJ:RefreshTrash(); print("  trash mobs:", #(d.trash.mobs or {}), "trash loot:", #(d.trash.loot or {}))
  SDJ:RefreshBosses()
  local nb, fb = 0, 0
  for _,row in ipairs(clickRows()) do if row.__scripts.OnClick and not row.meta then row.__scripts.OnClick(row); nb=nb+1; if F.selectedBossFallback.__shown then fb=fb+1; print("  PORTRAIT FALLBACK:", F.selectedBossName.__text) end; check_layout(d.name.." boss "..tostring(F.selectedBossName.__text)) end end
  print("  boss rows clicked:", nb, "portrait fallbacks:", fb)
  SDJ:RefreshMap()
  local nm = #(d.maps or {})
  print("  MAP 1:", F.mapFloorName.__text, "prev:", F.mapPrev.__shown, "counter:", F.mapCounter.__shown and F.mapCounter.__text or "-")
  assert((nm>1) == (F.mapPrev.__shown and true or false), id.." prev/next visibility wrong")
  if nm>1 then
    F.mapNext.__scripts.OnClick(); check_layout(d.name.." map 2"); print("  MAP 2:", F.mapFloorName.__text, F.mapCounter.__text, F.mapTexture.__tex or "")
    assert(F.mapCounter.__text=="2 / "..nm)
    -- advance to last page then wrap to first (works for any nm>1)
    for i=3,nm do F.mapNext.__scripts.OnClick() end
    assert(F.mapCounter.__text==nm.." / "..nm, id.." should be on last map page")
    F.mapNext.__scripts.OnClick(); assert(F.mapCounter.__text=="1 / "..nm, "wrap-around failed")
    F.mapPrev.__scripts.OnClick(); assert(F.mapCounter.__text==nm.." / "..nm, "prev wrap failed")
  end
  SDJ:RefreshPreparation(); check_layout(d.name.." preparation")
  assert(F.prepText.__text:find("Bot Consumables",1,true), id.." prep missing Bot Consumables section")
  assert(F.prepText.__text:find(".bot consumables",1,true), id.." prep missing .bot consumables command")
  SDJ:RefreshTrash(); check_layout(d.name.." trash")
  for _,fac in ipairs({"Alliance","Horde"}) do
    local btn = fac=="Alliance" and F.allianceQuestButton or F.hordeQuestButton
    btn.__scripts.OnClick(btn)
    local nq=0
    for _,row in ipairs(clickRows()) do if row.meta then row.__scripts.OnClick(row); nq=nq+1; check_layout(d.name.." quest "..tostring(F.questTitle.__text)); if F.chainButton.__shown then F.chainButton.__scripts.OnClick(); check_layout(d.name.." quest chain "..tostring(F.questTitle.__text)) end end end
    print("  "..fac.." quests:", nq, nq==0 and F.questText.__text or F.questTitle.__text)
  end
end
-- v0.4.2 named Bot Consumables profiles
do
  local F = DungeonJournalFrame
  local expect = {
    scholo=".bot consumables scholo",
    strat_ud=".bot consumables stratud",
    strat_live=".bot consumables <level>",
    mara_p=".bot consumables mara",
    st=".bot consumables sunken",
    brd=".bot consumables brd",
    dm_n=".bot consumables dm",
    lbrs=".bot consumables lbrs",
    ubrs=".bot consumables ubrs",
    rfc=".bot consumables <1-54>",
    mc=".bot consumables mc",
    onyxia=".bot consumables",
    zg=".bot consumables",
    aq20=".bot consumables",
    aq40=".bot consumables",
    naxx=".bot consumables",
  }
  for id, needle in pairs(expect) do
    SDJ:OpenDungeon(SDJ.BY_ID[id]); SDJ:RefreshPreparation()
    assert(F.prepText.__text:find(needle,1,true), id.." prep expected "..needle)
  end
  print("BOT CONSUMABLES PREP PROFILES OK")
end

-- v0.5.2 Primary sections: Dungeons | Raids | World Bosses (+ era secondary)
do
  local F = DungeonJournalFrame
  assert(F.sectionHolder and F.sectionButtons and F.sectionButtons.Dungeons and F.sectionButtons.Raids and F.sectionButtons.WorldBosses, "section tabs missing")
  assert(not F.kindHolder, "old Dungeons/Raids kind toggle must be removed")
  SDJ:ShowHome()
  assert(F.sectionHolder.__shown, "section tabs should show on home")
  assert(F.eraHolder.__shown, "era secondary filter should show on home")

  local function homeIds()
    local ids = {}
    for _,card in ipairs(homeCards or {}) do
      if card and card.__shown and card.dungeon then table.insert(ids, card.dungeon.id) end
    end
    -- harness HomeCard list is local; fall back to filtering BY_ID via GetDungeonList
    return ids
  end
  local function sectionIds(section)
    -- drive UI click then collect visible dungeon ids from GetDungeonList filter logic
    F.sectionButtons[section].__scripts.OnClick()
    local raw = SDJ:GetDungeonList("Vanilla")
    local out = {}
    for _,d in ipairs(raw) do
      local isRaid = (d.tag=="Raid" or d.raid==true)
      local isWB = (d.tag=="World Boss" or d.worldBoss==true)
      if section=="Raids" and isRaid then table.insert(out, d.id)
      elseif section=="WorldBosses" and isWB then table.insert(out, d.id)
      elseif section=="Dungeons" and not isRaid and not isWB then table.insert(out, d.id) end
    end
    return out
  end

  local dungeons = sectionIds("Dungeons")
  assert(#dungeons > 20, "Dungeons section should list many dungeons, got "..#dungeons)
  for _,id in ipairs(dungeons) do
    assert(SDJ.BY_ID[id].tag~="Raid" and SDJ.BY_ID[id].tag~="World Boss", "dungeon section leaked "..id)
  end
  assert(SDJ.BY_ID.rfc and SDJ.BY_ID.jintha, "sample dungeons missing")

  local raids = sectionIds("Raids")
  assert(SDJ.BY_ID.mc and SDJ.BY_ID.mc.tag=="Raid", "mc must be tagged Raid")
  assert(SDJ.BY_ID.onyxia and SDJ.BY_ID.onyxia.tag=="Raid", "onyxia must be tagged Raid")
  assert(SDJ.BY_ID.zg and SDJ.BY_ID.zg.tag=="Raid" and SDJ.BY_ID.zg.players=="20", "zg must be 20-player Raid")
  assert(SDJ.BY_ID.bwl and SDJ.BY_ID.bwl.tag=="Raid" and SDJ.BY_ID.bwl.players=="40", "bwl must be 40-player Raid")
  assert(SDJ.BY_ID.aq20 and SDJ.BY_ID.aq20.tag=="Raid" and SDJ.BY_ID.aq20.players=="20", "aq20 must be 20-player Raid")
  assert(SDJ.BY_ID.aq40 and SDJ.BY_ID.aq40.tag=="Raid" and SDJ.BY_ID.aq40.players=="40", "aq40 must be 40-player Raid")
  assert(SDJ.BY_ID.naxx and SDJ.BY_ID.naxx.tag=="Raid" and SDJ.BY_ID.naxx.players=="40", "naxx must be 40-player Raid")
  -- IP order: mc < onyxia < bwl < zg < aq20 < aq40 < naxx
  local mi, oi, bi, zi, a20, a40, nx
  for i,id in ipairs(raids) do
    if id=="mc" then mi=i elseif id=="onyxia" then oi=i elseif id=="bwl" then bi=i elseif id=="zg" then zi=i
    elseif id=="aq20" then a20=i elseif id=="aq40" then a40=i elseif id=="naxx" then nx=i end
  end
  assert(mi and oi and bi and zi and a20 and a40 and nx and mi<oi and oi<bi and bi<zi and zi<a20 and a20<a40 and a40<nx, "raid IP order expected mc < onyxia < bwl < zg < aq20 < aq40 < naxx")

  SDJ:OpenDungeon(SDJ.BY_ID.mc)
  assert(F.dungeonMeta.__text:find("40-PLAYER RAID",1,true), "MC header missing 40-PLAYER RAID: "..tostring(F.dungeonMeta.__text))
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("Attunement to the Core",1,true), "MC prep missing attunement")
  assert(F.prepText.__text:find("PROGRESSION_MOLTEN_CORE",1,true), "MC prep missing IP stage")
  SDJ:OpenDungeon(SDJ.BY_ID.onyxia)
  assert(F.dungeonMeta.__text:find("40-PLAYER RAID",1,true), "Onyxia header missing raid size")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("Drakefire Amulet",1,true), "Onyxia prep missing Drakefire")
  assert(F.prepText.__text:find("no named",1,true), "Onyxia must state no named bot profile")
  SDJ:OpenDungeon(SDJ.BY_ID.bwl)
  assert(F.dungeonMeta.__text:find("40-PLAYER RAID",1,true), "BWL header missing 40-PLAYER RAID")
  assert(#SDJ.BY_ID.bwl.bosses==8, "BWL should have 8 bosses")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("PROGRESSION_ONYXIA",1,true), "BWL prep missing IP Onyxia gate")
  assert(F.prepText.__text:find("Blackhand",1,true) or F.prepText.__text:find("7761",1,true), "BWL prep missing Blackhand attunement")
  assert(F.prepText.__text:find("Onyxia Scale Cloak",1,true) or F.prepText.__text:find("15138",1,true), "BWL prep missing Scale Cloak")
  assert(F.prepText.__text:find("Burning Adrenaline",1,true), "BWL prep missing Vael BA")
  assert(F.prepText.__text:find("RandomResize",1,true) or F.prepText.__text:find("randomised",1,true) or F.prepText.__text:find("TWO breaths",1,true), "BWL prep missing Chromaggus breaths")
  assert(F.prepText.__text:find("no named",1,true), "BWL must state no named bot profile")
  SDJ:OpenDungeon(SDJ.BY_ID.zg)
  assert(F.dungeonMeta.__text:find("20-PLAYER RAID",1,true), "ZG header missing 20-PLAYER RAID")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("RequiredZulGurubProgression",1,true) or F.prepText.__text:find("PROGRESSION_BLACKWING_LAIR",1,true), "ZG prep missing IP BWL gate")
  assert(F.prepText.__text:find("no named",1,true) or F.prepText.__text:find("does not cover ZG",1,true), "ZG must state no bot profile")

  SDJ:OpenDungeon(SDJ.BY_ID.aq20)
  assert(F.dungeonMeta.__text:find("20-PLAYER RAID",1,true), "AQ20 header missing 20-PLAYER RAID")
  assert(#SDJ.BY_ID.aq20.bosses==6, "AQ20 should have 6 bosses")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("PROGRESSION_PRE_AQ",1,true), "AQ20 prep missing PRE_AQ gate")
  assert(F.prepText.__text:find("Bang a Gong",1,true) or F.prepText.__text:find("8743",1,true), "AQ20 prep missing Bang a Gong")
  assert(F.prepText.__text:find("Cenarion",1,true), "AQ20 prep missing Cenarion Circle")
  assert(F.prepText.__text:find("no named",1,true), "AQ20 must state no named bot profile")
  SDJ:OpenDungeon(SDJ.BY_ID.aq40)
  assert(F.dungeonMeta.__text:find("40-PLAYER RAID",1,true), "AQ40 header missing 40-PLAYER RAID")
  assert(#SDJ.BY_ID.aq40.bosses==9, "AQ40 should have 9 bosses")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("PROGRESSION_PRE_AQ",1,true), "AQ40 prep missing PRE_AQ gate")
  assert(F.prepText.__text:find("Nature Resistance",1,true) or F.prepText.__text:find("Huhuran",1,true), "AQ40 prep missing NR/Huhuran")
  assert(F.prepText.__text:find("Frost",1,true) or F.prepText.__text:find("Viscidus",1,true), "AQ40 prep missing frost/Viscidus")
  assert(F.prepText.__text:find("Twin",1,true) or F.prepText.__text:find("teleport",1,true), "AQ40 prep missing Twin Emps teleports")
  assert(F.prepText.__text:find("C'Thun",1,true) or F.prepText.__text:find("Dark Glare",1,true), "AQ40 prep missing C'Thun")
  assert(F.prepText.__text:find("Brood of Nozdormu",1,true) or F.prepText.__text:find("Nozdormu",1,true), "AQ40 prep missing Brood of Nozdormu")
  assert(F.prepText.__text:find("no named",1,true), "AQ40 must state no named bot profile")

  SDJ:OpenDungeon(SDJ.BY_ID.naxx)
  assert(F.dungeonMeta.__text:find("40-PLAYER RAID",1,true), "Naxx header missing 40-PLAYER RAID")
  assert(#SDJ.BY_ID.naxx.bosses==15, "Naxx should have 15 bosses")
  assert(#(SDJ.BY_ID.naxx.maps or {})>=2, "Naxx should have multi-page maps")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("isAttuned",1,true) or F.prepText.__text:find("9121",1,true) or F.prepText.__text:find("Dread Citadel",1,true), "Naxx prep missing attunement")
  assert(F.prepText.__text:find("PROGRESSION_AQ",1,true) or F.prepText.__text:find("PROGRESSION_NAXX40",1,true), "Naxx prep missing IP stage")
  assert(F.prepText.__text:find("Stratholme",1,true) or F.prepText.__text:find("Elders",1,true), "Naxx prep missing Strath entrance")
  assert(F.prepText.__text:find("Frost",1,true) or F.prepText.__text:find("Sapphiron",1,true), "Naxx prep missing FR/Sapphiron")
  assert(F.prepText.__text:find("10MAN_HEROIC",1,true) or F.prepText.__text:find("351",1,true) or F.prepText.__text:find("Vanilla Naxx",1,true), "Naxx prep missing how-fork-works")
  assert(F.prepText.__text:find("no named",1,true), "Naxx must state no named bot profile")
  SDJ:RefreshMap()
  assert(F.mapPrev.__shown, "Naxx map Prev should show for multi-page")

  local wbs = sectionIds("WorldBosses")
  assert(SDJ.BY_ID.azuregos and SDJ.BY_ID.azuregos.tag=="World Boss", "azuregos missing")
  assert(SDJ.BY_ID.kazzak and SDJ.BY_ID.kazzak.tag=="World Boss", "kazzak missing")
  assert(SDJ.BY_ID.emerald and SDJ.BY_ID.emerald.tag=="World Boss", "emerald missing")
  assert(#wbs==3, "World Bosses should show exactly 3 entries, got "..#wbs.." "..table.concat(wbs,","))
  SDJ:OpenDungeon(SDJ.BY_ID.azuregos)
  assert(F.dungeonMeta.__text:find("WORLD BOSS",1,true), "Azuregos header missing WORLD BOSS")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("no named",1,true), "Azuregos must state no named bot profile")
  assert(F.prepText.__text:find("868400",1,true) or F.prepText.__text:find("10.05",1,true) or F.prepText.__text:find("10 day",1,true), "Azuregos prep missing respawn")
  SDJ:OpenDungeon(SDJ.BY_ID.kazzak)
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("180",1,true) or F.prepText.__text:find("Berserk",1,true) or F.prepText.__text:find("supreme",1,true), "Kazzak prep missing enrage timer")
  assert(F.prepText.__text:find("no named",1,true), "Kazzak must state no named bot profile")
  SDJ:OpenDungeon(SDJ.BY_ID.emerald)
  assert(#SDJ.BY_ID.emerald.bosses==4, "Emerald Dragons should list 4 bosses")
  SDJ:RefreshPreparation()
  assert(F.prepText.__text:find("PROGRESSION_ONYXIA",1,true), "Emerald prep missing IP Onyxia gate")
  assert(F.prepText.__text:find("Mark of Nature",1,true), "Emerald prep missing Mark of Nature")
  assert(F.prepText.__text:find("no named",1,true), "Emerald must state no named bot profile")

  -- selection resets on close
  SDJ:ShowHome()
  F.sectionButtons.WorldBosses.__scripts.OnClick()
  F.eraButtons.TBC.__scripts.OnClick()
  F:Hide()  -- triggers ResetOnClose
  assert(not F.__shown)
  SDJ:Open()
  -- after reset: Dungeons + Vanilla
  F.sectionButtons.Dungeons.__scripts.OnClick()  -- ensure we can click
  print("SECTIONS + RAIDS + WORLD BOSSES UI + PREP OK")
end


-- v0.6.0 Vanilla-wide consistency: every Vanilla entry is real (no unsupported placeholders)
do
  local list = SDJ:GetDungeonList("Vanilla")
  local unsupported = {}
  for _,d in ipairs(list) do
    if d.unsupported then table.insert(unsupported, d.id) end
    assert(d.name and d.id and d.tag, "Vanilla entry missing name/id/tag: "..tostring(d and d.id))
    assert(d.bosses and #d.bosses>0, "Vanilla entry has no bosses: "..d.id)
    assert(d.maps and #d.maps>0, "Vanilla entry has no maps: "..d.id)
  end
  assert(#unsupported==0, "Vanilla placeholders remain: "..table.concat(unsupported,","))
  local nd,nr,nw=0,0,0
  for _,d in ipairs(list) do
    if d.tag=="Raid" then nr=nr+1
    elseif d.tag=="World Boss" then nw=nw+1
    else nd=nd+1 end
  end
  print("VANILLA SECTIONS: Dungeons",nd,"Raids",nr,"World Bosses",nw)
  assert(nr==7, "expected 7 Vanilla raids (mc onyxia bwl zg aq20 aq40 naxx), got "..nr)
  assert(nw==3, "expected 3 Vanilla world bosses, got "..nw)
  print("VANILLA CONSISTENCY OK")
end

-- ---- version check: .toc and SDJ.VERSION must agree with the release being built
do
  local EXPECT_VERSION = "0.6.2"
  local tocv
  for l in io.lines(ADDON_DIR.."/DungeonJournal.toc") do tocv = tocv or l:match("^## Version:%s*(%S+)") end
  assert(tocv==EXPECT_VERSION, "toc Version "..tostring(tocv).." ~= expected "..EXPECT_VERSION)
  assert(SDJ.VERSION==EXPECT_VERSION, "SDJ.VERSION "..tostring(SDJ.VERSION).." ~= expected "..EXPECT_VERSION)
  print("VERSION CHECK: OK", EXPECT_VERSION)
end

-- ---- v0.6.1: cover art must not use generic continent/glue loadscreens
-- (in listfile from UI source trees, but unloadable on many clients → solid green).
do
  local function is_banned(path)
    if type(path)~="string" then return false end
    local low = path:lower():gsub("/","\\")
    if low:find("loadscreenkalimdor",1,true) then return true end
    if low:find("loadscreeneasternkingdom",1,true) then return true end
    if low:find("loadscreennorthrend",1,true) then return true end
    if low:find("loadscreenoutland",1,true) then return true end
    if low:find("loadscreenazeroth",1,true) then return true end
    return false
  end
  local bad = {}
  for era, list in pairs(SDJ.DUNGEONS or {}) do
    for _,d in ipairs(list) do
      if is_banned(d.art) then table.insert(bad, (d.id or "?").." art="..tostring(d.art)) end
    end
  end
  assert(#bad==0, "generic continent/glue cover art (v0.6.1): "..table.concat(bad, "; "))
  print("CONTINENT COVER-ART CHECK: OK")
end

-- ---- v0.6.1: bundled cover art (addon-folder paths) must exist; bundled TGAs must be
-- uncompressed 32-bit with power-of-two sides (what the 3.3.5a client loads reliably).
do
  local ours = "interface\\addons\\dungeonjournal\\"
  local function ispow2(n) local x=1 while x<n do x=x*2 end return x==n end
  local nb, bad = 0, {}
  for era, list in pairs(SDJ.DUNGEONS or {}) do
    for _,d in ipairs(list) do
      for _,key in ipairs({"art","artFallback"}) do
        local path = d[key]
        if type(path)=="string" and path:lower():gsub("/","\\"):sub(1,#ours)==ours then
          nb = nb + 1
          if not file_exists(path) then
            table.insert(bad, d.id.." "..key.." missing: "..path)
          else
            local rel = path:sub(#ours+1):gsub("\\","/")
            local f = io.open(ADDON_DIR.."/"..rel..".tga","rb")
            if f then
              local h = f:read(18); f:close()
              local itype, w, hh, bpp = h:byte(3), h:byte(13)+256*h:byte(14), h:byte(15)+256*h:byte(16), h:byte(17)
              if itype~=2 or bpp~=32 or not ispow2(w) or not ispow2(hh) then
                table.insert(bad, d.id.." "..key.." TGA type="..itype.." "..w.."x"..hh.." bpp="..bpp)
              elseif rel:find("^Media/Covers/") then
                print("BUNDLED COVER:", d.id, rel..".tga", w.."x"..hh, bpp.."-bit uncompressed")
              end
            end
          end
        end
      end
    end
  end
  assert(#bad==0, "bundled cover art problems: "..table.concat(bad,"; "))
  local o = SDJ.BY_ID.onyxia
  assert(o and o.art:find("Media\\Covers\\OnyxiasLair",1,true) and file_exists(o.art), "Onyxia cover must be the bundled Media\\Covers\\OnyxiasLair texture")
  assert(o.artFallback and file_exists(o.artFallback), "Onyxia artFallback (Atlas map) must exist")
  print("BUNDLED COVER-ART CHECK: OK ("..nb.." addon-folder art paths)")
end

-- ---- v0.3.7 ESC check: the UISpecialFrames name must resolve to the frame the addon shows/hides
do
  local F = DungeonJournalFrame
  local name = SDJ.FRAME_NAME or "DungeonJournalFrame"
  local n=0; for _,v in ipairs(UISpecialFrames) do if v==name then n=n+1 end end
  assert(n==1, "UISpecialFrames must contain "..tostring(name).." exactly once, found "..n)
  assert(_G[name]==F and F.__name==name, "UISpecialFrames name does not resolve to the main frame")
  assert(F.__parent==UIParent, "main frame must be top-level (parent UIParent)")
  -- the frame Toggle/Open show is that same object
  F:Hide(); SDJ:Open(); assert(F.__shown, "Open did not show the registered frame")
  -- open a dungeon deep state, then press ESC through the Blizzard path
  local d=SDJ.BY_ID.brd; SDJ:OpenDungeon(d); SDJ:RefreshQuests()
  GameTooltip:SetOwner(F.contentPanel); GameTooltip:Show()
  ToggleGameMenu()
  assert(not F.__shown, "ESC (ToggleGameMenu -> CloseSpecialWindows) did not hide the journal")
  assert(not GameMenuFrame.__shown, "ESC opened the game menu instead of closing the journal")
  assert(not GameTooltip.__shown, "closing did not hide the journal's tooltip")
  assert(F.homePanel.__shown and not F.contentPanel.__shown, "closing did not reset to the home view")
  ToggleGameMenu(); assert(GameMenuFrame.__shown, "second ESC should open the game menu"); ToggleGameMenu()
  -- re-open several times: still registered exactly once
  for i=1,3 do SDJ:Toggle(); SDJ:Toggle() end
  n=0; for _,v in ipairs(UISpecialFrames) do if v==name then n=n+1 end end
  assert(n==1, "duplicate UISpecialFrames entries after reopening: "..n)
  -- another addon replaces UISpecialFrames after we registered: OnShow re-registers
  UISpecialFrames = {"ItemRefTooltip","ColorPickerFrame"}
  SDJ:Open(); ToggleGameMenu(); assert(not F.__shown and not GameMenuFrame.__shown, "ESC failed after UISpecialFrames was replaced")
  -- entry removed while open: the ToggleGameMenu fallback hook closes the journal and the menu
  SDJ:Open(); UISpecialFrames = {"ItemRefTooltip","ColorPickerFrame"}; ToggleGameMenu()
  assert(not F.__shown and not GameMenuFrame.__shown, "ESC fallback hook failed")
  print("ESC CHECK OK:", name, "-> main frame, parent UIParent, registered once, closes + resets")
  SDJ:Open()
end
-- toggle closes
SlashCmdList.DUNGEONJOURNAL("")
print("chat log:"); for _,m in ipairs(log) do print("  "..m) end
-- report addon textures referenced
local seen = {}
for _,t in ipairs(textures_set) do if t:lower():find("addons") and not seen[t] then seen[t]=true; print("TEX", t, file_exists(t) and "OK" or "MISSING") end end
local cm={} for k in pairs(CLIENT_MISSING) do table.insert(cm,k) end; table.sort(cm)
for _,k in ipairs(cm) do print("CLIENT TEX NOT IN 3.3.5 LISTFILE:", k) end
-- Fail if any SetTexture path points at a different AddOns folder than this build.
do
  local outside = {}
  local prefix = "interface\\addons\\"
  local ours = "interface\\addons\\dungeonjournal\\"
  for _,path in ipairs(textures_set) do
    local low = path:lower():gsub("/","\\")
    if low:sub(1, #prefix) == prefix and low:sub(1, #ours) ~= ours then
      table.insert(outside, path)
    end
  end
  assert(#outside==0, (#outside).." texture path(s) point outside the DungeonJournal addon folder")
  print("OUTSIDE ADDON FOLDER CHECK: OK")
end

print("CLIENT TEXTURES CHECKED AGAINST 3.3.5 LISTFILE, missing:", #cm)
assert(#cm==0, #cm.." client texture paths are not in the 3.3.5 listfile")
local nov=0; for k in pairs(OVERFLOWS) do nov=nov+1 end
local keys={} for k in pairs(OVERFLOWS) do table.insert(keys,k) end; table.sort(keys)
for _,k in ipairs(keys) do print("LAYOUT OVERFLOW:", k) end
print("LAYOUT CHECKS:", CHECKS, "overflows:", nov)
print("TAB-ROW CHECKS:", TABROW_CHECKS or 0)
local sb={} for k in pairs(SCROLLBARS_SHOWN) do table.insert(sb,k) end; table.sort(sb); print("scrollbars that appeared for overflowing content:", table.concat(sb,", "))
assert(nov==0, nov.." text areas overflow their panels")
print("HARNESS OK")
