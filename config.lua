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
	local arg1, arg2, arg3 = string.split(".", info.arg)
	
	-- Global setting, update all the args
	if( arg3 and arg2 == "global" ) then
		for name in pairs(CCTracker.db.profile.anchors) do
			CCTracker.db.profile[arg1][name][arg3] = value
		end
		
		CCTracker:Reload()
		return
	end
	
	if( arg3 ) then
		CCTracker.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		CCTracker.db.profile[arg1][arg2] = value
	else
		CCTracker.db.profile[arg1] = value
	end
	
	CCTracker:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	
	-- Just grab the options out of another anchor, chances are if you've done global settings
	-- it'll be the same.
	if( arg3 and arg2 == "global" ) then
		return CCTracker.db.profile[arg1].friendly[arg3]
	end
	
	if( arg3 ) then
		return CCTracker.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return CCTracker.db.profile[arg1][arg2]
	else
		return CCTracker.db.profile[arg1]
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
		CCTracker.db.profile[arg1][arg2][value] = state
	else
		CCTracker.db.profile[arg1][value] = state
	end

	CCTracker:Reload()
end

local function getMulti(info, value)
	local arg1, arg2 = string.split(".", info.arg)
	
	if( arg2 ) then
		return CCTracker.db.profile[arg1][arg2][value]
	else
		return CCTracker.db.profile[arg1][value]
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
			growUp = {
				order = 1,
				type = "toggle",
				name = L["Grow display up"],
				desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
				width = "full",
				arg = "anchors." .. type .. ".growUp",
			},
			texture = {
				order = 2,
				type = "select",
				name = L["Bar texture"],
				values = "GetTextures",
				dialogControl = "LSM30_Statusbar",
				arg = "anchors." .. type .. ".texture",
			},
			location = {
				order = 3,
				type = "select",
				name = L["Redirect bars to group"],
				desc = L["Group name to redirect bars to, this lets you show CC Tracker timers under another addons bar group. Requires the bars to be created using GTB."],
				values = "GetGroups",
				arg = "anchors." .. type .. ".redirectTo",
			},
			scale = {
				order = 4,
				type = "range",
				name = L["Display scale"],
				desc = L["How big the actual timers should be."],
				min = 0, max = 2, step = 0.1,
				set = setNumber,
				arg = "anchors." .. type .. ".scale",
				width = "full",
			},
			maxBars = {
				order = 5,
				type = "range",
				name = L["Max bars"],
				desc = L["Maximum number of bars that will be shown in the anchor at the same time."],
				min = 0, max = 50, step = 1,
				set = setNumber,
				arg = "anchors." .. type .. ".maxBars",
			},
			width = {
				order = 7,
				type = "range",
				name = L["Bar width"],
				min = 0, max = 300, step = 1,
				set = setNumber,
				arg = "anchors." .. type .. ".width",
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
			anchor = {
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
			enabled = {
				order = 1.5,
				type = "multiselect",
				name = L["Enable CC tracking for"],
				desc = L["What player type CC tracking should be used for."],
				values = {["friendly"] = L["Friendly CC (Friendly player being CCed)"], ["enemy"] = L["Enemy CC (Enemy player being CCed)"]},
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "trackTypes"
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
						desc = L["Enables timers syncing with other CC Tracker users, also will send syncs of your own CCs."],
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
			bars = createBarConfig("global"),
			enabledIn = {
				order = 5,
				type = "multiselect",
				name = L["Enable CC Tracker inside"],
				desc = L["Allows you to set what scenario's CC Tracker should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "inside"
			},
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
			dialog:SetDefaultSize("CCTracker", 625, 500)
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