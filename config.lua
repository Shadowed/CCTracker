if( not PartyCC ) then return end

local Config = PartyCC:NewModule("Config")
local L = PartyCCLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\PartyCC\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\PartyCC\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\PartyCC\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\PartyCC\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\PartyCC\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\PartyCC\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\PartyCC\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\PartyCC\\images\\LiteStep")
end

-- GUI
local function set(info, value)
	local arg1, arg2 = string.split(".", info.arg)
	
	if( arg2 ) then
		PartyCC.db.profile[arg1][arg2] = value
	else
		PartyCC.db.profile[arg1] = value
	end
	
	PartyCC:Reload()
end

local function get(info)
	local arg1, arg2 = string.split(".", info.arg)
	
	if( arg2 ) then
		return PartyCC.db.profile[arg1][arg2]
	else
		return PartyCC.db.profile[arg1]
	end
end

local function reverseSet(info, value)
	set(info, not value)
end

local function reverseGet(info)
	return not get(info)
end


local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, value, state)
	local arg1, arg2 = string.split(".", info.arg)
	
	if( arg2 ) then
		PartyCC.db.profile[arg1][arg2][value] = state
	else
		PartyCC.db.profile[arg1][value] = state
	end

	PartyCC:Reload()
end

local function getMulti(info, value)
	local arg1, arg2 = string.split(".", info.arg)
	
	if( arg2 ) then
		return PartyCC.db.profile[arg1][arg2][value]
	else
		return PartyCC.db.profile[arg1][value]
	end
end


-- Return all registered SML textures
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

-- Return all registered GTB groups
local groups = {}
function Config:GetGroups()
	for k in pairs(groups) do groups[k] = nil end

	groups[""] = L["None"]
	for name, data in pairs(PartyCC.GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end

-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Party CC Tracker"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			enabled = {
				order = 0,
				type = "toggle",
				name = L["Show anchor"],
				desc = L["Display timer anchor for moving around."],
				width = "full",
				arg = "showAnchor",
			},
			nameOnly = {
				order = 1,
				type = "toggle",
				name = L["Only show trigger name in bars"],
				width = "full",
				arg = "nameOnly",
			},
			sync = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Syncing"],
				args = {
					enabled = {
						order = 1,
						type = "toggle",
						name = L["Enable timer syncing"],
						desc = L["Enables timers syncing with other Party CC Tracker users, also will send syncs of your own CCs."],
						arg = "enableSync",
					},
					silent = {
						order = 2,
						type = "toggle",
						name = L["Silent mode"],
						desc = L["Disables all timers, and just syncs your CCs to other players."],
						arg = "silent",
					},
				},
			},
			bars = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Bars"],
				args = {
					growUp = {
						order = 0,
						type = "toggle",
						name = L["Grow display up"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
						width = "double",
						arg = "growUp",
					},
					texture = {
						order = 1,
						type = "select",
						name = L["Bar texture"],
						values = "GetTextures",
						dialogControl = 'LSM30_Statusbar',
						arg = "texture",
					},
					location = {
						order = 2,
						type = "select",
						name = L["Redirect bars to group"],
						desc = L["Group name to redirect bars to, this lets you show Party CC Tracker timers under another addons bar group. Requires the bars to be created using GTB."],
						values = "GetGroups",
						arg = "redirectTo",
					},
					scale = {
						order = 3,
						type = "range",
						name = L["Display scale"],
						desc = L["How big the actual timers should be."],
						min = 0, max = 2, step = 0.1,
						set = setNumber,
						arg = "scale",
					},
					width = {
						order = 4,
						type = "range",
						name = L["Bar width"],
						min = 0, max = 300, step = 1,
						set = setNumber,
						arg = "width",
					},
				},
			},
			enabledIn = {
				order = 5,
				type = "multiselect",
				name = L["Enable Party CC Tracker inside"],
				desc = L["Allows you to set what scenario's Party CC Tracker should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "inside"
			},
		},
	}
	
	options.args.spells = {
		type = "group",
		order = 2,
		name = L["Spells"],
		get = get,
		set = set,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Spells which should be enabled and shown as timers."],
			},
			list = {
				order = 1,
				type = "group",
				inline = true,
				name = L["List"],
				args = {},
			},
		},
	}

	-- Load spell list
	local id = 0
	for spellName in pairs(PartyCC.db.profile.spells) do
		id = id + 1
		
		options.args.spells.args.list.args[tostring(id)] = {
			order = id,
			type = "toggle",
			name = spellName,
			set = reverseSet,
			get = reverseGet,
			arg = "disabled." .. spellName,
		}
	end

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(PartyCC.db)
	options.args.profile.order = 3
end

-- Slash commands
SLASH_PARTYCCTRACKER1 = "/partycc"
SLASH_PARTYCCTRACKER2 = "/pcc"
SlashCmdList["PARTYCCTRACKER"] = function(msg)
	if( msg == "clear" ) then
		PartyCC.GTBGroup:UnregisterAllBars()
	elseif( msg == "test" ) then
		local GTBGroup = PartyCC.GTBGroup
		GTBGroup:UnregisterAllBars()
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, PartyCC.db.profile.texture))
		GTBGroup:RegisterBar("pcc1", string.format("%s - %s", (select(1, GetSpellInfo(10890))), UnitName("player")), 10, nil, (select(3, GetSpellInfo(10890))))
		GTBGroup:RegisterBar("pcc2", string.format("%s - %s", (select(1, GetSpellInfo(26989))), UnitName("player")), 15, nil, (select(3, GetSpellInfo(26989))))
		GTBGroup:RegisterBar("pcc3", string.format("%s - %s", (select(1, GetSpellInfo(33786))), UnitName("player")), 20, nil, (select(3, GetSpellInfo(33786))))
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("PartyCC", options)
			dialog:SetDefaultSize("PartyCC", 625, 500)
			registered = true
		end

		dialog:Open("PartyCC")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["Party CC Tracker slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["- clear - Clears all running timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- test - Shows test timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- ui - Opens the configuration."])
	end
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("PartyCC-Bliz", {
		name = "PartyCC",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("Party CC Tracker r%d is a diminishing returns tracker for PvP", PartyCC.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("PartyCC-Bliz", 600, 400)
	dialog:AddToBlizOptions("PartyCC-Bliz", "PartyCC")
	
	config:RegisterOptionsTable("PartyCC-General", options.args.general)
	dialog:AddToBlizOptions("PartyCC-General", options.args.general.name, "PartyCC")

	config:RegisterOptionsTable("PartyCC-Profile", options.args.profile)
	dialog:AddToBlizOptions("PartyCC-Profile", options.args.profile.name, "PartyCC")
end)