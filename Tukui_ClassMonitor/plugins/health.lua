-- Resource Plugin
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

function CreateHealthMonitor(name, text, autohide, anchor, width, height, colors)
	local cmHealth = CreateFrame("Frame", name, UIParent)
	--cmHealth:CreatePanel("Default", width , height, unpack(anchor))
	cmHealth:SetTemplate()
	cmHealth:Size(width, height)

	cmHealth.status = CreateFrame("StatusBar", "cmHealthStatus", cmHealth)
	cmHealth.status:SetStatusBarTexture(C.media.normTex)
	cmHealth.status:SetFrameLevel(6)
	--cmHealth.status:SetStatusBarColor(unpack(color)) color will be set later
	cmHealth.status:Point("TOPLEFT", cmHealth, "TOPLEFT", 2, -2)
	cmHealth.status:Point("BOTTOMRIGHT", cmHealth, "BOTTOMRIGHT", -2, 2)
	cmHealth.status:SetMinMaxValues(0, UnitHealthMax("player"))

	if text == true then
		cmHealth.text = cmHealth.status:CreateFontString(nil, "OVERLAY")
		cmHealth.text:SetFont(C.media.uffont, 12)
		cmHealth.text:Point("CENTER", cmHealth.status)
		cmHealth.text:SetShadowColor(0, 0, 0)
		cmHealth.text:SetShadowOffset(1.25, -1.25)
	end

	cmHealth.timeSinceLastUpdate = GetTime()
	local function OnUpdate(self, elapsed)
		cmHealth.timeSinceLastUpdate = cmHealth.timeSinceLastUpdate + elapsed
		if cmHealth.timeSinceLastUpdate > 0.2 then
			local value = UnitHealth("player")
			cmHealth.status:SetValue(value)
			if text == true then
				local valueMax = UnitHealthMax("player")
				if value == valueMax then
					if value > 10000 then
						cmHealth.text:SetFormattedText("%.1fk", value/1000)
					else
						cmHealth.text:SetText(value)
					end
				else
					local percentage = (value * 100) / valueMax
					if value > 10000 then
						cmHealth.text:SetFormattedText("%2d%% - %.1fk", percentage, value/1000 )
					else
						cmHealth.text:SetFormattedText("%2d%% - %u", percentage, value )
					end
				end
			end
			cmHealth.timeSinceLastUpdate = 0
		end
	end

	cmHealth:RegisterEvent("PLAYER_ENTERING_WORLD")
	cmHealth:RegisterEvent("PLAYER_REGEN_DISABLED")
	cmHealth:RegisterEvent("PLAYER_REGEN_ENABLED")
	cmHealth:RegisterEvent("UNIT_HEALTH")
	cmHealth:RegisterEvent("UNIT_MAXHEALTH")
	cmHealth:SetScript("OnEvent", function(self, event, arg1)
		if event ~= "PLAYER_ENTERING_WORLD" and event ~= "PLAYER_REGEN_DISABLED" and event ~= "PLAYER_REGEN_ENABLED" and event ~= "UNIT_MAXHEALTH" and event ~= "UNIT_HEALTH" then return end

		--print("Resource: event:"..event)
		if event == "PLAYER_ENTERING_WORLD" or ((event == "UNIT_MAXHEALTH") and arg1 == "player") then
			local valueMax = UnitHealthMax("player")
			local color = (colors and (colors[resourceName] or colors[1])) or T.UnitColor.power[resourceName] or T.UnitColor.class[T.myclass]
			cmHealth.status:SetStatusBarColor(unpack(color))
			cmHealth.status:SetMinMaxValues(0, valueMax)
		end
		if autohide == true then
			if event == "PLAYER_REGEN_DISABLED" then
				cmHealth:Show()
			elseif event == "UNIT_HEALTH" then
				if InCombatLockdown() then
					cmHealth:Show()
				end
			else
				cmHealth:Hide()
			end
		end
	end)

	-- This is what stops constant OnUpdate
	cmHealth:SetScript("OnShow", function(self)
		self:SetScript("OnUpdate", OnUpdate)
	end)
	cmHealth:SetScript("OnHide", function (self)
		self:SetScript("OnUpdate", nil)
	end)

	-- If autohide is not set, show frame
	if autohide ~= true then
		if cmHealth:IsShown() then
			cmHealth:SetScript("OnUpdate", OnUpdate)
		else
			cmHealth:Show()
		end
	end
	
	return cmHealth
end