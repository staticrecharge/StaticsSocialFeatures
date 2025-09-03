--[[------------------------------------------------------------------------------------------------
Title:					Static's Social Features
Author:					Static_Recharge
Version:				1.1.0
Description:		Adds specific social featues.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local LAM2 = LibAddonMenu2
local LCM = LibCustomMenu
local CS = CHAT_SYSTEM
local EM = EVENT_MANAGER
local FLM = FRIENDS_LIST_MANAGER
local FL = FRIENDS_LIST
local CR = CHAT_ROUTER
local CSA = CENTER_SCREEN_ANNOUNCE


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
	self.addonVersion = "1.1.0"
	self.varsVersion = 2 -- SHOULD BE 2
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
	}
	self.chatRouterEventRedirected = false

	-- Saved variables initialization
	self.SV = ZO_SavedVars:NewAccountWide("StaticsSocialFeaturesAccountWideVars", self.varsVersion, nil, self.Defaults, nil)
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
	self.Settings = StaticsSocialFeaturesInitSettings(self)
	self.Status = StaticsSocialFeaturesInitStatus(self)
	self.Notifications = StaticsSocialFeaturesInitNotifications(self)
	self.Lists = StaticsSocialFeaturesInitLists(self)

	-- ZO Hooks
	self:FriendListHook()
	self:FriendEntryHook()
	self:FriendListSortHook()
	self:LogoutQuitHook()
	self:FriendMessageHook()
	self:FriendKeybindStripHook()
	self:FriendListTooltipHook()
	self:GroupListTooltipHook()

	-- Update Icon from settings
	self:UpdateFavIcon()

	-- Register Context Menu
	self:FriendListContextMenu()

	-- Event Registrations
	EM:RegisterForEvent(self.addonName, EVENT_PLAYER_ACTIVATED, function(...) self:OnPlayerActivated(...) end)
	EM:RegisterForEvent(self.addonName, EVENT_CHAT_MESSAGE_CHANNEL, function(...) self:OnEventChatMessageChannel(...) end)

	-- Slash commands declarations
	--SLASH_COMMANDS["/ssftest"] = function(...) self:Test(...) end

	-- Keybindings associations

	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
function SSF:UpdateFavIcon()
Inputs:			  None
Outputs:			None
Description:	Updates the display of the fav icon.
------------------------------------------------------------------------------------------------]]--
function SSF:UpdateFavIcon()
	if self.SV.favIconInheritColor then
		self.favIcon = zo_strformat("|t<<1>>%:<<2>>%:<<3>>:inheritcolor|t", self.SV.favIconSize, self.SV.favIconSize, self.SV.favIconTexture)
	else
		self.favIcon = zo_strformat("|t<<1>>%:<<2>>%:<<3>>|t", self.SV.favIconSize, self.SV.favIconSize, self.SV.favIconTexture)
	end
	FLM:BuildMasterList()
	FL:RefreshFilters()
	self:DebugMsg("Fav icon updated.")
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list manager to add Fav tag to all entries as required.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListHook()
	ZO_PostHook(FLM, 'BuildMasterList', function(self_)
		self:DebugMsg("Friend List prehook started.")
		for i, friendData in ipairs(self_.masterList) do
			if self.SV.Favs[friendData.displayName] then
				friendData.favs = false -- ZO sort function sorts false entries before true ones
			else
				friendData.favs = true
			end
		end
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendEntryHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list manager to add the icon for Fav friends.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendEntryHook()
	ZO_PostHook(FLM, 'SetupEntry', function(self_, control, data, selected)
		--self:DebugMsg("Friend Listy Entry prehook started.")
		local displayNameLabel = control:GetNamedChild("DisplayName")
		if displayNameLabel then
			if self.SV.Favs[data.displayName] then
				displayNameLabel:SetText(zo_strformat("<<1>> <<2>>", self.favIcon, ZO_FormatUserFacingDisplayName(data.displayName)))
			end
		end
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListSortHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list to sort Fav friends to the top.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListSortHook()
	ZO_PreHook(FL, 'SortScrollList', function(self_)
		self:DebugMsg("Friend List Sort prehook started.")
		if self_.currentSortOrder == ZO_SORT_ORDER_UP then
			for i, friendData in ipairs(FLM.masterList) do
				if self.SV.Favs[friendData.displayName] then
					friendData.favs = false -- ZO sort function sorts false entries before true ones
				else
					friendData.favs = true
				end
			end
		else
			for i, friendData in ipairs(FLM.masterList) do
				if self.SV.Favs[friendData.displayName] then
					friendData.favs = true -- ZO sort function sorts false entries before true ones
				else
					friendData.favs = false
				end
			end
		end
		local prevSortKey = "status"
		if self_.currentSortKey ~= "favs" then
			prevSortKey = self_.currentSortKey
		end
		FRIENDS_LIST_ENTRY_SORT_KEYS["favs"] = {tiebreaker = prevSortKey}
		if self.SV.favFriendsTop then
			self_.currentSortKey = "favs"
		end
	end)
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
		if self.SV.friendMsg == self.AllFavNone.All or (self.SV.friendMsg == self.AllFavNone.Fav and self.SV.Favs[displayName]) then
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
	if self.SV.friendMsg ~= self.AllFavNone.None and self.chatRouterEventRedirected == false then
		EM:UnregisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED)
		EM:RegisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(...) self:OnFriendStatusChanged(...) end)
		self.chatRouterEventRedirected = true
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendKeybindStripHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends keybind strip to add the invite and whisper option for offline 
							favs as well as the add/remove fav friend button.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendKeybindStripHook()
	ZO_PostHook(FL, 'InitializeKeybindDescriptors', function(self_)
		self:DebugMsg("Friend Keybind Strip prehook started.")
		-- Group Invite
		self_.keybindStripDescriptor[2].visible = function()
			if IsGroupModificationAvailable() and self_.mouseOverRow then
				local data = ZO_ScrollList_GetData(self_.mouseOverRow)
				if data and data.hasCharacter and (data.online or (self.SV.Favs[data.displayName] and self.SV.groupInvite ~= self.AllFavNone.None) or self.SV.groupInvite == self.AllFavNone.All) then
					return true
				end
			end
			return false
		end
		-- Add/Remove Fav
		self_.keybindStripDescriptor[3] = {
			name = function()
				if self_.mouseOverRow then
					local data = ZO_ScrollList_GetData(self_.mouseOverRow)
					if self.SV.Favs[data.displayName] then
						return "Remove Fav"
					end
				end
				return "Add Fav"
			end,
			keybind = "UI_SHORTCUT_QUATERNARY",
			callback = function()
				if self_.mouseOverRow then
					local data = ZO_ScrollList_GetData(self_.mouseOverRow)
					if self.SV.Favs[data.displayName] then
						self:RemoveFavFriend(data.displayName)
					else
						self:AddFavFriend(data.displayName)
					end
				end
			end,
			visible = function()
				if self_.mouseOverRow then
					return true
				end
				return false
			end,
			--icon = self.SV.favIconTexture,
		}
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListTooltipHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list to add mutual guilds to the tooltips.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListTooltipHook()
	ZO_PostHook(ZO_SocialListKeyboard, 'DisplayName_OnMouseEnter', function(self_, control)
		--self:DebugMsg("Friend List Tooltip prehook started.")
		if self.SV.sharedGuilds == self.AllFavNone.None then return end
		local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)
		local guilds = {}
		for i=1, GetNumGuilds() do
			for j=1, GetGuildInfo(GetGuildId(i)) do
				local name = GetGuildMemberInfo(GetGuildId(i),j)
				if name == data.displayName then
					table.insert(guilds, GetGuildName(GetGuildId(i)))
					break
				end
			end
		end
		guilds = table.concat(guilds, "\n")
		if data and data.hasCharacter and guilds ~= "" and (self.SV.sharedGuilds == self.AllFavNone.All or (self.SV.sharedGuilds == self.AllFavNone.Fav and  self.SV.Favs[data.displayName]))then
			SetTooltipText(InformationTooltip, guilds)
		end
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:GroupListTooltipHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the group list to sort Fav friends to the top.
------------------------------------------------------------------------------------------------]]--
function SSF:GroupListTooltipHook()
	ZO_PostHook('ZO_GroupListRowCharacterName_OnMouseEnter', function(control)
		--self:DebugMsg("Group List Tooltip prehook started.")
		if not self.SV.sharedGuildsGroup then return end
    local data = ZO_ScrollList_GetData(control.row)
		if data.displayName == GetDisplayName() then return end
		local guilds = {}
		for i=1, GetNumGuilds() do
			for j=1, GetGuildInfo(GetGuildId(i)) do
				local name = GetGuildMemberInfo(GetGuildId(i),j)
				if name == data.displayName then
					table.insert(guilds, GetGuildName(GetGuildId(i)))
					break
				end
			end
		end
		guilds = table.concat(guilds, "\n")
		if data and data.hasCharacter and guilds ~= "" then
			SetTooltipText(InformationTooltip, guilds) 
		end
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListContextMenu()
Inputs:			  None
Outputs:			None
Description:	Adds an entry to the friends list context menu.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListContextMenu()
	local function AddItem(data)
		self:DebugMsg("Friend List Context Menu started.")
		local name = data.displayName
		if self.SV.Favs[name] then 
			AddCustomMenuItem("Remove Fav Friend", function() self:RemoveFavFriend(name) end)
			if data.status == self.PlayerStatus.Offline and self.SV.groupInvite ~= self.AllFavNone.None then
				AddCustomMenuItem("Invite to Group", function() GroupInviteByName(name) end)
			end
		else
			AddCustomMenuItem("Add Fav Friend", function() self:AddFavFriend(name) end)
			if data.status == self.PlayerStatus.Offline and self.SV.groupInvite == self.AllFavNone.All then
				AddCustomMenuItem("Invite to Group", function() GroupInviteByName(name) end)
			end
		end
	end
	LCM:RegisterFriendsListContextMenu(AddItem, LCM.CATEGORY_LATE)
end


--[[------------------------------------------------------------------------------------------------
function SSF:AddFavFriend(name)
Inputs:			  name 						- The @name to add to the fav friends list
Outputs:			None
Description:	Adds the name to the Fav list.
------------------------------------------------------------------------------------------------]]--
function SSF:AddFavFriend(name)
	self.SV.Favs[name] = true
	self:DebugMsg(zo_strformat("<<1>> added to Fav Friends.", name))
	FLM:BuildMasterList()
	FL:RefreshFilters()
end


--[[------------------------------------------------------------------------------------------------
function SSF:RemoveFavFriend(name)
Inputs:			  name 						- The @name to remove from the fav friends list
Outputs:			None
Description:	Removes the name from the Fav list.
------------------------------------------------------------------------------------------------]]--
function SSF:RemoveFavFriend(name)
	self.SV.Favs[name] = nil
	self:DebugMsg(zo_strformat("<<1>> removed from Fav Friends.", name))
	FLM:BuildMasterList()
	FL:RefreshFilters()
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
function SSF:OnPlayerActivated(eventCode, initial)
Inputs:				eventCode				- Internal ZOS event code, not used here.
							initial					- Indicates if this is the first activation from log-in.
Outputs:			None
Description:	Fired when the player character is available after loading screens such as changing 
							zones, reloadui and logging in. Sets the desired player status for the logged in
							character, if not disabled.
------------------------------------------------------------------------------------------------]]--
function SSF:OnPlayerActivated(eventCode, initial)
	self:DebugMsg("OnPlayerActivated event fired.")
	self:DebugMsg(zo_strformat("Player status is <<1>>", GetPlayerStatus()))
	if initial then
		self:SettingsChanged()
		if self.initialized then self:DebugMsg("Initialized.") end
		local i = self:GetCharacterIndex()
		self:DebugMsg(zo_strformat("Character \"<<1>>\" (<<2>>) loaded.", self.SV.Characters[i].name, self.SV.Characters[i].id))
		if self.SV.accountOverrideEnabled and self.SV.accountOverrideLogin then
			SelectPlayerStatus(self.SV.accountOverride)
			self:DebugMsg(zo_strformat("Player status set to <<1>>", self.SV.accountOverride))
		elseif
			self.SV.Characters[i].charOverride ~= self.PlayerStatus.Disabled and self.SV.Characters[i].charOverrideLogin then
			SelectPlayerStatus(self.SV.Characters[i].charOverride)
			self:DebugMsg(zo_strformat("Player status set to <<1>>", self.SV.Characters[i].charOverride))
		end
		if self.SV.offlineNotice and GetPlayerStatus() == self.PlayerStatus.Offline then
			self.Notifications:Notify("You are set to offline.")
		end
	end
	EM:UnregisterForEvent(self.addonName, EVENT_PLAYER_ACTIVATED)
end


--[[------------------------------------------------------------------------------------------------
function SSF:OnEventChatMessageChannel(eventCode, channelType, fromName, text, isCustomerService, fromDisplayName)
Inputs:				eventCode				- Internal ZOS event code, not used here.
							channelType			- Global Constant channelType (using CHAT_CHANNEL_WHISPER_SENT)
							fromName  			- Character name of the sender
							text 						- body of the message
							isCustomerService- boolean if the message is from customer service
							fromDisplayName	- @name of the sender
Outputs:			None
Description:	Fired when there is a chat message. Checking for outgoing whispers and notifying if
							needed.
------------------------------------------------------------------------------------------------]]--
function SSF:OnEventChatMessageChannel(eventCode, channelType, fromName, text, isCustomerService, fromDisplayName)
	if channelType ~= CHAT_CHANNEL_WHISPER_SENT then return end
	self:DebugMsg("OnEventChatMessageChannel event fired.")
	if GetPlayerStatus() == self.PlayerStatus.Offline and self.SV.whisperNotice then
		self.Notifications:Notify("You are set to offline and cannot receive replies to whispers.")
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:SettingsChanged()
Inputs:				None
Outputs:			None
Description:	Fired when the player first loads in after a settings reset is forced
------------------------------------------------------------------------------------------------]]--
function SSF:SettingsChanged()
	if self.SV.settingsChanged then 
		self:SendToChat(zo_strformat("Static's Social Features updated to <<1>>. Settings have been reset.", self.addonVersion))
		self.SV.settingsChanged = false
	end
end


--[[------------------------------------------------------------------------------------------------
function SSF:SendToChat(inputString, ...)
Inputs:				inputString			- The input string to be formatted and sent to chat. Can be bools.
							...							- More inputs to be placed on new lines within the same message.
Outputs:			None
Description:	Formats text to be sent to the chat box for the user. Bools will be converted to 
							"true" or "false" text formats. All inputs after the first will be placed on a new 
							line within the message. Only the first line gets the add-on prefix.
------------------------------------------------------------------------------------------------]]--
function SSF:SendToChat(inputString, ...)
	if not self.SV.chatMsgEnabled then return end
	if inputString == false or inputString == "" then return end
	local Args = {...}
	local Output = {}
	inputString = self:BoolConvert(inputString)
	table.insert(Output, zo_strformat("<<1>><<2>><<3>><<4>>", self.chatPrefix, self.chatTextColor, inputString, self.chatSuffix))
	if #Args > 0 then
		for i,v in ipairs(Args) do
			v = self:BoolConvert(v)
		  table.insert(Output, zo_strformat("\n<<1>><<2>><<3>>", self.chatTextColor, v, self.chatSuffix))
		end
	end
	CS:AddMessage(table.concat(Output))
end


--[[------------------------------------------------------------------------------------------------
function function SSF:BoolConvert(bool, returnType)
Inputs:				bool 						- input bool to convert
							returnType 			- how the output should be formated (optional, 1 default)
Outputs:			string 					- string containing the converted bool, or the input if not a bool
Description:	Returns a converted bool or the input if not a bool.
returnType: 	1 	- "true/false"
							2		- "on/off"
							3		- "yes/no"
							4		- "positive/negative"
------------------------------------------------------------------------------------------------]]--
function SSF:BoolConvert(bool, returnType)
	local Responses = {
		{"true", "false"},
		{"on", "off"},
		{"yes", "no"},
		{"positive", "negative"},
	}

	if type(bool) == "boolean" then
		if not returnType then returnType = 1 end
		if bool then
			return Responses[returnType][1]
		else
			return Responses[returnType][2]
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
	if not self.SV.debugMode then return end
	if inputString == false then return end
	self:SendToChat("[DEBUG] " .. inputString)
end


--[[------------------------------------------------------------------------------------------------
function SSF:Test(...)
Inputs:				...							- Various test inputs.
Outputs:			None
Description:	For internal add-on testing only.
------------------------------------------------------------------------------------------------]]--
function SSF:Test(...)
	self.Notifications:Notify(...)
end


--[[------------------------------------------------------------------------------------------------
Main add-on event registration. Creates the global object, StaticsSocialFeatures, of the SSF class.
------------------------------------------------------------------------------------------------]]--
EM:RegisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if addonName ~= "StaticsSocialFeatures" then return end
	EM:UnregisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED)
	StaticsSocialFeatures = SSF:New()
end)