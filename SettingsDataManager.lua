--[[------------------------------------------------------------------------------------------------
Title:          Settings Data Manager
Author:         Static_Recharge
Description:    Creates and controls the settings menu and related saved variables.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local LAM2 = LibAddonMenu2
local CM = CALLBACK_MANAGER
local WM = WINDOW_MANAGER


--[[------------------------------------------------------------------------------------------------
SDM Class Initialization
SDM    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local SDM = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
SDM:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function SDM:Initialize(Parent)
  self.Parent = Parent
  self:CreateSettingsPanel()
end


--[[------------------------------------------------------------------------------------------------
SDM:CreateSettingsPanel()
Inputs:				None  
Outputs:			None
Description:	Creates and registers the settings panel with LibAddonMenu.
------------------------------------------------------------------------------------------------]]--
function SDM:CreateSettingsPanel()
	local panelData = {
		type = "panel",
		name = "Static's Social Features",
		displayName = "Static's Social Features",
		author = self:GetParent().author,
		--website = "https://www.esoui.com/downloads/info3836-StaticsRecruiter.html",
		feedback = "https://www.esoui.com/portal.php?&uid=6533",
		slashCommand = "/ssfmenu",
		registerForRefresh = true,
		registerForDefaults = true,
		version = self:GetParent().addonVersion,
	}

  local optionsData = {}
	local i = 1

	optionsData[i] = {
		type = "header",
		name = "Character Force Offline",
	}

	i = i + 1
	optionsData[i] = {
		type = "description",
    text = "If enabled, forces your player status to OFFLINE for the specific characters. Note that if you were listed as online before logging into these characters, you will still show a message to your friends.",
    width = "full",
	}

  --i = i + 1
	--[[for k = 1, #self:GetParent().ZM.Data do
		local v = self:GetParent().ZM.Data[k]
		optionsData[i] = {
			type = "checkbox",
			name = v.name,
			getFunc = function() return self:GetParent().Zones[v.zoneID] end,
			setFunc = function(var) self:GetParent().Zones[v.zoneID] = var self:GetParent().SavedVars.Profiles[self:GetParent().SavedVars.selectedProfile].Zones[v.zoneID] = var end,
			width = "half",
			default = self:GetParent().Defaults.zoneCheckbox,
			disabled = function()
				local disabled = false
				local autoStarted = self:GetParent().autoStarted
				local isCollectible = false
				local collectibleID = GetCollectibleIdForZone(GetZoneIndex(v.zoneID))
				local isUnlocked = false
				if collectibleID ~= 0 then
					isCollectible = true
					isUnlocked = IsCollectibleUnlocked(GetCollectibleIdForZone(GetZoneIndex(v.zoneID)))
					if not isUnlocked then
						self:GetParent().Zones[v.zoneID] = false
					end
				end
				if autoStarted or (isCollectible and not isUnlocked) then
					disabled = true
				end
				return disabled
			end, -- or boolean (optional)
		}
		i = i + 1
	end]]--

  i = i + 1
  optionsData[i] = {
		type = "header",
		name = "Misc.",
	}

	i = i + 1
	optionsData[i] = {
		type = "checkbox",
    name = "Chat Messages Enabled",
    getFunc = function() return self:GetParent().SavedVars.chatMsgEnabled end,
    setFunc = function(value) self:GetParent().SavedVars.chatMsgEnabled = value end,
    tooltip = "Disables ALL chat messages from this add-on.",
    width = "half",
		default = self:GetParent().Defaults.chatMsgEnabled,
	}

	i = i + 1
	optionsData[i] = {
		type = "checkbox",
    name = "Debugging Mode",
    getFunc = function() return self:GetParent().SavedVars.debugMode end,
    setFunc = function(value) self:GetParent().SavedVars.debugMode = value end,
    tooltip = "Turns on extra messages for the purposes of debugging. Not intended for normal use.",
    width = "half",
		default = self:GetParent().Defaults.debugMode,
	}

	local function LAMPanelCreated(panel)
		if panel ~= self:GetParent().LAMSettingsPanel then return end
		self:GetParent().LAMReady = true
		self:GetParent().Controls = {}
		self:Update()
	end

	local function LAMPanelOpened(panel)
		if panel ~= self:GetParent().LAMSettingsPanel then return end
		self:Update()
	end

	self:GetParent().LAMSettingsPanel = LAM2:RegisterAddonPanel(self:GetParent().addonName .. "_LAM", panelData)
	CM:RegisterCallback("LAM-PanelControlsCreated", LAMPanelCreated)
	CM:RegisterCallback("LAM-PanelOpened", LAMPanelOpened)
	LAM2:RegisterOptionControls(self:GetParent().addonName .. "_LAM", optionsData)
end


--[[------------------------------------------------------------------------------------------------
SDM:Update()
Inputs:				None
Outputs:			None
Description:	Updates the settings panel in LibAddonMenu.
------------------------------------------------------------------------------------------------]]--
function SDM:Update()
	local parent = self:GetParent()
	if not parent.LAMReady then return end
end


--[[------------------------------------------------------------------------------------------------
SDM:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function SDM:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
StaticsRecruiterInitSettingsDataManager(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			SDM             - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitSettingsDataManager(Parent)
	return SDM:New(Parent)
end