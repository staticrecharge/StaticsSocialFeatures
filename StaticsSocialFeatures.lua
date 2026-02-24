--[[------------------------------------------------------------------------------------------------
Title:					Static's Social Features
Author:					Static_Recharge
Version:				1.2.3
Description:		Adds specific social featues.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local CS = CHAT_SYSTEM
local EM = EVENT_MANAGER
local CR = CHAT_ROUTER


--[[------------------------------------------------------------------------------------------------
StaticsSocialFeatures Class Initialization
StaticsSocialFeatures    													- Parent object containing all functions, tables, variables, constants and other data managers.
├─ :IsInitialized()                               - Returns true if the object has been successfully initialized.
├─ :LogoutQuitHook()															- Hooks into the logout and quit function to set character status if needed before actually logging out.
├─ :FriendMessageHook()                						- Hooks into the friends message to allow only showing for fav friends.
├─ :GetCharacterIndex()                						- Returns the index of the curent character from the saved vars table.
└─ :Test(...)                                     - For internal add-on testing only.
------------------------------------------------------------------------------------------------]]--
StaticsSocialFeatures = {}


--[[------------------------------------------------------------------------------------------------
StaticsSocialFeatures:Initialize()
Inputs:				None
Outputs:			None
Description:	Initializes all of the variables, object managers, slash commands and main event
							callbacks.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:Initialize()
	-- Static definitions
	self.addonName = "StaticsSocialFeatures"
	self.addonVersion = "1.2.3"
	self.varsVersion = 2 -- SHOULD BE 2
	self.charVarsVersion = 1
	self.author = "|CFF0000Static_Recharge|r"

	self.PlayerStatus = LibStatic.PAIREDLIST:New({"Disabled", "Online", "Away", "Do Not Disturb", "Offline"}, {5, PLAYER_STATUS_ONLINE, PLAYER_STATUS_AWAY, PLAYER_STATUS_DO_NOT_DISTURB, PLAYER_STATUS_OFFLINE})

	self.AllFavNone = LibStatic.PAIREDLIST:New({"All", "Fav", "None"}, {1, 2, 3})

	self.NotificationTypes = LibStatic.PAIREDLIST:New({"Chat", "Center Screen", "Alert"}, {1, 2, 3})

  self.NotificationSizes = LibStatic.PAIREDLIST:New({"Small", "Medium", "Large"}, {CSA_CATEGORY_SMALL_TEXT, CSA_CATEGORY_MAJOR_TEXT, CSA_CATEGORY_LARGE_TEXT})

	self.NotificationSounds = LibStatic.PAIREDLIST:New({"None", "Book", "Default", "Map Open", "Error"}, {SOUNDS.NONE, SOUNDS.BOOK_ACQUIRED, SOUNDS.DEFAULT_CLICK, SOUNDS.MAP_WINDOW_OPEN, SOUNDS.GENERAL_ALERT_ERROR})

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
		chatEnabled = true,
		debugEnabled = false,
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
		multiMountNotify = true,
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

	-- Library Initializations
	local Options = {
		addonIdentifier = "SSF",
		prefixColor = "FF6600",
		textColor = "FFFFFF",
		chatEnabled = self.SV.chatEnabled,
		debugEnabled = self.SV.debugEnabled,
	}
	self.Chat = LibStatic.CHAT:New(Options)

	-- Child Initializations
	self.Status = self.STATUS:New(self)
	self.Notifications = self.NOTIFICATIONS:New(self)
	self.Lists = self.LISTS:New(self)
	self.Mounts = self.MOUNTS:New(self)
	self.Settings = self.SETTINGS:New(self)

	-- ZO Hooks
	self:LogoutQuitHook()
	self:FriendMessageHook()

	-- Slash commands declarations
	--SLASH_COMMANDS["/ssftest"] = function(...) self:Test(...) end

	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
StaticsSocialFeatures:IsInitialized()
Inputs:				None
Outputs:			initialized                         - bool for object initialized state
Description:	Returns true if the object has been successfully initialized.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:IsInitialized()
  return self.initialized
end


--[[------------------------------------------------------------------------------------------------
function StaticsSocialFeatures:LogoutQuitHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the logout and quit function to set character status if needed before actually logging out.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:LogoutQuitHook()
	function self:OnLogout()
		self.Chat:Debug("Logout/Quit prehook started.")
		if self.SV.accountOverrideEnabled and self.SV.accountOverrideLogout then
			SelectPlayerStatus(self.SV.accountOverride)
			self.Chat:Debug(zo_strformat("Player status set to <<1>>", self.SV.accountOverride))
		else
			local i = self:GetCharacterIndex()
			if self.SV.Characters[i].charOverride ~= self.PlayerStatus.Disabled and self.SV.Characters[i].charOverrideLogout then
				SelectPlayerStatus(self.SV.Characters[i].charOverride)
				self.Chat:Debug(zo_strformat("Player status set to <<1>>", self.SV.Characters[i].charOverride))
			end
		end
	end
	ZO_PreHook('Logout', function() self:OnLogout() end)
	ZO_PreHook('Quit', function() self:OnLogout() end)
end


--[[------------------------------------------------------------------------------------------------
function StaticsSocialFeatures:FriendMessageHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends message to allow only showing for fav friends.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:FriendMessageHook()
	function self:OnFriendStatusChanged(eventCode, displayName, characterName, oldStatus, newStatus)
		self.Chat:Debug("Friend Message prehook started.")
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
function StaticsSocialFeatures:GetCharacterIndex()
Inputs:			  None
Outputs:			index 					- The index of the character
Description:	Returns the index of the curent character from the saved vars table.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:GetCharacterIndex()
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
function StaticsSocialFeatures:Test(...)
Inputs:				...							- Various test inputs.
Outputs:			None
Description:	For internal add-on testing only.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeatures:Test(...)
	--self.Notifications:Notify(...)
	--self:Chat(...)
end


--[[------------------------------------------------------------------------------------------------
Main add-on event registration. Creates the global object, StaticsSocialFeatures, of the StaticsSocialFeatures class.
------------------------------------------------------------------------------------------------]]--
EM:RegisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if addonName ~= "StaticsSocialFeatures" then return end
	EM:UnregisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED)
	StaticsSocialFeatures:Initialize()
end)