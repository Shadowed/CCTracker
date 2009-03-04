if( not CCTracker ) then return end

local Config = CCTracker:NewModule("Config")
local L = CCTrackerLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\CCTracker\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\CCTracker\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\CCTracker\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\CCTracker\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\CCTracker\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\CCTracker\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\CCTracker\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\CCTracker\\images\\LiteStep")
end

-- GUI
local function set(info, value)
	if( info.arg ) then
		local cat, subCat, key = string.split(".", info.arg)
		key = key or info[#(info)]

		if( subCat == "global" ) then
			
			for name in pairs(CCTracker.db.profile.anchors) do
				CCTracker.db.profile[cat][name][key] = value
			end
			
			CCTracker:Reload()
			return
		end
		
		CCTracker.db.profile[cat][subCat][key] = value
	else
		CCTracker.db.profile[info[(#info)]] = value
	end
	
	CCTracker:Reload()
end

local function get(info)
	if( info.arg ) then
		local cat, subCat, key = string.split(".", info.arg)
		key = key or info[#(info)]

		if( subCat == "global" ) then
			return CCTracker.db.profile[cat].friendly[key]
		end
		
		return CCTracker.db.profile[cat][subCat][key]
	end

	return CCTracker.db.profile[info[(#info)]]
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, state, value)
	CCTracker.db.profile[info[(#info)]][state] = value
	CCTracker:Reload()
end

local function getMulti(info, state)
	return CCTracker.db.profile[info[(#info)]][state]
end

local function reverseSet(info, value)
	return set(info, not value)
end

local function reverseGet(info, value)
	return not get(info)
end

-- Return all fonts
local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
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
	for name, data in pairs(CCTracker.GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end

-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

-- Disabling spell config
local function createSpellConfig(type)
	local config = {
		type = "group",
		order = 2,
		name = "",
		get = get,
		set = set,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = "",
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
	for spellName in pairs(CCTracker.db.profile.spells) do
		id = id + 1
		
		config.args.list.args[tostring(id)] = {
			order = id,
			type = "toggle",
			name = spellName,
			set = reverseSet,
			get = reverseGet,
			arg = "disabled." .. type .. "." .. spellName,
		}
	end
	
	return config
end

local function createBarConfig(type)
	local config = {
		order = 3,
		type = "group",
		name = L["Anchors"],
		args = {
			bar = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Bar display"],
				args = {
					growUp = {
						order = 1,
						type = "toggle",
						name = L["Grow display up"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
						arg = "anchors." .. type,
						width = "full",
					},
					sep = {
						order = 3,
						name = "",
						type = "description",
					},
					redirectTo = {
						order = 8,
						type = "select",
						name = L["Redirect bars to group"],
						desc = L["Group name to redirect bars to, this lets you show the mods timers under another addons bar group. Requires the bars to be created using GTB."],
						arg = "anchors." .. type,
						values = "GetGroups",
						width = "full",
					},
					icon = {
						order = 5,
						type = "select",
						name = L["Icon position"],
						values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
						arg = "anchors." .. type,
					},
					texture = {
						order = 6,
						type = "select",
						name = L["Texture"],
						dialogControl = "LSM30_Statusbar",
						arg = "anchors." .. type,
						values = "GetTextures",
					},
					sep = {
						order = 8,
						name = "",
						type = "description",
					},
					fadeTime = {
						order = 9,
						type = "range",
						name = L["Fade time"],
						arg = "anchors." .. type,
						min = 0, max = 2, step = 0.1,
					},
					scale = {
						order = 11,
						type = "range",
						name = L["Display scale"],
						arg = "anchors." .. type,
						min = 0, max = 2, step = 0.01,
					},
					maxRows = {
						order = 12,
						type = "range",
						name = L["Max timers"],
						arg = "anchors." .. type,
						min = 1, max = 100, step = 1,
					},
					width = {
						order = 13,
						type = "range",
						name = L["Width"],
						min = 50, max = 300, step = 1,
						set = setNumber,
						arg = "anchors." .. type,
					},
				},
			},
			text = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Text"],
				args = {
					fontSize = {
						order = 1,
						type = "range",
						name = L["Size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
						arg = "anchors." .. type,
					},
					fontName = {
						order = 2,
						type = "select",
						name = L["Font"],
						dialogControl = "LSM30_Font",
						values = "GetFonts",
						arg = "anchors." .. type,
					},
				},
			},
		},
	}
	
	return config
end

-- General options
local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "CC Tracker"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			showAnchor = {
				order = 0,
				type = "toggle",
				name = L["Show anchor"],
				desc = L["Display timer anchor for moving around."],
				width = "full",
			},
			nameOnly = {
				order = 1.1,
				type = "toggle",
				name = L["Only show trigger name in bars"],
				width = "full",
			},
			trackTypes = {
				order = 1.2,
				type = "multiselect",
				name = L["Enable CC tracking for"],
				desc = L["What player type CC tracking should be used for."],
				values = {["friendly"] = L["Friendly CC (Friendly player being CCed)"], ["enemy"] = L["Enemy CC (Enemy player being CCed)"]},
				set = setMulti,
				get = getMulti,
				width = "full",
			},
			sync = {
				order = 1.3,
				type = "group",
				inline = true,
				name = L["Syncing"],
				args = {
					enableSync = {
						order = 1,
						type = "toggle",
						name = L["Enable timer syncing"],
						desc = L["Enables timers syncing with other CC Tracker users, also will send syncs of your own CCs."],
					},
					silent = {
						order = 2,
						type = "toggle",
						name = L["Silent mode"],
						desc = L["Disables all timers, and just syncs your CCs to other players."],
					},
				},
			},
			inside = {
				order = 1.4,
				type = "multiselect",
				name = L["Enable CC Tracker inside"],
				desc = L["Allows you to set what scenario's CC Tracker should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "full",
			},
			bars = createBarConfig("global"),
		},
	}
	
	-- Want the global options to be inline, we also need a good description
	options.args.general.args.bars.inline = true
	options.args.general.args.bars.args.desc = {
		order = 0,
		type = "description",
		name = L["Global settings for anchors, any changes made here will modify both the enemy and friendly anchors."],
	}
	
	-- ENEMY CONFIG
	options.args.enemy = {
		type = "group",
		order = 2,
		name = L["Enemy players"],
		get = get,
		set = set,
		handler = Config,
		args = {},
	}
	
	options.args.enemy.args.bars = createBarConfig("enemy")
	
	options.args.enemy.args.spells = createSpellConfig("enemy")
	options.args.enemy.args.spells.order = 2
	options.args.enemy.args.spells.name = L["Spells"]
	options.args.enemy.args.spells.args.desc.name = L["Lets you choose which timers should be shown if a party member uses them on an enemy."]
	
	-- FRIENDLY CONFIG
	options.args.friendly = {
		type = "group",
		order = 3,
		name = L["Friendly players"],
		get = get,
		set = set,
		handler = Config,
		args = {},
	}
	
	options.args.friendly.args.bars = createBarConfig("friendly")

	options.args.friendly.args.spells = createSpellConfig("friendly")
	options.args.friendly.args.spells.order = 3
	options.args.friendly.args.spells.name = L["Spells"]
	options.args.friendly.args.spells.args.desc.name = L["Lets you choose which timers should be shown if an enemy uses them on a party member."]


	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(CCTracker.db)
	options.args.profile.order = 4
end

-- Slash commands
SLASH_CCTRACKER1 = "/cctracker"
SLASH_CCTRACKER2 = "/cct"
SlashCmdList["CCTRACKER"] = function(msg)
	if( msg == "clear" ) then
		for _, group in pairs(CCTracker.anchors) do
			group:UnregisterAllBars()
		end
	elseif( msg == "test" ) then
		for _, group in pairs(CCTracker.anchors) do
			group:UnregisterAllBars()
			group:RegisterBar("pcc1", string.format("%s - %s", (select(1, GetSpellInfo(10890))), UnitName("player")), 10, nil, (select(3, GetSpellInfo(10890))))
			group:RegisterBar("pcc2", string.format("%s - %s", (select(1, GetSpellInfo(26989))), UnitName("player")), 15, nil, (select(3, GetSpellInfo(26989))))
			group:RegisterBar("pcc3", string.format("%s - %s", (select(1, GetSpellInfo(33786))), UnitName("player")), 20, nil, (select(3, GetSpellInfo(33786))))
		end
		
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("CCTracker", options)
			dialog:SetDefaultSize("CCTracker", 650, 525)
			registered = true
		end

		dialog:Open("CCTracker")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["CC Tracker slash commands"])
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

	config:RegisterOptionsTable("CCTracker-Bliz", {
		name = "CCTracker",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("CC Tracker r%d is a diminishing returns tracker for PvP", CCTracker.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("CCTracker-Bliz", 600, 400)
	dialog:AddToBlizOptions("CCTracker-Bliz", "CCTracker")
	
	config:RegisterOptionsTable("CCTracker-General", options.args.general)
	dialog:AddToBlizOptions("CCTracker-General", options.args.general.name, "CCTracker")

	config:RegisterOptionsTable("CCTracker-Profile", options.args.profile)
	dialog:AddToBlizOptions("CCTracker-Profile", options.args.profile.name, "CCTracker")
end)