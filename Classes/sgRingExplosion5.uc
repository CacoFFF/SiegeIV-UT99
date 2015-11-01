//================================================================================
// sgRingExplosion5.
//================================================================================
class sgRingExplosion5 expands UT_RingExplosion5;

simulated function PostBeginPlay()
{
	if ( (Owner == None) || (Owner.Role != 3) )
		Super.PostBeginPlay();
	else
		Destroy();
}

simulated function SpawnExtraEffects()
{
	if ( (Owner == None) || (Owner.Role != 3) )
		Spawn(class'EnergyImpact').RemoteRole = ROLE_None;
	bExtraEffectsSpawned = true;
}

defaultproperties
{
    bOwnerNoSee=True
}
