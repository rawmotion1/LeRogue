**[LeRogue.lua](https://www.redguides.com/community/resources/lerogue-lua.2676/ "LeRogue.lua")**\
Automate your EverQuest rogue and maximize your DPS. Now works for lvls 85 - 120.

**Who's it for:**\
For people who actively play a (85+) rogue and want to maximize their DPS potential without clicking dozens of buttons and remembering what each one does.

**Motivation:**\
As someone who loves playing a rogue as their main, I wanted a script that would automate 90% of my repetitive tasks without turning me into a bot. Nearly everything in this script used to be part of my ridiculously complex [MQ2React](https://www.redguides.com/community/resources/mq2react.1599/ "MQ2React") setup. When [LEM](https://www.redguides.com/community/resources/mighty-lua-event-manager.2539/ "(Mighty) Lua Events Manager") came out, I migrated most of my reacts there. But at some point, I had so many conditions that I realized it would be better just to create my own Lua add-on. 

**What makes it different:**\
LeRogue.lua is somewhat similar to using [MQ2Rogue](https://www.redguides.com/community/resources/mq2rogue.1084/ "MQ2Rogue") in manual mode. However, unlike [MQ2Rogue](https://www.redguides.com/community/resources/mq2rogue.1084/ "MQ2Rogue"), LeRogue.lua will **not** assist/chase/navigate or set camps. It's designed for people who prefer to be in the driver's seat. But, if you want, you can use it together with [KissAssist](https://www.redguides.com/wiki/KissAssist "kissassist") to get very similar "mode 1/mode 2" functionality (just be sure to disable DPS and burn options in KA).

**Features:**

**During combat, it will:**

-   Use all your best combat abilities to their fullest
-   Keep rotating your best disciplines
-   Use combat **clickies** you've added (you can add and remove them from combat and burn routines)
-   Burn on command
-   Keep your hate low
-   Keep your endurance up with breather line discs
-   Keep you from dying when you're in trouble with a series of defensive abilities

**During downtime, it will**

-   Keep you hidden, if desired
-   Apply and summon poison, if desired
-   Recast buffs like practiced reflexes

**Dragging corpses**

-   The requires MQ2Nav
-   If auto-drag is enabled and you have a camp set, it will automatically find and drag corpses whenever a group member dies
-   First, it will try to drag to your [Kissassist](https://www.redguides.com/wiki/KissAssist "kissassist") camp
-   If you don't have one, it will drag to your campfire
-   If you don't have a KA camp or campfire set, auto-drag won't do anything
-   You can also manually issue a drag command on any player or player corpse\

**Commands:**\
Virtually everything is configurable via the GUI, but the following commands can be useful:\
`/lua run lerogue /lua stop lerogue`

`/lr pause` --- toggles pause\
`/lr pause on/off` --- explicitly turns pause on or off

`/lr combat on/off` --- enables/disables combat abilities\
`/lr disc on/off` --- enables/disables rotating discs\
`/lr dot on/off` --- enables/disables DoTs

`/lr hide on/off` --- enables/disables auto hide/sneak\
`/lr pausehide x` --- makes you visible and pauses autohide for x seconds

`/lr stayalive on/off` --- when on, will use a series of defensive abilities to keep you from dying

`/lr glyph on/off` --- use power glyph during burn\
`/lr burn` --- do a big burn\
`/lr burnalways on/off` --- do big burn whenever you're in combat

`/lr addclicky combat` --- adds a clicky currently on your cursor to your combat routine\
`/lr addclicky burn` --- adds a clicky currently on your cursor to your burn routine\
`/lr removeclicky` --- removes a clicky currently on your cursor from both routines\
`/lr listclickies` --- lists the clickies you've added

`/lr minlevel x` --- change min NPC lvl you'll use combat abilities on (default is 75)

`/lr dragcorpses on/off` --- If you have a camp set, automatically search for and drag group member corpses whenever someone dies\
`/lr dragcorpse (name) or (target)` --- Specify a name, target a player, or target a corpse to drag. They don't have to be a group member. If you don't specify a player, it will look for any group member's corpse.

When dragging corpses, it will first check if you have a [Kissassist](https://www.redguides.com/wiki/KissAssist "kissassist") camp set, then check if you have a campfire set. If you have neither, it will pull corpses back to your current location.

`/lr resetdefaults` --- reset all settings to their default states\
`/lr help` or just `/lr` --- get a list of commands

Settings are saved in `config\LeRogueConfig_toonName.lua`
