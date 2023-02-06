**[LeRogue.lua](https://www.redguides.com/community/resources/lerogue-lua.2676/ "LeRogue.lua")**\
Automate your rogue and maximize your DPS.

**Who's it for:**\
This Lua script is for people who actively play a rogue and want to maximize their DPS potential without clicking dozens of buttons and remembering what each one does. Note that this is currently for end game (so, for level 120). Perhaps someday I'll work on lower levels too.

**Motivation:**\
As someone who loves playing a rogue as their main, I wanted a script that would automate 90% of my repetitive tasks without turning me into a bot. Nearly everything in this script used to be part of my ridiculously complex [MQ2React](https://www.redguides.com/community/resources/mq2react.1599/ "MQ2React") setup. When [LEM](https://www.redguides.com/community/resources/mighty-lua-event-manager.2539/ "(Mighty) Lua Events Manager") came out, I migrated most of my reacts there. But at some point, I had so many conditions that I realized it would be better just to create my own Lua add-on. This was my first real deep dive into Lua!

**What makes it different:**\
Unlike [MQ2Rogue](https://www.redguides.com/community/resources/mq2rogue.1084/ "MQ2Rogue"), LeRogue.lua will **not** assist/chase/navigate or set camps. It's really for people who prefer to be in their rogue's driver's seat. But, if you want, you can use it together with [KissAssist](https://www.redguides.com/wiki/KissAssist "kissassist") to get very similar functionality (just be sure to disable DPS and burn options in KA).

**Features:**

**During combat, it will:**

-   Use all your best combat abilities to their fullest
-   Keep rotating your best disciplines
-   Use combat **clickies** you've added (yes, you can add and remove them from the script)
-   Burn on command
-   Keep your hate low
-   Keep your endurance up with calming disc
-   Keep you from dying when you're in trouble

**During downtime, it will**

-   Keep you hidden, if desired
-   Apply and summon poison, if desired
-   Recast buffs like practiced reflexes

**Commands:**\
`/lua run lerogue`
`/lua stop lerogue`

`/lr pause` — toggles pause
`/lr pause on/off` — explicitly turns pause on or off

`/lr combat on/off` — enables/disables combat abilities\
`/lr disc on/off` — enables/disables rotating discs\
`/lr dot on/off` — enables/disables DoTs\
`/lr clickies on/off` — enables/disables using clickies in combat

`/lr hide on/off` — enables/disables auto hide/sneak\
`/lr pausehide x` — turn off autohide for x seconds, then resume

`/lr stayalive on/off` — when on, will use a series of defensive abilities to keep you from dying

`/lr glyph on/off` — use power glyph during burn\
`/lr burn` — do a big burn
`/lr burnalways on/of` — do a big burn whenver you're in combat

`/lr addclicky` — adds a clicky currently on your cursor to your combat routine\
`/lr removeclicky` — removes a clicky currently on your cursor from your combat routine\
`/lr listclickies` — lists the clickies you've added

`/lr minlevel x` — change min NPC lvl you'll use combat abilities on (default is 110)

`/lr resetdefaults` — reset all settings to their default states
`/lr help` — get a list of commands

Settings are saved in `config\LeRogueConfig.lua`
