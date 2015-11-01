//================================================================================
//================================================================================
class sgWallHit expands UT_WallHit;

simulated function SpawnSound ()
{
	if ( (Owner == None) || (Owner.Role != 3) )
		Super.SpawnSound();
}

simulated function SpawnEffects ()
{
	if ( (Owner == None) || (Owner.Role != 3) )
		Super.SpawnEffects();
}

defaultproperties
{
    bOwnerNoSee=True
}
