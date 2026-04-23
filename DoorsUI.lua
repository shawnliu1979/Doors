local addonName = ...

-- 这个文件专门负责 `/doors` 的界面。
-- 目前先把 UI、交互和传送按钮结构做完整，真实 spellID 以后再逐个补上。

local SEASON_FILTERS = {
    { id = "12.0-S1", label = "12.0 S1" },
    { id = "11.2-S3", label = "11.2 S3" },
    { id = "11.1-S2", label = "11.1 S2" },
    { id = "11.0-S1", label = "11.0 S1" },
    { id = "ALL", label = "全部" },
}

local activeSeasonFilter = "12.0-S1"
local activeContentMode = "DUNGEON"

local WOW_TIPS = (DoorsData and DoorsData.WOW_TIPS) or {}

-- 副本数据表：
local DUNGEONS = (DoorsData and DoorsData.DUNGEONS) or {}
local RAIDS = (DoorsData and DoorsData.RAIDS) or {}
local FINAL_BOSS_QUOTES = (DoorsData and DoorsData.FINAL_BOSS_QUOTES) or {}

local DEFAULT_ENTRY_ICON = 136243
local DEFAULT_ENTRY_COLOR = {0.58, 0.58, 0.62}

-- 这些布局常量集中放在一起，后面如果你要继续微调样式，改这里最直接。
local FRAME_WIDTH = 660
local FRAME_HEIGHT = 560
local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 84
local BUTTON_SPACING_X = 18
local BUTTON_SPACING_Y = 18
local BUTTON_COLUMNS = 2
local BUTTON_START_X = 12
local BUTTON_START_Y = -10
local SCROLL_TOP_Y = -156
local SCROLL_BOTTOM_Y = 54
local SCROLL_VIEW_HEIGHT = FRAME_HEIGHT + SCROLL_TOP_Y - SCROLL_BOTTOM_Y
local SCROLL_CONTENT_PADDING_BOTTOM = 12
local DOORS_DEBUG = false

local function DebugLog(message)
    if not DOORS_DEBUG then
        return
    end

    print(string.format("[%s:DEBUG] %s", addonName or "Doors", message))
end

local function DungeonMatchesFilter(dungeon, filterID)
    if filterID == "ALL" then
        return true
    end

    if type(dungeon.seasons) ~= "table" then
        return false
    end

    for _, seasonID in ipairs(dungeon.seasons) do
        if seasonID == filterID then
            return true
        end
    end

    return false
end

local function GetActiveEntries()
    if activeContentMode == "RAID" then
        return RAIDS
    end

    return DUNGEONS
end

local function GetEntryColor(entry)
    if entry and type(entry.color) == "table" and entry.color[1] and entry.color[2] and entry.color[3] then
        return entry.color
    end

    return DEFAULT_ENTRY_COLOR
end

local function GetQuotePoolForCurrentMode()
    if activeContentMode == "RAID" then
        return FINAL_BOSS_QUOTES.raids or {}
    end

    return FINAL_BOSS_QUOTES.dungeons or {}
end

local function FindBossQuoteEntry(entry)
    if not entry then
        return nil
    end

    local quotePool = GetQuotePoolForCurrentMode()
    for _, quoteEntry in ipairs(quotePool) do
        if quoteEntry.name and entry.name and quoteEntry.name == entry.name then
            return quoteEntry
        end

        if quoteEntry.subtitle and entry.subtitle and quoteEntry.subtitle == entry.subtitle then
            return quoteEntry
        end
    end

    return nil
end

local function BuildBossLine(entry)
    local quoteEntry = FindBossQuoteEntry(entry)
    if not quoteEntry then
        return nil
    end

    local bossName = quoteEntry.finalBoss
    if not bossName or bossName == "" then
        bossName = "尾王"
    end

    local line = nil
    if type(quoteEntry.quotes) == "table" and #quoteEntry.quotes > 0 then
        line = quoteEntry.quotes[math.random(#quoteEntry.quotes)]
    end

    if not line or line == "" then
        if quoteEntry.finalBoss and quoteEntry.finalBoss ~= "待补充" then
            line = "你们的结局，到此为止。"
        else
            return nil
        end
    end

    return string.format("[尾王·%s] %s", bossName, line)
end

local function SendBossLineToParty(entry)
    local bossLine = BuildBossLine(entry)
    if not bossLine then
        return
    end

    if IsInGroup and IsInGroup() and (not IsInRaid or not IsInRaid()) then
        if C_ChatInfo and C_ChatInfo.SendChatMessage then
            C_ChatInfo.SendChatMessage(bossLine, "PARTY")
        else
            print(string.format("[%s] %s", addonName or "Doors", bossLine))
        end
        return
    end

    print(string.format("[%s] %s", addonName or "Doors", bossLine))
end

-- 安全按钮在战斗中不能随意改施法属性。
-- 如果战斗中发生状态变化，就先记下来，等脱战后统一刷新。
local deferredSecureRefresh
local RefreshVisibleButtons

local function GetSpellLabel(spellID)
    if not spellID then
        return nil
    end

    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end

    return nil
end

local function GetCooldownRemaining(spellID)
    if not spellID or not C_Spell or not C_Spell.GetSpellCooldown then
        return 0
    end

    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    if not cooldownInfo or not cooldownInfo.startTime or not cooldownInfo.duration then
        return 0
    end

    if cooldownInfo.startTime <= 0 or cooldownInfo.duration <= 1.5 then
        return 0
    end

    local remaining = (cooldownInfo.startTime + cooldownInfo.duration) - GetTime()
    if remaining < 0 then
        return 0
    end

    return remaining
end

local function FormatCooldownText(remaining)
    if remaining <= 0 then
        return nil
    end

    if remaining < 60 then
        return string.format("CD %.0fs", remaining)
    end

    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    return string.format("CD %d:%02d", minutes, seconds)
end

local function IsTeleportKnown(spellID)
    if not spellID then
        return false
    end

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) == true
    end

    if C_Spell and C_Spell.IsSpellKnownOrOverridesKnown then
        return C_Spell.IsSpellKnownOrOverridesKnown(spellID) == true
    end

    if C_Spell and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellID) == true
    end

    return false
end

-- 统一生成卡片状态文案、颜色和提示说明。
-- 这样卡片文字、边框高亮和 tooltip 都可以共用一套判断。
local function GetDungeonState(dungeon)
    local isConfigured = dungeon.spellID ~= nil
    local isKnown = isConfigured and IsTeleportKnown(dungeon.spellID)

    if isKnown then
        return "已学会", 0.40, 0.90, 0.52, "点击后会尝试施放这个传送法术。"
    end

    if isConfigured then
        return "未学会", 1.00, 0.82, 0.40, "当前角色还没有学会。"
    end

    return "待配置", 0.92, 0.92, 0.92, "spellID 还没填，所以当前展示的是 UI 原型。"
end

local function GetOpenDoorHint(dungeon)
    if not dungeon then
        return nil
    end

    local isConfigured = dungeon.spellID ~= nil
    local isKnown = isConfigured and IsTeleportKnown(dungeon.spellID)

    if isKnown then
        return nil
    end

    if not isConfigured then
        if activeContentMode == "RAID" then
            return {
                "开门条件：",
                "1) 该团本若有对应传送法术，需先学会后才能点亮。",
                "2) 学会后卡片会变为可用，点击即可尝试传送。",
            }
        end

        return {
            "开门条件：",
            "1) 在史诗钥石模式限时完成该地下城 +10（或更高）。",
            "2) 达成后会解锁该本个人传送，卡片会自动点亮。",
        }
    end

    return {
        "开门条件：",
        "1) 用当前角色限时完成该地下城史诗钥石 +10（或更高）。",
        "2) 解锁后卡片会从灰色变为可用，可直接点击传送。",
    }
end

-- 鼠标悬停卡片时显示更完整的说明，方便理解这个按钮当前为什么能点或不能点。
local function ShowDungeonTooltip(button)
    local dungeon = button.dungeon
    if not dungeon then
        return
    end

    local stateText, _, _, _, detailText = GetDungeonState(dungeon)
    local cooldownRemaining = GetCooldownRemaining(dungeon.spellID)
    local cooldownText = FormatCooldownText(cooldownRemaining)

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(dungeon.subtitle, 1, 0.82, 0.20)
    GameTooltip:AddLine(dungeon.name, 0.85, 0.85, 0.85)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("状态：" .. stateText, 1, 1, 1)
    if cooldownText then
        GameTooltip:AddLine("冷却：" .. cooldownText, 1.0, 0.65, 0.22)
    end
    GameTooltip:AddLine(detailText, 0.78, 0.78, 0.78, true)

    local openDoorHint = GetOpenDoorHint(dungeon)
    if openDoorHint then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(openDoorHint[1], 1.0, 0.82, 0.25)
        GameTooltip:AddLine(openDoorHint[2], 0.72, 0.84, 1.0, true)
        GameTooltip:AddLine(openDoorHint[3], 0.72, 0.84, 1.0, true)
    end

    GameTooltip:Show()
end

local function UpdateButtonState(button, dungeon)
    if not dungeon then
        return
    end

    local _, red, green, blue = GetDungeonState(dungeon)
    local isConfigured = dungeon.spellID ~= nil
    local isKnown = isConfigured and IsTeleportKnown(dungeon.spellID)
    local spellName = GetSpellLabel(dungeon.spellID)
    local cooldownRemaining = GetCooldownRemaining(dungeon.spellID)
    local isCoolingDown = cooldownRemaining > 0
    local entryColor = GetEntryColor(dungeon)

    if button.HeaderAccent then
        if isKnown then
            if isCoolingDown then
                button.HeaderAccent:SetColorTexture(1.0, 0.65, 0.22, 0.95)
            else
                button.HeaderAccent:SetColorTexture(red, green, blue, 0.95)
            end
        else
            button.HeaderAccent:SetColorTexture(0.65, 0.65, 0.65, 0.70)
        end
    end

    if button.IconBorder then
        if isKnown then
            button.IconBorder:SetColorTexture(red, green, blue, 0.95)
        else
            button.IconBorder:SetColorTexture(0.62, 0.62, 0.62, 0.45)
        end
    end

    if button.InnerGlow then
        if isKnown then
            button.InnerGlow:SetColorTexture(red, green, blue, 0.14)
        else
            button.InnerGlow:SetColorTexture(0.40, 0.40, 0.40, 0.06)
        end
    end

    if button.BorderTop then
        if isKnown then
            button.BorderTop:SetColorTexture(red, green, blue, 0.95)
        else
            button.BorderTop:SetColorTexture(0.55, 0.55, 0.55, 0.45)
        end
    end

    if button.Tint then
        if isKnown then
            if isCoolingDown then
                button.Tint:SetColorTexture(0.60, 0.44, 0.20, 0.24)
            else
                button.Tint:SetColorTexture(entryColor[1], entryColor[2], entryColor[3], 0.24)
            end
        else
            button.Tint:SetColorTexture(0.40, 0.40, 0.40, 0.20)
        end
    end

    if button.Splash then
        if isKnown then
            button.Splash:SetDesaturated(isCoolingDown)
            button.Splash:SetAlpha(isCoolingDown and 0.85 or 1.0)
        else
            button.Splash:SetDesaturated(true)
            button.Splash:SetAlpha(0.72)
        end
    end

    if button.Name then
        if isKnown then
            button.Name:SetTextColor(1.0, 0.95, 0.84)
        else
            button.Name:SetTextColor(0.74, 0.74, 0.74)
        end
    end

    if button.EnglishName then
        if isKnown then
            button.EnglishName:SetTextColor(0.75, 0.75, 0.75)
        else
            button.EnglishName:SetTextColor(0.58, 0.58, 0.58)
        end
    end

    if button.CooldownText then
        local cooldownText = FormatCooldownText(cooldownRemaining)
        if cooldownText and isKnown then
            button.CooldownText:SetText(cooldownText)
            button.CooldownText:Show()
        else
            button.CooldownText:Hide()
        end
    end

    if InCombatLockdown() then
        deferredSecureRefresh = true
        return
    end

    if isKnown and spellName then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", spellName)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
    end
end

local frame = CreateFrame("Frame", "DoorsPortalFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- 让这个窗口支持 ESC 关闭，更像正式插件面板。
table.insert(UISpecialFrames, "DoorsPortalFrame")

local addonVersion
if C_AddOns and C_AddOns.GetAddOnMetadata then
    addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
else
    local legacyGetAddOnMetadata = _G and _G["GetAddOnMetadata"]
    if legacyGetAddOnMetadata then
        addonVersion = legacyGetAddOnMetadata(addonName, "Version")
    end
end
if addonVersion and addonVersion ~= "" then
    frame.TitleText:SetText(string.format("Doors v%s", addonVersion))
else
    frame.TitleText:SetText("Doors")
end

if frame.CloseButton then
    frame.CloseButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("关闭 Doors", 1, 0.82, 0.20)
        GameTooltip:AddLine("可以点击这里关闭，也可以按 ESC。", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    frame.CloseButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- 顶部深色区域单独压一层，让标题区和卡片区有更明显的层级。
frame.TopPanel = frame:CreateTexture(nil, "BACKGROUND")
frame.TopPanel:SetPoint("TOPLEFT", 8, -28)
frame.TopPanel:SetPoint("TOPRIGHT", -8, -28)
frame.TopPanel:SetHeight(96)
frame.TopPanel:SetColorTexture(0.06, 0.06, 0.08, 0.92)

frame.TopPanelAccent = frame:CreateTexture(nil, "BORDER")
frame.TopPanelAccent:SetPoint("BOTTOMLEFT", frame.TopPanel, "BOTTOMLEFT", 0, 0)
frame.TopPanelAccent:SetPoint("BOTTOMRIGHT", frame.TopPanel, "BOTTOMRIGHT", 0, 0)
frame.TopPanelAccent:SetHeight(1)
frame.TopPanelAccent:SetColorTexture(1, 0.82, 0.24, 0.30)

frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.header:SetPoint("TOPLEFT", 20, -40)
frame.header:SetText("地下城传送门")

frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.description:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 0, -8)
frame.description:SetJustifyH("LEFT")
frame.description:SetText("开门就像开箱，愿你把把都有宝、一路欧到尾王！")

frame.note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.note:SetPoint("TOPLEFT", frame.description, "BOTTOMLEFT", 0, -8)
frame.note:SetJustifyH("LEFT")
frame.note:SetText("拖动窗口可移动。右上角可切换地下城/团本并按赛季筛选。")

frame.filterButtons = {}
frame.modeButtons = {}

local function RefreshButtonHighlights()
    for _, btn in ipairs(frame.filterButtons) do
        if btn.filterID == activeSeasonFilter then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end

    for _, btn in ipairs(frame.modeButtons) do
        if btn.modeID == activeContentMode then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

local function GetContentTypeLabel()
    if activeContentMode == "RAID" then
        return "团本"
    end

    return "地下城"
end

local function RefreshContentHeader()
    frame.header:SetText(string.format("%s总览", GetContentTypeLabel()))
end

RefreshVisibleButtons = function()
    local entries = GetActiveEntries()
    local visibleIndex = 0

    RefreshButtonHighlights()
    RefreshContentHeader()

    for buttonIndex, entryButton in ipairs(frame.buttons) do
        local entry = entries[buttonIndex]
        local isVisible = entry and DungeonMatchesFilter(entry, activeSeasonFilter)

        if isVisible then
            local column = visibleIndex % BUTTON_COLUMNS
            local row = math.floor(visibleIndex / BUTTON_COLUMNS)
            local entryColor = GetEntryColor(entry)

            entryButton.dungeon = entry
            entryButton:ClearAllPoints()
            entryButton:SetPoint("TOPLEFT", BUTTON_START_X + (column * (BUTTON_WIDTH + BUTTON_SPACING_X)), BUTTON_START_Y - (row * (BUTTON_HEIGHT + BUTTON_SPACING_Y)))

            if entryButton.Name then
                entryButton.Name:SetText(entry.subtitle or "未命名")
            end

            if entryButton.EnglishName then
                entryButton.EnglishName:SetText(entry.name or "")
            end

            if entryButton.Splash then
                entryButton.Splash:SetTexture(entry.fallbackIcon or DEFAULT_ENTRY_ICON)
            end

            if entryButton.Tint then
                entryButton.Tint:SetColorTexture(entryColor[1], entryColor[2], entryColor[3], 0.24)
            end

            entryButton:Show()
            UpdateButtonState(entryButton, entry)
            visibleIndex = visibleIndex + 1
        else
            entryButton.dungeon = nil
            entryButton:Hide()
        end
    end

    local visibleRows = math.max(1, math.ceil(visibleIndex / BUTTON_COLUMNS))
    local contentHeight = math.max(
        SCROLL_VIEW_HEIGHT,
        math.abs(BUTTON_START_Y) + (visibleRows * BUTTON_HEIGHT) + ((visibleRows - 1) * BUTTON_SPACING_Y) + SCROLL_CONTENT_PADDING_BOTTOM
    )
    frame.scrollChild:SetHeight(contentHeight)
    frame.scrollFrame:SetVerticalScroll(0)

    if frame.emptyText then
        frame.emptyText:SetText(string.format("这个赛季暂时没有配置%s条目。", GetContentTypeLabel()))
        frame.emptyText:SetShown(visibleIndex == 0)
    end

end

for index, filter in ipairs(SEASON_FILTERS) do
    local filterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    filterButton:SetSize(84, 20)
    filterButton:SetPoint("TOPLEFT", 18 + ((index - 1) * 92), -132)
    filterButton:SetText(filter.label)
    filterButton.filterID = filter.id
    filterButton:SetScript("OnClick", function(self)
        activeSeasonFilter = self.filterID
        RefreshVisibleButtons()
    end)

    table.insert(frame.filterButtons, filterButton)
end

local modeButtonDefs = {
    { id = "DUNGEON", label = "地下城", offset = -196 },
    { id = "RAID", label = "团本", offset = -106 },
}

for _, modeDef in ipairs(modeButtonDefs) do
    local modeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    modeButton:SetSize(84, 20)
    modeButton:SetPoint("TOPRIGHT", modeDef.offset, -108)
    modeButton:SetText(modeDef.label)
    modeButton.modeID = modeDef.id
    modeButton:SetScript("OnClick", function(self)
        activeContentMode = self.modeID
        RefreshVisibleButtons()
    end)

    table.insert(frame.modeButtons, modeButton)
end

frame.closeHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.closeHint:SetPoint("TOPRIGHT", -40, -38)
frame.closeHint:SetText("ESC / 右上角关闭")
frame.closeHint:SetTextColor(0.82, 0.82, 0.82)

frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.footer:SetPoint("BOTTOMLEFT", 18, 16)
frame.footer:SetPoint("BOTTOMRIGHT", -18, 16)
frame.footer:SetJustifyH("LEFT")
frame.footer:SetText("Copyright © Shawnliu1979")

local lastTipIndex = nil

local function RefreshDescriptionTip()
    if #WOW_TIPS == 0 then
        frame.description:SetText("")
        return
    end

    local randomIndex = math.random(#WOW_TIPS)
    if #WOW_TIPS > 1 and lastTipIndex and randomIndex == lastTipIndex then
        randomIndex = (randomIndex % #WOW_TIPS) + 1
    end

    lastTipIndex = randomIndex
    frame.description:SetText(WOW_TIPS[randomIndex])
end

frame.scrollFrame = CreateFrame("ScrollFrame", "DoorsPortalScrollFrame", frame, "UIPanelScrollFrameTemplate")
frame.scrollFrame:SetPoint("TOPLEFT", 14, SCROLL_TOP_Y)
frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, SCROLL_BOTTOM_Y)

local scrollBar = frame.scrollFrame.ScrollBar or _G["DoorsPortalScrollFrameScrollBar"]
if scrollBar then
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", frame.scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", frame.scrollFrame, "BOTTOMRIGHT", 4, 16)
end

frame.scrollFrame:EnableMouseWheel(true)
frame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local bar = self.ScrollBar or _G["DoorsPortalScrollFrameScrollBar"]
    if not bar then
        return
    end

    local minScroll, maxScroll = bar:GetMinMaxValues()
    local nextScroll = self:GetVerticalScroll() - (delta * 32)

    if nextScroll < minScroll then
        nextScroll = minScroll
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
frame.scrollChild:SetPoint("TOPLEFT")
frame.scrollChild:SetPoint("TOPRIGHT")
frame.scrollChild:SetWidth((BUTTON_WIDTH * BUTTON_COLUMNS) + BUTTON_SPACING_X + (BUTTON_START_X * 2))
frame.scrollFrame:SetScrollChild(frame.scrollChild)

local maxEntryCount = math.max(#DUNGEONS, #RAIDS)
local buttonRows = math.ceil(math.max(1, maxEntryCount) / BUTTON_COLUMNS)
local contentHeight = math.max(
    SCROLL_VIEW_HEIGHT,
    math.abs(BUTTON_START_Y) + (buttonRows * BUTTON_HEIGHT) + ((buttonRows - 1) * BUTTON_SPACING_Y) + SCROLL_CONTENT_PADDING_BOTTOM
)
frame.scrollChild:SetHeight(contentHeight)

frame.emptyText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.emptyText:SetPoint("TOP", 0, -26)
frame.emptyText:SetText("这个赛季暂时没有配置地下城条目。")
frame.emptyText:Hide()

frame.buttons = {}

frame:HookScript("OnShow", function()
    RefreshDescriptionTip()
end)

local function RefreshAllButtonStates()
    for _, button in ipairs(frame.buttons) do
        if button:IsShown() and button.dungeon then
            UpdateButtonState(button, button.dungeon)
        end
    end
end

-- 鼠标移入时增加一点亮度和缩放反馈，让卡片更像正式入口按钮。
local function OnPortalButtonEnter(self)
    if not self.dungeon then
        return
    end

    self:SetScale(1.015)
    self.Hotspot:SetAlpha(1)
    ShowDungeonTooltip(self)
end

local function OnPortalButtonLeave(self)
    self:SetScale(1)
    self.Hotspot:SetAlpha(0)
    GameTooltip:Hide()
end

local function RegisterPortalButtonClicks(button)
    local useKeyDown = false

    if GetCVarBool then
        useKeyDown = GetCVarBool("ActionButtonUseKeyDown") == true
    end

    if useKeyDown then
        button:RegisterForClicks("AnyDown")
    else
        button:RegisterForClicks("AnyUp")
    end
end

for index = 1, maxEntryCount do
    local dungeon = DUNGEONS[index]
    local entryColor = GetEntryColor(dungeon)

    local button = CreateFrame("Button", "DoorsPortalButton" .. index, frame.scrollChild, "SecureActionButtonTemplate")
    local column = (index - 1) % BUTTON_COLUMNS
    local row = math.floor((index - 1) / BUTTON_COLUMNS)

    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", BUTTON_START_X + (column * (BUTTON_WIDTH + BUTTON_SPACING_X)), BUTTON_START_Y - (row * (BUTTON_HEIGHT + BUTTON_SPACING_Y)))
    RegisterPortalButtonClicks(button)
    button.dungeon = dungeon

    -- 最底层深色底板，让卡片从主面板里“浮”出来。
    button.Background = button:CreateTexture(nil, "BACKGROUND")
    button.Background:SetAllPoints()
    button.Background:SetColorTexture(0.05, 0.05, 0.07, 0.95)

    -- 一层主题色氛围，提供每个副本自己的色调。
    button.Tint = button:CreateTexture(nil, "BORDER")
    button.Tint:SetAllPoints()
    button.Tint:SetColorTexture(entryColor[1], entryColor[2], entryColor[3], 0.24)

    -- 左侧海报图保持紧凑，右侧留给中英文名称。
    button.Splash = button:CreateTexture(nil, "ARTWORK")
    button.Splash:SetPoint("TOPLEFT", 1, -1)
    button.Splash:SetPoint("BOTTOMLEFT", 1, 1)
    button.Splash:SetWidth(84)
    button.Splash:SetTexture((dungeon and dungeon.fallbackIcon) or DEFAULT_ENTRY_ICON)
    button.Splash:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.SplashShade = button:CreateTexture(nil, "ARTWORK")
    button.SplashShade:SetAllPoints(button.Splash)
    button.SplashShade:SetColorTexture(0, 0, 0, 0.34)

    button.InnerGlow = button:CreateTexture(nil, "BORDER")
    button.InnerGlow:SetPoint("TOPLEFT", 1, -1)
    button.InnerGlow:SetPoint("BOTTOMRIGHT", -1, 1)

    button.BorderTop = button:CreateTexture(nil, "BORDER")
    button.BorderTop:SetPoint("TOPLEFT", 0, 0)
    button.BorderTop:SetPoint("TOPRIGHT", 0, 0)
    button.BorderTop:SetHeight(2)

    button.BorderBottom = button:CreateTexture(nil, "BORDER")
    button.BorderBottom:SetPoint("BOTTOMLEFT", 0, 0)
    button.BorderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    button.BorderBottom:SetHeight(2)
    button.BorderBottom:SetColorTexture(0, 0, 0, 0.35)

    button.BorderLeft = button:CreateTexture(nil, "BORDER")
    button.BorderLeft:SetPoint("TOPLEFT", 0, 0)
    button.BorderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    button.BorderLeft:SetWidth(1)
    button.BorderLeft:SetColorTexture(1, 1, 1, 0.12)

    button.BorderRight = button:CreateTexture(nil, "BORDER")
    button.BorderRight:SetPoint("TOPRIGHT", 0, 0)
    button.BorderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    button.BorderRight:SetWidth(1)
    button.BorderRight:SetColorTexture(1, 1, 1, 0.12)

    button.HeaderAccent = button:CreateTexture(nil, "OVERLAY")
    button.HeaderAccent:SetPoint("TOPLEFT", 98, -10)
    button.HeaderAccent:SetSize(40, 2)

    button.Name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.Name:SetPoint("TOPLEFT", 98, -18)
    button.Name:SetWidth(BUTTON_WIDTH - 110)
    button.Name:SetJustifyH("LEFT")
    button.Name:SetWordWrap(false)
    button.Name:SetText((dungeon and dungeon.subtitle) or "")

    button.EnglishName = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.EnglishName:SetPoint("TOPLEFT", button.Name, "BOTTOMLEFT", 0, -4)
    button.EnglishName:SetWidth(BUTTON_WIDTH - 110)
    button.EnglishName:SetJustifyH("LEFT")
    button.EnglishName:SetWordWrap(false)
    button.EnglishName:SetText((dungeon and dungeon.name) or "")

    button.CooldownText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.CooldownText:SetPoint("BOTTOMRIGHT", -10, 10)
    button.CooldownText:SetJustifyH("RIGHT")
    button.CooldownText:SetTextColor(1.0, 0.65, 0.22)
    button.CooldownText:Hide()

    button.Hotspot = button:CreateTexture(nil, "HIGHLIGHT")
    button.Hotspot:SetAllPoints()
    button.Hotspot:SetColorTexture(1, 1, 1, 0.08)
    button.Hotspot:SetAlpha(0)

    button:SetScript("OnEnter", OnPortalButtonEnter)
    button:SetScript("OnLeave", OnPortalButtonLeave)
    button:HookScript("OnClick", function(self)
        if not self.dungeon then
            return
        end

        SendBossLineToParty(self.dungeon)
    end)

    if dungeon then
        UpdateButtonState(button, dungeon)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
    end

    frame.buttons[index] = button
end

if frame.filterButtons[1] then
    local defaultFilterID = activeSeasonFilter
    local foundDefault = false

    for _, filterButton in ipairs(frame.filterButtons) do
        if filterButton.filterID == defaultFilterID then
            foundDefault = true
            break
        end
    end

    if not foundDefault then
        activeSeasonFilter = frame.filterButtons[1].filterID
    end

    RefreshVisibleButtons()
end

local refreshFrame = CreateFrame("Frame")
refreshFrame:RegisterEvent("PLAYER_LOGIN")
refreshFrame:RegisterEvent("SPELLS_CHANGED")
refreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
refreshFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
refreshFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not deferredSecureRefresh then
        return
    end

    deferredSecureRefresh = false
    RefreshAllButtonStates()
end)

local cooldownTick = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then
        return
    end

    cooldownTick = cooldownTick + elapsed
    if cooldownTick < 10 then
        return
    end

    cooldownTick = 0
    RefreshAllButtonStates()
end)

local debugEventFrame = CreateFrame("Frame")

local function SafeRegisterEvent(frameRef, eventName)
    local ok = pcall(frameRef.RegisterEvent, frameRef, eventName)
    if not ok then
        -- 某些客户端/版本没有这些事件，忽略即可，避免插件整体加载失败。
    end
end

SafeRegisterEvent(debugEventFrame, "UNIT_SPELLCAST_SENT")
SafeRegisterEvent(debugEventFrame, "UNIT_SPELLCAST_FAILED")
SafeRegisterEvent(debugEventFrame, "UNIT_SPELLCAST_INTERRUPTED")
SafeRegisterEvent(debugEventFrame, "UNIT_SPELLCAST_START")
SafeRegisterEvent(debugEventFrame, "UNIT_SPELLCAST_SUCCEEDED")
SafeRegisterEvent(debugEventFrame, "CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
SafeRegisterEvent(debugEventFrame, "CHAT_MSG_SPELL_FAILED_SELF")
SafeRegisterEvent(debugEventFrame, "UI_ERROR_MESSAGE")
SafeRegisterEvent(debugEventFrame, "UI_INFO_MESSAGE")
SafeRegisterEvent(debugEventFrame, "CHAT_MSG_SYSTEM")
debugEventFrame:SetScript("OnEvent", function(_, event, ...)
    if not DOORS_DEBUG then
        return
    end

    if event == "UNIT_SPELLCAST_SENT" then
        local unitTarget, castGUID, spellID = ...
        DebugLog(string.format("cast sent: target=%s castGUID=%s spellID=%s", tostring(unitTarget), tostring(castGUID), tostring(spellID)))
        return
    end

    if event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" or event == "CHAT_MSG_SPELL_FAILED_SELF" then
        local message = ...
        if message then
            DebugLog(string.format("spell_failed_chat: %s", tostring(message)))
        end
        return
    end

    if event == "CHAT_MSG_SYSTEM" then
        local message = ...
        if message then
            DebugLog(string.format("system_msg: %s", tostring(message)))
        end
        return
    end

    if event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        if message then
            DebugLog(string.format("ui_error: %s", tostring(message)))
        end
        return
    end

    if event == "UI_INFO_MESSAGE" then
        local _, message = ...
        if message then
            DebugLog(string.format("ui_info: %s", tostring(message)))
        end
        return
    end

    local unit, castGUID, spellID = ...
    if unit ~= "player" then
        return
    end

    DebugLog(string.format("cast event: %s castGUID=%s spellID=%s", event, tostring(castGUID), tostring(spellID)))
end)

SLASH_DOORS1 = "/doors"
SlashCmdList["DOORS"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

SLASH_DOORSDEBUG1 = "/doorsdebug"
SlashCmdList["DOORSDEBUG"] = function(msg)
    local command = string.lower(strtrim(msg or ""))

    if command == "on" then
        DOORS_DEBUG = true
    elseif command == "off" then
        DOORS_DEBUG = false
    else
        DOORS_DEBUG = not DOORS_DEBUG
    end

    print(string.format("[%s] debug %s", addonName or "Doors", DOORS_DEBUG and "ON" or "OFF"))
end