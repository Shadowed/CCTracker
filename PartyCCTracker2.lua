PartyCC = LibStub("AceAddon-3.0"):NewAddon("PartyCC", "AceEvent-3.0")

local L = PartyCCLocals

local SML, GTBLib, GTBGroup, DRLib
local instanceType, playerName, playerGUID

local activeTimers = {}

-- Trying to be a little more conservative with the DR reset, don't like 18 when basing a spell
-- timer off of as much as I do when basing a DR timer
local DR_RESET_TIME = 16

function PartyCC:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "",
			texture = "BantoBar",
			showAnchor = false,
			showName = false,
			enableSync = true,
			silent = false,
			growUp = true,
			
			disabled = {},
			spells = {},
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("PartyCCDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)

	-- Setup SML
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")

	-- Setup GTB
	GTBLib = LibStub:GetLibrary("GTB-1.0")
	GTBGroup = GTBLib:RegisterGroup("Party CC Tracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterOnMove(self, "OnBarMove")
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	GTBGroup:SetBarGrowth(self.db.profile.growUp and "UP" or "DOWN")

	if( self.db.profile.position ) then
		GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
	end
	
	self.GTB = GTBLib
	self.GTBGroup = GTBGroup
	
	-- Setup DR lib
	DRLib = LibStub("DRData-1.0")
	
	-- Add our spells to the list for disabling
	self.spells = PartyCCSpells
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

function PartyCC:OnEnable()
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

function PartyCC:OnDisable()
	GTBGroup:UnregisterAllBars()

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
function PartyCC:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		if( auraType == "DEBUFF" ) then
			local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER
			
			if( DRLib:GetSpellCategory(spellID) ) then
				debuffGained(spellID, destGUID, isPlayer)
			end
				
			if( PartyCC.spells[spellID] ) then
				PartyCC:FoundInaccurateTimer(spellID, spellName, destName, destGUID, isPlayer)
			end
		end
	
	-- Debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		if( auraType == "DEBUFF" ) then
			if( DRLib:GetSpellCategory(spellID) ) then
				local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER
				debuffFaded(spellID, destGUID, isPlayer)
			end
		
			if( PartyCC.spells[spellID] ) then
				self:DebuffFaded(spellID, destName, destGUID)
			end
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		self:UnitDied(destGUID)
	end
end

-- TIMER TRACKING

-- Unit died, reset our timers on them
function PartyCC:UnitDied(guid)
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
			GTBGroup:UnregisterBar(id)
		end
	end
end

-- Debuff faded
function PartyCC:DebuffFaded(spellID, destName, destGUID)
	local spellName = GetSpellInfo(spellID)
	if( activeTimers[destGUID] and activeTimers[destGUID][spellName] ) then
		GTBGroup:UnregisterBar(activeTimers[destGUID][spellName])
	end
end

-- End result of the timer after any calculations needed are done
function PartyCC:FoundTimer(spellID, spellName, destName, destGUID, duration, timeLeft, isOurs)
	if( isOurs and self.db.profile.enableSync ) then
		self:SendMessage(string.format("GAIN:%s,%s,%s,%s,%s,%s", spellID, spellName, destName, destGUID, duration, timeLeft))
	end
	
	-- Don't show any timers if it's silent, or it's not supposed to be enabled
	if( self.db.profile.silent or self.db.profile.disabled[spellName] ) then
		return
	end

	local icon = select(3, GetSpellInfo(spellID))
	local id = string.format("pcc:%s:%s", spellName, destGUID)
	
	if( not activeTimers[destGUID] ) then
		activeTimers[destGUID] = {}
	end

	activeTimers[destGUID][spellName] = id
	
	-- So we can disable it if needed
	self.db.profile.spells[spellName] = true

	local text
	if( self.db.profile.showName ) then
		text = string.format("%s - %s", destName, spellName)
	else
		text = spellName
	end
	
	GTBGroup:RegisterBar(id, text, timeLeft, duration, icon)
end

-- Timer was found through UnitDebuff, so don't do any pre-calculations
function PartyCC:FoundAccurateTimer(spellID, spellName, destName, destGUID, duration, timeLeft)
	self:FoundTimer(spellID, spellName, destName, destGUID, duration, timeLeft, true)
end

-- Timer was found through the combat log, so perform DR checking to get an "accurate" answer
function PartyCC:FoundInaccurateTimer(spellID, spellName, destName, destGUID, isPlayer)
	local duration = self.spells[spellID]
	-- Cap it at 10 seconds if it's a player, or controlled by a player
	if( isPlayer and duration > 10 ) then
		duration = 10
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
	self:FoundTimer(spellID, spellName, destName, destGUID, nil, duration * diminished)
end

-- Check for accurate timers
function PartyCC:ScanUnit(unit)
	if( not UnitExists(unit) ) then return end
	
	local destName = UnitName(unit)
	local destGUID = UnitGUID(unit)

	local id = 0
	while( true ) do
		id = id + 1
		local name, rank, texture, _, _, startSeconds, timeLeft = UnitDebuff(unit, id)
		if( not name ) then break end

		local spellID = self.spellNames[name .. (rank or "")]
		if( startSeconds and timeLeft and spellID ) then
			self:FoundAccurateTimer(spellID, name, destName, destGUID, startSeconds, timeLeft)
		end
	end
end

function PartyCC:UPDATE_MOUSEOVER_UNIT(event)
	self:ScanUnit("mouseover")
end

function PartyCC:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function PartyCC:PLAYER_TARGET_CHANGED(event, unit)
	self:ScanUnit("target")
end

function PartyCC:UNIT_AURA(event, unit)
	self:ScanUnit(unit)
end

-- Catch syncs
function PartyCC:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( prefix == "PCCT2" and author ~= playerName ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType == "GAIN" ) then
			self:FoundTimer(string.split(",", data))
		end
	end
end

-- See if we should enable this in this zone
function PartyCC:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		-- Check if it's supposed to be enabled in this zone
		if( self.db.profile.inside[type] ) then
			self:OnEnable()
		else
			self:OnDisable()
		end
	end
		
	instanceType = type
end

function PartyCC:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

function PartyCC:SendMessage(msg)
	SendAddonMessage("PCCT2", msg, "RAID")
end

function PartyCC:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PartyCC|r: " .. msg)
end

-- Reload mod
function PartyCC:Reload()
	self:OnDisable()
	self:OnEnable()

	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	GTBGroup:SetBarGrowth(self.db.profie.growUp and "UP" or "DOWN")
end

-- Manage GTB group
function PartyCC:OnBarMove(parent, x, y)
	if( not PartyCC.db.profile.position ) then
		PartyCC.db.profile.position = {}
	end
	
	PartyCC.db.profile.position.x = x
	PartyCC.db.profile.position.y = y
end

function PartyCC:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR and PartyCC.db.profile.texture == key ) then
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	end
end