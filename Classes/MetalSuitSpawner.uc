//=============================================================================
// MetalSuitSpawner.
//=============================================================================
class MetalSuitSpawner expands WildcardsSpawners;

defaultproperties
{
     MinutesBeforeFirstSpawn=10
     SecondsBeforeRespawn=120.000000
     ItemToSpawn=Class'WildcardsMetalSuit'
     SpawnEffect=Class'SpawnFX'
     RespawnSound=Sound'PickUpRespawn'
}
