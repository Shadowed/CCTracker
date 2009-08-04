CCTracker = LibStub("AceAddon-3.0"):NewAddon("CCTracker", "AceEvent-3.0")

local L = CCTrackerLocals

local SML, GTBLib, DRLib
local instanceType, playerName, playerGUID

local activeTimers = {}

-- Trying to be a little more conservative with the DR reset, don't like 18 when basing a spell
-- timer off of as much as I do when basing a DR timer
local DR_RESET_TIME = 16

function CCTracker:OnInitialize()
	self.defaults = {
		profile = {
			showAnchor = false,
			nameOnly = false,
			enableSync = true,
			silent = false,
			
			anchors = {
				["friendly"] = {
					growUp = false,
					scale = 1.0,
					width = 180,
					maxRows = 30,
					fontSize = 12,
					fadeTime = 0.5,
					redirectTo = "",
					icon = "LEFT",
					fontName = "Friz Quadrata TT",
					texture = "BantoBar",
					text = "CC Tracker (Friendly)",
				},
				["enemy"] = {
					growUp = false,
					scale = 1.0,
					width = 180,
					maxRows = 30,
					fontSize = 12,
					fadeTime = 0.5,
					redirectTo = "",
					icon = "LEFT",
					fontName = "Friz Quadrata TT",
					texture = "BantoBar",
					text = "CC Tracker (Enemy)",
				},
			},
			
			trackTypes = {["enemy"] = true, ["friendly"] = false},
			disabled = {["enemy"] = {}, ["friendly"] = {}},
			position = {["enemy"] = {}, ["friendly"] = {}},
			spells = {},
			
			inside = {["pvp"] = true, ["arena"] = true},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("CCTrackerDB", self.defaults)

	-- Setup SML
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "MediaRegistered")

	-- Setup GTB
	GTBLib = LibStub:GetLibrary("GTB-1.0")
	self.GTB = GTBLib
	
	self.anchors = {}
	for name, config in pairs(self.db.profile.anchors) do
		self.anchors[name] = self:CreateAnchor(config.text, name)
	end
	
	-- Setup DR lib
	DRLib = LibStub("DRData-1.0")
	
	-- Add our spells to the list for disabling
	self.spellCap = CCTrackerCaps
	self.spells = CCTrackerSpells
	self.spellNames = {}
	
	for spellID in pairs(self.spells) do
		local name, rank = GetSpellInfo(spellID)
		self.db.profile.spells[name] = true
	
		-- Also setup a list of spells by name for catching ones from debuffs
		self.spellNames[name .. rank] = spellID
	end
	
	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

function CCTracker:OnEnable()
	local type = select(2, IsInInstance())
	if( not self.db.profile.inside[type] ) then
		return
	end
	
	playerName = UnitName("player")
	playerGUID = UnitGUID("player")

	-- Check for more accurate timers
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_AURA")

	if( not self.db.profile.silent ) then
		-- Silent mode doesn't require the combat log for DR tracking
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				
		-- Enable syncing
		if( self.db.profile.enableSync ) then
			self:RegisterEvent("CHAT_MSG_ADDON")
		end
	end
end

function CCTracker:OnDisable()
	self:UnregisterAllEvents()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

-- MANAGE DR

-- DR TRACKING
local trackedPlayers = {}
local function debuffGained(spellID, destGUID, isPlayer)
	local drCat = DRLib:GetSpellCategory(spellID)

	-- Not a player, and this category isn't diminished in PVE
	if( not isPlayer and not DRLib:IsPVE(drCat) ) then
		return
	end
	
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end
end

local function debuffFaded(spellID, destGUID, isPlayer)
	local drCat = DRLib:GetSpellCategory(spellID)
	
	-- Not a player, and this category isn't diminished in PVE
	if( not isPlayer and not DRLib:IsPVE(drCat) ) then
		return
	end
	
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	if( not trackedPlayers[destGUID][drCat] ) then
		trackedPlayers[destGUID][drCat] = { reset = 0, diminished = 1.0 }
	end
	
	local time = GetTime()
	local tracked = trackedPlayers[destGUID][drCat]
	
	tracked.reset = time + DR_RESET_TIME
	tracked.diminished = DRLib:NextDR(tracked.diminished)
end

-- Combat log data
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function CCTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" and auraType == "DEBUFF" ) then
		local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER
		if( DRLib:GetSpellCategory(spellID) ) then
			debuffGained(spellID, destGUID, isPlayer)
		end
		
		if( self.spells[spellID] and self.spells[spellID] > 0 ) then
			local isEnemy = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
			self:FoundInaccurateTimer(spellID, spellName, destName, destGUID, isPlayer, isEnemy and "enemy" or "friendly")
		end
	
	-- Debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" and auraType == "DEBUFF" ) then
		if( DRLib:GetSpellCategory(spellID) ) then
			local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER

			debuffFaded(spellID, destGUID, isPlayer)
		end

		if( self.spells[spellID] ) then
			self:DebuffFaded(spellID, destName, destGUID)
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		self:UnitDied(destGUID)
	end
end

-- TIMER TRACKING

-- Unit died, reset our timers on them
function CCTracker:UnitDied(guid)
	-- Reset the tracked DRs for this guid
	if( trackedPlayers[guid] ) then
		for cat in pairs(trackedPlayers[guid]) do
			trackedPlayers[guid][cat].reset = 0
			trackedPlayers[guid][cat].diminished = 1.0
		end
	end
	
	-- Remove all of our timers for this guid
	if( activeTimers[guid] ) then
		for _, id in pairs(activeTimers[guid]) do
			self.anchors.enemy:UnregisterBar(id)
			self.anchors.friendly:UnregisterBar(id)
		end
	end
end

-- Debuff faded
function CCTracker:DebuffFaded(spellID, destName, destGUID)
	local spellName = GetSpellInfo(spellID)
	if( activeTimers[destGUID] and activeTimers[destGUID][spellName] ) then
		self.anchors.enemy:UnregisterBar(activeTimers[destGUID][spellName])
		self.anchors.friendly:UnregisterBar(activeTimers[destGUID][spellName])
	end
end

-- End result of the timer after any calculations needed are done
function CCTracker:FoundTimer(spellID, spellName, destName, destGUID, duration, timeLeft, playerType)
	-- Don't show any timers if it's silent, or it's not supposed to be enabled
	if( self.db.profile.silent or self.db.profile.disabled[playerType][spellName] ) then
		return
	end
	
	local icon = select(3, GetSpellInfo(spellID))
	local id = string.format("pcc:%s:%s:%s", playerType, spellName, destGUID)
	
	if( not activeTimers[destGUID] ) then
		activeTimers[destGUID] = {}
	end

	activeTimers[destGUID][spellName] = id
	
	-- So we can disable it if needed
	self.db.profile.spells[spellName] = true

	local text
	if( not self.db.profile.nameOnly ) then
		text = string.format("%s - %s", destName, spellName)
	else
		text = destName
	end
	
	self.anchors[playerType]:RegisterBar(id, text, timeLeft, duration, icon)
end

-- Timer was found through UnitDebuff, so don't do any pre-calculations
function CCTracker:FoundAccurateTimer(spellID, spellName, destName, destGUID, duration, timeLeft, caster)
	if( self.db.profile.enableSync and caster == "player" ) then
		self:SendMessage(string.format("GAIN:%s,%s,%s,%s,%s,%s,%s", spellID, spellName, destName, destGUID, duration, timeLeft, "enemy"))
	end

	self:FoundTimer(spellID, spellName, destName, destGUID, duration, timeLeft, "enemy")
end

-- Timer was found through the combat log, so perform DR checking to get an "accurate" answer
function CCTracker:FoundInaccurateTimer(spellID, spellName, destName, destGUID, isPlayer, playerType)
	if( not self.db.profile.trackTypes[playerType] ) then
		return
	end
	
	local duration = self.spells[spellID]
	-- Cap it at 10 seconds if it's a player, or controlled by a player
	if( isPlayer and duration > 10 ) then
		duration = self.spellCap[spellID] or 10
	end
	
	-- Apply any DR
	local diminished = 1.0
	if( trackedPlayers[destGUID] ) then
		local cat = DRLib:GetSpellCategory(spellID)
		
		if( trackedPlayers[destGUID][cat] ) then
			diminished = trackedPlayers[destGUID][cat].diminished
		end
	end
	
	-- Send it off
	self:FoundTimer(spellID, spellName, destName, destGUID, nil, duration * diminished, playerType)
end

-- Check for accurate timers
function CCTracker:ScanUnit(unit)
	if( not UnitIsEnemy("player", unit) or not UnitCanAttack("player", unit) ) then
		return
	end
	
	local destName = UnitName(unit)
	local destGUID = UnitGUID(unit)

	local id = 0
	while( true ) do
		id = id + 1
		local name, rank, texture, count, debuffType, duration, endTime, caster, isStealable = UnitDebuff(unit, id)
		if( not name ) then break end

		local spellID = self.spellNames[name .. (rank or "")]
		if( duration and endTime and spellID ) then
			self:FoundAccurateTimer(spellID, name, destName, destGUID, duration, endTime - GetTime(), caster)
		end
	end
end

function CCTracker:UPDATE_MOUSEOVER_UNIT(event)
	self:ScanUnit("mouseover")
end

function CCTracker:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function CCTracker:PLAYER_TARGET_CHANGED(event, unit)
	self:ScanUnit("target")
end

function CCTracker:UNIT_AURA(event, unit)
	self:ScanUnit(unit)
end

-- Catch syncs
function CCTracker:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( prefix == "PCCT2" and author ~= playerName ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType == "GAIN" ) then
			local spellID, spellName, destName, destGUID, duration, timeLeft, playerType = string.split(",", data)
			self:FoundTimer(spellID, spellName, destName, destGUID, tonumber(duration), tonumber(timeLeft), playerType or "enemy")
		end
	end
end

-- See if we should enable this in this zone
function CCTracker:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		-- Check if it's supposed to be enabled in this zone
		if( self.db.profile.inside[type] ) then
			self:OnEnable()
		else
			for _, group in pairs(self.anchors) do
				group:UnregisterAllBars()
			end

			self:OnDisable()
		end
	end
		
	instanceType = type
end

function CCTracker:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

function CCTracker:SendMessage(msg)
	SendAddonMessage("PCCT2", msg, "RAID")
end

function CCTracker:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99CC Tracker|r: " .. msg)
end

-- Reload mod
function CCTracker:Reload()
	self:OnDisable()
	self:OnEnable()

	for name, group in pairs(self.anchors) do
		local config = self.db.profile.anchors[name]
		group:SetScale(config.scale)
		group:SetWidth(config.width)
		group:SetDisplayGroup(config.redirectTo ~= "" and config.redirectTo or nil)
		group:SetAnchorVisible(self.db.profile.showAnchor)
		group:SetBarGrowth(config.growUp and "UP" or "DOWN")
		group:SetMaxBars(config.maxRows)
		group:SetFont(SML:Fetch(SML.MediaType.FONT, config.fontName), config.fontSize)
		group:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, config.texture))
		group:SetFadeTime(config.fadeTime)
		group:SetIconPosition(config.icon)
	end
end

-- Manage GTB group
function CCTracker:OnBarMove(parent, x, y)
	local type = parent.name == "CC Tracker (Enemy)" and "enemy" or "friendly"
	
	if( not CCTracker.db.profile.position[type] ) then
		CCTracker.db.profile.position[type] = {}
	end
	
	CCTracker.db.profile.position[type].x = x
	CCTracker.db.profile.position[type].y = y
end

function CCTracker:MediaRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR ) then
		for name, config in pairs(CCTracker.db.profile.anchors) do
			if( CCTracker.anchors[name] and config.texture == key ) then
				CCTracker.anchors[name]:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, config.texture))
			end
		end
	elseif( mediaType == SML.MediaType.FONT ) then
		for name, config in pairs(CCTracker.db.profile.anchors) do
			if( CCTracker.anchors[name] and config.fontName == key ) then
				CCTracker.anchors[name]:SetFont(SML:Fetch(SML.MediaType.FONT, config.fontName), config.fontSize)
			end
		end
	end
end

-- Create anchor
function CCTracker:CreateAnchor(name, type)
	local config = self.db.profile.anchors[type]
	
	local group = GTBLib:RegisterGroup(name, SML:Fetch(SML.MediaType.STATUSBAR, config.texture))
	group:RegisterOnMove(self, "OnBarMove")
	group:SetScale(config.scale)
	group:SetWidth(config.width)
	group:SetDisplayGroup(config.redirectTo ~= "" and config.redirectTo or nil)
	group:SetAnchorVisible(self.db.profile.showAnchor)
	group:SetBarGrowth(config.growUp and "UP" or "DOWN")
	group:SetMaxBars(config.maxRows)
	group:SetFont(SML:Fetch(SML.MediaType.FONT, config.fontName), config.fontSize)
	group:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, config.texture))
	group:SetFadeTime(config.fadeTime)
	group:SetIconPosition(config.icon)

	if( self.db.profile.position[type] and self.db.profile.position[type].x and self.db.profile.position[type].y ) then
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position[type].x, self.db.profile.position[type].y)
	end
	
	return group
end
