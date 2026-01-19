--[[------------------------------------------------------------------------------------------------
Title:          Mounts
Author:         Static_Recharge
Description:    Creates and handles the mount specific features for the add-on.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local LCM = LibCustomMenu
local EM = EVENT_MANAGER
local CDM = ZO_COLLECTIBLE_DATA_MANAGER


--[[------------------------------------------------------------------------------------------------
Mounts Class Initialization
Mounts    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local Mounts = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
Mounts:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function Mounts:Initialize(Parent)
  self.Parent = Parent
  self.eventSpace = "SSFMounts"
  local SV = Parent.SV
  
  -- Session variables
	self.SoloMount = {
		Keys = {},
		Values = {},
	}
	self.MultiMount = {
		Keys = {},
		Values = {},
	}
	self.currentMount = nil
	self:UpdateMountData()

  -- Context Menu
  self:MountContextMenu()

  -- Event Registrations
	EM:RegisterForEvent(self.eventSpace, EVENT_GROUP_MEMBER_JOINED, function(...) self:OnGroupMemberJoined(...) end)
	EM:RegisterForEvent(self.eventSpace, EVENT_GROUP_MEMBER_LEFT, function(...) self:OnGroupMemberLeft(...) end)

  -- Keybindings associations
	ZO_CreateStringId("SI_BINDING_NAME_MOUNT_PLAYER", "Mount Group Member")
end


--[[------------------------------------------------------------------------------------------------
function Mounts:MountPlayer()
Inputs:				None
Outputs:			None
Description:	Mounts the targetted player
------------------------------------------------------------------------------------------------]]--
function Mounts:MountPlayer()
	UseMountAsPassenger(GetRawUnitName("reticleoverplayer"))
end


--[[------------------------------------------------------------------------------------------------
function Mounts:UpdateMountData()
Inputs:				None
Outputs:			None
Description:	Updates the mount lists
------------------------------------------------------------------------------------------------]]--
function Mounts:UpdateMountData()
  local Parent = self:GetParent()

	local function IsNotMountCategory(categoryData)
		return not categoryData:IsOutfitStylesCategory() and not categoryData:IsHousingCategory()
	end

	local function IsMount(collectibleData)
		return collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
	end

	local SoloMountCollectionData = {}
	local MultiMountCollectionData = {}

	--Iterate over the main categories and do not use outfits or houses
	for idx, categoryData in CDM:CategoryIterator({IsNotMountCategory}) do
		--Iterate over the sub-categories of the current main category and do not use outfits or houses
		for _, subCategoryData in categoryData:SubcategoryIterator({IsNotMountCategory}) do
			--Iterate over the sub-categorie's collectibles and only check for mounts collectible type
			for _, subCatCollectibleData in subCategoryData:CollectibleIterator({IsMount}) do
				--Check if the mount is owned/unlocked and not blocked
				if subCatCollectibleData:IsUnlocked() and not subCatCollectibleData:IsBlocked() then
					local id = subCatCollectibleData:GetId()
					local isActive = subCatCollectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
					local name = subCatCollectibleData:GetFormattedName()
					if isActive then
						self.currentMount = {
							id = id,
							name = name,
						}
					end
					if subCategoryData:GetId() == Parent.multiRiderSubCatID then
						table.insert(MultiMountCollectionData, {id = id, name = name})
					else
						table.insert(SoloMountCollectionData, {id = id, name = name})
					end
				end
			end
		end
	end

	table.sort(MultiMountCollectionData, function(a, b) return a.name < b.name end)
	table.sort(SoloMountCollectionData, function(a, b) return a.name < b.name end)
	table.insert(SoloMountCollectionData, 1, {id = 7, name = "-- Random Favorite Mount"}) --offset id by 6, first collectible that's not a mount
	table.insert(SoloMountCollectionData, 2, {id = 8, name = "-- Random Mount"})

	for index, value in ipairs(MultiMountCollectionData) do
		self.MultiMount.Values[index] = value.id
		self.MultiMount.Keys[index] = value.name
	end
	for index, value in ipairs(SoloMountCollectionData) do
		self.SoloMount.Values[index] = value.id
		self.SoloMount.Keys[index] = value.name
	end
end


--[[------------------------------------------------------------------------------------------------
function Mounts:OnGroupMemberJoined()
Inputs:				None
Outputs:			None
Description:	Updates the mount to the multi mount
------------------------------------------------------------------------------------------------]]--
function Mounts:OnGroupMemberJoined(eventCode, memberCharacterName, memberDisplayName, isLocalPlayer)
  local Parent = self:GetParent()
	if isLocalPlayer and Parent.CH.multiMountEnable then
    local Parent = self:GetParent()
		UseCollectible(Parent.CH.multiMount, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
		Parent:DebugMsg(zo_strformat("Set to multi mount: <<1>>", GetCollectibleLink(Parent.CH.multiMount)))
	end
end


--[[------------------------------------------------------------------------------------------------
function Mounts:OnGroupMemberLeft()
Inputs:				None
Outputs:			None
Description:	Updates the mount to the solo mount
------------------------------------------------------------------------------------------------]]--
function Mounts:OnGroupMemberLeft(eventCode, memberCharacterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
  local Parent = self:GetParent()
	if isLocalPlayer and Parent.CH.multiMountEnable then
		if Parent.CH.soloMount == 7 or Parent.CH.soloMount == 8 then
			SetRandomMountType(Parent.CH.soloMount - 6, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
		else
			UseCollectible(Parent.CH.soloMount, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
			Parent:DebugMsg(zo_strformat("Set to solo mount: <<1>>", GetCollectibleLink(Parent.CH.soloMount)))
		end
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:MountContextMenu()
Inputs:			  None
Outputs:			None
Description:	Adds an entry to the Mount list context menu.
------------------------------------------------------------------------------------------------]]--
function Mounts:MountContextMenu()
  local Parent = self:GetParent()
	ZO_PostHook(ZO_CollectibleTile_Keyboard, 'AddMenuOptions', function(self_)
		if self_.collectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_MOUNT and Parent.CH.multiMountEnable then
			AddCustomMenuItem("SSF Set Mount", function()
				local id = self_.collectibleData:GetId()
				local index = Parent:ReverseTableLookUp(id, self.SoloMount.Values)
				if index then
					Parent.CH.soloMount = id
					return
				end
				index = Parent:ReverseTableLookUp(id, self.MultiMount.Values)
				if index then
					Parent.CH.multiMount = id
					return
				end
			end)
		end
	end)

	ZO_PostHook(ZO_CollectibleImitationTile_Keyboard, 'ShowMenu', function(self_)
		local data = self_.imitationCollectibleData
		if data.randomMountType and Parent.CH.multiMountEnable then
			-- recreate the original menu entry and then add SSF item
			ClearMenu()
			local stringId = self_:GetPrimaryInteractionStringId()
			if stringId and self_:IsUsable() then
				AddMenuItem(GetString(stringId), function() self_:Use() end)
			end
			AddCustomMenuItem("SSF Set Mount", function()
				Parent.CH.soloMount = data.randomMountType
			end)
			ShowMenu()
		end
	end)
end


--[[------------------------------------------------------------------------------------------------
Mounts:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function Mounts:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
StaticsSocialFeaturesInitMounts(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			Notifications              - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitMounts(Parent)
	return Mounts:New(Parent)
end