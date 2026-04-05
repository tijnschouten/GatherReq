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
local REFERENCE_FRAME_WIDTH = 440
local REFERENCE_FRAME_HEIGHT = 480
local REFERENCE_BODY_WIDTH = 372
local REFERENCE_BODY_HEIGHT = 284
local TAB_BUTTON_WIDTH = 92
local TAB_BUTTON_HEIGHT = 22
local REFERENCE_ROW_HEIGHT = 20
local REFERENCE_ICON_SIZE = 18
local REFERENCE_MAX_ROWS = 40
local REFERENCE_NAME_WIDTH = 270
local REFERENCE_SKILL_WIDTH = 56
local GENERIC_LOCKBOX_ICON = "Interface\\Icons\\INV_Misc_Bag_10_Black"
local GENERIC_DOOR_ICON = "Interface\\Icons\\INV_Misc_Key_12"
local CHAT_PREFIX = "|cffd9d1b8GatherReq:|r "

local referenceCategories = {
    {
        key = "mining",
        label = "Mining",
        profession = professions.Mining,
        data = Data.MiningNodes,
    },
    {
        key = "herbalism",
        label = "Herbs",
        profession = professions.Herbalism,
        data = Data.HerbNodes,
    },
    {
        key = "lockpicking",
        label = "Locks",
        profession = professions.Lockpicking,
        data = Data.Lockboxes,
    },
    {
        key = "skinning",
        label = "Skinning",
        profession = professions.Skinning,
    },
}

local trackedProfessionOrder = {
    professions.Herbalism,
    professions.Mining,
    professions.Skinning,
    professions.Lockpicking,
}

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
        return COLOR_RED[1], COLOR_RED[2], COLOR_RED[3]
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

local function GetDefaultProfessionPrefix(professionName)
    return string.format("Requires %s", professionName)
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

    if Data.LockpickableDoors and Data.LockpickableDoors[title] then
        return professions.Lockpicking, Data.LockpickableDoors[title].skill, title
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
        return TRAINING_LINE_PREFIX .. string.format("%s available now", nextRank.rank), COLOR_YELLOW
    end

    return TRAINING_LINE_PREFIX .. string.format("%s at level %d (You: %d)", nextRank.rank, nextRank.level, playerLevel), COLOR_ORANGE
end

local function GetNextTrainingRank(professionName, currentSkill, currentMaxSkill)
    local professionTraining = trainingRanks[professionName]
    if not professionTraining or type(currentSkill) ~= "number" or type(currentMaxSkill) ~= "number" then
        return nil
    end

    if currentMaxSkill >= 375 then
        return nil
    end

    local nextRank = professionTraining[currentMaxSkill]
    if not nextRank then
        return nil
    end

    return nextRank
end

local function GetTrainingStatus(professionName, currentSkill, currentMaxSkill)
    local professionTraining = trainingRanks[professionName]
    if not professionTraining or type(currentSkill) ~= "number" or type(currentMaxSkill) ~= "number" then
        return nil, nil
    end

    if currentMaxSkill >= 375 then
        return "At max profession rank", COLOR_GREEN
    end

    local nextRank = professionTraining[currentMaxSkill]
    if not nextRank then
        return nil, nil
    end

    local playerLevel = UnitLevel("player")
    if type(playerLevel) ~= "number" or playerLevel < 1 then
        return nil, nil
    end

    if currentSkill < nextRank.skill then
        return string.format(
            "Next rank: %s at %d skill and level %d",
            nextRank.rank,
            nextRank.skill,
            nextRank.level
        ), COLOR_NEUTRAL
    end

    if playerLevel >= nextRank.level then
        return string.format("Next rank: %s available now", nextRank.rank), COLOR_YELLOW
    end

    return string.format("Next rank: %s at level %d (You: %d)", nextRank.rank, nextRank.level, playerLevel), COLOR_ORANGE
end

local function RGBToHex(color)
    if not color then
        return "d9d1b8"
    end

    return string.format(
        "%02x%02x%02x",
        math.floor((color[1] or 0) * 255 + 0.5),
        math.floor((color[2] or 0) * 255 + 0.5),
        math.floor((color[3] or 0) * 255 + 0.5)
    )
end

local function Colorize(text, color)
    return string.format("|cff%s%s|r", RGBToHex(color), text)
end

local function BuildSortedEntries(data)
    local entries = {}
    if not data then
        return entries
    end

    for name, value in pairs(data) do
        if type(value) == "table" then
            table.insert(entries, {
                name = name,
                skill = value.skill,
                location = value.location,
            })
        else
            table.insert(entries, { name = name, skill = value })
        end
    end

    table.sort(entries, function(left, right)
        if left.skill == right.skill then
            return left.name < right.name
        end

        return left.skill < right.skill
    end)

    return entries
end

local function BuildUnlockEntries(professionName)
    local entries = {}

    if professionName == professions.Herbalism then
        for _, entry in ipairs(BuildSortedEntries(Data.HerbNodes)) do
            table.insert(entries, {
                name = entry.name,
                skill = entry.skill,
            })
        end
    elseif professionName == professions.Mining then
        for _, entry in ipairs(BuildSortedEntries(Data.MiningNodes)) do
            table.insert(entries, {
                name = entry.name,
                skill = entry.skill,
            })
        end
    elseif professionName == professions.Lockpicking then
        for _, entry in ipairs(BuildSortedEntries(Data.Lockboxes)) do
            table.insert(entries, {
                name = entry.name,
                skill = entry.skill,
            })
        end

        for _, entry in ipairs(BuildSortedEntries(Data.LockedObjects)) do
            table.insert(entries, {
                name = entry.name,
                skill = entry.skill,
            })
        end

        for _, entry in ipairs(BuildSortedEntries(Data.LockpickableDoors)) do
            table.insert(entries, {
                name = string.format("%s (%s)", entry.name, entry.location),
                skill = entry.skill,
            })
        end

        table.sort(entries, function(left, right)
            if left.skill == right.skill then
                return left.name < right.name
            end

            return left.skill < right.skill
        end)
    end

    return entries
end

local function GetUnlockedEntries(professionName, oldSkill, newSkill)
    local unlocked = {}
    if type(oldSkill) ~= "number" or type(newSkill) ~= "number" or newSkill <= oldSkill then
        return unlocked
    end

    for _, entry in ipairs(BuildUnlockEntries(professionName)) do
        if entry.skill > oldSkill and entry.skill <= newSkill then
            table.insert(unlocked, entry)
        end
    end

    return unlocked
end

local function JoinEntryNames(entries, limit)
    local names = {}
    local total = #entries
    local maxEntries = math.min(total, limit or total)

    for index = 1, maxEntries do
        table.insert(names, entries[index].name)
    end

    local text = table.concat(names, ", ")
    if total > maxEntries then
        text = string.format("%s, +%d more", text, total - maxEntries)
    end

    return text
end

local function Notify(message)
    if not message or message == "" then
        return
    end

    if RaidWarningFrame and RaidNotice_AddMessage and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
        RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
    end

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. message)
    end
end

local function IsTrainingReady(professionName, currentSkill, currentMaxSkill, playerLevel)
    local nextTraining = GetNextTrainingRank(professionName, currentSkill, currentMaxSkill)
    if not nextTraining then
        return false, nil
    end

    if type(currentSkill) ~= "number" or type(playerLevel) ~= "number" then
        return false, nextTraining
    end

    return currentSkill >= nextTraining.skill and playerLevel >= nextTraining.level, nextTraining
end

function PST:RefreshTrackedSkills(silent)
    self.trackedSkills = self.trackedSkills or {}
    local playerLevel = UnitLevel("player")

    for _, professionName in ipairs(trackedProfessionOrder) do
        local currentSkill, currentMaxSkill = GetSkillInfo(professionName)
        local previous = self.trackedSkills[professionName]
        local trainingReady, nextTraining = IsTrainingReady(professionName, currentSkill, currentMaxSkill, playerLevel)

        if previous and not silent then
            if type(previous.skill) == "number" and type(currentSkill) == "number" and currentSkill > previous.skill then
                local unlockedEntries = GetUnlockedEntries(professionName, previous.skill, currentSkill)
                if #unlockedEntries > 0 then
                    Notify(string.format(
                        "%s %d: unlocked %s",
                        professionName,
                        currentSkill,
                        JoinEntryNames(unlockedEntries, 3)
                    ))
                end
            end

            if not previous.trainingReady and trainingReady and nextTraining then
                Notify(string.format("%s: %s training available", professionName, nextTraining.rank))
            end
        end

        self.trackedSkills[professionName] = {
            skill = currentSkill,
            maxSkill = currentMaxSkill,
            trainingReady = trainingReady,
        }
    end
end

local function GetItemData(itemToken)
    if not itemToken then
        return nil, nil, nil
    end

    local itemName, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(itemToken)
    if not texture and type(itemToken) == "number" then
        texture = GetItemIcon(itemToken)
    end

    if not itemLink and type(itemToken) == "number" then
        itemLink = "item:" .. itemToken
    end

    return itemName, itemLink, texture
end

local function BuildReferenceRows(category)
    local rows = {}
    local currentSkill, currentMaxSkill = GetSkillInfo(category.profession)

    if category.key == "skinning" then
        table.insert(rows, { kind = "text", text = "Skinning requirements follow mob level:" })
        table.insert(rows, { kind = "text", text = "Level 1-10: 1 skill" })
        table.insert(rows, { kind = "text", text = "Level 11-20: (level x 10) - 100" })
        table.insert(rows, { kind = "text", text = "Level 21-73: level x 5" })
        table.insert(rows, { kind = "header", text = "Examples" })

        local examples = {
            { label = "Level 11", skill = 10 },
            { label = "Level 20", skill = 100 },
            { label = "Level 30", skill = 150 },
            { label = "Level 40", skill = 200 },
            { label = "Level 50", skill = 250 },
            { label = "Level 60", skill = 300 },
            { label = "Level 70", skill = 350 },
            { label = "Level 73", skill = 365 },
        }

        for _, example in ipairs(examples) do
            local red, green, blue = GetLineColor(currentSkill, example.skill)
            table.insert(rows, {
                kind = "entry",
                label = example.label,
                skill = example.skill,
                color = { red, green, blue },
            })
        end

        return rows
    end

    if category.key == "lockpicking" then
        table.insert(rows, { kind = "header", text = "Lockboxes" })
        for _, entry in ipairs(BuildSortedEntries(Data.Lockboxes)) do
            local red, green, blue = GetLineColor(currentSkill, entry.skill)
            table.insert(rows, {
                kind = "entry",
                label = entry.name,
                skill = entry.skill,
                color = { red, green, blue },
                itemToken = Data.LockboxReferenceItems and Data.LockboxReferenceItems[entry.name] or nil,
                iconTexture = GENERIC_LOCKBOX_ICON,
                tooltipText = string.format("%s\nRequires Lockpicking %d", entry.name, entry.skill),
            })
        end

        table.insert(rows, { kind = "header", text = "Locked objects" })
        for _, entry in ipairs(BuildSortedEntries(Data.LockedObjects)) do
            local red, green, blue = GetLineColor(currentSkill, entry.skill)
            table.insert(rows, {
                kind = "entry",
                label = entry.name,
                skill = entry.skill,
                color = { red, green, blue },
                iconTexture = GENERIC_LOCKBOX_ICON,
                tooltipText = string.format("%s\nRequires Lockpicking %d", entry.name, entry.skill),
            })
        end

        table.insert(rows, { kind = "header", text = "Doors / gates" })
        for _, entry in ipairs(BuildSortedEntries(Data.LockpickableDoors)) do
            local red, green, blue = GetLineColor(currentSkill, entry.skill)
            table.insert(rows, {
                kind = "entry",
                label = entry.name,
                skill = entry.skill,
                color = { red, green, blue },
                iconTexture = GENERIC_DOOR_ICON,
                tooltipText = string.format("%s\nRequires Lockpicking %d\nLocation: %s", entry.name, entry.skill, entry.location),
            })
        end

        return rows
    end

    for _, entry in ipairs(BuildSortedEntries(category.data)) do
        local red, green, blue = GetLineColor(currentSkill, entry.skill)
        local itemToken = entry.name
        if category.key == "mining" then
            itemToken = Data.MiningReferenceItems and Data.MiningReferenceItems[entry.name] or nil
        elseif category.key == "herbalism" then
            itemToken = Data.HerbReferenceItems and Data.HerbReferenceItems[entry.name] or nil
        end

        table.insert(rows, {
            kind = "entry",
            label = entry.name,
            skill = entry.skill,
            color = { red, green, blue },
            itemToken = itemToken,
        })
    end

    return rows
end

local function GetReferenceCategory(key)
    if not key or key == "" then
        return referenceCategories[1]
    end

    key = string.lower(key)
    for _, category in ipairs(referenceCategories) do
        if category.key == key or string.lower(category.label) == key or string.lower(category.profession) == key then
            return category
        end
    end

    if key == "herbs" or key == "herb" then
        return referenceCategories[2]
    end

    if key == "locks" or key == "lock" then
        return referenceCategories[3]
    end

    return referenceCategories[1]
end

local function UpdateReferenceFrame(frame, category)
    if not frame or not category then
        return
    end

    local currentSkill, currentMaxSkill = GetSkillInfo(category.profession)
    local currentSkillText = type(currentSkill) == "number" and tostring(currentSkill) or "unlearned"
    local currentMaxText = type(currentMaxSkill) == "number" and tostring(currentMaxSkill) or "-"
    local trainingStatus, trainingColor = GetTrainingStatus(category.profession, currentSkill, currentMaxSkill)
    local rows = BuildReferenceRows(category)
    local totalHeight = 0

    frame.selectedCategory = category
    frame.title:SetText(string.format("GatherReq - %s", category.label))
    frame.summarySkill:SetText(string.format("Current skill: %s/%s", currentSkillText, currentMaxText))
    if trainingStatus then
        frame.summaryTraining:SetText(trainingStatus)
        frame.summaryTraining:SetTextColor(trainingColor[1], trainingColor[2], trainingColor[3])
        frame.summaryTraining:Show()
    else
        frame.summaryTraining:Hide()
    end

    frame.columnName:SetText("Name")
    frame.columnSkill:SetText("Skill")

    for index = 1, REFERENCE_MAX_ROWS do
        local row = frame.rows[index]
        local rowData = rows[index]
        if rowData then
            row:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 0, -totalHeight)
            row:SetPoint("TOPRIGHT", frame.body, "TOPRIGHT", 0, -totalHeight)
            row:Show()
            row.itemLink = nil
            row.itemToken = nil

            if rowData.kind == "header" then
                row.iconButton:Hide()
                row.nameText:ClearAllPoints()
                row.nameText:SetPoint("LEFT", row, "LEFT", 0, 0)
                row.nameText:SetWidth(REFERENCE_NAME_WIDTH + REFERENCE_SKILL_WIDTH + 26)
                row.nameText:SetText(rowData.text)
                row.nameText:SetTextColor(1.0, 0.82, 0.0)
                row.skillText:SetText("")
                row.descriptionText:SetText("")
            elseif rowData.kind == "text" then
                row.iconButton:Hide()
                row.nameText:ClearAllPoints()
                row.nameText:SetPoint("LEFT", row, "LEFT", 0, 0)
                row.nameText:SetWidth(REFERENCE_NAME_WIDTH + REFERENCE_SKILL_WIDTH + 26)
                row.nameText:SetText(rowData.text)
                row.nameText:SetTextColor(COLOR_NEUTRAL[1], COLOR_NEUTRAL[2], COLOR_NEUTRAL[3])
                row.skillText:SetText("")
                row.descriptionText:SetText("")
            else
                local _, itemLink, itemTexture = GetItemData(rowData.itemToken)
                row.iconButton:Show()
                row.iconButton.texture:SetTexture(itemTexture or rowData.iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.itemLink = itemLink
                row.itemToken = rowData.itemToken
                row.tooltipText = rowData.tooltipText
                row.nameText:ClearAllPoints()
                row.nameText:SetPoint("LEFT", row.iconButton, "RIGHT", 8, 0)
                row.nameText:SetWidth(REFERENCE_NAME_WIDTH)
                row.nameText:SetText(rowData.label)
                row.nameText:SetTextColor(rowData.color[1], rowData.color[2], rowData.color[3])
                row.skillText:SetText(tostring(rowData.skill))
                row.skillText:SetTextColor(rowData.color[1], rowData.color[2], rowData.color[3])
                row.descriptionText:SetText("")
            end

            totalHeight = totalHeight + REFERENCE_ROW_HEIGHT
        else
            row:Hide()
        end
    end

    frame.body:SetHeight(math.max(totalHeight + 4, REFERENCE_BODY_HEIGHT))
    frame.scrollFrame:SetVerticalScroll(0)

    for _, button in ipairs(frame.categoryButtons) do
        if button.category.key == category.key then
            button:Disable()
        else
            button:Enable()
        end
    end
end

local function CreateReferenceFrame()
    if PST.referenceFrame then
        return PST.referenceFrame
    end

    local frame = CreateFrame("Frame", "GatherReqReferenceFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetWidth(REFERENCE_FRAME_WIDTH)
    frame:SetHeight(REFERENCE_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    frame:Hide()

    frame.TitleText:SetText("GatherReq")
    frame.title = frame.TitleText

    if UISpecialFrames then
        local frameName = frame:GetName()
        local alreadyRegistered = false
        for _, specialFrameName in ipairs(UISpecialFrames) do
            if specialFrameName == frameName then
                alreadyRegistered = true
                break
            end
        end

        if not alreadyRegistered then
            table.insert(UISpecialFrames, frameName)
        end
    end

    frame.categoryButtons = {}
    for index, category in ipairs(referenceCategories) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetWidth(TAB_BUTTON_WIDTH)
        button:SetHeight(TAB_BUTTON_HEIGHT)
        button:SetText(category.label)
        button.category = category
        if index == 1 then
            button:SetPoint("TOPLEFT", 18, -48)
        else
            button:SetPoint("LEFT", frame.categoryButtons[index - 1], "RIGHT", 6, 0)
        end
        button:SetScript("OnClick", function(self)
            UpdateReferenceFrame(frame, self.category)
        end)
        table.insert(frame.categoryButtons, button)
    end

    local scrollFrame = CreateFrame("ScrollFrame", "GatherReqReferenceScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 22, -128)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 18)
    frame.scrollFrame = scrollFrame

    local body = CreateFrame("Frame", nil, scrollFrame)
    body:SetWidth(REFERENCE_BODY_WIDTH)
    body:SetHeight(REFERENCE_BODY_HEIGHT)
    scrollFrame:SetScrollChild(body)
    frame.body = body

    local summarySkill = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summarySkill:SetPoint("TOPLEFT", 24, -82)
    summarySkill:SetJustifyH("LEFT")
    frame.summarySkill = summarySkill

    local summaryTraining = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summaryTraining:SetPoint("TOPLEFT", summarySkill, "BOTTOMLEFT", 0, -4)
    summaryTraining:SetJustifyH("LEFT")
    frame.summaryTraining = summaryTraining

    local columnName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    columnName:SetPoint("TOPLEFT", 26, -112)
    columnName:SetJustifyH("LEFT")
    frame.columnName = columnName

    local columnSkill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    columnSkill:SetPoint("TOPRIGHT", -42, -112)
    columnSkill:SetWidth(REFERENCE_SKILL_WIDTH)
    columnSkill:SetJustifyH("RIGHT")
    frame.columnSkill = columnSkill

    frame.rows = {}
    for index = 1, REFERENCE_MAX_ROWS do
        local row = CreateFrame("Frame", nil, body)
        row:SetHeight(REFERENCE_ROW_HEIGHT)
        row:SetWidth(REFERENCE_BODY_WIDTH)

        local iconButton = CreateFrame("Button", nil, row)
        iconButton:SetWidth(REFERENCE_ICON_SIZE)
        iconButton:SetHeight(REFERENCE_ICON_SIZE)
        iconButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        local texture = iconButton:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(iconButton)
        iconButton.texture = texture
        iconButton:SetScript("OnEnter", function(self)
            local parent = self:GetParent()
            if parent.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(parent.itemLink)
                GameTooltip:Show()
            elseif parent.tooltipText then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(parent.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        iconButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row.iconButton = iconButton

        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", iconButton, "RIGHT", 8, 0)
        nameText:SetWidth(REFERENCE_NAME_WIDTH)
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        local skillText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        skillText:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        skillText:SetWidth(REFERENCE_SKILL_WIDTH)
        skillText:SetJustifyH("RIGHT")
        row.skillText = skillText

        local descriptionText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        descriptionText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1)
        descriptionText:SetWidth(REFERENCE_NAME_WIDTH)
        descriptionText:SetJustifyH("LEFT")
        row.descriptionText = descriptionText

        row:Hide()
        frame.rows[index] = row
    end

    PST.referenceFrame = frame
    UpdateReferenceFrame(frame, referenceCategories[1])
    return frame
end

function PST:ToggleReferenceFrame(categoryKey)
    local frame = CreateReferenceFrame()
    local category = GetReferenceCategory(categoryKey)
    local trimmedCategory = categoryKey and string.gsub(categoryKey, "%s+", "") or ""
    local explicitCategory = trimmedCategory ~= ""
    local wasShown = frame:IsShown()
    local previousCategoryKey = frame.selectedCategory and frame.selectedCategory.key or nil
    UpdateReferenceFrame(frame, category)

    if wasShown and not explicitCategory and previousCategoryKey == category.key then
        frame:Hide()
    else
        frame:Show()
    end
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
    local existingDefaultRequirementLine = FindTooltipLineByPrefix(tooltip, GetDefaultProfessionPrefix(professionName))
    local existingSkinnableLine = professionName == professions.Skinning and FindTooltipLineByText(tooltip, _G.UNIT_SKINNABLE or "Skinnable") or nil
    local trainingText, trainingColor = GetTrainingHint(professionName, currentSkill, currentMaxSkill)
    local existingTrainingLine = FindTooltipLineByPrefix(tooltip, TRAINING_LINE_PREFIX)

    tooltip.__PSTAddingLine = true
    if existingRequirementLine then
        SetTooltipLine(existingRequirementLine, requirementText, red, green, blue)
    elseif existingSkinnableLine then
        SetTooltipLine(existingSkinnableLine, requirementText, red, green, blue)
    elseif existingDefaultRequirementLine then
        SetTooltipLine(existingDefaultRequirementLine, requirementText, red, green, blue)
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
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= addonName then
            return
        end

        frame:UnregisterEvent("ADDON_LOADED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_LEVEL_UP")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("SKILL_LINES_CHANGED")

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

        SLASH_GATHERREQ1 = "/gatherreq"
        SLASH_GATHERREQ2 = "/gr"
        SlashCmdList.GATHERREQ = function(message)
            PST:ToggleReferenceFrame(message)
        end

        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        PST:RefreshTrackedSkills(true)
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if PST.referenceFrame and PST.referenceFrame:IsShown() then
            PST.referenceFrame:Hide()
        end
        return
    end

    if event == "PLAYER_LEVEL_UP" or event == "SKILL_LINES_CHANGED" then
        PST:RefreshTrackedSkills(false)
        return
    end
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
