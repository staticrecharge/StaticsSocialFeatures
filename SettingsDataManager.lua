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
	local Parent = self:GetParent()
	local panelData = {
		type = "panel",
		name = "Static's Social Features",
		displayName = "Static's Social Features",
		author = Parent.author,
		--website = "https://www.esoui.com/downloads/info3836-StaticsRecruiter.html",
		feedback = "https://www.esoui.com/portal.php?&uid=6533",
		slashCommand = "/ssfmenu",
		registerForRefresh = true,
		registerForDefaults = true,
		version = Parent.addonVersion,
	}

  local optionsData = {}
	local i = 1

	local controls = {}
	local k = 1

	controls[k] = {
		type = "description",
    text = "If enabled, forces your player status for the specific characters. Note that if you were listed as online/away/DND before logging into these characters, you will still show a message to your friends.",
    width = "full",
	}

	local choicesValues = {
		Parent.PlayerStatus.disabled,
		Parent.PlayerStatus.online,
		Parent.PlayerStatus.away,
		Parent.PlayerStatus.dnd,
		Parent.PlayerStatus.offline,
	}

	for key, value in ipairs(Parent.SavedVars.Characters) do
		k = k + 1
		controls[k] = {
			type = "dropdown",
			name = value.name, -- or string id or function returning a string
			choices = {"Disabled", "Online", "Away", "Do Not Disturb", "Offline"},
			choicesValues = choicesValues, -- if specified, these values will get passed to setFunc instead (optional)
			getFunc = function() return value.charOverride end, -- if multiSelect is true the getFunc must return a table
			setFunc = function(var) value.charOverride = var end, -- if multiSelect is true the setFunc's var must be a table
			width = "half", -- or "half" (optional)
			scrollable = false, -- boolean or number, if set the dropdown will feature a scroll bar if there are a large amount of choices and limit the visible lines to the specified number or 10 if true is used (optional)
			default = Parent.Defaults.charOverride, -- default value or function that returns the default value (optional)
			multiSelect = false, -- boolean or function returning a boolean. If set to true you can select multiple entries at the list (optional)
	}
	end

	optionsData[i] = {
		type = "submenu",
		name = "Force Character Status",
		controls = controls,
	}

  i = i + 1
  optionsData[i] = {
		type = "header",
		name = "Misc.",
	}

	i = i + 1
	optionsData[i] = {
		type = "checkbox",
    name = "Chat Messages Enabled",
    getFunc = function() return Parent.SavedVars.chatMsgEnabled end,
    setFunc = function(value) Parent.SavedVars.chatMsgEnabled = value end,
    tooltip = "Disables ALL chat messages from this add-on.",
    width = "half",
		default = Parent.Defaults.chatMsgEnabled,
	}

	i = i + 1
	optionsData[i] = {
		type = "checkbox",
    name = "Debugging Mode",
    getFunc = function() return Parent.SavedVars.debugMode end,
    setFunc = function(value) Parent.SavedVars.debugMode = value end,
    tooltip = "Turns on extra messages for the purposes of debugging. Not intended for normal use.",
    width = "half",
		default = Parent.Defaults.debugMode,
	}

	local function LAMPanelCreated(panel)
		if panel ~= Parent.LAMSettingsPanel then return end
		Parent.LAMReady = true
		Parent.Controls = {}
		self:Update()
	end

	local function LAMPanelOpened(panel)
		if panel ~= Parent.LAMSettingsPanel then return end
		self:Update()
	end

	Parent.LAMSettingsPanel = LAM2:RegisterAddonPanel(Parent.addonName .. "_LAM", panelData)
	CM:RegisterCallback("LAM-PanelControlsCreated", LAMPanelCreated)
	CM:RegisterCallback("LAM-PanelOpened", LAMPanelOpened)
	LAM2:RegisterOptionControls(Parent.addonName .. "_LAM", optionsData)
end


--[[------------------------------------------------------------------------------------------------
SDM:Update()
Inputs:				None
Outputs:			None
Description:	Updates the settings panel in LibAddonMenu.
------------------------------------------------------------------------------------------------]]--
function SDM:Update()
	local Parent = self:GetParent()
	if not Parent.LAMReady then return end
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