class KoalasSuperRing extends ut_superring2;

simulated function SpawnExtraEffects()
{
	bExtraEffectsSpawned = true;
	Spawn(class'EnergyImpact');
	Spawn(class'SuperShockExplo').RemoteRole = ROLE_None;
}


defaultproperties
{
bParticles=True
LODBias=1000
DrawScale=4.000000
Texture=Texture'Botpack.MUZZYPULSE'
ScaleGlow=3.0
Style=STY_Translucent
}