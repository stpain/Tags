
--[[
    Tags is a simple addon that allows you to 'tag' items so you can manage your inventory.

    An item can have multiple tags and each tag will show in tooltips.

    You can use alt + Right Click to open the Tags menu on bag items, character inventory slots, chat item links
]]

local addonName, addon = ...;

Tags = CreateFrame("Frame");

--Simple help message that can be printed to show slash commands
local infoMessages = {
    enUS = {

        cmdNewTag =                 string.format("newtag         [name]        %s", BLUE_FONT_COLOR:WrapTextInColorCode("Creates a new Tag")),
        cmdDeleteTag =              string.format("deletetag      [name]        %s", BLUE_FONT_COLOR:WrapTextInColorCode("Delete Tag")),
        --cmdShowItemInfo =         string.format("showItemInfo    [value]       %s", BLUE_FONT_COLOR:WrapTextInColorCode("Show/Hide item info")),
        cmdListTags =               string.format("listtags      %s", BLUE_FONT_COLOR:WrapTextInColorCode("List tags")),
        cmdAutoJunk =               string.format("autojunk      [true/false]      %s", BLUE_FONT_COLOR:WrapTextInColorCode("Auto vendor junk")),

        tagAdded = string.format("[%s] tag added!", addonName),
        tagAddedError = string.format("[%s] error creating tag!", addonName),
        tagDeleted = string.format("[%s] tag deleted!", addonName),
    },

}

--Tags are given a random colour when created, turn those {r,g,b} values into a wow ColorMixin and store here
Tags.TagColours = {}


--Saved Variables default values
local databaseDefaults = {
    version = 0.0,
    tags = {},
    items = {},
    showItemInfo = true,
    autoVendorJunk = false,
}

Tags.Database = {}


function Tags.Database:Init(forceReset)

    if (TAGS_GLOBAL == nil) then
        TAGS_GLOBAL = {};
    end

    if (forceReset == true) then
        TAGS_GLOBAL = {}
    end

    self.db = TAGS_GLOBAL;

    local version = tonumber(C_AddOns.GetAddOnMetadata(addonName, "Version"))

    self.db.version = version;

    --update the db for any new settings
    if self.db then
        for k, v in pairs(databaseDefaults) do
            if self.db[k] == nil then
                self.db[k] = v;
            end
        end
    end

    --load in the tag colours
    if self.db.tags then
        for tag, info in pairs(self.db.tags) do
            Tags.TagColours[tag] = CreateColor(info.colour.r, info.colour.g, info.colour.b)
        end
    end
end

---@return number float 
local function GetRandomRgbValue()
    return math.random(3,10) / 10;
end

function Tags.Database:NewTag(tag)
    if self.db and type(tag) == "string" then
        if not self.db.tags[tag] then

            local r, g, b = GetRandomRgbValue(), GetRandomRgbValue(), GetRandomRgbValue()

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
            print(infoMessages[GetLocale()].tagDeleted)
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

function Tags.Database:SetConfig(config, val)
    if self.db and (self.db[config] ~= nil) then
        self.db[config] = val;
    end
end

function Tags.Database:GetConfig(config)
    if self.db and (self.db[config] ~= nil) then
        return self.db[config]
    end
end






local SlashCommands = {
    
    newtag = function(msg)
        local tagInput = string.sub(msg, 8)
        Tags.Database:NewTag(tagInput)
    end,

    deletetag = function(msg)
        local tagInput = string.sub(msg, 11)
        Tags.Database:DeleteTag(tagInput)
    end,

    listtags = function()
        local tags = Tags.Database:GetAllTags();
        for tag, _ in pairs(tags) do
            print(tag);
        end
    end,

    showItemInfo = function(msg)
        local input = string.sub(msg, 13)
        if input == "true" then
            Tags.Database:SetConfig("showItemInfo", true)
        elseif input == "false" then
            Tags.Database:SetConfig("showItemInfo", false)
        end
    end,
}


local function CreateSlashCommands()
    SLASH_TAGS1 = '/tags'
    SlashCmdList['TAGS'] = function(msg)
        local locale = GetLocale()
        if msg == "" then
            local helperMessage = string.format("Tags slash commands, all start with /tags\n%s\n%s\n%s", infoMessages[locale].cmdNewTag, infoMessages[locale].cmdDeleteTag, infoMessages[locale].cmdListTags)
            print(helperMessage)

        else
            local cmd = strsplit(" ", msg)
            if SlashCommands[cmd] then
                SlashCommands[cmd](msg)
            end
        end
    end
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

local function TagsMenuIsConfigSelected(config)
    return Tags.Database:GetConfig(config);
end

local function TagsMenuSetConfigSelected(config)
    local currentValue = Tags.Database:GetConfig(config);
    if (currentValue == true) then
        Tags.Database:SetConfig(config, false);
    else
        Tags.Database:SetConfig(config, true);
    end
end

local function CreateAndShowContextMenu(button, itemLink, itemID)
    local tags = Tags.Database:GetAllTags()
    local newTagInput;
    MenuUtil.CreateContextMenu(button, function(button, rootDescription)
        --rootDescription:CreateTitle(addonName);
        rootDescription:CreateTitle(itemLink);
        rootDescription:CreateTitle("Tags");
        for tag, tagInfo in pairs(tags) do
            local tagButton = rootDescription:CreateCheckbox(string.format("%s %s|r", CreateSimpleTextureMarkup(tagInfo.icon, 16), Tags.TagColours[tag]:WrapTextInColorCode(tag)), TagsMenuIsSelectedFunc, TagsMenuSetSelectedFunc, {
                itemID = itemID,
                tag = tag,
            })

            local deleteTagButton = tagButton:CreateButton(DELETE, function()
                Tags.Database:DeleteTag(tag);
            end)
        end
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(OPTIONS);
        local newTagInputbox = rootDescription:CreateTemplate("InputBoxInstructionsTemplate");
        newTagInputbox:AddInitializer(function(frame)
            newTagInput = frame;
            frame.Instructions:SetText(NEW);
            frame.Instructions:SetPoint("TOPLEFT", 6, 0);
            frame:SetSize(120, 24);
            frame:SetPoint("TOPLEFT", 5, 0);
            frame:SetAutoFocus(false);

            frame:HookScript("OnTextChanged", function(self)
                self.Instructions:SetShown(self:GetText() == "");
            end)
        end)
        rootDescription:CreateButton(ADD, function()
            local text = newTagInput:GetText();
            if text == "" then
                return;
            end
            Tags.Database:NewTag(text);
        end)
        rootDescription:CreateCheckbox("Auto Vendor Junk", TagsMenuIsConfigSelected, TagsMenuSetConfigSelected, "autoVendorJunk");
        rootDescription:CreateCheckbox("Show Item Info", TagsMenuIsConfigSelected, TagsMenuSetConfigSelected, "showItemInfo");

    end)
end


local function UpdateTooltip(tooltip)

    if tooltip.GetItem == nil then
        return;
    end

    local name, link = tooltip:GetItem()
    if link then
        local itemID, itemType, itemSubType, equipLoc, icon, itemClassID, itemSubClassID = C_Item.GetItemInfoInstant(link)
        if itemID then
            local tags = Tags.Database:GetTagsForItemID(itemID)
            if (#tags > 0) then
                tooltip:AddLine(" ")
                GameTooltip_AddColoredLine(tooltip, addonName, BLUE_FONT_COLOR, true)
            end
            for k, tag in ipairs(tags) do
                GameTooltip_AddColoredLine(tooltip, string.format("  %s", tag), Tags.TagColours[tag], true)
            end
            if (#tags > 0) then
                tooltip:AddLine(" ")
            end

            local showItemInfo = Tags.Database:GetConfig("showItemInfo")
            if (showItemInfo == true) then
                if (#tags == 0) then
                    tooltip:AddLine(" ")
                    GameTooltip_AddColoredLine(tooltip, "Tags Item Info", BLUE_FONT_COLOR, true)
                end
                --GameTooltip_AddColoredLine(tooltip, itemSubType, BLUE_FONT_COLOR, true, 0)
                tooltip:AddDoubleLine("ItemID", itemID, 1,1,1);
                tooltip:AddDoubleLine("Item Type", itemType, 1,1,1);
                tooltip:AddDoubleLine("Item SubType", itemSubType, 1,1,1);
                tooltip:AddDoubleLine("Icon FileID", icon, 1,1,1);
                tooltip:AddDoubleLine("EquipLocation", _G[equipLoc], 1,1,1);
            end

        end
    end
end



Tags:RegisterEvent("PLAYER_ENTERING_WORLD");
Tags:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW");
Tags:SetScript("OnEvent", function(self, event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then
        local isInitial, isReload = ...;
        if (isInitial or isReload) then
            self:Init();
        end
    end
    if (event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW") then
        local id = ...;
        if (id == 5) and (MerchantSellAllJunkButton:IsVisible()) then
            local shouldVendorJunk = Tags.Database:GetConfig("autoVendorJunk");
            if (shouldVendorJunk == true) then
                C_MerchantFrame.SellAllJunkItems();
                print(string.format("[%s] Junk sold!", addonName));
            end
        end
    end
end)


function Tags:Init()

    Tags.Database:Init()

    CreateSlashCommands()

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

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        UpdateTooltip(tooltip);
    end)

end