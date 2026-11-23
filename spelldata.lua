-- Which abilities this character has. Each line lists its ranks best-first; the
-- character gets the best one they know. Worked out once, when LeRogue starts
-- (restart LeRogue after learning a new rank).

--- @type Mq
local mq = require('mq')

---------------------------- Ability lines ----------------------------

-- Combat abilities
local strike = { 'assault x', 'mayhem', 'shadowstrike', 'blitzstrike', 'fellstrike', 'barrage', 'incursion', 'onslaught', 'battery' }
local stun = { 'ambush xi', 'bamboozle', 'ambuscade', 'bushwhack', 'lie in wait', 'surprise attack', 'beset', 'accost', 'assail', 'ambush' }
local puncture = { 'invidious puncture', 'disorienting puncture', 'vindictive puncture', 'vexatious puncture', 'disassociative puncture' }
local blade = { 'holdout blade Vii', 'veiled blade', 'obfuscated blade', 'cloaked blade', 'secret blade', 'hidden blade', 'holdout blade' }
local distract = { 'misdirection ix', 'trickery', 'beguile', 'cozen', 'diversion', 'disorientation', 'deceit', 'delusion', 'misdirection' }
local vision = { 'thief\'s sight', 'thief\'s vision', 'thief\'s eyes' }
local progressive = { 'reciprocal weapons', 'ecliptic weapons', 'composite weapons', 'dissident weapons', 'dichotomic weapons' }
local dagger = { "Queseris' Dagger" }

-- Debuffs
local mark = { 'easy mark x', 'unsuspecting mark', 'foolish mark', 'naive mark', 'dim-witted mark', 'wide-eyed mark', 'gullible mark', 'simple mark', 'easy mark' }
local pin = { 'pinpoint fault', 'pinpoint defects', 'pinpoint shortcomings', 'pinpoint deficiencies', 'pinpoint liabilities', 'pinpoint flaws', 'pinpoint vitals' }

-- DoTs
local jugular = { 'jugular slash xi', 'jugular hew', 'jugular rend', 'jugular cut', 'jugular strike', 'jugular hack', 'jugular lacerate', 'jugular gash', 'jugular sever' }
local cut = { 'bleed x', 'carve', 'lance', 'slash', 'slice', 'hack', 'gash', 'lacerate', 'wound', 'bleed' }

-- Rotating discs, named by the reuse timer they share
local timerthree = { 'executioner discipline', 'eradicator\'s discipline', 'assassin discipline' }
local timerfour = { 'Twisted Chance Discipline' }
local timerfive = { 'weapon covenant', 'weapon bond', 'weapon affiliation' }
local timersix = { 'Frenzied Stabbing Discipline' }
local timerfourteen = { 'reckless edge discipline', 'ragged edge discipline', 'razor\'s edge discipline' }
local timerfifteen = { 'visaphen discipline', 'crinotoxin discipline', 'exotoxin discipline', 'chelicerae discipline', 'aculeus discipline', 'arcwork discipline', 'aspbleeder discipline' }
local timersixteen = { 'Knifeplay Discipline' }

-- Burn
local toxicblade = { 'toxic blade viii', 'venomous blade', 'netherbian blade', 'drachnid blade', 'skorpikis blade', 'reefcrawler blade', 'asp blade', 'toxic blade' }

-- Other
local calm = { 'breather', 'rest', 'reprieve', 'respite' }
local hiatus = { 'hiatus v', 'convalesce', "night's calming", 'relax', 'hiatus' }
local reflex = { 'practiced reflexes', 'conditioned reflexes' }
local nimble = { 'Nimble Discipline' }

-- AAs (by ID)
local AA = {
	ligamentSlice = 672,
	dot = 670,
	burns = { 3514, 1410, 378, 1506 },
	tumble = 673,
	premonition = 1134,
	escape = 102,
}

---------------------------- Helpers ----------------------------

-- Rank name of the best ability in a line that this character knows, or nil
local function best(line)
	for _, name in ipairs(line) do
		local rank = mq.TLO.Spell(name).RankName()
		if rank and mq.TLO.Me.CombatAbility(rank)() then return rank end
	end
	return nil
end

local function hasAA(id)
	return mq.TLO.Me.AltAbility(id)() ~= nil
end

-- Best known rank of each line, in order, skipping lines the character doesn't have
local function bestOfEach(lines)
	local result = {}
	for _, line in ipairs(lines) do
		local rank = best(line)
		if rank then table.insert(result, rank) end
	end
	return result
end

---------------------------- This character's lists ----------------------------

local spells = {}

spells.myCombatAbilities = bestOfEach({ strike, stun, puncture, blade, distract, vision, progressive, dagger })

spells.myDebuffs = bestOfEach({ mark, pin })
if hasAA(AA.ligamentSlice) then table.insert(spells.myDebuffs, AA.ligamentSlice) end

spells.myDots = bestOfEach({ jugular, cut })
if hasAA(AA.dot) then table.insert(spells.myDots, AA.dot) end

spells.myDiscs = bestOfEach({ timerfour, timerthree, timerfourteen, timersix, timersixteen, timerfifteen, timerfive })

spells.myBurn = {}
for _, id in ipairs(AA.burns) do
	if hasAA(id) then table.insert(spells.myBurn, id) end
end
for _, rank in ipairs(bestOfEach({ toxicblade })) do table.insert(spells.myBurn, rank) end

spells.other = {
	calm = best(calm),
	hiatus = best(hiatus),
	reflex = best(reflex),
	nimble = best(nimble),
	tumble = hasAA(AA.tumble) and AA.tumble or nil,
	premonition = hasAA(AA.premonition) and AA.premonition or nil,
	escape = hasAA(AA.escape) and AA.escape or nil,
}

return spells
