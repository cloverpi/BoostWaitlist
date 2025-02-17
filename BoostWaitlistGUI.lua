local L = LibStub("AceLocale-3.0"):GetLocale("BoostWaitlist", true)

local addonName, addon = ...

-- Create local vars
local DB -- assigned during ADDON_LOADED
local Main = addon
local GUI = {}
local UIBuilder = addon.UIBuilder

addon.GUI = GUI



-- Local functions
local waitlist = {}
local players = {}

local CustomSort = function(self, rowA, rowB, sortBy)
  local a = self:GetRow(rowA);
	local b = self:GetRow(rowB);
	local column = self.columns[sortBy];
	local idx = column.index;

	local direction = column.sort or 'asc';
  if (idx == 'time') then
    direction = 'dsc'
  end

	if direction:lower() == 'asc' then
    return a[idx] > b[idx];
	else
    return a[idx] < b[idx];
	end
end


local waitlistTableCols = {
  {
    name = L["Waitlist"],
    width = 130,
    align = 'LEFT',
    format = 'string',
    index = 'target',
    sortable = true,
    compareSort = function(self, rowA, rowB, sortBy)
      return CustomSort(self, rowA, rowB, 3)
    end,
    color = {r=1,g=1,b=1,a=1}
  },
  {
    name = L["WaitingOn"],
    width = 115,
    align = 'LEFT',
    format = 'string',
    index = 'sender',
    sortable = true,
    compareSort = function(self, rowA, rowB, sortBy)
      return CustomSort(self, rowA, rowB, 3)
    end,
    color = {r=1,g=1,b=1,a=1}
  },
  {
    name = L["Actions"],
    width = 170,
    align = 'RIGHT',
    format = 'custom',
    index = 'time',
    sortable = false,
    compareSort = function(self, rowA, rowB, sortBy)
      return CustomSort(self, rowA, rowB, 3)
    end,
    renderer = function(cellFrame, value, rowData, columnData)

                  if (cellFrame.buttonFrame == nil) then
                    local buttonFrame = CreateFrame("Frame", nil, cellFrame)
                    buttonFrame:SetWidth(150)
                    buttonFrame:SetHeight(20)

                    buttonFrame:SetPoint("RIGHT", cellFrame, "RIGHT", -1, 0)
                    cellFrame.buttonFrame = buttonFrame
                  end

                  if (cellFrame.remove == nil) then
                      cellFrame.remove = UIBuilder:TextButton(cellFrame, L["Remove"], 50, 20)
                      -- cellFrame.remove:SetPoint('RIGHT', cellFrame, 'RIGHT', -1, 0)
                      cellFrame.remove:SetPoint('RIGHT', cellFrame.buttonFrame, 'RIGHT', 0, 0)
                  end

                  if (cellFrame.invite == nil) then
                      cellFrame.invite = UIBuilder:TextButton(cellFrame, L["Invite"], 50, 20)
                      -- cellFrame.invite:SetPoint('RIGHT', cellFrame.remove, 'LEFT', -1.5, 0)
                      cellFrame.invite:SetPoint('CENTER', cellFrame.buttonFrame, 'CENTER', 0, 0)
                  end

                  if (cellFrame.whisper == nil) then
                      cellFrame.whisper = UIBuilder:TextButton(cellFrame, L["Whisper"], 50, 20)
                      -- cellFrame.whisper:SetPoint('RIGHT', cellFrame.invite, 'LEFT', -1, 0)
                      cellFrame.whisper:SetPoint('LEFT', cellFrame.buttonFrame, 'LEFT', 0, 0)
                  end

                  cellFrame.whisper:SetScript("OnClick", function()
                    Main:GetReadyWhisper(rowData.target)
                  end)

                  cellFrame.invite:SetScript("OnClick", function()
                    Main:TriggerInvite(rowData.target)
                  end)

                  cellFrame.remove:SetScript("OnClick", function()
                    Main:RemoveWaitlist(rowData.target, true)
                  end)

              end,
  }
}


local playerTableCols = {
  {
      name = L["Name"],
      width = 115,
      align = 'LEFT',
      format = 'string',
      index = 'name',
      sortable = true,
      defaultSort = 'dsc',
      compareSort = CustomSort,
      color = {r=1,g=1,b=1,a=1}
  },
  {
      name = L["Bal"],
      width = 70,
      align = 'CENTER',
      format = 'number',
      index = 'accountBalance',
      compareSort = CustomSort,
      sortable = true,
      color = function (table, value)
          local c = {r=1,g=1,b=1,a=1}
          if (tonumber(value) < 0) then
              c = {r=1,g=0,b=0,a=1}
          end
          return c
      end,
      events = {
          OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
              local cellData = rowData[columnData.index]
              cellFrame.cellEdit = UIBuilder:TableNumericEditBox(table, cellFrame, cellData, rowData, columnData,
              function(value, row)
                  Main:SetBalance(row.name, value)
              end
              )
              return true
          end,
      }
  },
  {
      name = L["Cost"],
      width = 70,
      align = 'CENTER',
      format = 'number',
      index = 'overrideCharge',
      sortable = true,
      compareSort = CustomSort,
      color = function (table, value)
          local c = {r=1,g=1,b=1,a=1}
          if (tonumber(value) < 0) then
              c = {r=1,g=0,b=0,a=1}
          end
          return c
      end,
      events = {
          OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
              local cellData = rowData[columnData.index]
              cellFrame.cellEdit = UIBuilder:TableNumericEditBox(table, cellFrame, cellData, rowData, columnData,
              function(value)
                  if (value < 0) then
                      Main:SetOverrideDefaultCharge(rowData.name, DB.Main.cost)
                  else
                      Main:SetOverrideDefaultCharge(rowData.name, value)
                  end
              end
              )
              return true
          end,
      }
  },
  {
      name = L["Actions"],
      width = 160,
      align = 'RIGHT',
      format = 'custom',
      index = 'name',
      sortable = false,
      renderer = function(cellFrame, value, rowData, columnData)
                    

                    if (cellFrame.buttonFrame == nil) then
                      local buttonFrame = CreateFrame("Frame", nil, cellFrame)
                      buttonFrame:SetWidth(150)
                      buttonFrame:SetHeight(20)

                      buttonFrame:SetPoint("RIGHT", cellFrame, "RIGHT", -1, 0)
                      cellFrame.buttonFrame = buttonFrame
                    end

                    if (cellFrame.trade == nil) then
                        cellFrame.trade = UIBuilder:TextButton(cellFrame, L["Trade"], 50, 20)
                        -- cellFrame.trade:SetPoint('RIGHT', cellFrame, 'RIGHT', -1, 0)
                        cellFrame.trade:SetPoint('RIGHT', cellFrame.buttonFrame, 'RIGHT', 0, 0)
                    end

                    if (cellFrame.add == nil) then
                        cellFrame.add = UIBuilder:TextButton(cellFrame, L["Add"], 50, 20)
                        -- cellFrame.add:SetPoint('RIGHT', cellFrame.trade, 'LEFT', -1.5, 0)
                        cellFrame.add:SetPoint('CENTER', cellFrame.buttonFrame, 'CENTER', 0, 0)
                    end

                    if (cellFrame.addEditBox == nil) then
                      cellFrame.addEditBox = UIBuilder:NumericEditBox(cellFrame, DB.Main.cost, 50, 20, 
                      function(v) --doesn't scope properly
                        
                      end)
                      -- cellFrame.addEditBox:SetPoint('RIGHT', cellFrame.trade, 'LEFT', -1.5, 0)
                      cellFrame.addEditBox:SetPoint('CENTER', cellFrame.buttonFrame, 'CENTER', 0, 0)
                    end

                    if (cellFrame.charge == nil) then
                        cellFrame.charge = UIBuilder:TextButton(cellFrame, L["Charge"], 50, 20)
                        -- cellFrame.charge:SetPoint('RIGHT', cellFrame.add, 'LEFT', -1, 0)
                        cellFrame.charge:SetPoint('LEFT', cellFrame.buttonFrame, 'LEFT', 0, 0)
                    end

                    cellFrame.addEditBox:Hide()

                    local HandleAdd = function()
                      local vnum = tonumber(cellFrame.addEditBox:GetText())
                      if (vnum ~= nil) then
                          Main:AddBalance(value, vnum)
                      end

                      cellFrame.addEditBox:ClearFocus()
                    end

                    cellFrame.addEditBox:SetScript("OnEditFocusLost", function()
                      cellFrame.addEditBox:Hide()
                      cellFrame.addEditBox:SetValue(DB.Main.cost)
                      cellFrame.add:Show()
                    end)

                    cellFrame.addEditBox:SetScript("OnEnterPressed", function()
                      HandleAdd()
                    end)

                    cellFrame.addEditBox.button:SetScript("OnClick", function()
                      HandleAdd()
                    end)

                    cellFrame.trade:SetScript("Onclick", function()
                      InitiateTrade(value)
                    end)

                    cellFrame.add:SetScript("OnClick", function()
                      cellFrame.add:Hide()
                      cellFrame.addEditBox:Show()
                      cellFrame.addEditBox:HighlightText()
                      cellFrame.addEditBox:SetFocus()
                    end)

                    cellFrame.charge:SetScript("OnClick", function()
                      Main:ChargeBalance(value)
                    end)
                end,
  }
}


-- Init functions
function GUI:Init()
  DB = _G.BoostWaitlistDB
  GUI.created = false
  GUI:CreateMinimapIcon()
  GUI:UpdateBrokerTexture()
  GUI:ShowMinimapIcon()
  GUI:Create()
  if (not DB.Main.everActive) then
    GUI:HideMinimapIcon()
  end
  
end


-- Main GUI creation

function GUI:Create()
  local frame = UIBuilder:Window(UIParent, 468, 400, addonName)
  frame:SetToplevel(true)
  frame:SetPoint(DB.GUI.points[1], DB.GUI.points[2], DB.GUI.points[3], DB.GUI.points[4], DB.GUI.points[5])
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnMouseDown", frame.StartMoving)
  frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local a,b,c,d,e = self:GetPoint()
    DB.GUI.points = {a, nil, c, d, e}
  end)

  frame.closeButton = UIBuilder:CloseButton(frame)

  -- Header options

  frame.auobillCheckbox = UIBuilder:Checkbox(frame,L["Autobill"], L["AutobillTooltip"],
  function(checked)
      DB.Main.autobill = checked
  end)
  frame.auobillCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -65)
  frame.auobillCheckbox:SetChecked(DB.Main.autobill or false)

  frame.chargeAllButton = UIBuilder:TextButton(frame, L["ChargeAll"], 100, 25, 
  function()
    Main:ChargeAll()
  end)
  frame.chargeAllButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -63)

  frame.defaultPrice = UIBuilder:NumericEditBox(frame, DB.Main.cost, 40, 25, 
  function(v)
    DB.Main.cost = v
    GUI:Update()
  end)
  frame.defaultPrice:SetScript("OnEditFocusLost", 
  function()
    frame.defaultPrice:SetValue(DB.Main.cost)
  end)
  frame.defaultPrice:SetScript("OnEditFocusGained", function()
    frame.defaultPrice:HighlightText()
  end)
  frame.defaultPrice:SetPoint("RIGHT", frame.chargeAllButton, "LEFT", -10, 0)

  local defaultPriceLabel = UIBuilder:Label(frame.defaultPrice, L["DefaultPrice"])
  -- defaultPriceLabel:SetPoint("LEFT", frame.defaultPrice, "LEFT", -45, 0)

  -- player table

  frame.playerTable = UIBuilder:Table(frame, playerTableCols, 4, 10, -113)

  -- waitlist

  frame.waitlistTable = UIBuilder:Table(frame, waitlistTableCols, 4, 10, -90)
  frame.waitlistTable:SetPoint("TOPLEFT", frame.playerTable, "BOTTOMLEFT", 0, -65) 

  local formingOptions = {
      {text = L["Forming"], value = 1},
      {text = L["Full"], value = 0},
   }
   frame.formingDropdown = UIBuilder:Dropdown(frame, 100, 25, formingOptions, DB.Main.forming and 1 or 0, 
    function(_, v)
      DB.Main.forming = v > 0
    end)
    frame.formingDropdown:SetPoint("BOTTOMLEFT", frame.waitlistTable, "TOPLEFT", 0, 30) 

  frame:Hide()

  --hide on Escape, without exposing the entire frame.
  _G[addonName .. "MainFrame"] = 
    {
      Hide = function() frame:Hide() end,
      IsShown = function() return frame:IsShown() end
    }
  tinsert(UISpecialFrames, addonName .. "MainFrame")

  GUI.mainFrame = frame
  GUI:Update()
end

function GUI:Show()
  GUI:Update(true)
  GUI.mainFrame:Show()
end


function GUI:UpdateBrokerTexture()
    local i = "Interface\\AddOns\\BoostWaitlist\\res\\ability_warrior_charge_grey"
    if (DB.Main.active) then
      i = "Interface\\Icons\\Ability_Warrior_Charge"
    end
    GUI.minimapLDB.icon = i
end

function GUI:CreateMinimapIcon()
  -- Minimap Button ------------------------
  GUI.minimapButton = LibStub("LibDBIcon-1.0")
  GUI.minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("BoostWaitlist", {
    type = "launcher",
    text = "BoostWaitlist",
    icon = "Interface\\AddOns\\BoostWaitlist\\res\\ability_warrior_charge_grey",
    OnClick = 
      function(_, button) 
        if (button == "LeftButton") then
          GUI:ShowToggle()
        elseif (button == "RightButton") then
          if (IsShiftKeyDown()) then
            if Settings then
              Settings.OpenToCategory(addonName)
            else
              InterfaceOptionsFrame_OpenToCategory(addonName);
            end
          else
            if (DB.Main.active) then
              Main:HandleAddonOff()
            else
              Main:HandleAddonOn()
            end
          end
        end
      end,
    OnTooltipShow = function(tt)
      tt:AddLine("BoostWaitlist")
      tt:AddLine(L["MinimapTooltipLeft"])
      tt:AddLine(L["MinimapTooltipRight"])
      tt:AddLine(L["MinimapTooltipSRight"])
    end,
  })

  GUI.minimapButton:Register("BoostWaitlist", GUI.minimapLDB, DB.GUI.minimap)
end


function GUI:ShowToggle()
  if (GUI.mainFrame ~= nil) then
    if (GUI.mainFrame:IsShown()) then
      GUI.mainFrame:Hide()
    else
      GUI:Show()
    end
  else
    GUI:Create()
    GUI:Show()
  end
end


function GUI:RebuildPlayerlist()
  local partyNames = Main:GetPartyNames() or {}
  local rows = {}
  for i=1,#partyNames do
    table.insert(rows, {
      name = partyNames[i],
      accountBalance = Main:GetBalance(partyNames[i]) or 0,
      overrideCharge = Main:GetOverrideDefaultCharge(partyNames[i]) or DB.Main.cost,
      offline = true,
  })
  end
  players = rows
end

function GUI:RebuildWaitlist()
  waitlist = DB.Main.waitlistInfo.waitlist or {}

  -- to make sure data is there between updates.
  for i=1,#waitlist do
    waitlist[i].time = waitlist[i].time or time()
  end
end

function GUI:Update(fullUpdate)
  local frame = GUI.mainFrame

  frame.auobillCheckbox:SetChecked(DB.Main.autobill)
  frame.defaultPrice:SetValue(DB.Main.cost)
  frame.formingDropdown:SetValue(DB.Main.forming and 1 or 0)

  if (#players ~= #Main:GetPartyNames() or fullUpdate) then
    GUI:RebuildPlayerlist()
  else
    for i=1,#players do
      players[i].accountBalance = Main:GetBalance(players[i].name) or 0
      players[i].overrideCharge = Main:GetOverrideDefaultCharge(players[i].name) or DB.Main.cost
      players[i].online = UnitIsConnected(players[i].name) or false
    end
  end
  GUI:RebuildWaitlist()
  frame.playerTable:SetData(players)
  frame.playerTable:Refresh()

  frame.waitlistTable:SetData(waitlist)
  frame.waitlistTable:Refresh()
end

function GUI:ShowPopupFrame(reason)
  if (reason == L["DoneBoosting"]) then
    local buttons = {
      yes     = {
        text    = 'Yes',
        onClick = function(b)
          Main:NotifyClearWaitlist()
          b.window:Hide()
        end
      },
      no = {
        text    = 'No',
        onClick = function(b)
          b.window:Hide();
        end
      }
    }
    UIBuilder:ConfirmDialog("Inform Waitlist?", "You turned BoostWaitlist off but you still have players in the waitlist.  Do you want to clear the waitlist and whisper those players that you're done?", buttons)
  end
end

function GUI:ShowMinimapIcon()
  DB.GUI.minimap.hide = false
  if (GUI.minimapButton ~= nil) then
    GUI.minimapButton:Show("BoostWaitlist")
  end
end

function GUI:HideMinimapIcon()
  DB.GUI.minimap.hide = true
  if (GUI.minimapButton ~= nil) then
    GUI.minimapButton:Hide("BoostWaitlist")
  end
end
