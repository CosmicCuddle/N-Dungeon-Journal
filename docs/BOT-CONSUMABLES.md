# Bot Consumables

**Applies to:** v0.6.2
**Checked against:** Mod-Naxxramas-Core `src/Systems/BotRaidConsumables.cpp` at commit `69a91be` (12 October 2026) and N-MultiBot-Chatless `UI/MultiBotConsumablesUI.lua` at commit `7bc9baa` (11 October 2026)
**Journal files:** `Core.lua` (`SDJ.BOT_CONSUMABLES`, `SDJ.BOT_CONSUMABLES_DEFAULT`, `SDJ:GetBotConsumablesPrep`) and `UI.lua` (`BotHelpBody`, `SDJ:ShowBotConsumablesHelp`)

The journal does not run any bot commands. It only shows what the server's `.bot consumables` command does, so players know which command to type in which instance. The server is the authority. If the module changes, the journal text has to be updated by hand.

## How the three projects fit together

| Project | Role |
| --- | --- |
| [Mod-Naxxramas-Core](https://github.com/CosmicCuddle/Mod-Naxxramas-Core) | Implements `.bot consumables` in `BotRaidConsumables.cpp`: profiles, level caps, role packages, cooldown, aura tracking |
| [N-MultiBot-Chatless](https://github.com/CosmicCuddle/N-MultiBot-Chatless) | Consumables button in the MultiBot bar. Left-click asks for a custom level (1-54); right-click opens a bar with mara, sunken, brd, scholo, stratud, dm, lbrs and ubrs. It sends the command with `SendChatMessage` (SAY). There is no MC button |
| Dungeon Journal | Explains the command on the home-screen Bot Consumables page and in every instance's Preparation tab |

## Where it shows in the journal

- **Home page, Bot Consumables button.** A help page with these sections: What it does, Roles, Who is affected, Levels, Cooldown and refresh, Commands, Tracking, Molten Core, MultiBot addon, Dungeon profiles.
- **Preparation tab of every instance.** A Bot Consumables block at the bottom. The text comes from `SDJ.BOT_CONSUMABLES[<dungeon id>]`; entries without their own text use `SDJ.BOT_CONSUMABLES_DEFAULT` (the custom-level form). That default also appears on the TBC and Wrath stub pages, since they are non-raid dungeons. The server clamps the custom form to 54, so it is of limited use there.

## Commands (as the server parses them)

| Command | What it does | Source (BotRaidConsumables.cpp) |
| --- | --- | --- |
| `.bot consumables <1-54>` | Role package at a custom level, inside a non-raid dungeon only | 3298-3333, 3609-3738 |
| `.bot consumables mara` / `sunken` / `brd` / `scholo` / `stratud` (alias `strat`) / `dm` / `lbrs` / `ubrs` | Named dungeon profile | 3751-3874, 4245-4254 |
| `.bot consumables mc` | Molten Core raid package, inside MC only | 3502-3507, 1128-1158 |
| `.bot consumables status` | Active profile, tracked auras, missing buffs, timed sequences | usage text 3335-3348 |
| `.bot consumables clear` | Removes tracked auras and stops timed sequences | usage text 3335-3348 |
| `.bot consumables debug <profile>` | Debug output for one preparation | 4190-4212 |

## Named dungeon profiles

| Profile | Level cap | Protection potion | Extra | Where you must stand |
| --- | ---: | --- | --- | --- |
| `mara` | 54 | Nature | | Maraudon |
| `sunken` | 54 | Nature | | Sunken Temple |
| `brd` | 60 | Fire | | Blackrock Depths |
| `scholo` | 60 | Shadow | | Scholomance |
| `stratud` / `strat` | 60 | Shadow | | Stratholme, Undead / Service Entrance side |
| `dm` (East) | 60 | Nature | | Dire Maul East; the wing is detected from your position |
| `dm` (West) | 60 | Shadow | | Dire Maul West |
| `dm` (North) | 60 | none | Enhanced extras | Dire Maul North |
| `lbrs` | 60 | none | | Lower Blackrock Spire |
| `ubrs` | 60 | Fire | Enhanced extras | Upper Blackrock Spire |

- Effective level for a named profile is the lower of the bot's level and the cap (3963-3966).
- The protection potion is the Greater version when the bot can use it at its effective level, otherwise the normal one (2255-2297).
- Enhanced extras, each only if usable at the effective level (2299-2377): bandages to 20, Limited Invulnerability Potions to 5, Brilliant Wizard Oil 1 for casters, Brilliant Mana Oil 1 for healers, Instant Poison VI 20 and Deadly Poison IV 20 for rogues.
- If you are not in the right dungeon or wing the command is refused (3916-3918).

There is no named profile for the Living side of Stratholme. Its Preparation tab says to use the custom-level form.

## Custom level form

`.bot consumables <n>` takes a whole number from 1 to 54. It only works inside a non-raid dungeon. Effective level is the lowest of the number you typed, the bot's level and the dungeon's level cap. The dungeon cap comes from the LFG data (target max level, else max level, else target level), falls back to your level, and is never above 54 (2833-2867). Bots must be on the same map.

## Molten Core

`.bot consumables mc` only works on the Molten Core map. Every bot gets a Greater Fire Protection aura and Vanilla stacks of Major Healing Potion (5), Heavy Runecloth Bandage (20) and Limited Invulnerability Potion (5), plus class reagents (1065-1158). Each class and spec then gets its own raid package (1244-1780); the per-class list is on the MC Preparation tab. Weapon stones (Elemental Sharpening Stone for sharp, Dense Weightstone for blunt, picked from the equipped weapon) go to warrior tanks, DPS warriors and Retribution paladins. Juju Flurry is applied three times about 60 seconds apart (898-947). Hunter pets get Juju Power and Juju Might, skipped if there is no pet. Protection paladins and Death Knights are unsupported in MC (2467-2482). A Cache of Mau'ari is supplied for the juju.

## Raids and world bosses without a profile

Onyxia's Lair, Blackwing Lair, Zul'Gurub, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj, Naxxramas, Azuregos, Lord Kazzak and the Emerald Dragons have no profile. The custom-level form is refused there too, because it only works in non-raid dungeons (3618-3626). Their Preparation tabs say this and point to the manual consumables list for that raid.

## Who gets prepared

- If you are in a group or raid, only bots in your group that are inside the right instance or wing (2703-2721).
- If you are not grouped, your own controlled bots inside it. No group is needed.
- Random bots are only prepared when they are in your group (2869-2881). They are never changed globally.
- Leaving the instance clears the profile (4386-4398).
- Death Knights are unsupported. Protection paladins count as tanks in dungeon profiles (1857-1934).

## Role packages (dungeon profiles and the custom form)

- Tank: defense elixir and a Protection scroll. Strength DPS: strength elixir and Strength scroll. Agility DPS: agility elixir and Agility scroll. Healer: intellect or wisdom elixir and Spirit scroll. Caster DPS: a school elixir (shadow, frost or fire, else arcane or wisdom) and Intellect scroll (1936-2137).
- Food: Well Fed tiers by level; at 35 and above Agility DPS gets Grilled Squid and casters and healers get Nightfin Soup (2139-2214).
- Potions: 5 level-appropriate healing potions; mana users also get 5 mana potions (2216-2253).

## Cooldown, refresh and tracking

- A successful preparation starts a 10-minute cooldown for the group. It survives logout. `status` and `clear` are not affected (61-69, 4274-4284, 4440).
- You cannot prepare while dead.
- Running it again refreshes auras with 10 minutes or less left and food with 5 minutes or less left (65-69).
- About every 10 seconds the server checks tracked auras and warns once per missing buff. Scrolls, Greater Stoneshield and Juju Escape do not warn (3080-3125).

## Updating the journal text when the module changes

1. Pull Mod-Naxxramas-Core and diff `src/Systems/BotRaidConsumables.cpp` against the commit named at the top of this file.
2. Check the usage text, `ResolveNamedProfile`, the cap and stack constants, the scope rules and the MC per-class functions.
3. Pull N-MultiBot-Chatless and check the profile bar in `UI/MultiBotConsumablesUI.lua`.
4. Edit `SDJ.BOT_CONSUMABLES` in `Core.lua` and `BotHelpBody` in `UI.lua`. Keep the wording neutral: say a profile does not exist, do not tell the reader what not to do.
5. Update the commit hashes and line numbers in this file, and add a CHANGELOG entry with the old and new text.
