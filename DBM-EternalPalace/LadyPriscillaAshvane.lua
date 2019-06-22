local mod	= DBM:NewMod(2354, "DBM-EternalPalace", nil, 1179)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(152236)
mod:SetEncounterID(2304)
mod:SetZone()
--mod:SetHotfixNoticeRev(16950)
--mod:SetMinSyncRevision(16950)
--mod.respawnTime = 29

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
--	"SPELL_CAST_START 297402 297398 297324",
	"SPELL_CAST_SUCCESS 296569 296662 296725 297398 297240 298056",
	"SPELL_AURA_APPLIED 296650 296725 296943 296940 296942 296939 296941 296938",
	"SPELL_AURA_REMOVED 296650 296943 296940 296942 296939 296941 296938",
	"SPELL_PERIODIC_DAMAGE 296752",
	"SPELL_PERIODIC_MISSED 296752"
--	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 297402 or ability.id = 297398 or ability.id = 297324) and type = "begincast"
 or (ability.id = 296569 or ability.id = 296944 or ability.id = 296725 or ability.id = 296662 or ability.id = 297398) and type = "cast"
 or ability.id = 296650 and (type = "applybuff" or type = "removebuff")
 or ability.id = 296943 or ability.id = 296940 or ability.id = 296942 or ability.id = 296939 or ability.id = 296941 or ability.id = 296938
--]]
--TODO< blizzard gutted half the mod by stripping a ton out of combat log. Review other ways to readd stuff with scheduling?
local warnShield						= mod:NewTargetNoFilterAnnounce(296650, 2, nil, nil, nil, nil, nil, 2)
local warnShieldOver					= mod:NewEndAnnounce(296650, 2, nil, nil, nil, nil, nil, 2)
--local warnCoral							= mod:NewCountAnnounce(296555, 2)
local warnCrushingDepths				= mod:NewTargetNoFilterAnnounce(297324, 4)
--local warnUpsurge						= mod:NewSpellAnnounce(298055, 3)

--local specWarnRipplingWave				= mod:NewSpecialWarningCount(296688, nil, nil, nil, 2, 2)
local specWarnCrushingDepths			= mod:NewSpecialWarningMoveAway(297324, nil, nil, nil, 1, 2)
local yellCrushingDepths				= mod:NewYell(297324)
local specWarnCrushingNear				= mod:NewSpecialWarningClose(297324, nil, nil, nil, 1, 2)
local specWarnBarnacleBash				= mod:NewSpecialWarningTaunt(296725, nil, nil, nil, 1, 2)
local specWarnArcingAzerite				= mod:NewSpecialWarningYouPos(296944, nil, nil, nil, 3)--, 9
local yellArcingAzerite					= mod:NewPosYell(296944, DBM_CORE_AUTO_YELL_CUSTOM_POSITION)
local yellArcingAzeriteFades			= mod:NewIconFadesYell(296944)
local specWarnGTFO						= mod:NewSpecialWarningGTFO(296752, nil, nil, nil, 1, 8)

--mod:AddTimerLine(BOSS)
--local timerCoralGrowthCD				= mod:NewCDCountTimer(30, 296555, nil, nil, nil, 3, nil, nil, nil, 1, 4)
local timerRipplingwaveCD				= mod:NewCDCountTimer(32.2, 296688, nil, nil, nil, 3, nil, nil, nil, 3, 4)
local timerCrushingDepthsCD				= mod:NewCDCountTimer(15, 297324, nil, nil, nil, 3, nil, DBM_CORE_TANK_ICON..DBM_CORE_DAMAGE_ICON, nil, 2, 4)
--local timerUpsurgeCD					= mod:NewCDTimer(15.3, 298055, nil, nil, nil, 3)
local timerBarnacleBashCD				= mod:NewCDCountTimer(15, 296725, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON, nil, mod:IsTank() and 2, 4)
--Stage 2
local timerArcingAzeriteCD				= mod:NewCDCountTimer(39, 296944, nil, nil, nil, 3, nil, nil, nil, 3, 4)
local timerShieldCD						= mod:NewCDTimer(66.1, 296650, nil, nil, nil, 6, nil, nil, nil, 1, 4)

--local berserkTimer					= mod:NewBerserkTimer(600)

mod:AddRangeFrameOption("4/12")
mod:AddInfoFrameOption(296650, true)
--mod:AddSetIconOption("SetIconOnArcingAzerite", 296944, true)

mod.vb.coralGrowth = 0
mod.vb.ripplingWave = 0
mod.vb.spellPicker = 0
mod.vb.arcingCast = 0
mod.vb.blueone, mod.vb.bluetwo = nil, nil
mod.vb.redone, mod.vb.redtwo = nil, nil
mod.vb.greenone, mod.vb.greentwo = nil, nil

local updateInfoFrame
do
	local lines = {}
	local sortedLines = {}
	local function addLine(key, value)
		-- sort by insertion order
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end
	updateInfoFrame = function()
		table.wipe(lines)
		table.wipe(sortedLines)
		if mod.vb.blueone and mod.vb.bluetwo then
			addLine("|TInterface\\Icons\\Ability_Bossashvane_Icon03.blp:12:12|tBlue|"..mod.vb.blueone, mod.vb.bluetwo)
		end
		if mod.vb.redone and mod.vb.redtwo then
			addLine("|TInterface\\Icons\\Ability_Bossashvane_Icon02.blp:12:12|tRed|"..mod.vb.redone, mod.vb.redtwo)
		end
		if mod.vb.greenone and mod.vb.greentwo then
			addLine("|TInterface\\Icons\\Ability_Bossashvane_Icon01.blp:12:12|tGreen|"..mod.vb.greenone, mod.vb.greentwo)
		end
		return lines, sortedLines
	end
end

function mod:OnCombatStart(delay)
	self.vb.coralGrowth = 0
	self.vb.ripplingWave = 0
	self.vb.spellPicker = 0
	self.vb.arcingCast = 0
	self.vb.blueone, self.vb.bluetwo = nil, nil
	self.vb.redone, self.vb.redtwo = nil, nil
	self.vb.greenone, self.vb.greentwo = nil, nil
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

--[[
function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 297402 or spellId == 297398 or spellId == 297324 then--297398 verified, other two unknown
		--timerCrushingDepthsCD:Start()
	end
end
--]]

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 296569 then
		self.vb.coralGrowth = self.vb.coralGrowth + 1
		--warnCoral:Show(self.vb.coralGrowth)
		--timerCoralGrowthCD:Start(30, self.vb.coralGrowth+1)
	--elseif spellId == 296944 then
	--	timerArcingAzeriteCD:Start()
	elseif spellId == 296725 or spellId == 297398 then
		self.vb.spellPicker = self.vb.spellPicker + 1
		if self.vb.spellPicker == 3 then
			self.vb.spellPicker = 0
			timerBarnacleBashCD:Start(15.9, self.vb.spellPicker+1)
		elseif self.vb.spellPicker == 2 then--Two bash been cast, crushing is next
			timerCrushingDepthsCD:Start(15.9, self.vb.spellPicker+1)
		end
	elseif spellId == 296662 then
		self.vb.ripplingWave = self.vb.ripplingWave + 1
		--specWarnRipplingWave:Show(self.vb.ripplingWave)
		--specWarnRipplingWave:Play("watchwave")
		timerRipplingwaveCD:Start(32.2, self.vb.ripplingWave+1)
	elseif spellId == 297240 then--Shield, slightly delayed to make sure UnitGetTotalAbsorbs returns a value
		if self.Options.InfoFrame then
			DBM.InfoFrame:SetHeader(args.spellName)
			DBM.InfoFrame:Show(2, "enemyabsorb", nil, UnitGetTotalAbsorbs("boss1"), true, "boss1")
		end
	elseif spellId == 298056 then--Upsurge
		warnUpsurge:Show()
		--timerUpsurgeCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 296650 then
		warnShield:Show(args.destName)
		warnShield:Play("phasechange")
		self.vb.coralGrowth = 0
		self.vb.ripplingWave = 0
		self.vb.spellPicker = 0
		--timerUpsurgeCD:Stop()
		timerBarnacleBashCD:Stop()
		timerCrushingDepthsCD:Stop()
		timerArcingAzeriteCD:Stop()
		timerShieldCD:Stop()
		--timerUpsurgeCD:Start(3.1)
		timerBarnacleBashCD:Start(7.3, 1)
		timerRipplingwaveCD:Start(13.5, 1)
		--timerCoralGrowthCD:Start(30.5, 1)
		--timerCrushingDepthsCD:Start(45.2)--Not started here
		if self.Options.RangeFrame then
			if self:IsRanged() then
				DBM.RangeCheck:Show(12)
			else
				DBM.RangeCheck:Show(4)
			end
		end
	elseif spellId == 296725 then
		if not args:IsPlayer() then
			specWarnBarnacleBash:Show(args.destName)
			specWarnBarnacleBash:Play("tauntboss")
		end
	elseif spellId == 296943 or spellId == 296940 or spellId == 296942 or spellId == 296939 or spellId == 296941 or spellId == 296938 then--Arcing Azerite
		--Not in combat log, blizzard hates combat log
		if self:AntiSpam(5, 1) then
			self.vb.arcingCast = self.vb.arcingCast + 1
			if self.vb.arcingCast == 1 then
				timerArcingAzeriteCD:Start(39, 2)
			end
		end
		if (spellId == 296943 or spellId == 296940) then--Blue
			if args:IsPlayer() then
				specWarnArcingAzerite:Show("|TInterface\\Icons\\Ability_Bossashvane_Icon03.blp:12:12|tBlue|TInterface\\Icons\\Ability_Bossashvane_Icon03.blp:12:12|t")
				--specWarnArcingAzerite:Play("breakcoral")
				yellArcingAzerite:Yell(6, "", 6)
				yellArcingAzeriteFades:Countdown(8, nil, 6)
			end
			if spellId == 296943 then
				self.vb.blueone = args.destName
			else
				self.vb.bluetwo = args.destName
			end
		elseif (spellId == 296942 or spellId == 296939) then--Red
			if args:IsPlayer() then
				specWarnArcingAzerite:Show("|TInterface\\Icons\\Ability_Bossashvane_Icon02.blp:12:12|tRed|TInterface\\Icons\\Ability_Bossashvane_Icon02.blp:12:12|t")
				--specWarnArcingAzerite:Play("breakcoral")
				yellArcingAzerite:Yell(7, "", 7)
				yellArcingAzeriteFades:Countdown(8, nil, 7)
			end
			if spellId == 296942 then
				self.vb.redone = args.destName
			else
				self.vb.redtwo = args.destName
			end
		elseif (spellId == 296941 or spellId == 296938) then--Green/Yellow
			if args:IsPlayer() then
				specWarnArcingAzerite:Show("|TInterface\\Icons\\Ability_Bossashvane_Icon01.blp:12:12|tGreen|TInterface\\Icons\\Ability_Bossashvane_Icon01.blp:12:12|t|")
				--specWarnArcingAzerite:Play("breakcoral")
				yellArcingAzerite:Yell(4, "", 4)
				yellArcingAzeriteFades:Countdown(8, nil, 4)
			end
			if spellId == 296941 then
				self.vb.greenone = args.destName
			else
				self.vb.greentwo = args.destName
			end
		end
		if self.Options.InfoFrame then
			if not DBM.InfoFrame:IsShown() then
				DBM.InfoFrame:SetHeader(args.spellName)
				DBM.InfoFrame:Show(6, "function", updateInfoFrame, false, false, true)
			else
				DBM.InfoFrame:Update()
			end
		end
	elseif spellId == 297397 then
		if args:IsPlayer() then
			specWarnCrushingDepths:Show()
			specWarnCrushingDepths:Play("runout")
			yellCrushingDepths:Yell()
		elseif self:CheckNearby(12, args.destname) then
			specWarnCrushingNear:Show(args.destname)
			specWarnCrushingNear:Play("runaway")
		else
			warnCrushingDepths:Show(args.destname)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 296650 then
		self.vb.spellPicker = 0
		warnShieldOver:Show()
		warnShieldOver:Play("phasechange")
		--timerCoralGrowthCD:Stop()
		timerRipplingwaveCD:Stop()
		timerCrushingDepthsCD:Stop()
		--timerUpsurgeCD:Stop()
		timerBarnacleBashCD:Stop()
		--timerCrushingDepthsCD:Start(2)--Not started here
		timerBarnacleBashCD:Start(8.6, 1)
		timerArcingAzeriteCD:Start(16.6, 1)
		--timerUpsurgeCD:Start(32.6)--Upsurge is cast in this phase, but only event for it is spell_damage. timer is estimation
		timerShieldCD:Start(66.1)
		if self.Options.InfoFrame then
			DBM.InfoFrame:Hide()
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(4)
		end
	elseif spellId == 296943 or spellId == 296940 or spellId == 296942 or spellId == 296939 or spellId == 296941 or spellId == 296938 then--Arcing Azerite
		if args:IsPlayer() then
			yellArcingAzeriteFades:Cancel()
		end
		if (spellId == 296943 or spellId == 296940) then--Blue
			if spellId == 296943 then
				self.vb.blueone = nil
			else
				self.vb.bluetwo = nil
			end
		elseif (spellId == 296942 or spellId == 296939) then--Red
			if spellId == 296942 then
				self.vb.redone = nil
			else
				self.vb.redtwo = nil
			end
		elseif (spellId == 296941 or spellId == 296938) then--Green/Yellow
			if spellId == 296941 then
				self.vb.greenone = nil
			else
				self.vb.greentwo = nil
			end
		end
		if self.Options.InfoFrame then
			DBM.InfoFrame:Update()
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 296752 and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

--[[
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 297437 then--Lady Ashvane Spell Picker
		self.vb.spellPicker = self.vb.spellPicker + 1
		if self.vb.spellPicker == 3 then
			self.vb.spellPicker = 0
			timerBarnacleBashCD:Start(15.9, self.vb.spellPicker+1)
		elseif self.vb.spellPicker == 2 then--Two bash been cast, crushing is next
			timerCrushingDepthsCD:Start(15.9, self.vb.spellPicker+1)
		end
	end
end
--]]
