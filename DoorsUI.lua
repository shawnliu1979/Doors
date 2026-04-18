local addonName = ...

-- 这个文件专门负责 `/doors` 的界面。
-- 目前先把 UI、交互和传送按钮结构做完整，真实 spellID 以后再逐个补上。

local SEASON_FILTERS = {
    { id = "ALL", label = "全部" },
    { id = "11.0-S1", label = "11.0 S1" },
    { id = "11.1-S2", label = "11.1 S2" },
    { id = "11.2-S3", label = "11.2 S3" },
    { id = "12.0-S1", label = "12.0 S1" },
}

local activeSeasonFilter = "ALL"

local WOW_TIPS = (DoorsData and DoorsData.WOW_TIPS) or {}

-- 副本数据表：
local DUNGEONS = (DoorsData and DoorsData.DUNGEONS) or {}

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
local SCROLL_TOP_Y = -132
local SCROLL_BOTTOM_Y = 54
local SCROLL_VIEW_HEIGHT = FRAME_HEIGHT + SCROLL_TOP_Y - SCROLL_BOTTOM_Y
local SCROLL_CONTENT_PADDING_BOTTOM = 12
local DOORS_DEBUG = true

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

-- 安全按钮在战斗中不能随意改施法属性。
-- 如果战斗中发生状态变化，就先记下来，等脱战后统一刷新。
local deferredSecureRefresh

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

-- 鼠标悬停卡片时显示更完整的说明，方便理解这个按钮当前为什么能点或不能点。
local function ShowDungeonTooltip(button)
    local dungeon = button.dungeon
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
    GameTooltip:Show()
end

local function UpdateButtonState(button, dungeon)
    local _, red, green, blue = GetDungeonState(dungeon)
    local isConfigured = dungeon.spellID ~= nil
    local isKnown = isConfigured and IsTeleportKnown(dungeon.spellID)
    local spellName = GetSpellLabel(dungeon.spellID)
    local cooldownRemaining = GetCooldownRemaining(dungeon.spellID)
    local isCoolingDown = cooldownRemaining > 0

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
                button.Tint:SetColorTexture(dungeon.color[1], dungeon.color[2], dungeon.color[3], 0.24)
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
        DebugLog(string.format("defer secure refresh: %s in combat", dungeon.subtitle))
        return
    end

    if isKnown and spellName then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", spellName)
        DebugLog(string.format("state update: %s configured=%s known=%s spellID=%s spellName=%s attrType=%s attrSpell=%s", dungeon.subtitle, tostring(isConfigured), tostring(isKnown), tostring(dungeon.spellID), tostring(spellName), tostring(button:GetAttribute("type")), tostring(button:GetAttribute("spell"))))
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        DebugLog(string.format("state update: %s configured=%s known=%s spellID=%s spellName=%s attrType=nil attrSpell=nil", dungeon.subtitle, tostring(isConfigured), tostring(isKnown), tostring(dungeon.spellID), tostring(spellName)))
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
frame.note:SetText("拖动窗口可移动。右上角可按赛季筛选史诗钥石地下城列表。")

frame.filterButtons = {}

for index, filter in ipairs(SEASON_FILTERS) do
    local filterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    filterButton:SetSize(84, 20)
    filterButton:SetPoint("TOPLEFT", 18 + ((index - 1) * 92), -108)
    filterButton:SetText(filter.label)
    filterButton.filterID = filter.id
    filterButton:SetScript("OnClick", function(self)
        activeSeasonFilter = self.filterID

        for _, btn in ipairs(frame.filterButtons) do
            if btn.filterID == activeSeasonFilter then
                btn:LockHighlight()
            else
                btn:UnlockHighlight()
            end
        end

        local visibleIndex = 0

        for _, dungeonButton in ipairs(frame.buttons) do
            local isVisible = DungeonMatchesFilter(dungeonButton.dungeon, activeSeasonFilter)
            if isVisible then
                local column = visibleIndex % BUTTON_COLUMNS
                local row = math.floor(visibleIndex / BUTTON_COLUMNS)
                dungeonButton:ClearAllPoints()
                dungeonButton:SetPoint("TOPLEFT", BUTTON_START_X + (column * (BUTTON_WIDTH + BUTTON_SPACING_X)), BUTTON_START_Y - (row * (BUTTON_HEIGHT + BUTTON_SPACING_Y)))
                dungeonButton:Show()
                visibleIndex = visibleIndex + 1
            else
                dungeonButton:Hide()
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
            frame.emptyText:SetShown(visibleIndex == 0)
        end

        DebugLog(string.format("filter switched to %s, visible=%d", activeSeasonFilter, visibleIndex))
    end)

    table.insert(frame.filterButtons, filterButton)
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

local buttonRows = math.ceil(#DUNGEONS / BUTTON_COLUMNS)
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
        if button:IsShown() then
            UpdateButtonState(button, button.dungeon)
        end
    end
end

-- 鼠标移入时增加一点亮度和缩放反馈，让卡片更像正式入口按钮。
local function OnPortalButtonEnter(self)
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

for index, dungeon in ipairs(DUNGEONS) do
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
    button.Tint:SetColorTexture(dungeon.color[1], dungeon.color[2], dungeon.color[3], 0.24)

    -- 左侧海报图保持紧凑，右侧留给中英文名称。
    button.Splash = button:CreateTexture(nil, "ARTWORK")
    button.Splash:SetPoint("TOPLEFT", 1, -1)
    button.Splash:SetPoint("BOTTOMLEFT", 1, 1)
    button.Splash:SetWidth(84)
    button.Splash:SetTexture(dungeon.fallbackIcon)
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
    button.Name:SetText(dungeon.subtitle)

    button.EnglishName = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.EnglishName:SetPoint("TOPLEFT", button.Name, "BOTTOMLEFT", 0, -4)
    button.EnglishName:SetWidth(BUTTON_WIDTH - 110)
    button.EnglishName:SetJustifyH("LEFT")
    button.EnglishName:SetWordWrap(false)
    button.EnglishName:SetText(dungeon.name)

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

    UpdateButtonState(button, dungeon)
    frame.buttons[index] = button
end

if frame.filterButtons[1] then
    frame.filterButtons[1]:Click()
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
debugEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
debugEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
debugEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
debugEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
debugEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
debugEventFrame:SetScript("OnEvent", function(_, event, ...)
    if not DOORS_DEBUG then
        return
    end

    if event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        if message then
            DebugLog(string.format("ui_error: %s", tostring(message)))
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