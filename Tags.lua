
--[[
    Tags is a simple addon that allows you to 'tag' items so you can manage your inventory.

    An item can have multiple tags and each tag will show in tooltips.

    You can use alt + Right Click to open the Tags menu on bag items, character inventory slots, chat item links
]]

local addonName, Tags = ...;


--Simple help message that can be printed to show slash commands
local infoMessages = {
    enUS = {

        cmdNewTag =      string.format("/tags newtag     name    %s", BLUE_FONT_COLOR:WrapTextInColorCode("Creates a new Tag")),
        cmdDeleteTag =   string.format("/tags deletetag  name    %s", BLUE_FONT_COLOR:WrapTextInColorCode("Delete Tag")),

        tagAdded = string.format("[%s] tag added!", addonName),
        tagAddedError = string.format("[%s] error creating tag!", addonName),
        tagDeleted = string.format("[%s] tag deleted!", addonName),
    },

}

--Tags are given a random colour when created, turn those {r,g,b} values into a wow ColorMixin and store here
Tags.TagColours = {}

--API table (for now only has minimal methods)
Tags.Api = {}

---Get TradeSkill IDs for professions that use the item
---@param itemID number the itemID to query
---@return table tradeskillIDs an iterable ipairs table of tradeskill IDs
function Tags.Api:GetTradeskillsForItemID(itemID)

    local tradeskills = {}

    local recipes = self:GetRecipesForItemID(itemID)
    
    for k, recipe in ipairs(recipes) do
        if Tags.Data.SpellIdToTradeskillId[recipe] then
            tradeskills[Tags.Data.SpellIdToTradeskillId[recipe]] = true
        end
    end

    local ret = {}

    for id, _ in pairs(tradeskills) do
        table.insert(ret, id)
    end

    return ret;
end

---Get Recipes Spell IDs for all recipes that use the item
---@param itemID number the itemID to query
---@return table recipes an iterable table of recipes, this data will be the SpellID for the recipe NOT the itemID for the recipe itself
function Tags.Api:GetRecipesForItemID(itemID)

    local recipes = {}

    for recipeSpellID, reagents in pairs(Tags.Data.SpellIdToReagentData) do
        for i = 1, 7 do
            if reagents[i] == itemID then
                table.insert(recipes, recipeSpellID)
            end
        end
    end

    return recipes;
end






--Saved Variables default values
local databaseDefaults = {
    version = 0.0,
    tags = {
        ["Junk"] = {
            colour = {r = 0.5, g = 0.5, b = 0.5},
            icon = 134328,
        },
    },
    items = {},
    autoVendorJunk = false,
}

Tags.Database = {}


function Tags.Database:GetOrSetSavedVariables(forceReset)
    if forceReset == true or (not TAGS_GLOBAL) then
        TAGS_GLOBAL = {}
        for k, v in pairs(databaseDefaults) do
            TAGS_GLOBAL[k] = v;
        end
    end

    self.db = TAGS_GLOBAL;

    if self.db.tags then
        for tag, info in pairs(self.db.tags) do
            Tags.TagColours[tag] = CreateColor(info.colour.r, info.colour.g, info.colour.b)
        end
    end
end

function Tags.Database:NewTag(tag)
    if self.db and type(tag) == "string" then
        if not self.db.tags[tag] then

            local r, g, b = math.random(), math.random(), math.random()

            self.db.tags[tag] = {
                colour = {r = r, g = g, b = b},
                icon = 134328,
            }
            Tags.TagColours[tag] = CreateColor(r, g, b)

            print(infoMessages[GetLocale()].tagAdded)

        else
            print(infoMessages[GetLocale()].tagAddedError)
        end
    end
end

function Tags.Database:DeleteTag(tag)
    if self.db and type(tag) == "string" then
        if self.db.tags[tag] then
            self:RemoveTagFromAllItems(tag)
            self.db.tags[tag] = nil
        end
    end
end

function Tags.Database:GetTagInfo(tag)
    return self.db.tags[tag]
end

function Tags.Database:GetAllTags()
    return self.db.tags or {}
end

function Tags.Database:SetTagForItemID(tag, itemID)
    if self.db and type(tag) == "string" and type(itemID) == "number" then
        if not self.db.items[itemID] then
            self.db.items[itemID] = {}
        end
        table.insert(self.db.items[itemID], tag)
    end
end

function Tags.Database:GetTagsForItemID(itemID)
    if self.db and type(itemID) == "number" then
        return self.db.items[itemID] or {}
    end
end

function Tags.Database:IsTagValidForItemID(tag, itemID)
    local itemTags = self:GetTagsForItemID(itemID)
    for k, v in ipairs(itemTags) do
        if v == tag then
            return true;
        end
    end
    return false;
end

function Tags.Database:RemoveTagsForItemID(tags, itemID)
    if self.db and type(tags) == "table" and type(itemID) == "number" then
        if self.db.items[itemID] then
            local newTags = {}
            for _, currentTag in ipairs(self.db.items[itemID]) do
                local removeTag = false
                for _, tagToRemove in ipairs(tags) do
                    if currentTag == tagToRemove then
                        removeTag = true
                    end
                end
                if removeTag == false then
                    table.insert(newTags, currentTag)
                end
            end
            self.db.items[itemID] = newTags;
        end
    end
end

function Tags.Database:RemoveTagForItemID(tag, itemID)
    if self.db and type(tag) == "string" and type(itemID) == "number" then
        if self.db.items[itemID] then
            local newTags = {}
            for _, currentTag in ipairs(self.db.items[itemID]) do
                if currentTag ~= tag then
                    table.insert(newTags, currentTag)
                end
            end
            self.db.items[itemID] = newTags;
        end
    end
end

function Tags.Database:RemoveTagFromAllItems(tag)
    if self.db then
        for itemID, tags in pairs(self.db.items) do
            self:RemoveTagForItemID(tag, itemID)
        end
    end
end







local function CreateSlashCommands()
    SLASH_TAGS1 = '/tags'
    SlashCmdList['TAGS'] = function(msg)
        if msg == "" then
            local helperMessage = string.format("Tags help\n%s\n%s", infoMessages[GetLocale()].cmdNewTag, infoMessages[GetLocale()].cmdDeleteTag)
            print(helperMessage)

        else
            local cmd, arg1, arg2 = strsplit(" ", msg)

            if cmd == "newtag" and (type(arg1) == "string") then
                local tagInput = string.sub(msg, 8)
                Tags.Database:NewTag(tagInput)

            elseif cmd == "deletetag" and (type(arg1) == "string") then
                local tagInput = string.sub(msg, 11)
                Tags.Database:DeleteTag(tagInput)
            end
        end
    end
end

local function HookGameTooltip()
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local name, link = tooltip:GetItem()
        if link then
            local itemID = C_Item.GetItemInfoInstant(link)
            if itemID then
                local tags = Tags.Database:GetTagsForItemID(itemID)
                if #tags > 0 then
                    tooltip:AddLine(" ")
                    GameTooltip_AddColoredLine(tooltip, addonName, BLUE_FONT_COLOR, true)
                end
                for k, tag in ipairs(tags) do
                    local tagInfo = Tags.Database:GetTagInfo(tag)
                    GameTooltip_AddColoredLine(tooltip, string.format("  %s", tag), Tags.TagColours[tag], true)
                end
                if #tags > 0 then
                    tooltip:AddLine(" ")
                end

                local tradeskills = Tags.Api:GetTradeskillsForItemID(itemID)
                if #tradeskills > 0 then
                    if #tags == 0 then
                        tooltip:AddLine(" ")
                    end
                    GameTooltip_AddColoredLine(tooltip, "Tradeskills Tags", BLUE_FONT_COLOR, true, 0)
                    for _, tradeskillID in ipairs(tradeskills) do
                        --GameTooltip_AddColoredLine(tooltip, string.format("  |cffffffff%s", C_TradeSkillUI.GetTradeSkillDisplayName(tradeskillID)))
                        tooltip:AddLine(string.format("  |cffffffff%s", C_TradeSkillUI.GetTradeSkillDisplayName(tradeskillID)))
                    end
                    tooltip:AddLine(" ")
                end
            end
        end
    end)
end

local function TagsMenuIsSelectedFunc(info)
    return Tags.Database:IsTagValidForItemID(info.tag, info.itemID)
end

local function TagsMenuSetSelectedFunc(info)
    if Tags.Database:IsTagValidForItemID(info.tag, info.itemID) then
        Tags.Database:RemoveTagForItemID(info.tag, info.itemID)
    else
        Tags.Database:SetTagForItemID(info.tag, info.itemID)
    end
end

local function CreateAndShowContextMenu(button, itemLink, itemID)
    local tags = Tags.Database:GetAllTags()
    MenuUtil.CreateContextMenu(button, function(button, rootDescription)
        rootDescription:CreateTitle(addonName)
        rootDescription:CreateTitle(itemLink)
        rootDescription:CreateDivider()
        --rootDescription:CreateSpacer()
        rootDescription:CreateTitle("Tags")
        for tag, tagInfo in pairs(tags) do
            local tagButton = rootDescription:CreateCheckbox(string.format("%s %s|r", CreateSimpleTextureMarkup(tagInfo.icon, 16), Tags.TagColours[tag]:WrapTextInColorCode(tag)), TagsMenuIsSelectedFunc, TagsMenuSetSelectedFunc, {
                itemID = itemID,
                tag = tag,
            })
        end
    end)
end

local function HookItemModifiedClick()
    hooksecurefunc("HandleModifiedItemClick", function(link, location)
        if IsAltKeyDown() then
            local button = GetMouseFoci()
            if type(button) == "table" then
                button = button[1]
            end
            local itemID = C_Item.GetItemInfoInstant(link)
            if button and link and itemID then
                CreateAndShowContextMenu(button, link, itemID)
            end
        end
    end)
end

local function HookContainerFrameItemButton()
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(button, leftRight)

        if IsAltKeyDown() and leftRight == "RightButton" then
            local slot, bag = button:GetID(), button:GetParent():GetID()
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            if itemInfo and itemInfo.itemID then
                CreateAndShowContextMenu(button, itemInfo.hyperlink, itemInfo.itemID)
            end
        end
    end)
end






TagsMixin = {}

function TagsMixin:OnLoad()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function TagsMixin:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:Init()
    end
end

function TagsMixin:Init()

    Tags.Database:GetOrSetSavedVariables()

    HookGameTooltip()
    HookItemModifiedClick()
    HookContainerFrameItemButton()
    CreateSlashCommands()

end