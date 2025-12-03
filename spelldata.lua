--- @type Mq
local mq = require('mq')

local spells = {}
spells.myCombatAbilities = {}
spells.myDebuffs = {}
spells.myDots = {}
spells.myDiscs = {}
spells.myBurn = {}
spells.other = {}

local strike = {
    'assault x',
    'mayhem',
    'shadowstrike',
    'blitzstrike',
    'fellstrike',
    'barrage',
    'incursion',
    'onslaught',
    'battery'
}
local stun = {
    'ambush xi',
    'bamboozle',
    'ambuscade',
    'bushwhack',
    'lie in wait',
    'surprise attack',
    'beset',
    'accost',
    'assail',
    'ambush'
}
local puncture = {
    'invidious puncture',
    'disorienting puncture',
    'vindictive puncture',
    'vexatious puncture',
    'disassociative puncture'
}
local blade = {
    'holdout blade Vii',
    'veiled blade',
    'obfuscated blade',
    'cloaked blade',
    'secret blade',
    'hidden blade',
    'holdout blade'
}
local distract = {
    'misdirection ix',
    'trickery',
    'beguile',
    'cozen',
    'diversion',
    'disorientation',
    'deceit',
    'delusion',
    'misdirection'
}
local vision = {
    'thief\'s sight',
    'thief\'s vision',
    'thief\'s eyes'
}
local progressive = {
    'reciprocal weapons',
    'ecliptic weapons',
    'composite weapons',
    'dissident weapons',
    'dichotomic weapons'
}
local mark = {
    'easy mark x',
    'unsuspecting mark',
    'foolish mark',
    'naive mark',
    'dim-witted mark',
    'wide-eyed mark',
    'gullible mark',
    'simple mark',
    'easy mark'
}
local pin = {
    'pinpoint fault',
    'pinpoint defects',
    'pinpoint shortcomings',
    'pinpoint deficiencies',
    'pinpoint liabilities',
    'pinpoint flaws',
    'pinpoint vitals'
}
local jugular = {
    'jugular slash xi',
    'jugular hew',
    'jugular rend',
    'jugular cut',
    'jugular strike',
    'jugular hack',
    'jugular lacerate',
    'jugular gash',
    'jugular sever'
}
local cut = {
    'bleed x',
    'carve',
    'lance',
    'slash',
    'slice',
    'hack',
    'gash',
    'lacerate',
    'wound',
    'bleed'
}
local timerthree = {
    'executioner discipline',
    'eradicator\'s discipline',
    'assassin discipline'
}
local timerfour = 'Twisted Chance Discipline'
local timersix = 'Frenzied Stabbing Discipline'
local timerfive = {
    'weapon covenant',
    'weapon bond',
    'weapon affiliation'
}
local timerfourteen = {
    'reckless edge discipline',
    'ragged edge discipline',
    'razor\'s edge discipline'
}
local timerfifteen = {
    'visaphen discipline',
    'crinotoxin discipline',
    'exotoxin discipline',
    'chelicerae discipline',
    'aculeus discipline',
    'arcwork discipline',
    'aspbleeder discipline'
}
local timersixteen = 'Knifeplay Discipline'
local toxicblade = {
    'toxic blade viii',
    'venomous blade',
    'netherbian blade',
    'drachnid blade',
    'skorpikis blade',
    'reefcrawler blade',
    'asp blade',
    'toxic blade',
}
local calm = {
    'breather',
    'rest',
    'reprieve',
    'respite'
}
local reflex = {
    'practiced reflexes',
    'conditioned reflexes'
}
local nimble = mq.TLO.Spell('Nimble Discipline').RankName()
local tumble = 673
local premonition = 1134
local escape = 102

--Set combat abilities
for _,v in pairs(strike) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(stun) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(puncture) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(blade) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(distract) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(vision) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(progressive) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myCombatAbilities, mq.TLO.Spell(v).RankName()) break end
end
if mq.TLO.Me.AltAbility(1506)() ~= nil then table.insert(spells.myCombatAbilities, 1506) end

--Set debuffs
for _,v in pairs(mark) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDebuffs, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(pin) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDebuffs, mq.TLO.Spell(v).RankName()) break end
end
if mq.TLO.Me.AltAbility(672)() ~= nil then table.insert(spells.myDebuffs, 672) end

--Set DOTs
for _,v in pairs(jugular) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDots, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(cut) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDots, mq.TLO.Spell(v).RankName()) break end
end
if mq.TLO.Me.AltAbility(670)() ~= nil then table.insert(spells.myDots, 670) end

--Set rotating discs
if mq.TLO.Me.CombatAbility(mq.TLO.Spell(timerfour).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(timerfour).RankName()) end
for _,v in pairs(timerthree) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(timerfourteen) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(v).RankName()) break end
end
if mq.TLO.Me.CombatAbility(mq.TLO.Spell(timersix).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(timersix).RankName()) end
if mq.TLO.Me.CombatAbility(mq.TLO.Spell(timersixteen).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(timersixteen).RankName()) end
for _,v in pairs(timerfifteen) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(v).RankName()) break end
end
for _,v in pairs(timerfive) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myDiscs, mq.TLO.Spell(v).RankName()) break end
end

--Set burns
if mq.TLO.Me.AltAbility(3514)() ~= nil then table.insert(spells.myBurn, 3514) end
if mq.TLO.Me.AltAbility(1410)() ~= nil then table.insert(spells.myBurn, 1410) end
if mq.TLO.Me.AltAbility(378)() ~= nil then table.insert(spells.myBurn, 378) end
for _,v in pairs(toxicblade) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then table.insert(spells.myBurn, mq.TLO.Spell(v).RankName()) break end
end

--Set other
for _,v in pairs(calm) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then spells.other.calm = mq.TLO.Spell(v).RankName() break end
end
for _,v in pairs(reflex) do
    if mq.TLO.Me.CombatAbility(mq.TLO.Spell(v).RankName())() then spells.other.reflex = mq.TLO.Spell(v).RankName() break end
end
if mq.TLO.Me.CombatAbility(mq.TLO.Spell(nimble).RankName())() then spells.other.nimble = mq.TLO.Spell(nimble).RankName() end
if mq.TLO.Me.AltAbility(tumble)() ~= nil then spells.other.tumble = tumble end
if mq.TLO.Me.AltAbility(premonition)() ~= nil then spells.other.premonition = premonition end
if mq.TLO.Me.AltAbility(escape)() ~= nil then spells.other.escape = escape end

return spells