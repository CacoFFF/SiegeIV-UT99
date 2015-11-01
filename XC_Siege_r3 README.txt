Useful mapping resources to Siege and any other mod.
A small description about the insertable actors:
(Any actor not mentioned here shouldn't be added into a map)

There's also a few effect textures in it that might be of use.


--- (Info) SiegeMapInfo
Inserting this actor into a map and setting bRandomizeCores to True will
cause SiegeIV to make cores not appear in their preset order, useful for
randomizing the locations of teams in non symmetric maps.

--- (XC_NotifyActor) XC_BuildFilter
Contains various methods of preventing sgBuildings from being constructed at
certain BSP areas, check actor code for more details on filtering method.
It is recommended to use this as a 'bGlobalNotify=True'

--- (NavigationPoint) XC_CleanPath
Toggle BlockedPath.
If bIsBlocked is on, make sure you set a high ExtraCost as well.
Siege won't spawn RU crystals on these paths.

--- (Mover) XC_CoreAttacher.
This mover will attach any Siege core within 150 uu radius.
It will only try for 20 seconds, and will trigger an event after attaching.

--- XC_InventorySpawner.
Works in a TriggerToggle fashion.
If the item stays too long without being picked up, the spawner will
be able to spawn another one 2 seconds after the pickup.
This spawner will attach the item to an empty InventorySpot marker in a
100 unit radius if present.
Use this to spawn items in Siege, or spawn them in a UT3 fashion.

--- (XC_InventorySpawner) XC_ComplexSpawner
Will add objects randomly and at configurable rates.
Timer factor is the multiplier at which the timer counts down
so increasing it when the number of triggers increases makes the item respawn
a lot faster, making the spawner have a gradually progressive effect.
- Conditions block:
- GAME=gameclass
- ANYGAME=gameclass
If game class loads, then proceed to load item, if item has no DOT in string
then add the gameclass.Package name before the item string
ANYGAME performs wide search, looking for a word or expression in the game name

--- (Teleporter) XC_LinkedNavs.
Dummy collisionless teleporter
All it does is generate a forced connection between two nodes.

--- (Triggers) XC_LiftTrigger.
Trigger is enabled as long as it's lift isn't moving.
This variation doesn't send UnTrigger commands, meaning that movers must not
be used with TriggerControl state.
LiftTag is the associated lift, if bTriggerLift is on, then the lift will
receive a Trigger command on its own.
- bTriggerLift; //Trigger the lift directly (don't do actor search)
- MinDistance; //Don't function if distance below this
- MaxDistance; //Don't function if distance greater than this

--- (Triggers) XC_MultiTrigger_Control.
In order to push an event, all triggers pointing here must be enabled at the time.
Can disable an event given one of the trigger returns to untriggered.

--- (Triggers) XC_PulseCharger.
Pulse gun charger, this trigger needs the pulse gun's alt fire to charge it
Once charged, it will discharge and trigger an event.
It also includes a particle generator to indicate progress.

--- (Triggers) XC_sgB_Trigger.
Detects visible buildings in specified radius, team is optional.
- sgKeyword; //If building class has this string in it, it qualifies
- bToggleMechanics; //Call Trigger instead of UnTrigger on disable

--- (Trigger) XC_TeamTrigger.
Triggers only for the specified team
Continuous mode, ideal for TT_TriggerControl actors and big trigger spots.

--- (Kicker) XC_TargetedKicker.
Kick towards KickDest, using the Z velocity.

--- (Light) XC_TeamLight.
Picks a light hue based on team conditions.
EXCL_PowerNode and EXCL_Projectile are not functional.
- bReturnIfNull; //Return to index 4 if null
- bWhiteIfNull; //255 saturation if null

- XC_MusicController
- XC_PowerNode.
- XC_PowerNodeBase (Triggers).
- XC_NodeTeleporter (Teleporter).
- XC_TeamWall (Mover)
These are advanced actor, only attempt to use them if you manage to
understand the code.

--- XC_NotifyZone
This is a zone that will notify a set of handlers when something enters.
The handlers are the XC_NotifyActor derivates on said zone.

--- XC_NotifyActor.
This processes zone notifications (enter, exit).

--- (XC_NotifyActor) XC_LiftBuilds.
All Siege buildings in this zone will be attached to a lift below them

--- (XC_NotifyActor) XC_MeshFX_Attacher.
Always use this if you're using a core attacher, or a LiftBuilds notify.
Otherwise clients will see 3d models for buildings at erroneous positions.

--- (XC_NotifyActor) XC_PlayerAddVel.
Makes players and their translocators be pushed in a certain velocity