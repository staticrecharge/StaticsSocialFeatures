--[[------------------------------------------------------------------------------------------------
Title:					Static's Social Features
Author:					Static_Recharge
Version:				1.0.0
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
Description:	Initializes all of the variables, data managers, slash commands and event callbacks.
------------------------------------------------------------------------------------------------]]--
function SSF:Initialize()
	-- Static definitions
	self.addonName = "StaticsSocialFeatures"
	self.addonVersion = "1.0.0"
	self.varsVersion = 2
	self.author = "|CFF0000Static_Recharge|r"
	self.chatPrefix = "|cFFFFFF[SSF]:|r "
	self.chatTextColor = "|cFFFFFF"
	self.chatSuffix = "|r"
	self.PlayerStatus = {
		disabled = 5,
		online = PLAYER_STATUS_ONLINE,
		away = PLAYER_STATUS_AWAY,
		dnd = PLAYER_STATUS_DO_NOT_DISTURB,
		offline = PLAYER_STATUS_OFFLINE,
	}
	self.FriendMsgType = {
		all = 1,
		fav = 2,
		none = 3,
	}
	self.SharedGuildsSelection = {
		all = 1,
		fav = 2,
		none = 3,
	}
	self.Defaults = {
		chatMsgEnabled = true,
		debugMode = false,
		charOverride = self.PlayerStatus.disabled,
		charOverrideLogin = false,
		charOverrideLogout = false,
		afkTimerEnabled = true,
		afkTimeout = 600, -- s
		Characters = {},
		Favs = {},
		friendMsg = self.FriendMsgType.all,
		favFriendsTop = true,
		sharedGuilds = self.SharedGuildsSelection.all,
	}
	self.favTexture = "|t90%:90%:esoui/art/targetmarkers/target_gold_star_64.dds|t"
	self.currentCharIndex = nil

	-- Saved variables initialization
	self.SavedVars = ZO_SavedVars:NewAccountWide("StaticsSocialFeaturesAccountWideVars", self.varsVersion, nil, self.Defaults, GetWorldName())
	-- Update Character list (preserve any settings)
	local NewData = {}
	for i=1, GetNumCharacters() do
		local name, _, _, _, _, _, id, _ = GetCharacterInfo(i)
		local found = false
		name = zo_strformat("<<1>>", name)
		for index, value in ipairs(self.SavedVars.Characters) do
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
	self.SavedVars.Characters = NewData


	-- Manager Initializations
	self.SM = StaticsSocialFeaturesInitSettingsDataManager(self)
	self.AFKM = StaticsSocialFeaturesInitAFKManager(self)

	-- ZO Hooks
	self:FriendListHook()
	self:FriendEntryHook()
	self:FriendListSortHook()
	self:LogoutQuitHook()
	self:FriendMessageHook()
	self:FriendKeybindStripHook()
	self:FriendListTooltipHook()

	-- Register Context Menu
	self:FriendListContextMenu()

	-- Event Registrations
	EM:RegisterForEvent(self.addonName, EVENT_PLAYER_ACTIVATED, function(...) self:OnPlayerActivated(...) end)

	-- Slash commands declarations
	SLASH_COMMANDS["/ssf"] = function(...) self:CommandParse(...) end

	-- Keybindings associations
	
	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list manager to add Fav tag to all entries
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListHook()
	ZO_PostHook(FLM, 'BuildMasterList', function(self_)
		self:DebugMsg("Friend List prehook started.")
		for i, friendData in ipairs(self_.masterList) do
			if self.SavedVars.Favs[friendData.displayName] then
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
		self:DebugMsg("Friend Listy Entry prehook started.")
		local displayNameLabel = control:GetNamedChild("DisplayName")
		if displayNameLabel then
			if self.SavedVars.Favs[data.displayName] then
				displayNameLabel:SetText(zo_strformat("<<1>> <<2>>", self.favTexture, ZO_FormatUserFacingDisplayName(data.displayName)))
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
		local prevSortKey = "status"
		if self_.currentSortKey ~= "favs" then
			prevSortKey = self_.currentSortKey
		end
		FRIENDS_LIST_ENTRY_SORT_KEYS["favs"] = {tiebreaker = prevSortKey}
		if self.SavedVars.favFriendsTop then
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
		local i = self.currentCharIndex
		if self.SavedVars.Characters[i].charOverride ~= self.PlayerStatus.disabled and self.SavedVars.Characters[i].charOverrideLogout then
			SelectPlayerStatus(self.SavedVars.Characters[i].charOverride)
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
		if self.SavedVars.friendMsg == self.FriendMsgType.none then return end
		if self.SavedVars.friendMsg == self.FriendMsgType.all or (self.SavedVars.friendMsg == self.FriendMsgType.fav and self.SavedVars.Favs[displayName]) then
			CR:FormatAndAddChatMessage(eventCode, displayName, characterName, oldStatus, newStatus)
		end
	end
	EM:UnregisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED)
	EM:RegisterForEvent("ChatRouter", EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(...) self:OnFriendStatusChanged(...) end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendKeybindStripHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends keybind strip to add the invite and whisper option for offline 
							favs.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendKeybindStripHook()
	ZO_PostHook(FL, 'InitializeKeybindDescriptors', function(self_)
		-- Whisper
		self_.keybindStripDescriptor[1].visible = function()
			if(self_.mouseOverRow and IsChatSystemAvailableForCurrentPlatform()) then
				local data = ZO_ScrollList_GetData(self_.mouseOverRow)
				return data and data.hasCharacter and (data.online or self.SavedVars.Favs[data.displayName])
			end
			return false
		end
		-- Group Invite
		self_.keybindStripDescriptor[2].visible = function()
			if IsGroupModificationAvailable() and self_.mouseOverRow then
				local data = ZO_ScrollList_GetData(self_.mouseOverRow)
				if data and data.hasCharacter and (data.online or self.SavedVars.Favs[data.displayName]) then
					return true
				end
			end
			return false
		end
		-- Add Fav
		--[[self_.keybindStripDescriptor[3] = {
			name = "Add Fav",
			keybind = "UI_SHORTCUT_QUATERNARY",
			callback = function()
				local data = ZO_ScrollList_GetData(self_.mouseOverRow)
				self:AddFavFriend(data.displayName)
			end,
			visible = function()
				if not self.SavedVars.Favs[data.displayName] then
					return true
				end
				return false
			end,
		}]]--
		-- Remove Fav
		--[[self_.keybindStripDescriptor[4] = {
			name = "Remove Fav",
			keybind = "UI_SHORTCUT_QUATERNARY",
			callback = function()
				local data = ZO_ScrollList_GetData(self_.mouseOverRow)
				self:RemoveFavFriend(data.displayName)
			end,
			visible = function()
				if self.SavedVars.Favs[data.displayName] then
					return true
				end
				return false
			end
		}]]--
	end)
end


--[[------------------------------------------------------------------------------------------------
function SSF:FriendListTooltipHook()
Inputs:			  None
Outputs:			None
Description:	Hooks into the friends list to sort Fav friends to the top.
------------------------------------------------------------------------------------------------]]--
function SSF:FriendListTooltipHook()
	ZO_PostHook(ZO_SocialListKeyboard, 'DisplayName_OnMouseEnter', function(self_, control)
		if self.SavedVars.sharedGuilds == self.SharedGuildsSelection.none then return end
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
		if data and data.hasCharacter and guilds ~= "" and (self.SavedVars.sharedGuilds == self.SharedGuildsSelection.all or (self.SavedVars.sharedGuilds == self.SharedGuildsSelection.fav and  self.SavedVars.Favs[data.displayName]))then
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
		local name = data.displayName
		if self.SavedVars.Favs[name] then 
			AddCustomMenuItem("Remove Fav Friend", function() self:RemoveFavFriend(name) end)
			if data.status == self.PlayerStatus.offline then
				AddCustomMenuItem("Invite to Group", function() GroupInviteByName(name) end)
				AddCustomMenuItem("Whisper", function() StartChatInput("", CHAT_CHANNEL_WHISPER, name) end)
			end
		else
			AddCustomMenuItem("Add Fav Friend", function() self:AddFavFriend(name) end)
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
	self.SavedVars.Favs[name] = true
	--self:SendToChat(name .. " added to Favs.")
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
	self.SavedVars.Favs[name] = nil
	--self:SendToChat(name .. " removed from Favs.")
	FLM:BuildMasterList()
	FL:RefreshFilters()
end


--[[------------------------------------------------------------------------------------------------
function OnPlayerActivated(eventCode, initial)
Inputs:				eventCode				- Internal ZOS event code, not used here.
							initial					- Indicates if this is the first activation from log-in. From 
															experience this is actually opposite what it means.
Outputs:			None
Description:	Fired when the player character is available after loading screens such as changing 
							zones, reloadui and logging in. Sets the desired player status for the logged in
							character, if not disabled.
------------------------------------------------------------------------------------------------]]--
function SSF:OnPlayerActivated(eventCode, initial)
	self:DebugMsg("OnPlayerActivated event fired.")
	--self:SendToChat(GetPlayerStatus())
	if not initial then
		local i
		local _, _, _, _, _, _, id, _ = GetCharacterInfo(i)
		for index, value in ipairs(self.SavedVars.Characters) do
			if value.id == id then
				self.currentCharIndex = index
				i = index
				break
			end
		end
		if self.SavedVars.Characters[i].charOverride ~= self.PlayerStatus.disabled and self.SavedVars.Characters[i].charOverrideLogin then
			SelectPlayerStatus(self.SavedVars.Characters[i].charOverride)
		end
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
	if not self.SavedVars.chatMsgEnabled then return end
	if inputString == false then return end
	local Args = {...}
	local Output = {}
	table.insert(Output, self.chatPrefix)
	table.insert(Output, self.chatTextColor)
	table.insert(Output, inputString) 
	table.insert(Output, self.chatSuffix)
	if #Args > 0 then
		for i,v in ipairs(Args) do
			if type(v) == boolean then
				if v then v = "true" else v = "false" end
			end
		  table.insert(Output, "\n")
			table.insert(Output, self.chatTextColor)
	    table.insert(Output, v) 
	    table.insert(Output, self.chatSuffix)
		end
	end
	CS:AddMessage(table.concat(Output))
end


--[[------------------------------------------------------------------------------------------------
function SSF:DebugMsg(inputString)
Inputs:				inputString			- The debug string to print to chat
							...							- More inputs to be placed on new lines within the same message.
Outputs:			None
Description:	Checks if debugging mode is on and if so, sends the input message to chat.
------------------------------------------------------------------------------------------------]]--
function SSF:DebugMsg(inputString)
	if not self.SavedVars.debugMode then return end
	if inputString == false then return end
	self:SendToChat("[DEBUG] " .. inputString)
end


--[[------------------------------------------------------------------------------------------------
function SSF:CommandParse(args)
Inputs:			  args            - arguments from the slash command input.
Outputs:			None
Description:	Parses the command arguments into a table to execute certain functions.
------------------------------------------------------------------------------------------------]]--
function SSF:CommandParse(args)
	local Options = {}
	local searchResult = {string.match(args, "^(%S*)%s*(.-)$")}
	for i,v in pairs(searchResult) do
		if (v ~= nil and v~= "") then
			Options[i] = string.lower(v)
		end
	end
	if #Options == 0 then
		self:SendToChat("No command entered.")
	else
		
	end
end


--[[------------------------------------------------------------------------------------------------
Main add-on event registration. Creates the global object, StaticsRecruiter, of the SR class.
------------------------------------------------------------------------------------------------]]--
EM:RegisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if addonName ~= "StaticsSocialFeatures" then return end
	EM:UnregisterForEvent("StaticsSocialFeatures", EVENT_ADD_ON_LOADED)
	StaticsSocialFeatures = SSF:New()
end)