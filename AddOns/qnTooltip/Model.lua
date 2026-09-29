-- qnTooltip: 3D-Modell der Einheit unter der Maus über dem Tooltip; dreht sich mit Strg oder Alt.

local _, ns = ...

local Model = {}
ns.Model = Model

local model

function Model.Show(tip, unit, cfg)
	if not model then
		return
	end
	if cfg.showModel and unit == "mouseover" and UnitIsVisible(unit) then
		model:SetUnit(unit)
		model:SetFacing(-0.25)
		model:Show()
	else
		model:ClearModel()
		model:Hide()
	end
end

function Model.Init()
	model = CreateFrame("PlayerModel", nil, GameTooltip)
	model:SetSize(100, 100)
	model:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", 8, -16)
	model:Hide()
	model:SetScript("OnUpdate", function(self, elapsed)
		if IsControlKeyDown() or IsAltKeyDown() then
			self:SetFacing(self:GetFacing() + math.pi * elapsed)
		end
	end)
	Model.frame = model
	GameTooltip:HookScript("OnTooltipCleared", function()
		model:ClearModel()
		model:Hide()
	end)
end
