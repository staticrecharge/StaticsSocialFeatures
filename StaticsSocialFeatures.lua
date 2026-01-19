--[[------------------------------------------------------------------------------------------------
Title:					Static's Social Features
Author:					Static_Recharge
Version:				1.1.0
Description:		Adds specific social featues.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local CS = CHAT_SYSTEM
local EM = EVENT_MANAGER
local CR = CHAT_ROUTER


--[[------------------------------------------------------------------------------------------------
SSF Class Initialization
SSF    - Parent object containing all functions, tables, variables, constants and other data managers.
  |-  Defaults    - Default values for saved vars and settings menu items.
------------------------------------------------------------------------------------------------]]--
local SSF = ZO_InitializingObject:Subclass()

--[[------------------------------------------------------------------------------------------------
SSF:Initialize()
Inputs:				None
Outputs:			None
Description:	Initializes all of the variables, object managers, slash commands and main event
							callbacks.
------------------------------------------------------------------------------------------------]]--
function SSF:Initialize()
	-- Static definitions
	self.addonName = "StaticsSocialFeatures"
	self.addonVersion = "1.2.0"
	self.varsVersion = 2 -- SHOULD BE 2
	self.charVarsVersion = 1
	self.author = "|CFF0000Static_Recharge|r"
	self.chatPrefix = "|cFF6600[SSF]:|r "
	self.chatTextColor = "|cFFFFFF"
	self.chatSuffix = "|r"

	self.PlayerStatus = {
		Disabled = 5,
		Online = PLAYER_STATUS_ONLINE,
		Away = PLAYER_STATUS_AWAY,
		["Do Not Disturb"] = PLAYER_STATUS_DO_NOT_DISTURB,
		Offline = PLAYER_STATUS_OFFLINE,
		Keys = {"Disabled", "Online", "Away", "Do Not Disturb", "Offline"},
		Values = {5, PLAYER_STATUS_ONLINE, PLAYER_STATUS_AWAY, PLAYER_STATUS_DO_NOT_DISTURB, PLAYER_STATUS_OFFLINE},
	}

	self.AllFavNone = {
		All = 1,
		Fav = 2,
		None = 3,
		Keys = {"All", "Fav", "None"},
		Values = {1, 2, 3},
	}

	self.NotificationTypes = {
    ["Chat"] = 1,
    ["Center Screen"] = 2,
		["Alert"] = 3,
		Keys = {"Chat", "Center Screen", "Alert"},
		Values = {1, 2, 3},
  }

  self.NotificationSizes = {
    Small = CSA_CATEGORY_SMALL_TEXT,
    Medium = CSA_CATEGORY_MAJOR_TEXT,
    Large = CSA_CATEGORY_LARGE_TEXT,
		Keys = {"Small", "Medium", "Large"},
		Values = {CSA_CATEGORY_SMALL_TEXT, CSA_CATEGORY_MAJOR_TEXT, CSA_CATEGORY_LARGE_TEXT},
  }

	self.NotificationSounds = {
		["None"] = SOUNDS.NONE,
		["Book Acquired"] = SOUNDS.BOOK_ACQUIRED,
		["Default Click"] = SOUNDS.DEFAULT_CLICK,
		["Map Open"] = SOUNDS.MAP_WINDOW_OPEN,
		["Error"] = SOUNDS.GENERAL_ALERT_ERROR,
		Keys = {"None", "Book", "Default", "Map Open", "Error"},
		Values = {SOUNDS.NONE, SOUNDS.BOOK_ACQUIRED, SOUNDS.DEFAULT_CLICK, SOUNDS.MAP_WINDOW_OPEN, SOUNDS.GENERAL_ALERT_ERROR},
	}

	self.IconTextures = {
		"/esoui/art/compass/target_gold_star.dds",					-- Gold Star
		"/esoui/art/compass/target_blue_square.dds",				-- Blue Square
		"/esoui/art/compass/target_green_circle.dds",				-- Green Circle
		"/esoui/art/compass/target_orange_triangle.dds",		-- Orange Triangle
		"/esoui/art/compass/target_pink_moons.dds",					-- Pink Moons
		"/esoui/art/compass/target_purple_oblivion.dds",		-- Purple Oblivion
		"/esoui/art/compass/target_red_weapons.dds",				-- Red Weapons
		"/esoui/art/compass/target_white_skull.dds",				-- White Skull
		"/esoui/art/armory/buildicons/buildicon_5.dds",			-- CP Star
		"/esoui/art/armory/buildicons/buildicon_32.dds",		-- Dolmen Swirl
		"/esoui/art/armory/buildicons/buildicon_34.dds",		-- Veteran
		"/esoui/art/armory/buildicons/buildicon_46.dds",		-- DB Hand
		"/esoui/art/armory/buildicons/buildicon_49.dds",		-- Buddies
		"/esoui/art/tutorial/journal_tabicon_quest_up.dds",	-- Quest Icon
		"/esoui/art/buttons/featuredot_active.dds",					-- Feature Dot
	}

	self.multiRiderSubCatID = 75

	self.Defaults = {
		chatMsgEnabled = true,
		debugMode = false,
		charOverride = self.PlayerStatus.Disabled,
		charOverrideLogin = false,
		charOverrideLogout = false,
		accountOverride = self.PlayerStatus.Disabled,
		accountOverrideLogin = false,
		accountOverrideLogout = false,
		accountOverrideEnabled = true,
		afkTimerEnabled = true,
		afkTimeout = 600, -- s
		Characters = {},
		Favs = {},
		friendMsg = self.AllFavNone.All,
		friendMsgChat = true,
		favFriendsTop = true,
		sharedGuilds = self.AllFavNone.All,
		favIconSize = 90, -- %
		favIconInheritColor = false,
		favIconTexture = self.IconTextures[1],
		settingsChanged = true,
		offlineNotice = true,
		groupInvite = self.AllFavNone.All,
		whisperNotice = true,
		notificationType = self.NotificationTypes["Center Screen"],
		notificationSize = self.NotificationSizes.Medium,
		notificationSound = self.NotificationSounds["Book Acquired"],
		afkNotice = true,
		offlineTimerEnabled = false,
		offlineTimeout = 10, -- m
		offlineTimerNotice = true,
		offlineTimerEnd = nil,
		sharedGuildsGroup = true,
		Friends = {},
		Ignored = {},
	}
	self.CharDefaults = {
		multiMountEnable = false,
		multiMount = nil,
		soloMount = nil,
	}

	-- Session variables
	self.chatRouterEventRedirected = false
	

	-- Saved variables initialization
	self.SV = ZO_SavedVars:NewAccountWide("StaticsSocialFeaturesAccountWideVars", self.varsVersion, nil, self.Defaults, nil)
	self.CH = ZO_SavedVars:NewCharacterIdSettings("StaticsSocialFeaturesCharVars", self.charVarsVersion, nil, self.CharDefaults, nil)
	--RequestAddOnSavedVariablesPrioritySave(self.addonName)

	-- Update Character list (preserve any settings)
	local NewData = {}

	for i=1, GetNumCharacters() do
		local name, _, _, _, _, _, id, _ = GetCharacterInfo(i)
		local found = false
		name = zo_strformat("<<1>>", name)

		for index, value in ipairs(self.SV.Characters) do
			if value.id == id then
				NewData[i] = {name = name, id = id, charOverride = value.charOverride, charOverrideLogin = value.charOverrideLogin, charOverrideLogout = value.charOverrideLogout}
				found = true
				break
			end
		end

		if not found then
			NewData[i] = {name = name, id = id, charOverride = self.Defaults.charOverride, charOverrideLogin = self.Defaults.charOverrideLogin, charOverrideLogout = self.Defaults.charOverrideLogout}
		end
	end

	table.sort(NewData, function(a, b) return a.name < b.name end)
	self.SV.Characters = NewData

	-- Child Initializations
	self.Status = StaticsSocialFeaturesInitStatus(self)
	self.Notifications = StaticsSocialFeaturesInitNotifications(self)
	self.Lists = StaticsSocialFeaturesInitLists(self)
	self.Mounts = StaticsSocialFeaturesInitMounts(self)
	self.Settings = StaticsSocialFeaturesInitSettings(self)

	-- ZO Hooks
	self:LogoutQuitHook()
	self:FriendMessageHook()

	-- Slash commands declarations
	--SLASH_COMMANDS["/ssftest"] = function(...) self:Test(...) end

	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
function SSF:LogoutQuitHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the logout and quit function to set character status if needed before actually logging out.
------------------------------------------------------------------------------------------------]]--
function SSF:LogoutQuitHook()
	function self:OnLogout()
		self:DebugMsg("Logout/Quit prehook started.")
		if self.SV.accountOverrideEnabled and self.SV.accountOverrideLogout then
			SelectPlayerStatus(self.SV.accountOverride)
			self:DebugMsg(zo_strformat("Player status set to <<1>>", self.SV.accountOverride))
		else
			local i = self:GetCharacterIndex()
			if self.SV.Characters[i].charOverride ~= self.PlayerStatus.Disabled and self.SV.Characters[i].charOverrideLogout then
				SelectPlayerStatus(self.SV.Characters[i].charOverride)
				self:DebugMsg(zo_strformat("Player status set to <<1>>", self.SV.Characters[i].charOverride))
			end
		end
	end
	ZO_PreHook('Logout', function() self:OnLogout() end)
	ZO_PreHook('Quit', function() self:OnLogout() end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendMessageHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends message to allow only showing for fav friends.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendMessageHook()
	function self:OnFriendStatusChanged(eventCode, displayName, characterName, oldStatus, newStatus)
		self:DebugMsg("Friend Message prehook started.")
		if self.SV.friendMsg == self.AllFavNone.None then return end
		if self.SV.friendMsg == self.AllFavNone.Fav and self.SV.Favs[displayName] then
			if not self.SV.friendMsgChat and self.SV.notificationType ~= self.NotificationTypes.Chat then
				local wasOnline = oldStatus ~= self.PlayerStatus.Offline
				local isOnline = newStatus ~= self.PlayerStatus.Offline
				if wasOnline ~= isOnline then
					local text
					if isOnline then
						self.Notifications:Notify(zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_ON, displayName, characterName))
					else
						self.Notifications:Notify(zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayName, characterName))
					end
				end
			else
				CR:FormatAndAddChatMessage(eventCode, displayName, characterName, oldStatus, newStatus)
			end
		end
	end
	if self.SV.friendMsg ~= self.AllFavNone.All and self.chatRouterEventRedirected == false then
		EM:UnregisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED)
		EM:RegisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(...) self:OnFriendStatusChanged(...) end)
		self.chatRouterEventRedirected = true
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:GetCharacterIndex()
Inputs:			  None
Outputs:			index 					- The index of the character
Description:	Returns the index of the curent character from the saved vars table.
------------------------------------------------------------------------------------------------]]--
function SSF:GetCharacterIndex()
	local index
	local id = GetCurrentCharacterId()
	for i, v in ipairs(self.SV.Characters) do
		if v.id == id then
			index = i
			break
		end
	end
	return index
end


--[[------------------------------------------------------------------------------------------------
function SSF:ReverseTableLookUp(search, list)
Inputs:				search, list
Outputs:			index
Description:	returns index of found item in list
------------------------------------------------------------------------------------------------]]--
function SSF:ReverseTableLookUp(search, list)
	for index, value in ipairs(list) do
		if value == search then
			return index
		end
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:Chat(inputString, ...)
Inputs:				inputString			- The input string to be formatted and sent to chat. Can be bools.
							...							- More inputs to be placed on new lines within the same message.
Outputs:			None
Description:	Formats text to be sent to the chat box for the user. Bools will be converted to 
							"true" or "false" text formats. All inputs after the first will be placed on a new 
							line within the message. Only the first line gets the add-on prefix.
------------------------------------------------------------------------------------------------]]--
function SSF:Chat(inputString, ...)
	-- if chat isn't enabled then return
	if not self.SV.chatMsgEnabled then return end

	local Args = {...}

	-- Print first line
	CS:AddMessage(zo_strformat("<<1>><<2>><<3>><<4>>", self.chatPrefix, self.chatTextColor, inputString, self.chatSuffix))

	-- Print subsequent lines if any
	if #Args > 0 then
		for i,v in ipairs(Args) do
		  CS:AddMessage(zo_strformat("<<1>><<2>><<3>>", self.chatTextColor, v, self.chatSuffix))
		end
	end
end


--[[------------------------------------------------------------------------------------------------
function function SSF:BoolConvert(bool, returnType)
Inputs:				bool 						- input bool to convert
Outputs:			string 					- string containing the converted bool, or the input if not a bool
Description:	Returns a converted bool or the input if not a bool.
------------------------------------------------------------------------------------------------]]--
function SSF:BoolConvert(bool)
	if type(bool) ~= "boolean" then
		if bool then
			return "true"
		else
			return "false"
		end
	end
	return bool
end


--[[------------------------------------------------------------------------------------------------
function SSF:DebugMsg(inputString)
Inputs:				inputString			- The debug string to print to chat
Outputs:			None
Description:	Checks if debugging mode is on and if so, sends the input message to chat.
------------------------------------------------------------------------------------------------]]--
function SSF:DebugMsg(inputString)
	-- if debugging isn't enabled or the string is empty or nil then return
	if not self.SV.debugMode or inputString == false or inputString == "" then return end

	self:Chat(zo_strformat("[DEBUG] <<1>>", inputString))
end


--[[------------------------------------------------------------------------------------------------
function SSF:Test(...)
Inputs:				...							- Various test inputs.
Outputs:			None
Description:	For internal add-on testing only.
------------------------------------------------------------------------------------------------]]--
function SSF:Test(...)
	--self.Notifications:Notify(...)
	--self:Chat(...)
end


--[[------------------------------------------------------------------------------------------------
Main add-on event registration. Creates the global object, StaticsSocialFeatures, of the SSF class.
------------------------------------------------------------------------------------------------]]--
EM:RegisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if addonName ~= "StaticsSocialFeatures" then return end
	EM:UnregisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED)
	StaticsSocialFeatures = SSF:New()
end)