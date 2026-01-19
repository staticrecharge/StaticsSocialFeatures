--[[------------------------------------------------------------------------------------------------
Title:          Lists
Author:         Static_Recharge
Description:    Controls the extended friends and ignored list features.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local EM = EVENT_MANAGER
local FLM = FRIENDS_LIST_MANAGER
local ILM = IGNORE_LIST_MANAGER


--[[------------------------------------------------------------------------------------------------
Defines
------------------------------------------------------------------------------------------------]]--
local FRIENDS_MAX = 100
local IGNORED_MAX = 100


--[[------------------------------------------------------------------------------------------------
Lists Class Initialization
Status    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local Lists = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
Lists:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function Lists:Initialize(Parent)
  self.Parent = Parent
  self.eventSpace = "SSFLists"

  -- Hooks
  self:IgnoreMasterListHook()

  -- Event Regristrations
  EM:RegisterForEvent(self.eventSpace, EVENT_IGNORE_ADDED, function(...) self:OnIgnoreAdded(...) end)
end


--[[------------------------------------------------------------------------------------------------
Lists:OnIgnoreAdded(eventCode, displayName)
Inputs:				eventCode 			- ZOS event code
              displayName     - display name of the ignore added
Outputs:			None
Description:	Determines if the added ignore needs to be placed on the virtual list. Reserves the
              last ignore spot for transferring data and preserving ignore add functionality.
------------------------------------------------------------------------------------------------]]--
function Lists:OnIgnoreAdded(eventCode, displayName)
  -- if not at max ignore then we don't have to add to virtual list
  if GetNumIgnored() ~= IGNORED_MAX then return end

  local Parent = self:GetParent()

  table.insert(Parent.SV.Ignored, {displayName})
  RemoveIgnore(displayName)

  Parent:Chat(zo_strformat("Ignore list is full! <<1>> added to virtual ignore list.", displayName))
end


--[[------------------------------------------------------------------------------------------------
Lists:IgnoreMasterListHook()
Inputs:				None
Outputs:			None
Description:	Hooks into the ignore master list to add our virtual items.
------------------------------------------------------------------------------------------------]]--
function Lists:IgnoreMasterListHook()
  local Parent = self:GetParent()

  ZO_PostHook(ILM, "BuildMasterList", function(self_)
    for index, Ignore in ipairs(Parent.SV.Ignored) do
      table.insert(self_.masterList, {Ignore.displayName, Ignore.note, SOCIAL_NAME_SEARCH, IGNORED_MAX - 1 + index})
    end
  end)
end

--[[
RequestFriend(*string* _charOrDisplayName_, *string* _message_)

* RemoveFriend(*string* _displayName_)

* SetFriendNote(*luaindex* _friendIndex_, *string* _note_)

GetNumFriends()

IsFriend(*string* _charOrDisplayName_)
** _Returns:_ *bool* _isFriend_

GetFriendCharacterInfo(*luaindex* _friendIndex_)
** _Returns:_ *bool* _hasCharacter_, *string* _characterName_, *string* _zoneName_, *integer* _classType_, *[Alliance|#Alliance]* _alliance_, *integer* _level_, *integer* _championRank_, *integer* _zoneId_, *id64* _consoleId_

GetFriendInfo(*luaindex* _friendIndex_)
** _Returns:_ *string* _displayName_, *string* _note_, *[PlayerStatus|#PlayerStatus]* _playerStatus_, *integer* _secsSinceLogoff_

GetNumIncomingFriendRequests()
** _Returns:_ *integer* _numRequests_

* GetIncomingFriendRequestInfo(*luaindex* _index_)
** _Returns:_ *string* _displayName_, *integer* _secsSinceRequest_, *string* _message_

AcceptFriendRequest(*string* _displayName_)

* RejectFriendRequest(*string* _displayName_)

* CancelFriendRequest(*luaindex* _index_)

EVENT_INCOMING_FRIEND_INVITE_ADDED (*string* _displayName_)
* EVENT_INCOMING_FRIEND_INVITE_NOTE_UPDATED (*string* _displayName_, *string* _message_)
* EVENT_INCOMING_FRIEND_INVITE_REMOVED (*string* _displayName_)

EVENT_FRIEND_ADDED (number eventCode, string displayName)

EVENT_OUTGOING_FRIEND_INVITE_ADDED (*string* _displayName_)
* EVENT_OUTGOING_FRIEND_INVITE_REMOVED (*string* _displayName_)

GetNumOutgoingFriendRequests()
** _Returns:_ *integer* _numRequests_

* GetOutgoingFriendRequestInfo(*luaindex* _index_)
** _Returns:_ *string* _displayName_, *integer* _secsSinceRequest_, *string* _note_


EVENT_IGNORE_ADDED (*string* _displayName_)
* EVENT_IGNORE_NOTE_UPDATED (*string* _displayName_, *string* _note_)
* EVENT_IGNORE_ONLINE_CHARACTER_CHANGED (*string* _displayName_)
* EVENT_IGNORE_REMOVED (*string* _displayName_)

GetNumIgnored()
** _Returns:_ *integer* _numIgnored_

* GetIgnoredInfo(*luaindex* _index_)
** _Returns:_ *string* _displayName_, *string* _note_

* IsIgnored(*string* _charOrDisplayName_)
** _Returns:_ *bool* _isIgnored_

AddIgnore(*string* _charOrDisplayName_)

* RemoveIgnore(*string* _displayName_)

* SetIgnoreNote(*luaindex* _ignoreIndex_, *string* _note_)

EVENT_SOCIAL_DATA_LOADED
* EVENT_SOCIAL_ERROR (*[SocialActionResult|#SocialActionResult]* _error_)
]]--

--[[------------------------------------------------------------------------------------------------
Lists:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function Lists:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
function StaticsSocialFeaturesInitLists(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			Lists           - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitLists(Parent)
	return Lists:New(Parent)
end