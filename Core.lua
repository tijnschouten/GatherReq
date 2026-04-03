local addonName, PST = ...

PST = PST or _G[addonName] or {}
_G[addonName] = PST

local Data = PST.Data or {}
local professions = Data.Professions or {}
local trainingRanks = Data.TrainingRanks or {}

local TOOLTIP_LINE_WITH_SKILL = "Requires %s %d (You: %s)"
local TRAINING_LINE_PREFIX = "Training: "
local COLOR_RED = { 0.95, 0.10, 0.10 }
local COLOR_ORANGE = { 1.00, 0.50, 0.00 }
local COLOR_YELLOW = { 1.00, 0.82, 0.00 }
local COLOR_GREEN = { 0.10, 0.85, 0.10 }
local COLOR_GRAY = { 0.55, 0.55, 0.55 }
local COLOR_NEUTRAL = { 0.85, 0.82, 0.72 }
local UPDATE_INTERVAL = 0.10

local function GetTooltipTitle(tooltip)
    local tooltipName = tooltip and tooltip:GetName()
    if not tooltipName then
        return nil
    end

    local titleLine = _G[tooltipName .. "TextLeft1"]
    if not titleLine then
        return nil
    end

    local text = titleLine:GetText()
    if not text or text == "" then
        return nil
    end

    return text
end

local function GetSkillInfo(skillName)
    if not skillName then
        return nil, nil
    end

    local numSkills = GetNumSkillLines()
    for index = 1, numSkills do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(index)
        if not isHeader and name == skillName then
            return rank, maxRank
        end
    end

    return nil, nil
end

local function GetLineColor(currentSkill, requiredSkill)
    if type(currentSkill) ~= "number" then
        return COLOR_NEUTRAL[1], COLOR_NEUTRAL[2], COLOR_NEUTRAL[3]
    end

    if currentSkill < requiredSkill then
        return COLOR_RED[1], COLOR_RED[2], COLOR_RED[3]
    end

    if currentSkill < requiredSkill + 25 then
        return COLOR_ORANGE[1], COLOR_ORANGE[2], COLOR_ORANGE[3]
    end

    if currentSkill < requiredSkill + 50 then
        return COLOR_YELLOW[1], COLOR_YELLOW[2], COLOR_YELLOW[3]
    end

    if currentSkill < requiredSkill + 100 then
        return COLOR_GREEN[1], COLOR_GREEN[2], COLOR_GREEN[3]
    end

    return COLOR_GRAY[1], COLOR_GRAY[2], COLOR_GRAY[3]
end

local function GetRequirementText(professionName, requiredSkill, currentSkill)
    if type(currentSkill) == "number" then
        return string.format(TOOLTIP_LINE_WITH_SKILL, professionName, requiredSkill, tostring(currentSkill))
    end

    return string.format("Requires %s %d", professionName, requiredSkill)
end

local function GetRequirementPrefix(professionName, requiredSkill)
    return string.format("Requires %s %d", professionName, requiredSkill)
end

local function TooltipContainsText(tooltip, expectedText)
    if not tooltip or not expectedText then
        return false
    end

    local tooltipName = tooltip:GetName()
    if not tooltipName then
        return false
    end

    for lineIndex = 2, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. lineIndex]
        if line and line:GetText() == expectedText then
            return true
        end
    end

    return false
end

local function FindTooltipLineByText(tooltip, expectedText)
    if not tooltip or not expectedText then
        return nil
    end

    local tooltipName = tooltip:GetName()
    if not tooltipName then
        return nil
    end

    for lineIndex = 2, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. lineIndex]
        if line and line:GetText() == expectedText then
            return line
        end
    end

    return nil
end

local function FindTooltipLineByPrefix(tooltip, prefix)
    if not tooltip or not prefix then
        return nil
    end

    local tooltipName = tooltip:GetName()
    if not tooltipName then
        return nil
    end

    for lineIndex = 2, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. lineIndex]
        local text = line and line:GetText()
        if text and string.sub(text, 1, string.len(prefix)) == prefix then
            return line
        end
    end

    return nil
end

local function GetSkinningRequirement(tooltip, unit)
    if not unit or not UnitExists(unit) or not UnitIsDead(unit) then
        return nil
    end

    local skinnableText = _G.UNIT_SKINNABLE or "Skinnable"
    if not TooltipContainsText(tooltip, skinnableText) then
        return nil
    end

    local level = UnitLevel(unit)
    if type(level) ~= "number" or level < 1 or level == -1 then
        return nil
    end

    if level <= 10 then
        return 1
    end

    if level <= 20 then
        return (level * 10) - 100
    end

    return level * 5
end

local function GetTooltipMatch(tooltip)
    local title = GetTooltipTitle(tooltip)
    if not title then
        return nil
    end

    local itemName = tooltip:GetItem()
    if itemName and Data.Lockboxes and Data.Lockboxes[itemName] then
        return professions.Lockpicking, Data.Lockboxes[itemName], itemName
    end

    local _, unit = tooltip:GetUnit()
    local skinningSkill = GetSkinningRequirement(tooltip, unit)
    if skinningSkill then
        return professions.Skinning, skinningSkill, title
    end

    if Data.MiningNodes and Data.MiningNodes[title] then
        return professions.Mining, Data.MiningNodes[title], title
    end

    if Data.HerbNodes and Data.HerbNodes[title] then
        return professions.Herbalism, Data.HerbNodes[title], title
    end

    if Data.LockedObjects and Data.LockedObjects[title] then
        return professions.Lockpicking, Data.LockedObjects[title], title
    end

    return nil
end

local function GetTrainingHint(professionName, currentSkill, currentMaxSkill)
    local professionTraining = trainingRanks[professionName]
    if not professionTraining or type(currentSkill) ~= "number" or type(currentMaxSkill) ~= "number" then
        return nil
    end

    if currentMaxSkill >= 375 or currentSkill < (currentMaxSkill - 25) then
        return nil
    end

    local nextRank = professionTraining[currentMaxSkill]
    if not nextRank then
        return nil
    end

    local playerLevel = UnitLevel("player")
    if type(playerLevel) ~= "number" or playerLevel < 1 then
        return nil
    end

    if playerLevel >= nextRank.level then
        return TRAINING_LINE_PREFIX .. string.format("%s available now", nextRank.rank), COLOR_GREEN
    end

    return TRAINING_LINE_PREFIX .. string.format("%s at level %d (You: %d)", nextRank.rank, nextRank.level, playerLevel), COLOR_ORANGE
end

local function SetTooltipLine(line, text, red, green, blue)
    if not line then
        return
    end

    line:SetText(text)
    line:SetTextColor(red, green, blue)
end

function PST:ProcessTooltip(tooltip)
    if not tooltip or tooltip ~= GameTooltip then
        return
    end

    if tooltip.__PSTAddingLine then
        return
    end

    local professionName, requiredSkill, matchKey = GetTooltipMatch(tooltip)
    if not professionName or not requiredSkill or not matchKey then
        return
    end

    local currentSkill, currentMaxSkill = GetSkillInfo(professionName)
    local requirementText = GetRequirementText(professionName, requiredSkill, currentSkill)
    local requirementPrefix = GetRequirementPrefix(professionName, requiredSkill)
    local red, green, blue = GetLineColor(currentSkill, requiredSkill)
    local existingRequirementLine = FindTooltipLineByPrefix(tooltip, requirementPrefix)
    local existingProfessionLine = FindTooltipLineByText(tooltip, professionName)
    local trainingText, trainingColor = GetTrainingHint(professionName, currentSkill, currentMaxSkill)
    local existingTrainingLine = FindTooltipLineByPrefix(tooltip, TRAINING_LINE_PREFIX)

    tooltip.__PSTAddingLine = true
    if existingRequirementLine then
        SetTooltipLine(existingRequirementLine, requirementText, red, green, blue)
    elseif existingProfessionLine then
        SetTooltipLine(existingProfessionLine, requirementText, red, green, blue)
    else
        tooltip:AddLine(requirementText, red, green, blue)
    end

    if trainingText and trainingColor then
        if existingTrainingLine then
            SetTooltipLine(existingTrainingLine, trainingText, trainingColor[1], trainingColor[2], trainingColor[3])
        else
            tooltip:AddLine(trainingText, trainingColor[1], trainingColor[2], trainingColor[3])
        end
    end

    tooltip:Show()
    tooltip.__PSTAddingLine = nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= addonName then
        return
    end

    frame:UnregisterEvent("ADDON_LOADED")

    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        PST:ProcessTooltip(tooltip)
    end)

    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        PST:ProcessTooltip(tooltip)
    end)

    GameTooltip:HookScript("OnShow", function(tooltip)
        PST:ProcessTooltip(tooltip)
    end)

    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip.__PSTAddingLine = nil
    end)
end)

frame:SetScript("OnUpdate", function(_, elapsed)
    frame.__PSTElapsed = (frame.__PSTElapsed or 0) + elapsed
    if frame.__PSTElapsed < UPDATE_INTERVAL then
        return
    end

    frame.__PSTElapsed = 0

    if GameTooltip and GameTooltip:IsShown() then
        PST:ProcessTooltip(GameTooltip)
    end
end)
