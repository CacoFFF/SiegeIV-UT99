Higor
caco_fff@hotmail.com

Basically, SiegeIV gone public.
Other coder's credited in their respective work (class files).

You do NOT need to set any ServerPackages on your server for Siege.
Put the contents from /System folder from this package into your UT's System folder.


The normal game mode is SiegeGI
The FreeBuild siege is FreeSiegeGI
Use RUsPerTeam= to specify the amount of crystals per team
Use bEffBasedRUKill=True to use efficiency based RU per kill reward (nerfs camping).



==============================
Profile system:
==============================
Specify a profile name in SiegeGI.GameProfile and have the appropiate INI file created.
Build rules, core rules, spawner rules will be enforced as of second 0.5 of the game.
The reason of said delay is to allow certain mapvote utilities to edit the GameProfile var.
In the MapVote, add GameProfile=(ini file name, no extension) to create a new profile.
Default: GameProfile=OldSiege
Example: GameProfile=SiegePub


==============================
ImageDrop fixer:
==============================
Setting is reflected in runtime, setting SiegeGI.bDisableIDropFix to true disables it
Should only work with clients running XC_Engine without the default FCollisionHash. (too many crashes without it)


==============================
RemoveGuardian for AdminAlert:
==============================
This module is now built in, you should enable it by setting bUseRemoveGuardian to TRUE in the SiegeGI gametypes
Admin alert will receive a notification about team removal of buildings, useful for moderation.


==============================
Startup options:
==============================
==== Round mode
There are 3 ways to force round mode:
1 - Adding a SiegeMapInfo actor (subclass of Info) with this boolean "bRounds=True", you can script this dummy actor yourself (for mappers)
2 - On test sessions or round-only servers, it can be forced on the URL by adding ?roundmode=1 on the mapswitch command URL, it will last until closed or respecified
3 - Loading the SiegeRounds mutator on a mapvote (for a server with various choices), the mutator won't slow down anything, it self destructs once rounds are set at map start.

==== Base randomizer (not recommended outside of mapping)
1 - Adding a SiegeMapInfo actor (subclass of Info) with this boolean "bRandomizeCores=True", you can script this dummy actor yourself (for mappers) or load it from XC_Siege_r(x) package.
2 - On test sessions can be forced on the URL by adding ?SwapCores=1 on the mapswitch command URL, it will last until closed or respecified


==== Edit mode
On a local game, type MUTATE EDITMODE and the map will restart in edit mode.
In this mode you may specify how bots build.
Priority 4 is for critical builds before attackers start saving RU.
During edit mode, type SAVEBUILDMAP to save the building markers to an INI file.
The EditMode profile is mandatory to run this mode.


==============================
Other utils to check out
Contact me for the private ones
==============================
- AdminAlert - Moderate noobs and griefers removing buildings.
- NetRateMod - Ideal for super high traffic servers (>16 players).
- FerBotz - Test AI, default bots won't work in this gametype.
- CacusTeamBalancer - (Win32 Native) - 4way Siege supporting team balancer, contact Higor.
- LCWeapons - Mod friendly lag compensation, supports Siege weapons as well.
- CacusBetas - Adds extra taunts and interface icons for Male Commando.
- XC_Siege_r3.u - (INCLUDED) - Useful mapping resources for most up to date Siege versions
- NoMapProtection - (INCLUDED) - Load server restricted maps without crashing.
