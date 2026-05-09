local shared = _G.DoorsUIShared or {}
local frame = shared.frame

if not frame then
    error("DoorsLootUI.lua loaded before DoorsUI.lua frame setup")
end

local LOOT_CLASS_FILTERS = shared.LOOT_CLASS_FILTERS or {}
local LOOT_ROW_BUTTON_HEIGHT = shared.LOOT_ROW_BUTTON_HEIGHT or 56
local LOOT_ROW_HEIGHT = shared.LOOT_ROW_HEIGHT or 62
local GetDisplayTrackID = shared.GetDisplayTrackID
local GetActiveContentMode = shared.GetActiveContentMode
local FindLootConfigForEntry = shared.FindLootConfigForEntry
local GetLootEntriesForEntry = shared.GetLootEntriesForEntry
local SortLootEntriesByPreferredOrder = shared.SortLootEntriesByPreferredOrder
local GetItemDisplayName = shared.GetItemDisplayName
local SetLootButtonTooltip = shared.SetLootButtonTooltip
local SetLootButtonTextColor = shared.SetLootButtonTextColor
local GetLootButtonDetailText = shared.GetLootButtonDetailText
local LootDebugPrint = shared.LootDebugPrint

local lootFrame = CreateFrame("Frame", "DoorsLootPreviewFrame", UIParent, "BasicFrameTemplateWithInset")
lootFrame:SetSize(420, 500)
lootFrame:SetPoint("LEFT", frame, "RIGHT", 16, 0)
lootFrame:SetMovable(true)
lootFrame:EnableMouse(true)
lootFrame:RegisterForDrag("LeftButton")
lootFrame:SetScript("OnDragStart", lootFrame.StartMoving)
lootFrame:SetScript("OnDragStop", lootFrame.StopMovingOrSizing)
lootFrame:Hide()
table.insert(UISpecialFrames, "DoorsLootPreviewFrame")

lootFrame.TitleText:SetText("副本掉落预览")

lootFrame.subTitle = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lootFrame.subTitle:SetPoint("TOPLEFT", 16, -36)
lootFrame.subTitle:SetPoint("TOPRIGHT", -16, -36)
lootFrame.subTitle:SetJustifyH("LEFT")
lootFrame.subTitle:SetText("右键任意副本卡片以查看掉落")

lootFrame.desc = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
lootFrame.desc:SetPoint("TOPLEFT", lootFrame.subTitle, "BOTTOMLEFT", 0, -6)
lootFrame.desc:SetPoint("TOPRIGHT", -16, -68)
lootFrame.desc:SetJustifyH("LEFT")
lootFrame.desc:SetJustifyV("TOP")
lootFrame.desc:SetText("右键卡片查看掉落。当前筛选：本角色可用 / 全职业可用。")

lootFrame.currentEntry = nil
lootFrame.lootScope = "PLAYER"
lootFrame.filterButtons = {}

local function RefreshLootFilterHighlights()
    for _, btn in ipairs(lootFrame.filterButtons) do
        if btn.filterID == lootFrame.lootScope then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

for index, filter in ipairs(LOOT_CLASS_FILTERS) do
    local filterButton = CreateFrame("Button", nil, lootFrame, "UIPanelButtonTemplate")
    filterButton:SetSize(104, 24)
    filterButton:SetPoint("TOPLEFT", 16 + ((index - 1) * 114), -84)
    filterButton:SetText(filter.label)
    filterButton.filterID = filter.id
    filterButton:SetScript("OnClick", function(self)
        lootFrame.lootScope = self.filterID
        RefreshLootFilterHighlights()
        if lootFrame.currentEntry and lootFrame.OpenPreview then
            lootFrame.OpenPreview(lootFrame.currentEntry)
        end
    end)

    table.insert(lootFrame.filterButtons, filterButton)
end

RefreshLootFilterHighlights()

lootFrame.scrollFrame = CreateFrame("ScrollFrame", "DoorsLootPreviewScrollFrame", lootFrame, "UIPanelScrollFrameTemplate")
lootFrame.scrollFrame:SetPoint("TOPLEFT", 14, -118)
lootFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 14)

lootFrame.scrollChild = CreateFrame("Frame", nil, lootFrame.scrollFrame)
lootFrame.scrollChild:SetPoint("TOPLEFT")
lootFrame.scrollChild:SetPoint("TOPRIGHT")
lootFrame.scrollChild:SetWidth(360)
lootFrame.scrollFrame:SetScrollChild(lootFrame.scrollChild)

lootFrame.itemButtons = {}

lootFrame.emptyText = lootFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
lootFrame.emptyText:SetPoint("TOPLEFT", 10, -12)
lootFrame.emptyText:SetPoint("TOPRIGHT", -10, -12)
lootFrame.emptyText:SetJustifyH("LEFT")
lootFrame.emptyText:SetText("当前筛选下没有可显示的掉落。")
lootFrame.emptyText:Hide()

local function EnsureLootButtons(count)
    for i = #lootFrame.itemButtons + 1, count do
        local itemButton = CreateFrame("Button", nil, lootFrame.scrollChild)
        itemButton:SetSize(342, LOOT_ROW_BUTTON_HEIGHT)
        itemButton:SetPoint("TOPLEFT", 8, -((i - 1) * LOOT_ROW_HEIGHT) - 4)

        itemButton.bg = itemButton:CreateTexture(nil, "BACKGROUND")
        itemButton.bg:SetAllPoints()
        itemButton.bg:SetColorTexture(0.16, 0.12, 0.08, 0.52)

        itemButton.hover = itemButton:CreateTexture(nil, "HIGHLIGHT")
        itemButton.hover:SetAllPoints()
        itemButton.hover:SetColorTexture(1, 0.90, 0.55, 0.10)

        itemButton.bottomLine = itemButton:CreateTexture(nil, "BORDER")
        itemButton.bottomLine:SetPoint("BOTTOMLEFT", 0, 0)
        itemButton.bottomLine:SetPoint("BOTTOMRIGHT", 0, 0)
        itemButton.bottomLine:SetHeight(1)
        itemButton.bottomLine:SetColorTexture(0.45, 0.34, 0.18, 0.60)

        itemButton.icon = itemButton:CreateTexture(nil, "ARTWORK")
        itemButton.icon:SetSize(42, 42)
        itemButton.icon:SetPoint("LEFT", 8, 0)
        itemButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        itemButton.iconBorder = itemButton:CreateTexture(nil, "BORDER")
        itemButton.iconBorder:SetPoint("TOPLEFT", itemButton.icon, "TOPLEFT", -1, 1)
        itemButton.iconBorder:SetPoint("BOTTOMRIGHT", itemButton.icon, "BOTTOMRIGHT", 1, -1)
        itemButton.iconBorder:SetColorTexture(0.62, 0.46, 0.22, 0.90)

        itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        itemButton.text:SetPoint("TOPLEFT", itemButton.icon, "TOPRIGHT", 10, -3)
        itemButton.text:SetPoint("TOPRIGHT", -8, -3)
        itemButton.text:SetJustifyH("LEFT")
        itemButton.text:SetWordWrap(false)

        itemButton.subText = itemButton:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        itemButton.subText:SetPoint("TOPLEFT", itemButton.text, "BOTTOMLEFT", 0, -5)
        itemButton.subText:SetPoint("TOPRIGHT", -8, -24)
        itemButton.subText:SetJustifyH("LEFT")
        itemButton.subText:SetTextColor(0.80, 0.80, 0.80)
        itemButton.subText:SetWordWrap(false)

        itemButton:SetScript("OnEnter", function(self)
            SetLootButtonTooltip(self)
        end)
        itemButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        lootFrame.itemButtons[i] = itemButton
    end
end

local function OpenLootPreview(entry)
    if not entry then
        return
    end

    lootFrame.currentContentMode = GetActiveContentMode and GetActiveContentMode() or "DUNGEON"
    local contentMode = lootFrame.currentContentMode or "DUNGEON"

    local retryKey = string.format(
        "%s|%s|%s|%s",
        tostring(entry and (entry.name or entry.subtitle) or "unknown"),
        tostring(entry and (entry.subtitle or entry.name) or "unknown"),
        tostring(lootFrame.lootScope or "PLAYER"),
        tostring(contentMode)
    )
    if lootFrame.lastRetryKey ~= retryKey then
        lootFrame.linkRetryCount = 0
        lootFrame.lastRetryKey = retryKey
    end

    lootFrame.currentEntry = entry
    local displayTrackID = GetDisplayTrackID(contentMode)
    local dropEntries, hasConfiguredLoot, isSampleData, lootSource = GetLootEntriesForEntry(entry, displayTrackID, lootFrame.lootScope, contentMode)
    SortLootEntriesByPreferredOrder(dropEntries)
    lootFrame.subTitle:SetText(string.format("%s  (%s)", entry.subtitle or "未知副本", entry.name or "N/A"))

    local scopeLabel = "本角色"
    if lootFrame.lootScope == "ALL" then
        scopeLabel = "全职业"
    end

    local dropCount = #dropEntries

    if hasConfiguredLoot and not isSampleData then
        if lootSource == "player-empty" then
            lootFrame.desc:SetText(string.format("当前筛选：本角色可用（未匹配到可装备掉落，%d件）。", dropCount))
        elseif lootSource == "player-loading" then
            lootFrame.desc:SetText(string.format("当前筛选：本角色可用（初始化中，请稍候，当前%d件）。", dropCount))
        elseif lootSource == "runtime-player-ordered" then
            lootFrame.desc:SetText(string.format("当前筛选：本角色可用（%d件）。", dropCount))
        elseif lootSource == "runtime-player-warmup" then
            lootFrame.desc:SetText(string.format("当前筛选：本角色可用（%d件）。", dropCount))
        elseif lootSource == "runtime-all-warmup" and lootFrame.lootScope == "PLAYER" then
            lootFrame.desc:SetText(string.format("当前筛选：本角色可用（预热中，先展示%d件，稍后自动收敛）。", dropCount))
        else
            lootFrame.desc:SetText(string.format("当前筛选：%s可用（%d件）。", scopeLabel, dropCount))
        end
    elseif lootSource == "raid-unconfigured" then
        lootFrame.desc:SetText("该团本掉落尚未录入，后续可补充静态掉落或遇境日记索引。")
    elseif hasConfiguredLoot and isSampleData then
        lootFrame.desc:SetText(string.format("当前筛选：%s可用（%d件）。", scopeLabel, dropCount))
    else
        lootFrame.desc:SetText(string.format("当前筛选：%s可用（%d件）。", scopeLabel, dropCount))
    end

    EnsureLootButtons(#dropEntries)

    local missingLinkCount = 0
    for _, d in ipairs(dropEntries) do
        if d and (not d.itemLink or d.itemLink == "") then
            missingLinkCount = missingLinkCount + 1
        end
    end

    local unresolvedNameCount = 0
    if C_Item and C_Item.GetItemNameByID then
        for _, d in ipairs(dropEntries) do
            if d and d.itemID then
                local resolvedName = C_Item.GetItemNameByID(d.itemID)
                if not resolvedName or resolvedName == "" then
                    unresolvedNameCount = unresolvedNameCount + 1
                end
            end
        end
    end

    local shouldRetry = false
    if lootSource == "player-loading" then
        shouldRetry = true
    elseif lootSource == "player-empty" and lootFrame.lootScope == "PLAYER" then
        shouldRetry = true
    elseif lootSource == "runtime-empty" then
        shouldRetry = true
    elseif lootSource == "runtime-all-warmup" and lootFrame.lootScope == "PLAYER" then
        shouldRetry = true
    elseif lootSource == "runtime" and missingLinkCount > 0 then
        shouldRetry = true
    elseif lootSource == "runtime-player" and missingLinkCount > 0 then
        shouldRetry = true
    elseif lootSource == "runtime-player-warmup" and missingLinkCount > 0 then
        shouldRetry = true
    elseif lootSource == "runtime-player-ordered" and missingLinkCount > 0 then
        shouldRetry = true
    elseif lootSource == "raid-unconfigured" and contentMode == "RAID" and entry then
        local lootConfig = FindLootConfigForEntry(entry, contentMode)
        if lootConfig and lootConfig.journalInstanceID and type(lootConfig.journalEncounterIDs) == "table" and #lootConfig.journalEncounterIDs > 0 then
            shouldRetry = true
        end
    end

    if unresolvedNameCount > 0 then
        shouldRetry = true
    end

    if shouldRetry then
        local retryEntries = dropEntries

        local requestLoadItemDataByID = C_Item and C_Item.RequestLoadItemDataByID
        if requestLoadItemDataByID then
            for _, dropEntry in ipairs(retryEntries or {}) do
                if dropEntry and dropEntry.itemID then
                    requestLoadItemDataByID(dropEntry.itemID)
                end
            end
        end

        lootFrame.linkRetryCount = (lootFrame.linkRetryCount or 0) + 1
        if lootFrame.linkRetryCount <= 8 and C_Timer and C_Timer.After then
            local retryEntry = entry
            local retryScope = lootFrame.lootScope
            C_Timer.After(0.35, function()
                if lootFrame:IsShown() and lootFrame.currentEntry == retryEntry and lootFrame.lootScope == retryScope and lootFrame.OpenPreview then
                    lootFrame.OpenPreview(retryEntry)
                end
            end)
        end
    else
        lootFrame.linkRetryCount = 0
    end

    if (entry.name == "Skyreach" or entry.subtitle == "通天峰") and #dropEntries > 0 then
        LootDebugPrint(string.format("panel open: %s source=%s scope=%s count=%d", entry.subtitle or entry.name or "unknown", tostring(lootSource), tostring(lootFrame.lootScope), #dropEntries))
        local inspectCount = math.min(10, #dropEntries)
        for i = 1, inspectCount do
            local d = dropEntries[i]
            local linkState = d and d.itemLink and "hasLink" or "noLink"
            local linkPreview = "nil"
            if d and d.itemLink then
                linkPreview = d.itemLink:sub(1, 60)
            end
            LootDebugPrint(string.format("item[%d]: id=%s slot=%s %s link=%s", i, tostring(d and d.itemID), tostring(d and d.slot), linkState, linkPreview))
        end
    end

    for i, itemButton in ipairs(lootFrame.itemButtons) do
        local dropEntry = dropEntries[i]
        if dropEntry then
            local itemName = GetItemDisplayName(dropEntry)
            itemButton.itemID = dropEntry.itemID
            itemButton.itemName = itemName
            itemButton.lootScope = lootFrame.lootScope
            itemButton.contentMode = contentMode
            if dropEntry.itemLink then
                itemButton.itemLink = dropEntry.itemLink
            else
                itemButton.itemLink = nil
            end
            local itemIcon = nil
            if C_Item and C_Item.GetItemIconByID and dropEntry.itemID then
                itemIcon = C_Item.GetItemIconByID(dropEntry.itemID)
            end
            itemButton.icon:SetTexture(itemIcon or 134400)

            itemButton.text:SetText(itemName)
            if itemButton.subText then
                itemButton.subText:SetText(GetLootButtonDetailText(dropEntry, contentMode))
            end
            SetLootButtonTextColor(itemButton, dropEntry)
            itemButton:Show()
        else
            itemButton.itemID = nil
            itemButton.itemName = nil
            itemButton.itemLink = nil
            itemButton.lootScope = nil
            itemButton.contentMode = nil
            if itemButton.subText then
                itemButton.subText:SetText("")
            end
            itemButton:Hide()
        end
    end

    local height = math.max(340, (#dropEntries * LOOT_ROW_HEIGHT) + 16)
    lootFrame.scrollChild:SetHeight(height)
    lootFrame.scrollFrame:SetVerticalScroll(0)
    lootFrame.emptyText:SetShown(#dropEntries == 0)
    lootFrame:Show()
end

lootFrame.OpenPreview = OpenLootPreview
shared.lootFrame = lootFrame
shared.OpenLootPreview = OpenLootPreview
shared.HideLootPreview = function()
    if lootFrame:IsShown() then
        lootFrame:Hide()
    end
end

frame:HookScript("OnHide", function()
    if lootFrame:IsShown() then
        lootFrame:Hide()
    end
end)
