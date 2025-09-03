--[[------------------------------------------------------------------------------------------------
Title:          Lists
Author:         Static_Recharge
Description:    Controls the extended friends and ignored list features.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local EM = EVENT_MANAGER


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
end


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
StaticsRecruiterInitLists(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			Lists             - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitLists(Parent)
	return Lists:New(Parent)
end