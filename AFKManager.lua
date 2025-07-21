--[[------------------------------------------------------------------------------------------------
Title:          AFK Manager
Author:         Static_Recharge
Description:    Controls the AFK timer and features
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local EM = EVENT_MANAGER


--[[------------------------------------------------------------------------------------------------
AFKM Class Initialization
AFKM    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local AFKM = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
AFKM:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function AFKM:Initialize(Parent)
  self.Parent = Parent
  self.eventSpace = "SSFAFKTimer"
  self.updateInterval = 1000 -- ms
  self.afkAccumulator = 0 -- s

  local afkEnabled = Parent.SavedVars.afkTimerEnabled
  if afkEnabled then
    EM:RegisterForUpdate(self.eventSpace, self.updateInterval, function() self:PlayerIdle() end)
  end
end


--[[------------------------------------------------------------------------------------------------
AFKM:PlayerIdle()
Inputs:				None  
Outputs:			None
Description:	Checks if the player is idle and updates the timer accordingly.
------------------------------------------------------------------------------------------------]]--
function AFKM:PlayerIdle()
  local Parent = self:GetParent()
  local afkEnabled = Parent.SavedVars.afkTimerEnabled
  local afkNotice = Parent.SavedVars.afkNotice
  -- Unregister timer and quit if setting changed since last update.
  if not afkEnabled then
    self.afkAccumulator = 0
    EM:UnregisterForUpdate(self.eventSpace)
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
      if afkNotice then Parent.NM:Notify("Switched to Online.") end
    end
  else
    self.afkAccumulator = self.afkAccumulator + 1
    if self.afkAccumulator >= Parent.SavedVars.afkTimeout and GetPlayerStatus() == Parent.PlayerStatus.Online then
      SelectPlayerStatus(Parent.PlayerStatus.Away)
      if afkNotice then Parent.NM:Notify("Switched to AFK.") end
    end
  end
end


--[[------------------------------------------------------------------------------------------------
AFKM:StartTimerAgain()
Inputs:				None
Outputs:			None
Description:	Used to re-enable the afk timer from external code
------------------------------------------------------------------------------------------------]]--
function AFKM:StartTimerAgain()
  self.afkAccumulator = 0
  EM:RegisterForUpdate(self.eventSpace, self.updateInterval, function() self:PlayerIdle() end)
end


--[[------------------------------------------------------------------------------------------------
AFKM:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function AFKM:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
StaticsRecruiterInitAFKManager(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			AFKM             - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitAFKManager(Parent)
	return AFKM:New(Parent)
end