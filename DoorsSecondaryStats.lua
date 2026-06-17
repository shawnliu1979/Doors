local addonName = ...

local frame = CreateFrame("Frame", "DoorsSecondaryStatsFrame", UIParent)
frame:SetSize(170, 86)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -72, -180)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", 0, 0)
title:SetPoint("TOPRIGHT", 0, 0)
title:SetJustifyH("LEFT")
title:SetText("副属性")
title:SetTextColor(1, 1, 1)

local lines = {}
local labels = {
    { key = "crit", text = "暴击" },
    { key = "haste", text = "急速" },
    { key = "mastery", text = "精通" },
    { key = "versatility", text = "全能" },
}

local function CreateLine(index, labelText)
    local line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    if index == 1 then
        line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    else
        line:SetPoint("TOPLEFT", lines[index - 1], "BOTTOMLEFT", 0, -4)
    end
    line:SetJustifyH("LEFT")
    line:SetText(labelText .. ": 0.0%")
    line:SetTextColor(0.95, 0.95, 0.95)
    return line
end

for index, info in ipairs(labels) do
    lines[index] = CreateLine(index, info.text)
end

local function FormatPercent(value)
    value = tonumber(value) or 0
    return string.format("%.1f%%", value)
end

local function GetMasteryPercent()
    if GetMasteryEffect then
        local masteryEffect = GetMasteryEffect()
        if masteryEffect then
            return masteryEffect
        end
    end

    if GetMastery then
        return GetMastery()
    end

    return 0
end

local function GetVersatilityPercent()
    if GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
        local bonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
        if bonus then
            return bonus
        end
    end

    return 0
end

local function RefreshStats()
    local crit = GetCritChance and GetCritChance() or 0
    local haste = GetHaste and GetHaste() or 0
    local mastery = GetMasteryPercent()
    local versatility = GetVersatilityPercent()

    lines[1]:SetText("暴击: " .. FormatPercent(crit))
    lines[2]:SetText("急速: " .. FormatPercent(haste))
    lines[3]:SetText("精通: " .. FormatPercent(mastery))
    lines[4]:SetText("全能: " .. FormatPercent(versatility))
end

local refreshFrame = CreateFrame("Frame")
refreshFrame:RegisterEvent("PLAYER_LOGIN")
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
refreshFrame:RegisterEvent("UNIT_STATS")
refreshFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
refreshFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
refreshFrame:RegisterEvent("MASTERY_UPDATE")
refreshFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_STATS" and unit ~= "player" then
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        frame:Show()
    end

    RefreshStats()
end)

local elapsedSinceRefresh = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then
        return
    end

    elapsedSinceRefresh = elapsedSinceRefresh + elapsed
    if elapsedSinceRefresh < 5 then
        return
    end

    elapsedSinceRefresh = 0
    RefreshStats()
end)

RefreshStats()
frame:Show()