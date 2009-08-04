CCTrackerSpells = {
	--[[ DEATH KNIGHTS ]]--
	-- Hungering Cold
	[49203] = 10,

	--[[ PRIESTS ]]--
	-- Shackle Undead
	[9484] = 30,
	[9485] = 40,
	[10955] = 50,

	-- Psychic Scream
	[8122] = 8,
	[8124] = 8,
	[10888] = 8,
	[10890] = 8,
	
	-- Mind Control
	[605] = 60,

	-- Psychic Horror
	[64044] = 3,
	
	--[[ DRUIDS ]]--
	-- Entangling Roots
	[339] = 12,
	[1062] = 15,
	[5195] = 18,
	[5196] = 21,
	[9852] = 24,
	[9853] = 27,
	[26989] = 27,
	[53308] = 27,

	-- Hibernate
	[2637] = 20,
	[18657] = 30,
	[18658] = 40,
	
	-- Cyclone
	[33786] = 6,
	
	--[[ PALADINS ]]--
	-- Turn Evil
	[10326] = 20,
	
	-- Repentance
	[20066] = 60,
	
	-- Hammer of Justice
	[853] = 3,
	[5588] = 4,
	[5589] = 5,
	[10308] = 6,

	--[[ MAGES ]]--
	-- Polymorph
	[118] = 20,
	[12824] = 30,
	[12825] = 40,
	[28272] = 50,
	[28271] = 50,
	[12826] = 50,
	[61305] = 50,
	[61025] = 50,
	[61721] = 50,
	[61780] = 50,
	
	-- Deep Freeze
	[44572] = 5,
		
	--[[ HUNTERS ]]--
	-- Freezing Trap
	[3355] = 30,
	[14308] = 30,
	[14309] = 30,
	
	-- Freezing Arrow
	[60210] = 30,

	-- Scare Beast
	[1513] = 10,
	[14326] = 15,
	[14327] = 20,
	
	-- Wyvern Sting
	[19386] = 12,
	[24132] = 12,
	[24133] = 12,
	[27068] = 12,
	[49011] = 12,
	[49012] = 12,
	
	-- Scatter Shot
	[19503] = 4,
		
	--[[ WARLOCKS ]]--
	-- Banish
	[710] = 20,
	[18647] = 30,
	
	-- Fear
	[5782] = 10,
	[6213] = 15,
	[6215] = 20,
	
	-- Seduction
	[6358] = 15,
	
	-- Howl of Terror
	[5484] = 6,
	[17928] = 8,
	
	-- Death Coil
	[6789] = 3,
	[17925] = 3,
	[17926] = 3,
	[27223] = 3,
	[47859] = 3,
	[47860] = 3,
	
	--[[ SHAMANS ]]--
	-- Hex
	[51514] = 30,	

	--[[ ROGUES ]]--
	-- Blind
	[2094] = 10,
	
	-- Sap
	[6770] = 25,
	[2070] = 35,
	[11297] = 45,
	[51724] = 60,
	
	--[[ Spells which are only tracked through debuffs ]]--
	-- Cheap Shot
	[1833] = 0,
	
	-- Kidney Shot
	[408] = 0,
	[8643] = 0,
	
	-- Gouge
	[1776] = 0,
	
	-- Pounce
	[9005] = 0,
	[9823] = 0,
	[9827] = 0,
	[27006] = 0,
	[49803] = 0,
	
	-- Maim
	[22570] = 0,
	[49802] = 0,
}

-- Spells that cap at 6 seconds, not 10 in PVP
CCTrackerCaps = {
	-- Wyvern sting
	[19386] = 6,
	[24132] = 6,
	[24133] = 6,
	[27068] = 6,
	[49011] = 6,
	[49012] = 6,
	
	-- Repentance
	[20066] = 6,

	-- Banish
	[710] = 6,
	[18647] = 6,
}