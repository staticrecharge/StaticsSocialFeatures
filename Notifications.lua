--[[------------------------------------------------------------------------------------------------
Title:          Notifications
Author:         Static_Recharge
Description:    Creates and handles the notifications for the add-on.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local CSA = CENTER_SCREEN_ANNOUNCE


--[[------------------------------------------------------------------------------------------------
Notifications Class Initialization
Notifications    - Object containing all functions, tables, variables,and constants.
  |-  Parent    - Reference to parent object.
------------------------------------------------------------------------------------------------]]--
local Notifications = ZO_InitializingObject:Subclass()


--[[------------------------------------------------------------------------------------------------
Notifications:Initialize(Parent)
Inputs:				Parent 					- The parent object containing other required information.  
Outputs:			None
Description:	Initializes all of the variables and tables.
------------------------------------------------------------------------------------------------]]--
function Notifications:Initialize(Parent)
  self.Parent = Parent
  local SV = Parent.SV
  self.NotificationHandlers = {
    [Parent.NotificationTypes.Chat] = function(message)
      if not message then return end
      Parent:SendToChat(message)
      if SV.notificationSound then PlaySound(SV.notificationSound) end
    end,
    [Parent.NotificationTypes["Center Screen"]] = function(message)
      local messageParams = CSA:CreateMessageParams(SV.notificationSize, SV.notificationSound)
      messageParams:SetText(message)
      messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_BOOK_LEARNED)
      CSA:AddMessageWithParams(messageParams)
    end,
    [Parent.NotificationTypes.Alert] = function(message)
      ZO_Alert(UI_ALERT_CATEGORY_ALERT, SV.notificationSound, message)
    end,
  }
end


--[[------------------------------------------------------------------------------------------------
Notifications:Notify(message)
Inputs:				message         - The message to post to the correct notify channel 
Outputs:			None
Description:	Updates the notification settings.
------------------------------------------------------------------------------------------------]]--
function Notifications:Notify(message)
  local Parent = self:GetParent()
  local SV = Parent.SV
  self.NotificationHandlers[SV.notificationType](message)
end


--[[------------------------------------------------------------------------------------------------
Notifications:GetParent()
Inputs:				None
Outputs:			Parent          - The parent object of this object.
Description:	Returns the parent object of this object for reference to parent variables.
------------------------------------------------------------------------------------------------]]--
function Notifications:GetParent()
  return self.Parent
end


--[[------------------------------------------------------------------------------------------------
StaticsRecruiterInitNotifications(Parent)
Inputs:				Parent          - The parent object of the object to be created.
Outputs:			Notifications              - The new object created.
Description:	Global function to create a new instance of this object.
------------------------------------------------------------------------------------------------]]--
function StaticsSocialFeaturesInitNotifications(Parent)
	return Notifications:New(Parent)
end