--[[ spec-role status for Grid2 addon by MiCHaEL --]]

local L = LibStub("AceLocale-3.0"):GetLocale("Grid2")

local SpecRole = Grid2.statusPrototype:new("spec-role")

local LGS = LibStub("LibGroupInSpecT-1.1")

local unpack = unpack
local roster_guids = Grid2.roster_guids

local role_texts = {
	tank = L['TANK'],
	melee = L['melee'],
	ranged = L['ranged'],
	healer = L['HEALER'],
}

local role_coords_all = { {
	tank   = {      0, 0.296875, 0.34375 ,  0.640625 },
	healer = { 0.3125, 0.609375, 0.015625,  0.312500 },
	melee  = { 0.3125, 0.609375, 0.34375 ,  0.640625 },
	ranged = {      0, 0.296875, 0.015625,  0.312500 },
}, {
	tank   = { .5,  .75, .75, 1 },
	healer = { .75,  1,  .75, 1 },
	melee  = { .25, .5,  .75, 1 },
	ranged = { 0  , .25, .75, 1 },
} }

local role_coords
local role_cache = setmetatable( {}, { __index = function(t,u)
	local guid = roster_guids[u]
	if guid then
		local info = LGS:GetCachedInfo(guid)
		local role = info and info.spec_role_detailed or false
		t[u] = role
		return role
	end
	return nil
end })

-- SpecRole
SpecRole.GetColor = Grid2.statusLibrary.GetColor

function SpecRole:GroupInSpecT_Update(event, guid, unit, info)
	role_cache[unit] = info.spec_role_detailed
	self:UpdateIndicators(unit)
end

function SpecRole:ClearCache(_, unit)
	role_cache[unit] = nil
end

function SpecRole:OnEnable()
	LGS.RegisterCallback(self, "GroupInSpecT_Update")
	self:RegisterMessage("Grid_UnitUpdated", "ClearCache")
	self:RegisterMessage("Grid_UnitLeft",    "ClearCache")
end

function SpecRole:OnDisable()
	LGS.UnregisterCallback(self, "GroupInSpecT_Update")
	self:UnregisterMessage("Grid_UnitUpdated")
	self:UnregisterMessage("Grid_UnitLeft")
end

function SpecRole:IsActive(unit)
	return role_cache[unit]
end

function SpecRole:GetText(unit)
	return role_texts[ role_cache[unit] ]
end

function SpecRole:GetIcon(unit)
	return "Interface\\Addons\\Grid2StatusSpecRole\\media\\specrole"
end

function SpecRole:GetTexCoord(unit)
	return unpack( role_coords[ role_cache[unit] ] )
end

function SpecRole:GetColor(unit)
	local c
	local role = role_cache[unit]
	if role=="ranged" then
		c = self.dbx.color4
	elseif role=="melee" then
		c = self.dbx.color3
	elseif role=="healer" then
		c = self.dbx.color2
	else
		c = self.dbx.color1
	end
	return c.r, c.g, c.b, c.a
end

function SpecRole:UpdateDB()
	role_coords = role_coords_all[ self.dbx.useAlternateIcons and 2 or 1 ]
end

Grid2.setupFunc["spec-role"] = function(baseKey, dbx)
	Grid2:RegisterStatus(SpecRole, {"color", "icon", "text"}, baseKey, dbx)
	return SpecRole
end

Grid2:DbSetStatusDefaultValue("spec-role", {type = "spec-role", colorCount = 4,
	color1 = { r = 0,    g = 0,    b = 0.75, a=1 }, --tank
	color2 = { r = 0,    g = 0.75, b = 0,    a=1 }, --healer
	color3 = { r = 0.75, g = 0,    b = 0.75, a=1 }, --melee
	color4 = { r = 0.75, g = 0,    b = 0,    a=1 }, --ranged
})

--[[ configuration options --]]
local prev_LoadOptions = Grid2.LoadOptions
function Grid2:LoadOptions()
	local L, LG = Grid2Options.L, Grid2Options.LG
	Grid2Options:RegisterStatusOptions("spec-role",   "role", function(self, status, options, optionParams)
		self:MakeStatusColorOptions(status, options, optionParams)
		self:MakeSpacerOptions(options, 30)
		options.useAlternateIcons = {
			type = "toggle",
			name = L["Use alternate icons"],
			desc = L["Use alternate icons"],
			width = "full",
			order = 60,
			get = function () return status.dbx.useAlternateIcons end,
			set = function (_, v)
				status.dbx.useAlternateIcons = v or nil
				status:Refresh()
			end,
		}
	end , {
		color1 = LG["TANK"],
		color2 = LG["HEALER"],
		color3 = LG["melee"],
		color4 = LG["ranged"],
		width = "full",
		titleIcon = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
		titleIconCoords = {0,0.65,0,0.65},
	})
	prev_LoadOptions(self)
end
