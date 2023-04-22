-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

local GetContainerNumSlots = _G["GetContainerNumSlots"];
local GetContainerItemCooldown = _G["GetContainerItemCooldown"];
local GetContainerItemInfo = _G["GetContainerItemInfo"];
local GetContainerItemQuestInfo = _G["GetContainerItemQuestInfo"];
local GetContainerNumFreeSlots = _G["GetContainerNumFreeSlots"];
local GameTooltip = _G["GameTooltip"];

if (_G.C_Container) then
  local Container = _G.C_Container;
  GetContainerNumSlots = Container.GetContainerNumSlots;
  GetContainerItemCooldown = Container.GetContainerItemCooldown;
  GetContainerItemInfo = Container.GetContainerItemInfo;
  GetContainerItemQuestInfo = Container.GetContainerItemQuestInfo;
  GetContainerNumFreeSlots = Container.GetContainerNumFreeSlots;
end

local Mixin, Item, GetMoney = _G.Mixin, _G.Item, _G.GetMoney;

--- Also has `$parentNormalTexture`, `PushedTexture`, `HighlightTexture`, `$parentStock FontString`,
--- `$parentCooldown`, and `$parentIconQuestTexture`
---@class MayronUI.Inventory.Slot : Button, ItemMixin, MayronUI.Icon
---@field icon Texture
---@field Count FontString
---@field searchOverlay Texture
---@field IconBorder Texture
---@field IconOverlay Texture
---@field JunkIcon Texture
---@field UpgradeIcon Texture
---@field NewItemTexture Texture
---@field BattlepayItemTexture Texture
---@field ExtendedSlot Texture
---@field ExtendedOverlay Texture
---@field ExtendedOverlay2 Texture
---@field flash Texture
---@field BagStaticBottom Texture
---@field BagStaticTop Texture
---@field newitemglowAnim AnimationGroup
---@field flashAnim AnimationGroup

---@class MayronUI.Inventory.Bag : Frame
---@field slots MayronUI.Inventory.Slot[]

---@class MayronUI.Inventory.Frame : Frame
---@field bags MayronUI.Inventory.Bag[]
---@field currency FontString
---@field freeSlots FontString

-- Register and Import Modules -----------
local C_Inventory = MayronUI:RegisterModule("Inventory", "Inventory");


-- Local Functions --------------
---@param slot MayronUI.Inventory.Slot
local function ClearBagSlot(slot)
  slot.icon:Hide();
  slot.JunkIcon:Hide();
  slot.searchOverlay:Hide();
  slot.Count:Hide();
  slot.gloss:Hide();
  slot:SetGridColor(0.2, 0.2, 0.2);
end

---@param slot MayronUI.Inventory.Slot
local function UpdateBagSlot(slot)
  if (slot:IsItemEmpty()) then
    ClearBagSlot(slot);
    return
  end

  local slotIndex = slot:GetID() or 0;
  local bag = slot:GetParent() --[[@as Frame]];
  local bagID = bag:GetID() or 0;
  local iconFileID = slot:GetItemIcon();

  slot.icon:SetTexture(iconFileID);
  slot.icon:Show();
  slot.gloss:Show();

  local info = GetContainerItemInfo(bagID, slotIndex);
  local countText = "";

  local invType = slot:GetInventoryType();
  if (invType > 0) then
    local color = slot:GetItemQualityColor();
    slot:SetGridColor(color.r, color.g, color.b);
  else
    slot:SetGridColor(0.2, 0.2, 0.2);
  end

  if (info.stackCount > 1) then
    if (info.stackCount > 9999) then
      countText = "*";
    else
      countText = tostring(info.stackCount);
    end
  end

  slot.Count:SetText(countText);
  slot.Count:Show();

  local questInfo = GetContainerItemQuestInfo(bagID, slotIndex);-- Could also use `isActive`
  local iconQuestTexture = _G[slot:GetName().."IconQuestTexture"];
  iconQuestTexture:SetShown(questInfo.isQuestItem);
  slot.JunkIcon:SetShown(slot:GetItemQuality() == 0);
  slot.searchOverlay:SetShown(info.isFiltered);

  local start, duration, enable = GetContainerItemCooldown(bagID, slotIndex);
  local isCooldownActive = enable and enable ~= 0 and start > 0 and duration > 0;

  if (isCooldownActive) then
    slot.cooldown:SetCooldown(start, duration);
  else
    slot.cooldown:Clear();
  end
end

local function CreateBagItemSlot(bagFrame, slotIndex, slotWidth, slotHeight)
  local bagGlobalName = bagFrame:GetName();
  local bagID = bagFrame:GetID();
  local slotGlobalName = bagGlobalName.."Slot"..tostring(slotIndex);

  local slot = tk:CreateFrame("Button", bagFrame, slotGlobalName, "ContainerFrameItemButtonTemplate");
  slot:SetSize(slotWidth, slotHeight);
  slot.cooldown = _G[slotGlobalName.."Cooldown"];

  slot = gui:ReskinIcon(slot, 2);
  Mixin(slot, Item:CreateFromBagAndSlot(bagID, slotIndex));

  ---@cast slot MayronUI.Inventory.Slot

  slot:SetID(slotIndex);
  ClearBagSlot(slot);

  bagFrame.slots[slotIndex] = slot;

  tk:KillAllElements(
    slot.ExtendedOverlay,
    slot.ExtendedOverlay2,
    slot.ExtendedSlot,
    slot.BagStaticBottom,
    slot.BagStaticTop,
    slot.IconBorder,
    slot.BattlepayItemTexture,
    slot:GetNormalTexture()
  );

  if (not slot:IsItemEmpty()) then
    slot:ContinueOnItemLoad(function()
      UpdateBagSlot(slot);
    end);
  end

  return slot;
end

---@param inventoryFrame MayronUI.Inventory.Frame
local function UpdateFreeSlots(inventoryFrame)
  local totalFreeSlots = 0;
  local totalSlots = 0;

  for _, bag in ipairs(inventoryFrame.bags) do
    local bagID = bag:GetID();

    if (bagID) then
      local freeBagSlots = GetContainerNumFreeSlots(bagID) or 0;
      local totalBagSlots = GetContainerNumSlots(bagID) or 0;
      totalFreeSlots = totalFreeSlots + freeBagSlots;
      totalSlots = totalSlots + totalBagSlots;
    end
  end

  local text = totalFreeSlots .. "/" .. totalSlots;
  local percent = (totalFreeSlots / totalSlots) * 100;
  local r, g, b = tk:GetProgressColor(percent, 100);
  text = tk.Strings:SetTextColorByRGB(text, r, g, b);
  inventoryFrame.freeSlots:SetText(text);
end

---@param bag MayronUI.Inventory.Bag
local function UpdateAllBagSlots(bag)
  for _, slot in ipairs(bag.slots) do
    UpdateBagSlot(slot);
  end

  local inventoryFrame = bag:GetParent()--[[@as MayronUI.Inventory.Frame]];
  UpdateFreeSlots(inventoryFrame);
end


---@param inventoryFrame MayronUI.Inventory.Frame
---@param event string
---@param bagID number?
---@param slotIndex number?
local function InventoryFrameOnEvent(inventoryFrame, event, bagID, slotIndex)
  local bag = type(bagID) == "number" and bagID >= 0 and inventoryFrame.bags[bagID + 1];

  MayronUI:LogDebug("Inventory Event: %s with bagID: %s and slotIndex: %s", event, bagID, slotIndex);
--[[
	if ( event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" ) then
		ContainerFrame_UpdateItemUpgradeIcons(self);
--]]

	if (event == "BAG_UPDATE") then
    if (bag) then
      UpdateAllBagSlots(bag);
    end

    return
  end

	if (event == "ITEM_LOCK_CHANGED") then
    if (bag and type(slotIndex) == "number" and slotIndex > 0) then
      local slot = bag.slots[slotIndex];

      if (slot) then
        local locked = slot:IsItemLocked();
        slot.icon:SetDesaturated(locked);

        if (GameTooltip:IsShown()) then
          local _, itemLink = _G.GameTooltip:GetItem();
          local slotLink = slot:GetItemLink();

          if (itemLink == slotLink) then
            GameTooltip:Hide();
          end
        end
      end
    end

    return
  end

	if (event == "BAG_NEW_ITEMS_UPDATED") then
    if (bag) then
		  UpdateAllBagSlots(bag);
    end
    return
  end

	if (event == "QUEST_ACCEPTED" or event == "UNIT_QUEST_LOG_CHANGED") then
    if (event == "UNIT_QUEST_LOG_CHANGED") then
      local unitID = bagID --[[@as UnitId]]
      if (unitID ~= "player") then return end
    end

		if (bag and bag:IsShown()) then
			UpdateAllBagSlots(bag);
		end

    return
  end

  if (event == "PLAYER_MONEY") then
    local money = GetMoney();
    local currencyText = tk.Strings:GetFormattedCurrency(money);
    inventoryFrame.currency:SetText(currencyText);
    return
	end

  -- Bag Extensions:
	-- if (event == "DISPLAY_SIZE_CHANGED" ) then
	-- 	-- UpdateContainerFrameAnchors();
  --   return
  -- end

	-- if ( event == "INVENTORY_SEARCH_UPDATE" ) then
	-- 	-- ContainerFrame_UpdateSearchResults(self);
  --   return
  -- end

	-- if ( event == "BAG_SLOT_FLAGS_UPDATED" ) then
	-- 	-- if (self:GetID() == bagID) then
	-- 	-- 	self.localFlag = nil;
	-- 	-- 	if (self:IsShown()) then
	-- 	-- 		UpdateDisplay(self);
	-- 	-- 	end
	-- 	-- end
	-- elseif ( event == "BANK_BAG_SLOT_FLAGS_UPDATED" ) then
	-- 	-- if (self:GetID() == (bagID + NUM_BAG_SLOTS)) then
	-- 	-- 	self.localFlag = nil;
	-- 	-- 	if (self:IsShown()) then
	-- 	-- 		UpdateDisplay(self);
	-- 	-- 	end
	-- 	-- end

end



-- C_Inventory ------------------

function C_Inventory:OnInitialize()
  if (not (tk:IsWrathClassic() and MayronUI.DEBUG_MODE)) then
    return
  end

  local slotWidth, slotHeight = 36, 30;
  local slotSpacing = 6;
  local maxColumns = 10;
  local containerPadding = { top = 30, right = 8, bottom = 30, left = 8 };
  local inventoryFrame = tk:CreateFrame("Frame", nil, "MUI_Inventory")--[[@as MayronUI.Inventory.Frame]];
  inventoryFrame:Hide();

  -- local OpenInventoryFrame = function() inventoryFrame:Show(); end
  -- local CloseInventoryFrame = function() inventoryFrame:Hide(); end
  local ToggleInventoryFrame = function() inventoryFrame:SetShown(not inventoryFrame:IsShown()) end

  -- tk:HookFunc("OpenBag", function() print("OpenBag") end);
  -- tk:HookFunc("OpenAllBags", function() print("OpenAllBags") end);
  -- tk:HookFunc("OpenBackpack", function() print("OpenBackpack") end);

  -- tk:HookFunc("ToggleBag", function() print("ToggleBag") end);
  tk:HookFunc("ToggleAllBags", ToggleInventoryFrame);
  -- tk:HookFunc("ToggleBackpack", function() print("ToggleBackpack") end);

  -- tk:HookFunc("CloseBag", function() print("CloseBag") end);
  -- tk:HookFunc("CloseAllBags", function() print("CloseAllBags") end);
  -- tk:HookFunc("CloseBackpack", function() print("CloseBackpack") end);

  gui:CreateDialogBox(nil, "high", inventoryFrame);
  inventoryFrame:SetFrameStrata(tk.Constants.FRAME_STRATAS.HIGH);
  gui:AddTitleBar(inventoryFrame, "Inventory");
  gui:AddCloseButton(inventoryFrame)
  gui:AddResizer(inventoryFrame);
  inventoryFrame.bags = {};

  -- self = inventoryFrame:
	inventoryFrame:RegisterEvent("BAG_UPDATE");
	inventoryFrame:RegisterEvent("ITEM_LOCK_CHANGED");
	inventoryFrame:RegisterEvent("BAG_NEW_ITEMS_UPDATED");
	inventoryFrame:RegisterEvent("PLAYER_MONEY");

  -- Wrath Only --------------:
	inventoryFrame:RegisterEvent("QUEST_ACCEPTED");
	inventoryFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED"); -- and arg1 == "player", then also do the same as QUEST_ACCEPTED
  ----------------------------

  -- Retail?:
  -- UNIT_INVENTORY_CHANGED, PLAYER_SPECIALIZATION_CHANGED

  -- Bag Extensions:
	-- inventoryFrame:RegisterEvent("DISPLAY_SIZE_CHANGED"); -- UpdateContainerFrameAnchors();
	-- inventoryFrame:RegisterEvent("INVENTORY_SEARCH_UPDATE"); -- ContainerFrame_UpdateSearchResults(self);
	-- inventoryFrame:RegisterEvent("BAG_SLOT_FLAGS_UPDATED");
	-- inventoryFrame:RegisterEvent("BANK_BAG_SLOT_FLAGS_UPDATED");

  print("Loaded Inventory Module");

  -- The current cell in the grid of rows and columns
  local columnIndex = 1;
  local rowIndex = 1;

  for bagID = 0, _G.NUM_BAG_SLOTS do
    tk:KillElement(_G["ContainerFrame"..tostring(bagID + 1)]);

    local numSlots = GetContainerNumSlots(bagID);
    local bagGlobalName = "MUI_InventoryBag"..tostring(bagID + 1);
    local bagFrame = tk:CreateFrame("Frame", inventoryFrame, bagGlobalName);
    inventoryFrame.bags[bagID + 1] = bagFrame;

    bagFrame:SetPoint("TOPLEFT", containerPadding.left, -containerPadding.top);
    bagFrame:SetPoint("BOTTOMRIGHT", -containerPadding.right, containerPadding.bottom);
    bagFrame:SetID(bagID);
    bagFrame.slots = {};

    if (numSlots > 0) then
      for slotIndex = 1, numSlots do
        local slot = CreateBagItemSlot(bagFrame, slotIndex, slotWidth, slotHeight);

        if ((columnIndex % (maxColumns + 1)) == 0) then
           -- next row
          rowIndex = rowIndex + 1;
          columnIndex = 1;
        end

        local xOffset = (columnIndex - 1) * (slotWidth + slotSpacing);
        local yOffset = (rowIndex - 1) * (slotHeight + slotSpacing);

        slot:SetPoint("TOPLEFT", xOffset, -yOffset);
        columnIndex = columnIndex + 1; -- next column
      end
    end
  end

  inventoryFrame:SetPoint("CENTER");

  local width = ((slotWidth + slotSpacing) * maxColumns) - slotSpacing + (containerPadding.left + containerPadding.right);
  local height = ((slotHeight + slotSpacing) * rowIndex) - slotSpacing + (containerPadding.top + containerPadding.bottom);

  tk:SetResizeBounds(inventoryFrame, width, height, width*2, height*2);
  inventoryFrame:SetSize(width, height);

  inventoryFrame.currency = inventoryFrame:CreateFontString("MUI_InventoryCurrency", "ARTWORK", "MUI_FontNormal");
  inventoryFrame.currency:SetPoint("BOTTOMLEFT", 8, 8);
  inventoryFrame.currency:SetJustifyH("LEFT");

  inventoryFrame.freeSlots = inventoryFrame:CreateFontString("MUI_InventorySlots", "ARTWORK", "MUI_FontNormal");
  inventoryFrame.freeSlots:SetPoint("BOTTOMLEFT", inventoryFrame.currency, "BOTTOMRIGHT", 12, 0);
  inventoryFrame.freeSlots:SetJustifyH("LEFT");

  InventoryFrameOnEvent(inventoryFrame, "PLAYER_MONEY");
  UpdateFreeSlots(inventoryFrame);
  inventoryFrame:SetScript("OnEvent", InventoryFrameOnEvent);
end