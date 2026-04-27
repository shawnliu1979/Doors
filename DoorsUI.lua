local addonName = ...

-- 这个文件专门负责 `/doors` 的界面。

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
local DUNGEON_LOOT = (DoorsData and DoorsData.DUNGEON_LOOT) or {}

local LOOT_CLASS_FILTERS = {
    { id = "PLAYER", label = "本角色" },
    { id = "ALL", label = "全职业" },
}

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

local FORCE_LOOT_DEBUG_PRINT = true
local LOOT_ROW_HEIGHT = 62
local LOOT_ROW_BUTTON_HEIGHT = 56
local LOOT_TEXT_COLOR = { 0.64, 0.21, 0.93 } -- #A335EE
local ROLL_CURRENCY_ID = 3418

local function DebugLog(message)
    if not DOORS_DEBUG then
        return
    end

    print(string.format("[%s:DEBUG] %s", addonName or "Doors", message))
end

local function LootDebugPrint(message)
    if not FORCE_LOOT_DEBUG_PRINT and not DOORS_DEBUG then
        return
    end

    print(string.format("[%s:LOOT] %s", addonName or "Doors", message))
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

-- 掉落表缺数据时使用预览池兜底，这样 UI 演示不会中断。
local DROP_SAMPLE_POOL = {
    { itemID = 18832, slot = "单手剑" },
    { itemID = 19364, slot = "双手剑" },
    { itemID = 17076, slot = "双手剑" },
    { itemID = 17182, slot = "双手锤" },
    { itemID = 18803, slot = "法杖" },
    { itemID = 19348, slot = "盾牌" },
    { itemID = 16908, slot = "头部" },
    { itemID = 18805, slot = "匕首" },
    { itemID = 18817, slot = "头部" },
    { itemID = 19356, slot = "法杖" },
}

local function HashTextForSeed(text)
    if type(text) ~= "string" then
        return 1
    end

    local total = 0
    for i = 1, #text do
        total = total + string.byte(text, i)
    end

    return total
end

local function BuildFallbackDropsForDungeon(entry)
    if not entry then
        return {}
    end

    local seed = HashTextForSeed(entry.name or entry.subtitle or "Doors")
    local startIndex = (seed % #DROP_SAMPLE_POOL) + 1
    local result = {}

    for i = 0, 5 do
        local index = ((startIndex + i - 1) % #DROP_SAMPLE_POOL) + 1
        local sample = DROP_SAMPLE_POOL[index]
        result[#result + 1] = {
            itemID = sample.itemID,
            slot = sample.slot,
        }
    end

    return result
end

local function FindLootConfigForDungeon(entry)
    if not entry or type(DUNGEON_LOOT) ~= "table" then
        return nil
    end

    for _, lootConfig in ipairs(DUNGEON_LOOT) do
        if lootConfig.name == entry.name or lootConfig.subtitle == entry.subtitle then
            return lootConfig
        end
    end

    return nil
end

local RUNTIME_LOOT_CACHE = {}

local function ExtractItemIDFromLink(itemLink)
    if type(itemLink) ~= "string" then
        return nil
    end

    local itemID = itemLink:match("item:(%d+)")
    if itemID then
        return tonumber(itemID)
    end

    return nil
end

local function HasKnownEquipSlot(slotText)
    if type(slotText) ~= "string" then
        return false
    end

    local slot = string.gsub(slotText, "^%s+", "")
    slot = string.gsub(slot, "%s+$", "")
    if slot == "" or slot == "未知部位" or slot == "装备" then
        return false
    end

    local slotLower = string.lower(slot)
    if slotLower == "unknown" or slotLower == "unknown slot" then
        return false
    end

    return true
end

local ITEM_EQUIP_LOC_TO_SLOT_TEXT = {
    INVTYPE_2HWEAPON = "双手武器",
    INVTYPE_WEAPONMAINHAND = "单手武器",
    INVTYPE_WEAPON = "单手武器",
    INVTYPE_WEAPONOFFHAND = "副手武器",
    INVTYPE_HOLDABLE = "副手武器",
    INVTYPE_SHIELD = "副手武器",
    INVTYPE_RANGED = "远程",
    INVTYPE_RANGEDRIGHT = "远程",
    INVTYPE_THROWN = "远程",
    INVTYPE_RELIC = "副手武器",
    INVTYPE_HEAD = "头",
    INVTYPE_NECK = "颈部",
    INVTYPE_SHOULDER = "肩",
    INVTYPE_CLOAK = "披风",
    INVTYPE_CHEST = "胸",
    INVTYPE_ROBE = "胸",
    INVTYPE_WRIST = "手腕",
    INVTYPE_HAND = "手",
    INVTYPE_WAIST = "腰",
    INVTYPE_LEGS = "腿",
    INVTYPE_FEET = "脚",
    INVTYPE_FINGER = "戒指",
    INVTYPE_TRINKET = "饰品",
}

local function ResolveLootSlotText(dropEntry)
    if not dropEntry then
        return "未知部位"
    end

    if HasKnownEquipSlot(dropEntry.slot) then
        return dropEntry.slot
    end

    local itemID = dropEntry.itemID
    if itemID and C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemID)
        if itemEquipLoc and ITEM_EQUIP_LOC_TO_SLOT_TEXT[itemEquipLoc] then
            return ITEM_EQUIP_LOC_TO_SLOT_TEXT[itemEquipLoc]
        end
    end

    return dropEntry.slot or "未知部位"
end

local function GetTrackDifficultyIDs(trackID)
    if trackID == "MYTH" then
        return { 8, 23, 24, 2, 1 }
    end

    if trackID == "HERO" then
        return { 8, 23, 2, 1, 24 }
    end

    return { 23, 2, 1, 24, 8 }
end

local function GetPlayerClassAndSpecForLootFilter()
    local classID = 0
    if UnitClass then
        local _, _, classTokenID = UnitClass("player")
        classID = tonumber(classTokenID) or 0
    end

    local specID = 0
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            specID = GetSpecializationInfo(specIndex) or 0
        end
    end

    return classID, specID
end

local function GetLootFilterValues(lootScope)
    if lootScope == "ALL" then
        return 0, 0
    end

    local classID = GetPlayerClassAndSpecForLootFilter()
    -- "本角色可用"按职业过滤即可，避免专精过滤误伤可装备物品（如通用/主属性饰品）。
    return classID, 0
end

local function IsPlayerLootScopeReady()
    local classID, specID = GetPlayerClassAndSpecForLootFilter()
    if (classID or 0) <= 0 then
        return false
    end

    -- 专精在首次打开时可能短暂为 0；此时允许按职业维度筛选，避免空列表闪烁。
    return true
end

local function CopyLootEntries(entries)
    local copy = {}
    for index, entry in ipairs(entries or {}) do
        copy[index] = {
            itemID = entry.itemID,
            itemLink = entry.itemLink,
            slot = entry.slot,
        }
    end
    return copy
end

local LOOT_SLOT_SORT_ORDER = {
    TWO_HAND_WEAPON = 1,
    ONE_HAND_WEAPON = 2,
    OFF_HAND_WEAPON = 3,
    RANGED_WEAPON = 4,
    HEAD = 5,
    NECK = 6,
    SHOULDER = 7,
    CLOAK = 8,
    CHEST = 9,
    WRIST = 10,
    HANDS = 11,
    WAIST = 12,
    LEGS = 13,
    FEET = 14,
    RING = 15,
    TRINKET = 16,
    UNKNOWN = 99,
}

local function GetLootSlotSortRank(slotText)
    local slot = tostring(slotText or "")
    local slotLower = string.lower(slot)

    if string.find(slot, "双手", 1, true)
        or string.find(slot, "法杖", 1, true)
        or string.find(slot, "长柄", 1, true)
        or string.find(slotLower, "two%-hand")
        or string.find(slotLower, "staff")
        or string.find(slotLower, "polearm")
        then
        return LOOT_SLOT_SORT_ORDER.TWO_HAND_WEAPON
    end

    if string.find(slot, "单手", 1, true)
        or string.find(slot, "匕首", 1, true)
        or string.find(slot, "拳套", 1, true)
        or string.find(slotLower, "one%-hand")
        or string.find(slotLower, "dagger")
        or string.find(slotLower, "fist") then
        return LOOT_SLOT_SORT_ORDER.ONE_HAND_WEAPON
    end

    if string.find(slot, "副手", 1, true)
        or string.find(slot, "盾", 1, true)
        or string.find(slot, "圣契", 1, true)
        or string.find(slot, "神像", 1, true)
        or string.find(slot, "图腾", 1, true)
        or string.find(slotLower, "off hand")
        or string.find(slotLower, "off%-hand")
        or string.find(slotLower, "shield") then
        return LOOT_SLOT_SORT_ORDER.OFF_HAND_WEAPON
    end

    if string.find(slot, "远程", 1, true)
        or string.find(slot, "弓", 1, true)
        or string.find(slot, "弩", 1, true)
        or string.find(slot, "枪", 1, true)
        or string.find(slotLower, "ranged")
        or string.find(slotLower, "bow")
        or string.find(slotLower, "crossbow")
        or string.find(slotLower, "gun")
        or string.find(slotLower, "thrown")
        or string.find(slotLower, "wand") then
        return LOOT_SLOT_SORT_ORDER.RANGED_WEAPON
    end

    if string.find(slot, "头", 1, true) or string.find(slotLower, "head") or string.find(slotLower, "helm") then
        return LOOT_SLOT_SORT_ORDER.HEAD
    end

    if string.find(slot, "颈", 1, true)
        or string.find(slot, "项链", 1, true)
        or string.find(slotLower, "neck")
        or string.find(slotLower, "amulet") then
        return LOOT_SLOT_SORT_ORDER.NECK
    end

    if string.find(slot, "肩", 1, true) or string.find(slotLower, "shoulder") then
        return LOOT_SLOT_SORT_ORDER.SHOULDER
    end

    if string.find(slot, "披风", 1, true)
        or string.find(slot, "背", 1, true)
        or string.find(slotLower, "cloak")
        or string.find(slotLower, "back") then
        return LOOT_SLOT_SORT_ORDER.CLOAK
    end

    if string.find(slot, "胸", 1, true)
        or string.find(slotLower, "chest")
        or string.find(slotLower, "robe")
        or string.find(slotLower, "tunic") then
        return LOOT_SLOT_SORT_ORDER.CHEST
    end

    if string.find(slot, "腕", 1, true) or string.find(slotLower, "wrist") or string.find(slotLower, "bracer") then
        return LOOT_SLOT_SORT_ORDER.WRIST
    end

    if string.find(slot, "戒指", 1, true)
        or string.find(slot, "指环", 1, true)
        or string.find(slot, "手指", 1, true)
        or string.find(slotLower, "ring")
        or string.find(slotLower, "finger") then
        return LOOT_SLOT_SORT_ORDER.RING
    end

    if string.find(slot, "手", 1, true)
        and not string.find(slot, "双手", 1, true)
        and not string.find(slot, "单手", 1, true)
        and not string.find(slot, "副手", 1, true) then
        return LOOT_SLOT_SORT_ORDER.HANDS
    end
    if string.find(slotLower, "hand") and not string.find(slotLower, "off") then
        return LOOT_SLOT_SORT_ORDER.HANDS
    end

    if string.find(slot, "腰", 1, true) or string.find(slotLower, "waist") or string.find(slotLower, "belt") then
        return LOOT_SLOT_SORT_ORDER.WAIST
    end

    if string.find(slot, "腿", 1, true) or string.find(slotLower, "leg") then
        return LOOT_SLOT_SORT_ORDER.LEGS
    end

    if string.find(slot, "脚", 1, true) or string.find(slotLower, "feet") or string.find(slotLower, "boot") then
        return LOOT_SLOT_SORT_ORDER.FEET
    end

    if string.find(slot, "饰品", 1, true)
        or string.find(slot, "圣物", 1, true)
        or string.find(slotLower, "trinket") then
        return LOOT_SLOT_SORT_ORDER.TRINKET
    end

    return LOOT_SLOT_SORT_ORDER.UNKNOWN
end

local function SortLootEntriesByPreferredOrder(entries)
    if type(entries) ~= "table" or #entries <= 1 then
        return
    end

    table.sort(entries, function(a, b)
        local resolvedSlotA = ResolveLootSlotText(a)
        local resolvedSlotB = ResolveLootSlotText(b)
        local rankA = GetLootSlotSortRank(resolvedSlotA)
        local rankB = GetLootSlotSortRank(resolvedSlotB)
        if rankA ~= rankB then
            return rankA < rankB
        end

        local slotA = tostring(resolvedSlotA or "")
        local slotB = tostring(resolvedSlotB or "")
        if slotA ~= slotB then
            return slotA < slotB
        end

        return (a and a.itemID or 0) < (b and b.itemID or 0)
    end)
end

local function SplitByColon(text)
    local fields = {}
    if type(text) ~= "string" then
        return fields
    end

    local startIndex = 1
    while true do
        local sepStart, sepEnd = string.find(text, ":", startIndex, true)
        if not sepStart then
            fields[#fields + 1] = string.sub(text, startIndex)
            break
        end

        fields[#fields + 1] = string.sub(text, startIndex, sepStart - 1)
        startIndex = sepEnd + 1
    end

    return fields
end

local function BuildColonString(fields)
    return table.concat(fields, ":")
end

local function GetTrackRank(trackID)
    if trackID == "MYTH" then
        return 4
    end

    if trackID == "HERO" then
        return 3
    end

    return 2
end

local function GetTrackRankByModifier28(modifier28Value)
    if not modifier28Value then
        return nil
    end

    if modifier28Value <= 3024 then
        return 1 -- 冒险者
    end

    if modifier28Value == 3025 then
        return 2 -- 勇士
    end

    if modifier28Value == 3026 then
        return 3 -- 英雄
    end

    if modifier28Value >= 3027 then
        return 4 -- 神话
    end

    return nil
end

local function ExtractModifier28Value(itemLink)
    if type(itemLink) ~= "string" then
        return nil
    end

    local itemString = itemLink:match("|Hitem:([^|]+)|h")
    if not itemString then
        return nil
    end

    local fields = SplitByColon(itemString)
    local numBonusIDs = tonumber(fields[13])
    if not numBonusIDs or numBonusIDs <= 0 then
        return nil
    end

    local numModifiersIndex = 14 + numBonusIDs
    local numModifiers = tonumber(fields[numModifiersIndex])
    if not numModifiers or numModifiers <= 0 then
        return nil
    end

    local firstModifierIndex = numModifiersIndex + 1
    for modifierOffset = 0, (numModifiers - 1) do
        local typeIndex = firstModifierIndex + (modifierOffset * 2)
        local valueIndex = typeIndex + 1
        if tonumber(fields[typeIndex]) == 28 then
            return tonumber(fields[valueIndex])
        end
    end

    return nil
end

local function GetLinkTrackRank(itemLink)
    return GetTrackRankByModifier28(ExtractModifier28Value(itemLink))
end

local function GetTrackLabelByRank(rank)
    if rank == 4 then
        return "神话"
    end

    if rank == 3 then
        return "英雄"
    end

    if rank == 2 then
        return "勇士"
    end

    if rank == 1 then
        return "冒险者"
    end

    return "未知"
end

local function IsLinkCloserToTargetTrack(newLink, currentLink, trackID)
    if not newLink then
        return false
    end

    if not currentLink then
        return true
    end

    local targetRank = GetTrackRank(trackID)
    local newRank = GetLinkTrackRank(newLink)
    local currentRank = GetLinkTrackRank(currentLink)

    if newRank and not currentRank then
        return true
    end

    if not newRank then
        return false
    end

    if not currentRank then
        return true
    end

    local newDistance = math.abs(targetRank - newRank)
    local currentDistance = math.abs(targetRank - currentRank)
    if newDistance < currentDistance then
        return true
    end

    if newDistance == currentDistance and newRank > currentRank then
        return true
    end

    return false
end

local function BuildTrackAdjustedItemLink(itemLink, trackID)
    if type(itemLink) ~= "string" then
        return itemLink
    end

    if trackID ~= "HERO" and trackID ~= "MYTH" then
        return itemLink
    end

    local itemString = itemLink:match("|Hitem:([^|]+)|h")
    if not itemString then
        return itemLink
    end

    local fields = SplitByColon(itemString)
    local difficultyFieldIndex = 12
    local numBonusIDs = tonumber(fields[13])
    if not numBonusIDs or numBonusIDs <= 0 then
        return itemLink
    end

    local numModifiersIndex = 14 + numBonusIDs
    local numModifiers = tonumber(fields[numModifiersIndex])
    if not numModifiers or numModifiers <= 0 then
        return itemLink
    end

    local targetDifficultyID = 23
    local targetModifier28 = 3025
    if trackID == "MYTH" then
        targetDifficultyID = 8
        targetModifier28 = 3026
    end

    local firstModifierIndex = numModifiersIndex + 1
    local changed = false

    local currentDifficultyID = tonumber(fields[difficultyFieldIndex])
    if currentDifficultyID ~= targetDifficultyID then
        fields[difficultyFieldIndex] = tostring(targetDifficultyID)
        changed = true
    end

    for modifierOffset = 0, (numModifiers - 1) do
        local typeIndex = firstModifierIndex + (modifierOffset * 2)
        local valueIndex = typeIndex + 1
        local modifierType = tonumber(fields[typeIndex])
        local modifierValue = tonumber(fields[valueIndex])
        if modifierType == 28 and modifierValue and modifierValue ~= targetModifier28 then
            fields[valueIndex] = tostring(targetModifier28)
            changed = true
            break
        end
    end

    if not changed then
        return itemLink
    end

    local adjustedItemString = BuildColonString(fields)
    local adjustedLink = itemLink:gsub("|Hitem:[^|]+|h", "|Hitem:" .. adjustedItemString .. "|h", 1)
    return adjustedLink
end

local function HasAnyItemLink(entries)
    for _, entry in ipairs(entries or {}) do
        if entry and entry.itemLink and entry.itemLink ~= "" then
            return true
        end
    end

    return false
end

local function CountLinkedEntries(entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do
        if entry and entry.itemLink and entry.itemLink ~= "" then
            total = total + 1
        end
    end

    return total
end

local function MergeLootEntriesPreferLinks(primaryEntries, secondaryEntries)
    local mergedByItemID = {}

    for _, entry in ipairs(primaryEntries or {}) do
        if entry and entry.itemID then
            mergedByItemID[entry.itemID] = {
                itemID = entry.itemID,
                itemLink = entry.itemLink,
                slot = entry.slot,
            }
        end
    end

    for _, entry in ipairs(secondaryEntries or {}) do
        if entry and entry.itemID then
            local existing = mergedByItemID[entry.itemID]
            if not existing then
                mergedByItemID[entry.itemID] = {
                    itemID = entry.itemID,
                    itemLink = entry.itemLink,
                    slot = entry.slot,
                }
            elseif (not existing.itemLink or existing.itemLink == "") and entry.itemLink and entry.itemLink ~= "" then
                existing.itemLink = entry.itemLink
                if entry.slot and entry.slot ~= "" then
                    existing.slot = entry.slot
                end
            end
        end
    end

    local merged = {}
    for _, entry in ipairs(primaryEntries or {}) do
        if entry and entry.itemID then
            merged[#merged + 1] = mergedByItemID[entry.itemID] or {
                itemID = entry.itemID,
                itemLink = entry.itemLink,
                slot = entry.slot,
            }
        end
    end

    return merged
end

local function KeepOnlyLinkedEntries(entries)
    local filtered = {}
    for _, entry in ipairs(entries or {}) do
        if entry and entry.itemLink and entry.itemLink ~= "" then
            filtered[#filtered + 1] = {
                itemID = entry.itemID,
                itemLink = entry.itemLink,
                slot = entry.slot,
            }
        end
    end

    return filtered
end

local function EnsureEncounterJournalLoaded()
    if EJ_SelectInstance and EJ_SetDifficulty then
        return true
    end

    local isAddOnLoaded = _G["IsAddOnLoaded"]
    local loadAddOn = _G["LoadAddOn"]
    if isAddOnLoaded and loadAddOn and not isAddOnLoaded("Blizzard_EncounterJournal") then
        pcall(loadAddOn, "Blizzard_EncounterJournal")
    end

    return EJ_SelectInstance ~= nil and EJ_SetDifficulty ~= nil
end

local function EnrichStaticLootWithEncounterJournalLinks(lootConfig, trackID, lootScope)
    if not lootConfig or type(lootConfig.drops) ~= "table" or #lootConfig.drops == 0 then
        return nil
    end

    if not lootConfig.journalInstanceID or not EnsureEncounterJournalLoaded() then
        return nil
    end

    local getLootInfoByIndex = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex
    local getNumLoot = _G["EJ_GetNumLoot"]
    if not getLootInfoByIndex or not getNumLoot or not EJ_SelectInstance or not EJ_SetDifficulty then
        return nil
    end

    local getLootFilter = _G["EJ_GetLootFilter"]
    local setLootFilter = _G["EJ_SetLootFilter"]
    local previousFilterClassID, previousFilterSpecID = 0, 0
    if getLootFilter then
        local ok, classID, specID = pcall(getLootFilter)
        if ok then
            previousFilterClassID = classID or 0
            previousFilterSpecID = specID or 0
        end
    end

    local desiredFilterClassID, desiredFilterSpecID = GetLootFilterValues(lootScope)

    local cacheKey = string.format(
        "static-link:%s:%s:%s:%s",
        tostring(lootConfig.journalInstanceID),
        tostring(trackID or "CHAMPION"),
        tostring(desiredFilterClassID),
        tostring(desiredFilterSpecID)
    )
    if RUNTIME_LOOT_CACHE[cacheKey] then
        local cachedEntries = RUNTIME_LOOT_CACHE[cacheKey]
        if CountLinkedEntries(cachedEntries) == #cachedEntries then
            return CopyLootEntries(cachedEntries)
        end

        RUNTIME_LOOT_CACHE[cacheKey] = nil
    end

    local wantedByItemID = {}
    for _, entry in ipairs(lootConfig.drops) do
        wantedByItemID[entry.itemID] = entry.slot or "装备"
    end

    EJ_SelectInstance(lootConfig.journalInstanceID)

    local didOverrideFilter = false
    if setLootFilter then
        local ok = pcall(setLootFilter, desiredFilterClassID, desiredFilterSpecID)
        didOverrideFilter = ok == true

        if ok and getLootFilter then
            local readOK, activeClassID, activeSpecID = pcall(getLootFilter)
            if readOK then
                LootDebugPrint(string.format(
                    "EJ loot filter active: scope=%s class=%s spec=%s",
                    tostring(lootScope),
                    tostring(activeClassID or 0),
                    tostring(activeSpecID or 0)
                ))
            end
        end
    end

    local linkedByItemID = {}
    local linkedCount = 0

    for _, difficultyID in ipairs(GetTrackDifficultyIDs(trackID)) do
        EJ_SetDifficulty(difficultyID)

        local lootCount = getNumLoot() or 0
        if lootCount > 0 then
            for index = 1, lootCount do
                local itemInfo = getLootInfoByIndex(index)
                if itemInfo and itemInfo.itemID and wantedByItemID[itemInfo.itemID] then
                    local itemID = itemInfo.itemID
                    local existingEntry = linkedByItemID[itemID]
                    local shouldReplace = false
                    if not existingEntry then
                        shouldReplace = true
                    elseif not existingEntry.itemLink and itemInfo.link then
                        shouldReplace = true
                    elseif itemInfo.link and existingEntry.itemLink and IsLinkCloserToTargetTrack(itemInfo.link, existingEntry.itemLink, trackID) then
                        shouldReplace = true
                    end

                    if shouldReplace then
                        linkedByItemID[itemID] = {
                            itemID = itemID,
                            itemLink = itemInfo.link,
                            slot = itemInfo.slot or wantedByItemID[itemID] or "装备",
                        }

                        if itemInfo.link and (not existingEntry or not existingEntry.itemLink) then
                            linkedCount = linkedCount + 1
                        end
                    end
                end
            end

            if linkedCount >= #lootConfig.drops then
                break
            end
        end
    end

    if didOverrideFilter and setLootFilter then
        pcall(setLootFilter, previousFilterClassID, previousFilterSpecID)
    end

    if next(linkedByItemID) then
        local enrichedEntries = {}
        for _, entry in ipairs(lootConfig.drops) do
            enrichedEntries[#enrichedEntries + 1] = linkedByItemID[entry.itemID] or {
                itemID = entry.itemID,
                itemLink = entry.itemLink,
                slot = entry.slot,
            }
        end

        if lootScope == "PLAYER" then
            enrichedEntries = KeepOnlyLinkedEntries(enrichedEntries)
        end

        if CountLinkedEntries(enrichedEntries) == #enrichedEntries then
            RUNTIME_LOOT_CACHE[cacheKey] = CopyLootEntries(enrichedEntries)
        end

        return enrichedEntries
    end

    return nil
end

local function GetEncounterJournalLoot(lootConfig, trackID, lootScope)
    if not lootConfig or not lootConfig.journalInstanceID or type(lootConfig.journalEncounterIDs) ~= "table" then
        return nil
    end

    if not EnsureEncounterJournalLoaded() then
        return nil
    end

    local getLootInfoByIndex = (C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex) or _G["EJ_GetLootInfoByIndex"]
    local selectEncounter = _G["EJ_SelectEncounter"]
    local getNumLoot = _G["EJ_GetNumLoot"]
    local getLootInfo = _G["EJ_GetLootInfo"]
    if not EJ_SelectInstance or not EJ_SetDifficulty or (not getLootInfoByIndex and not (selectEncounter and getNumLoot and getLootInfo)) then
        return nil
    end

    local getLootFilter = _G["EJ_GetLootFilter"]
    local setLootFilter = _G["EJ_SetLootFilter"]
    local previousFilterClassID, previousFilterSpecID = 0, 0
    if getLootFilter then
        local ok, classID, specID = pcall(getLootFilter)
        if ok then
            previousFilterClassID = classID or 0
            previousFilterSpecID = specID or 0
        end
    end
    local desiredFilterClassID, desiredFilterSpecID = GetLootFilterValues(lootScope)

    local cacheKey = string.format(
        "%s:%s:%s:%s",
        tostring(lootConfig.journalInstanceID),
        tostring(trackID or "CHAMPION"),
        tostring(desiredFilterClassID),
        tostring(desiredFilterSpecID)
    )
    if RUNTIME_LOOT_CACHE[cacheKey] then
        local cachedEntries = RUNTIME_LOOT_CACHE[cacheKey]
        if CountLinkedEntries(cachedEntries) == #cachedEntries then
            return cachedEntries
        end

        RUNTIME_LOOT_CACHE[cacheKey] = nil
    end

    -- 按装等层级优先取对应难度，拿到当前层级的 itemLink（含品质/装等信息）。
    local difficultyIDs = GetTrackDifficultyIDs(trackID)
    local byItemID = {}

    EJ_SelectInstance(lootConfig.journalInstanceID)

    local didOverrideFilter = false
    if setLootFilter then
        local ok = pcall(setLootFilter, desiredFilterClassID, desiredFilterSpecID)
        didOverrideFilter = ok == true
    end

    local function ingestLootEntry(rawInfo, fallbackEncounterID, fallbackIndex)
        local itemID
        local slotText
        local itemLink

        if type(rawInfo) == "table" then
            local tableItemID = rawInfo.itemID
            if not tableItemID then
                tableItemID = rawInfo["itemId"]
            end
            itemID = tonumber(tableItemID)
            slotText = rawInfo.slot or rawInfo.armorType
            itemLink = rawInfo.link
            if not itemID then
                itemID = ExtractItemIDFromLink(itemLink)
            end
        else
            local _, _, slot, armorType, resultItemLink = rawInfo, nil, nil, nil, nil
            if getLootInfoByIndex then
                _, _, slot, armorType, resultItemLink = getLootInfoByIndex(fallbackIndex, fallbackEncounterID)
            else
                _, _, slot, armorType, resultItemLink = getLootInfo(fallbackIndex)
            end
            slotText = slot or armorType
            itemLink = resultItemLink
            itemID = ExtractItemIDFromLink(itemLink)
        end

        if itemID and not byItemID[itemID] then
            byItemID[itemID] = {
                itemID = itemID,
                itemLink = itemLink,
                slot = slotText or "装备",
            }
        end
    end

    for _, encounterID in ipairs(lootConfig.journalEncounterIDs) do
        if selectEncounter then
            selectEncounter(encounterID)
        end

        for _, difficultyID in ipairs(difficultyIDs) do
            EJ_SetDifficulty(difficultyID)

            if getLootInfoByIndex then
                local index = 1
                while true do
                    local info = getLootInfoByIndex(index, encounterID)
                    if not info then
                        info = getLootInfoByIndex(index)
                    end
                    if not info then
                        break
                    end

                    ingestLootEntry(info, encounterID, index)
                    index = index + 1
                end
            elseif selectEncounter and getNumLoot and getLootInfo then
                selectEncounter(encounterID)
                local lootCount = getNumLoot() or 0
                for index = 1, lootCount do
                    local info = getLootInfo(index)
                    if info then
                        ingestLootEntry(info, encounterID, index)
                    end
                end
            end
        end
    end

    local entries = {}
    for _, entry in pairs(byItemID) do
        entries[#entries + 1] = entry
    end

    table.sort(entries, function(a, b)
        return a.itemID < b.itemID
    end)

    if #entries == 0 then
        if didOverrideFilter and setLootFilter then
            pcall(setLootFilter, previousFilterClassID, previousFilterSpecID)
        end
        return nil
    end

    if didOverrideFilter and setLootFilter then
        pcall(setLootFilter, previousFilterClassID, previousFilterSpecID)
    end

    if #entries == 0 then
        return nil
    end

    RUNTIME_LOOT_CACHE[cacheKey] = entries
    return entries
end

local function GetLootEntriesForDungeon(entry, trackID, lootScope)
    if not entry then
        return {}, false, true, "empty"
    end

    if lootScope == "PLAYER" and not IsPlayerLootScopeReady() then
        return {}, true, false, "player-loading"
    end

    local lootConfig = FindLootConfigForDungeon(entry)
    if lootConfig and lootConfig.preferStatic and type(lootConfig.drops) == "table" and #lootConfig.drops > 0 then
        if lootScope == "PLAYER" then
            local runtimePlayerDrops = GetEncounterJournalLoot(lootConfig, trackID, lootScope)
            if runtimePlayerDrops and #runtimePlayerDrops > 0 then
                local runtimeByItemID = {}
                for _, runtimeEntry in ipairs(runtimePlayerDrops) do
                    if runtimeEntry and runtimeEntry.itemID then
                        runtimeByItemID[runtimeEntry.itemID] = runtimeEntry
                    end
                end

                local orderedPlayerDrops = {}
                for _, configuredEntry in ipairs(lootConfig.drops) do
                    local matched = runtimeByItemID[configuredEntry.itemID]
                    if matched then
                        local resolvedSlot = matched.slot
                        if not resolvedSlot or resolvedSlot == "" or resolvedSlot == "未知部位" then
                            resolvedSlot = configuredEntry.slot
                        end

                        orderedPlayerDrops[#orderedPlayerDrops + 1] = {
                            itemID = matched.itemID,
                            itemLink = matched.itemLink,
                            slot = resolvedSlot,
                        }
                    end
                end

                if #orderedPlayerDrops > 0 then
                    LootDebugPrint(string.format("%s: source=runtime-player-ordered, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #orderedPlayerDrops))
                    return orderedPlayerDrops, true, false, "runtime-player-ordered"
                end
            end
        end

        local enrichedStaticDrops = EnrichStaticLootWithEncounterJournalLinks(lootConfig, trackID, lootScope)
        if enrichedStaticDrops and #enrichedStaticDrops > 0 then
            if lootScope == "ALL" and CountLinkedEntries(enrichedStaticDrops) < #enrichedStaticDrops then
                local runtimeDropsForBackfill = GetEncounterJournalLoot(lootConfig, trackID, lootScope)
                if runtimeDropsForBackfill and #runtimeDropsForBackfill > 0 then
                    enrichedStaticDrops = MergeLootEntriesPreferLinks(enrichedStaticDrops, runtimeDropsForBackfill)
                end
            end

            LootDebugPrint(string.format("%s: source=static+ejlink, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #enrichedStaticDrops))
            return enrichedStaticDrops, true, lootConfig.sample == true, "static+ejlink"
        end

        if lootScope == "PLAYER" then
            local runtimePlayerDrops = GetEncounterJournalLoot(lootConfig, trackID, lootScope)
            if runtimePlayerDrops and #runtimePlayerDrops > 0 then
                LootDebugPrint(string.format("%s: source=runtime-player, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #runtimePlayerDrops))
                return runtimePlayerDrops, true, false, "runtime-player"
            end

            LootDebugPrint(string.format("%s: source=player-empty, track=%s", entry.subtitle or entry.name or "unknown", tostring(trackID)))
            return {}, true, false, "player-empty"
        end

        LootDebugPrint(string.format("%s: source=static, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #lootConfig.drops))
        return lootConfig.drops, true, lootConfig.sample == true, "static"
    end

    local runtimeDrops = GetEncounterJournalLoot(lootConfig, trackID, lootScope)
    if runtimeDrops and #runtimeDrops > 0 then
        LootDebugPrint(string.format("%s: source=runtime, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #runtimeDrops))
        return runtimeDrops, true, false, "runtime"
    end

    if lootConfig and type(lootConfig.drops) == "table" and #lootConfig.drops > 0 then
        LootDebugPrint(string.format("%s: source=static-fallback, track=%s, count=%d", entry.subtitle or entry.name or "unknown", tostring(trackID), #lootConfig.drops))
        return lootConfig.drops, true, lootConfig.sample == true, "static"
    end

    LootDebugPrint(string.format("%s: source=preview-fallback, track=%s", entry.subtitle or entry.name or "unknown", tostring(trackID)))
    return BuildFallbackDropsForDungeon(entry), false, true, "fallback"
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
    GameTooltip:AddLine("左键施放传送，右键打开掉落列表", 0.70, 0.88, 1.0)
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
        -- 只把左键绑定为安全施法，右键保留给自定义 UI 交互。
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:SetAttribute("type1", "spell")
        button:SetAttribute("spell1", spellName)
        button:SetAttribute("type2", nil)
        button:SetAttribute("spell2", nil)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:SetAttribute("type1", nil)
        button:SetAttribute("spell1", nil)
        button:SetAttribute("type2", nil)
        button:SetAttribute("spell2", nil)
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
    filterButton:SetSize(88, 20)
    filterButton:SetPoint("TOPLEFT", 16 + ((index - 1) * 96), -88)
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

local function GetItemDisplayName(dropEntry)
    if not dropEntry then
        return "未知物品"
    end

    if dropEntry.itemLink and C_Item and C_Item.GetItemNameByID then
        local linkItemID = ExtractItemIDFromLink(dropEntry.itemLink)
        if linkItemID then
            local linkItemName = C_Item.GetItemNameByID(linkItemID)
            if linkItemName and linkItemName ~= "" then
                return linkItemName
            end
        end
    end

    if not dropEntry.itemID then
        return "未知物品"
    end

    local itemName = nil
    if C_Item and C_Item.GetItemNameByID then
        itemName = C_Item.GetItemNameByID(dropEntry.itemID)
    end

    if itemName and itemName ~= "" then
        return itemName
    end

    return string.format("物品 #%d", dropEntry.itemID)
end

local function SetLootButtonTooltip(button)
    if not button or (not button.itemID and not button.itemLink) then
        return
    end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.itemLink and GameTooltip.SetHyperlink then
        GameTooltip:SetHyperlink(button.itemLink)
    elseif button.itemID then
        if button.lootScope == "ALL" and GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(button.itemID)
        elseif button.lootScope == "ALL" then
            GameTooltip:SetHyperlink("item:" .. tostring(button.itemID))
        else
            -- 本角色筛选下没有真实 itemLink 时，避免展示基础模板（如 ilvl 16）。
            GameTooltip:ClearLines()
            local itemName = button.itemName or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(button.itemID)) or ("物品 #" .. tostring(button.itemID))
            GameTooltip:AddLine(itemName, 1.0, 0.82, 0.20)
            GameTooltip:AddLine("该条目当前没有可用物品链接，无法显示准确装等。", 0.82, 0.82, 0.82, true)
            GameTooltip:AddLine(string.format("ItemID %d", button.itemID), 0.70, 0.70, 0.70)
        end
    end
    GameTooltip:Show()
end

local function ParseItemLinkColor(itemLink)
    if type(itemLink) ~= "string" then
        return nil
    end

    local hex = itemLink:match("|c(%x%x%x%x%x%x%x%x)")
    if not hex or #hex ~= 8 then
        return nil
    end

    local r = tonumber(hex:sub(3, 4), 16)
    local g = tonumber(hex:sub(5, 6), 16)
    local b = tonumber(hex:sub(7, 8), 16)
    if not r or not g or not b then
        return nil
    end

    return r / 255, g / 255, b / 255
end

local function SetLootButtonTextColor(itemButton, dropEntry)
    if not itemButton or not itemButton.text then
        return
    end

    itemButton.text:SetTextColor(LOOT_TEXT_COLOR[1], LOOT_TEXT_COLOR[2], LOOT_TEXT_COLOR[3])
end

local function GetLootButtonDetailText(dropEntry)
    local slotText = ResolveLootSlotText(dropEntry)
    if dropEntry and dropEntry.itemLink and C_Item and C_Item.GetDetailedItemLevelInfo then
        local ok, itemLevel = pcall(C_Item.GetDetailedItemLevelInfo, dropEntry.itemLink)
        if ok and itemLevel and itemLevel > 0 then
            return string.format("%s  ·  物品等级 %d", slotText, math.floor(itemLevel + 0.5))
        end
    end

    return slotText
end

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

    lootFrame.currentEntry = entry
    local dropEntries, hasConfiguredLoot, isSampleData, lootSource = GetLootEntriesForDungeon(entry, "CHAMPION", lootFrame.lootScope)
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
        else
            lootFrame.desc:SetText(string.format("当前筛选：%s可用（%d件）。", scopeLabel, dropCount))
        end
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

    local shouldRetry = false
    if lootSource == "player-loading" then
        shouldRetry = true
    elseif lootSource == "player-empty" and lootFrame.lootScope == "PLAYER" then
        shouldRetry = true
    elseif lootSource == "runtime-player-ordered" and missingLinkCount > 0 then
        shouldRetry = true
    elseif lootSource == "static+ejlink" and missingLinkCount > 0 then
        shouldRetry = true
    end

    if shouldRetry then
        local retryEntries = dropEntries
        if (lootSource == "player-loading" or (lootSource == "player-empty" and lootFrame.lootScope == "PLAYER")) and entry then
            local lootConfig = FindLootConfigForDungeon(entry)
            if lootConfig and type(lootConfig.drops) == "table" then
                retryEntries = lootConfig.drops
            end
        end

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
                itemButton.subText:SetText(GetLootButtonDetailText(dropEntry))
            end
            SetLootButtonTextColor(itemButton, dropEntry)
            itemButton:Show()
        else
            itemButton.itemID = nil
            itemButton.itemName = nil
            itemButton.itemLink = nil
            itemButton.lootScope = nil
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

frame:HookScript("OnHide", function()
    if lootFrame:IsShown() then
        lootFrame:Hide()
    end
end)

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

frame.footerLeft = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.footerLeft:SetPoint("BOTTOMLEFT", 18, 16)
frame.footerLeft:SetWidth(FRAME_WIDTH - 220)
frame.footerLeft:SetJustifyH("LEFT")
frame.footerLeft:SetTextColor(0.72, 0.90, 1.00)
frame.footerLeft:SetText("晦暗虚空核心 : 读取中")

frame.footerRight = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.footerRight:SetPoint("BOTTOMRIGHT", -18, 16)
frame.footerRight:SetJustifyH("RIGHT")
frame.footerRight:SetText("Copyright © Shawnliu1979")

-- 兼容旧代码里可能还在使用 frame.footer 的地方。
frame.footer = frame.footerRight

frame.footerLeft:SetPoint("RIGHT", frame.footerRight, "LEFT", -14, 0)

local function GetRollCurrencyProgressText()
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then
        return "晦暗虚空核心 : ?/?"
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(ROLL_CURRENCY_ID)
    if not info then
        return "晦暗虚空核心 : ?/?"
    end

    local quantity = tonumber(info.quantity) or 0
    local seasonCap = tonumber(info.maxQuantity) or 0

    if seasonCap <= 0 then
        seasonCap = tonumber(info.maxWeeklyQuantity) or 0
    end

    if seasonCap > 0 then
        return string.format("晦暗虚空核心 : %d/%d", quantity, seasonCap)
    end

    return string.format("晦暗虚空核心 : %d/?", quantity)
end

local function RefreshFooterCurrency()
    if not frame.footerLeft then
        return
    end

    frame.footerLeft:SetText(GetRollCurrencyProgressText())
end

RefreshFooterCurrency()

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
    RefreshFooterCurrency()
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
    button:HookScript("OnClick", function(self, mouseButton)
        if not self.dungeon then
            return
        end

        if mouseButton == "RightButton" then
            OpenLootPreview(self.dungeon)
        end
    end)

    if dungeon then
        UpdateButtonState(button, dungeon)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:SetAttribute("type1", nil)
        button:SetAttribute("spell1", nil)
        button:SetAttribute("type2", nil)
        button:SetAttribute("spell2", nil)
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
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
refreshFrame:RegisterEvent("SPELLS_CHANGED")
refreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
refreshFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
refreshFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
refreshFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not deferredSecureRefresh then
        return
    end

    deferredSecureRefresh = false
    RefreshAllButtonStates()
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "CURRENCY_DISPLAY_UPDATE" then
        RefreshFooterCurrency()
    end
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