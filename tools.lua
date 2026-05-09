local addonName = ...

local function EnsureEncounterJournalLoadedForTools()
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

local function DumpCurrentEncounterJournalIDs()
    if not EnsureEncounterJournalLoadedForTools() then
        print(string.format("[%s] 无法加载冒险指南。", addonName or "Doors"))
        return
    end

    local getCurrentInstance = _G["EJ_GetCurrentInstance"]
    local getInstanceInfo = _G["EJ_GetInstanceInfo"]
    local getEncounterInfoByIndex = _G["EJ_GetEncounterInfoByIndex"]
    if not getEncounterInfoByIndex then
        print(string.format("[%s] 当前客户端没有可用的 EJ_GetEncounterInfoByIndex。", addonName or "Doors"))
        return
    end

    local instanceID = (getCurrentInstance and getCurrentInstance()) or (EncounterJournal and EncounterJournal.instanceID)
    if not instanceID then
        print(string.format("[%s] 请先打开冒险指南，并切到目标副本页面后再执行此命令。", addonName or "Doors"))
        return
    end

    local instanceName = (getInstanceInfo and select(1, getInstanceInfo(instanceID))) or ("Instance #" .. tostring(instanceID))
    local encounterIDs = {}

    print(string.format("[%s] 当前副本: %s", addonName or "Doors", tostring(instanceName)))
    print(string.format("[%s] journalInstanceID = %d", addonName or "Doors", instanceID))

    for index = 1, 40 do
        local encounterName, _, encounterID = getEncounterInfoByIndex(index, instanceID)
        if not encounterName then
            break
        end

        if encounterID then
            encounterIDs[#encounterIDs + 1] = encounterID
            print(string.format("[%s] boss %d: %s -> %d", addonName or "Doors", index, tostring(encounterName), encounterID))
        end
    end

    if #encounterIDs == 0 then
        print(string.format("[%s] 未读取到 encounterID，请确认当前页面已选中具体副本。", addonName or "Doors"))
        return
    end

    print(string.format("[%s] journalEncounterIDs = { %s }", addonName or "Doors", table.concat(encounterIDs, ", ")))
end

SLASH_DOORSJOURNAL1 = "/doorsjournal"
SLASH_DOORSJOURNAL2 = "/doorsej"
SlashCmdList["DOORSJOURNAL"] = function()
    DumpCurrentEncounterJournalIDs()
end
