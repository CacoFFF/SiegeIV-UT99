//=============================================================================
// RubberSuitSpawner.
//=============================================================================
class RubberSuitSpawner expands WildcardsSpawners;

defaultproperties
{
     MinutesBeforeFirstSpawn=7
     SecondsBeforeRespawn=80.000000
     ItemToSpawn=Class'WildcardsRubberSuit'
     SpawnEffect=Class'SpawnFX'
     RespawnSound=Sound'PickUpRespawn'
}
