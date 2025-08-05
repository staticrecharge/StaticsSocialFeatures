--[[------------------------------------------------------------------------------------------------
Title:          Status
Author:         Static_Recharge
Description:    Controls the AFK and Offline timer and features
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local EM = EVENT_MANAGER


--[[------------------------------------------------------------------------------------------------
Status Class Initialization
Status    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local Status = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
Status:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function Status:Initialize(Parent)
  self.Parent = Parent
  self.afkEventSpace = "SSFAFKTimer"
  self.offlineEventSpace = "SSFOfflineTimer"
  self.updateInterval = 1000 -- ms
  self.afkAccumulator = 0 -- s

  local afkEnabled = Parent.SavedVars.afkTimerEnabled
  local offlineEnabled = Parent.SavedVars.offlineTimerEnabled

  if afkEnabled then
    EM:RegisterForUpdate(self.afkEventSpace, self.updateInterval, function() self:PlayerIdle() end)
  end

  if offlineEnabled then
    -- wait for character to load in before timing
    EM:RegisterForEvent(self.offlineEventSpace, EVENT_PLAYER_ACTIVATED, function(eventCode, initial)
      if initial then
        Parent.SavedVars.offlineTimerEnd = os.clock() + (Parent.SavedVars.offlineTimeout * 60)
      end
      EM:RegisterForUpdate(self.offlineEventSpace, self.updateInterval, function() self:OfflineTimerUpdate() end)
      EM:UnregisterForEvent(self.offlineEventSpace, EVENT_PLAYER_ACTIVATED)
    end)
  end
end


--[[------------------------------------------------------------------------------------------------
Status:PlayerIdle()
Inputs:				None  
Outputs:			None
Description:	Checks if the player is idle and updates the timer accordingly.
------------------------------------------------------------------------------------------------]]--
function Status:PlayerIdle()
  local Parent = self:GetParent()
  local afkEnabled = Parent.SavedVars.afkTimerEnabled
  local afkNotice = Parent.SavedVars.afkNotice
  -- Unregister timer and quit if setting changed since last update.
  if not afkEnabled then
    self.afkAccumulator = 0
    EM:UnregisterForUpdate(self.afkEventSpace)
    return
  end

  -- if even one of these evaluate to true then the player is busy.
  -- All have to be false for the player to be idle
	if (not ArePlayerWeaponsSheathed())
		or GetInteractionType() ~= 0
		or GetUnitStealthState("player") ~= 0
		or IsBlockActive()
		or (IsGameCameraUIModeActive() and DoesGameHaveFocus())
		or IsInteracting()
		or IsInteractionPending()
		or IsLooting()
		or IsMounted()
		or IsPlayerInteractingWithObject()
		or IsPlayerMoving()
		or IsPlayerStunned()
		or IsPlayerTryingToMove()
		or IsUnitDeadOrReincarnating("player")
		or IsUnitInCombat("player")
		or IsUnitSwimming("player")
	then
		self.afkAccumulator = 0
    if GetPlayerStatus() == Parent.PlayerStatus.Away then
      SelectPlayerStatus(Parent.PlayerStatus.Online)
      if afkNotice then Parent.Notifications:Notify("Switched to Online.") end
    end
  else
    self.afkAccumulator = self.afkAccumulator + 1
    if self.afkAccumulator >= Parent.SavedVars.afkTimeout and GetPlayerStatus() == Parent.PlayerStatus.Online then
      SelectPlayerStatus(Parent.PlayerStatus.Away)
      if afkNotice then Parent.Notifications:Notify("Switched to AFK.") end
    end
  end
end


--[[------------------------------------------------------------------------------------------------
Status:StartAFKTimerAgain()
Inputs:				None
Outputs:			None
Description:	Used to re-enable the afk timer from external code
------------------------------------------------------------------------------------------------]]--
function Status:StartAFKTimerAgain()
  self.afkAccumulator = 0
  EM:RegisterForUpdate(self.afkEventSpace, self.updateInterval, function() self:PlayerIdle() end)
end


--[[------------------------------------------------------------------------------------------------
Status:OfflineTimerUpdate()
Inputs:				None  
Outputs:			None
Description:	Checks if the offline timer end has been reached if enabled.
------------------------------------------------------------------------------------------------]]--
function Status:OfflineTimerUpdate()
  local time = os.clock()
  local Parent = self:GetParent()
  local offlineEnabled = Parent.SavedVars.offlineTimerEnabled
  -- unregister if they already switched to online or if they disabled it.
  if not offlineEnabled or GetPlayerStatus() == Parent.PlayerStatus.Online then
    EM:UnregisterForUpdate(self.offlineEventSpace)
  end
  if time >= Parent.SavedVars.offlineTimerEnd and GetPlayerStatus() == Parent.PlayerStatus.Offline then    
    SelectPlayerStatus(Parent.PlayerStatus.Online)
    if Parent.SavedVars.offlineTimerNotice then Parent.Notifications:Notify("Automatically set to Online.") end
  end
end


--[[------------------------------------------------------------------------------------------------
Status:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function Status:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
StaticsRecruiterInitStatus(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			Status             - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitStatus(Parent)
	return Status:New(Parent)
end