//Modify CTF-Kosov
class sgMapEditor expands SiegeActor;

function EditKosov()
{
	local ZoneInfo Z;
	Z = ZoneInfo( class'SiegeStatics'.static.FindActorCN( self, class'WaterZone', 'WaterZone2'));
	if ( Z != None )
	{
		Z.bPainZone = false;
		Z.DamagePerSec = 0;
	}

	SiegeGI(Level.Game).Cores[1].SetLocation( vect(2456,-2944,-3080) );
}

function EditDeNovo()
{
	local ZoneInfo Z;
	ForEach AllActors (class'ZoneInfo', Z)
		if ( Z.DamagePerSec == 9999 )
			Z.DamagePerSec = 25;
}

function EditKanjar()
{
	local XC_Obstruction Obs;
	
	Spawn( class'XC_Obstruction',,,vect(-32,16,16));
	Spawn( class'XC_Obstruction',,,vect(-480,16,16));
	Spawn( class'XC_Obstruction',,,vect(-160,1520,-112));
	Spawn( class'XC_Obstruction',,,vect(-608,1520,-112));
	Spawn( class'XC_Obstruction',,,vect(-2720,16,-112));
	Spawn( class'XC_Obstruction',,,vect(-3168,16,-112));
	Spawn( class'XC_Obstruction',,,vect(-3296,1520,16));
	Spawn( class'XC_Obstruction',,,vect(-2848,1520,16));

	ForEach AllActors( class'XC_Obstruction', Obs)
	{
		Obs.SetCollisionSize( 4, 48);
		Obs.RemoteRole = ROLE_None;
	}
}

function EditBlackRiverUltimateV5()
{
	local Boulder2 Boulder;
	local WeightedItemSpawner ItemSpawner;
	
	ForEach AllActors( class'Boulder2', Boulder)
		Spawn( class'XC_Obstruction',,,Boulder.Location).SetCollisionSize( Boulder.CollisionRadius, Boulder.CollisionHeight);
		
	ForEach AllActors( class'WeightedItemSpawner', ItemSpawner)
		ItemSpawner.SpawnLocations[ItemSpawner.SpawnLocationCount++] = vect(-2050,11905,-5097);
}


