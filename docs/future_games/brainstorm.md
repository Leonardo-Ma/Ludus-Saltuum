## Brainstorm

##### What people actually like?
- It seems people like permanent upgrades, here I mean the whole roguelike/roguelite, incremental genres.

##### Game ideas
- Silly car game like [barro](https://store.steampowered.com/app/618140/Barro/)
- Tower defense
- Power fantasy with minigames as stats progression like [return of the saiyans](https://saiyansreturn.com/)
- Voxel? Something similar [Cube World's Alpha](https://store.steampowered.com/app/1128000/Cube_World/)

#### Ambience
- [Youtube: bensmotel What Happened To Video Game Ambience?](https://www.youtube.com/watch?v=lxzWJdYnwLQ)

#### Combat
- Dodge:
	- Player dodge, based on ?dexterity?, after leveled enough becomes a quick teleport instead, leaving an afterimage behind
- Enemies have a random delay between attacks to avoid same pattern


#### Enemy AI & Systemic mechanics

- Enemies and entities should react to stimulus instead of specific events. [Youtube: The Rise of Systemic Games - Game Maker's Toolkit](https://youtu.be/SnpAAX9CkIc?si=kfrU1zWJrXrY1Cr-&t=370)
	- [Youtube: GCAP 2016: Systems Are Everywhere - Aleissia Laidacker](https://youtu.be/Gelpn4mksXQ?si=iZ7F0UjRvHzGbbeW&t=248)
	- Example: Entities have a temperature, when a fire nearby it increases and when it hits a certain temperature it catches fire that also increase temperature further.
	- Example: Enemy being on alert when hears a sound nearby, or an animal gets scared and runs from fire
- Need to find a proper way to document interactions(Maybe a graph view?)
- Enemies also take part in automatic missions and develop themselves with time and somewhat stay balanced considering the player
	- [Youtube: How the Nemesis System Creates Stories - Game Maker's Toolkit](https://www.youtube.com/watch?v=Lm_AzK27mZY)


##### Map
- Map doesn't automatically open upon exploration, need to level cartography that is automatically leveled upon exploration. It increases details on map.

- When opening the map, the player opens the paper on hands, and it doesn't pause the game, like in farcry 2 https://youtu.be/gWNXGfXOrro?si=YxL7e18s4FA7nVr8&t=3245

- When in a higher level area than the character, the player will loudly say "I feel I shouldn't be here".


#### Quests
- When nearby a NPC that have a new quest, they will keep saying: (What variation depends on personality traits that are randomly generated)
    - "I need your aid!"
    - "Please help me!"
    - "Can you do this mission?"
    - "Are you strong enough to help me kiddo?"
- If you approach (Cone 'raycast' check)
    - Opens minimal popup on left side, "Want to check this quest?"
- When agree to check the quest:
    - In a letter like paper, present the exact text that the NPC will say, with an accept or refuse.
- When refusing:
    - Lose general reputation and with this NPC, and with this town

- Quests possibilities (Tier based [F-S]):
    - [F-D]: Fetch at least [x] of these [herbs] on this [location]. (Each herb increases payout and reputation gain in case player grabs more than needed)
    - [D+ to S]: The [specific animal] population nearby has been increasing a lot lately and is getting out of control, go decrease their number.
    - [C to S]: The [specific animal] population nearby has been decreasing a lot lately and may go extinct, go kill their predators.
    - [C- to S]: A fire has started in a nearby forest, go extinguish it.

- Random thunderstorm that may hit a tree and start a generalized fire that triggers a mission to extinguish the fire.
#### Boss
- Ao encontrar um boss, duas falas diferentes dependendo do idioma:
- Portuguese:
    - "Alôôôu! É do posto ipiranga? Sua geladeira tá fria?"
    - [Boss ruge]
    - "Ô satélite! Acho que ele num gosto muito naum"
- English:
    - [Imitate a Grandma]
    - "Hellooooou! Have you seen my granddaughter? She wears a red dress!"
    - [Boss screams]
    - "What a huge teeth you have!"

#### Misc
- For event quests, prompt it by a crow delivery (Like Demon slayer).

- Early game:
	- First 5 minutes the player has very little stamina and can barely run, but it quickly increases stamina and running skills.

	- First jump the player will fall, then get enough experience in jumping so they can jump normally

	- When low mana, it's hard to breath and screen goes gray, as if it drains your life

	- You need to maintain your weapons by doing blacksmith job, or they will break and disappear.

- Every time you press to quit it gives you an offensive different quote (Like from barony)

- Have an in-game feature request to be voted by players, with suggestions from discord.

- After game release if no other priority:
	- Chess
	- Musical instruments
		- Acoustic guitar
		- Drum
	- Television with in game news events from nation

#### Terrain 3D
- Search for world images of a realistic reference before changing the terrain. You can use albedo color and alfa for it
- [Importing and Exporting](https://terrain3d.readthedocs.io/en/stable/docs/import_export.html#importing-exporting-data), Maybe use this to set possibilities for procedural generation?
- To get new textures:
	- https://ambientcg.com/list?type=material&sort=popular
	- [To configure them for Godot:](https://terrain3d.readthedocs.io/en/latest/docs/texture_prep.html#channel-pack-textures-in-terrain3d)
		- Use: 1K-png
		- Save in new folder (scr/terrain/textures/<name_of_texture>) > Unzip only Color + Displacement/height/depth + NormalGl + Roughtness
		- Select one by one and check if import menu matches the other textures
		- Top menu with terrain3d selected > Terrain3d > Pack textures
- For making roads, use spray (v) with strength 100%

- If performance becomes an issue:
	- https://terrain3d.readthedocs.io/en/stable/docs/tips_technical.html#performance
	- Consider unchecking 'high quality' option for all textures to see performance impact

- Possible errors:
	- Terrain3DAssets#7144:_update_texture_files:203: Texture ID 2 albedo format: 19 doesn't match format of first texture: 22. They must be identical. Read Texture Prep in docs.
		- **Import Settings**: Select each texture used in pack in the file system, select Import tab, and verify **Mode** (VRAM Compressed), **Normal Map** (Disabled for albedo), and **High Quality** are identical for all files.

#### Very far future
- Very far future:
	- Trailer:
		- A very long 'movie-like' of the game, presenting most mechanics, large scale battles, attacking settlements, completing quests...
		- 'I used to be an adventurer like you' [He has an arrow on his knee], player stares his knee, draws an arrow to the other knee... [Cuts to him fleeing the scene being pursued]
	- Check if possible to embed the godot engine inside the game, so the player can create both maps and new mechanics from within the game itself
	- Search for youtubers that post content of games of same genre and offer keys and ask for opinion

	- Study:
		- Embed a version system that uses releases tags that can be changed on main menu, that downloads the build of that version and changes to it.

	- Licenses:
		- Consider adding a Business Source License if going 'open source' Maybe [FCL-1.0-ALv2](https://github.com/keygen-sh/fcl.dev/blob/master/FCL-1.0-MIT.md)
		- Consider usage of [reuse-tool](https://github.com/fsfe/reuse-tool) to license each file individually
	- Move code to codeberg and mirror on gitlab
