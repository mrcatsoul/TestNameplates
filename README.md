A micro-experiment with default nameplates.

The goal was to make everything as lightweight as possible, without adding anything extra to the code that could lead to FPS loss, leaving the default frames almost untouched, removing unnecessary clutter, minimizing the screen space occupied by frames, and maximizing information extraction.

No extra frames/textures/texts were created in the code: this should improve performance in crowds. All manipulations were performed on the regions of the original frames. During the experiment, a scaler patch from the respected person Atom was used, as well as his library Awesomewotlk. The only two replacements made on the native regions were the font and the background texture (overlayRegion), from which a border was made. The texture had to be drawn in Photoshop to fit the coordinates, and finding the right coordinates was quite difficult. After setup, I ran through the instances on the test server and everything seems to work fine, but how it will perform in practice, for example, in a 40 vs 40 BG, is still unknown and requires further testing.

The functionality is minimal for now:
0) the main task is completed - the default UI is reduced several times
1) combat state icon in the player name text
2) icon on those who targeted us, in the player name text
3) hiding the health bar and cast bar if health is full for NPCs and friendly players; for friendly/neutral NPCs, it is always hidden if they are not targeted/focused/hovered over/have a mark/casting a mark
4) mobs that attacked us and hostile players who targeted us are highlighted with an orange border
5) nickname abbreviation up to 12 characters maximum
6) nickname color by class
7) removed: level, elite icon, boss icon, edge glow for aggro mobs, hover glow, + 1 unclear region, most likely also useless
7) PlateBuffs/Icicle/VirtualPlates and similar addons may work as well

To Do:
1) options
2) custom marks with display in the texture of the cast/raid mark, when they are "free", and when not, then in the nickname
3) detecting healers, and perhaps even specs, with icons displayed in the nickname, although this is probably nonsense

For those who are going to test this:
1) close WoW, patch wow.exe with a scaler patcher, this may not be easy: different resolutions will require different scaling values; for 16:9 (1920x1080, 1280x720) I used 58, for others, I don't know
2) install the Awesomewotlk library
3) step 1 is mandatory, otherwise there will be a mess of textures + HUGE hitbox from the original size of the nameplate, without step 2, the functionalities from the list: 1, 2, 4, 6 + target edge glow will not work
4) enable Lua errors (Interface->Help->Lua script errors), if something goes wrong, it will be visible, if possible, compare with the default settings in crowds and provide feedback/report, you can even make a video, just out of interest

Links:
Scaler patch: https://mega.nz/file/9AtHmQqa#Y23_Iu9zWJ7XNT1ksnDn3UsWYaQxuuNiTxzzfDhjs4w
Awesomewotlk: https://github.com/FrostAtom/awesome_wotlk
Archive with the experiment, install as a regular addon: https://github.com/mrcatsoul/TestNameplates/archive/refs/heads/main.zip

![video](https://www.youtube.com/watch?v=ce8eZfgMphs)
