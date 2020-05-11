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
		SpawnObstruction( Boulder.Location, Boulder.CollisionRadius, Boulder.CollisionHeight);
		
	ForEach AllActors( class'WeightedItemSpawner', ItemSpawner)
		ItemSpawner.SpawnLocations[ItemSpawner.SpawnLocationCount++] = vect(-2050,11905,-5097);
}

function EditMiniCivilWarV3()
{
	SiegeGI(Level.Game).Cores[1].SetLocation( vect(-27,56,-1146) );
}

function EditClarionSwS()
{
	local XC_Obstruction Obs[3];
	local WeightedItemSpawner ItemSpawner;

	Foreach AllActors( class'WeightedItemSpawner', ItemSpawner)
		break;
	if ( ItemSpawner == None )
	{
		ItemSpawner = Spawn( class'WeightedItemSpawner',,,vect(0,0,1624));
		SiegeGI(Level.Game).SpawnedRandomItemSpawner = true;
	}
	
	Obs[0] = SpawnObstruction( vect(826,-3854,1754), 60, 30);
	Obs[1] = SpawnObstruction( vect(830,-3975,1814), 60, 90);
	Obs[2] = SpawnObstruction( vect(826,-4096,1754), 60, 30);
	InterpolateObstructions( Obs[0], Obs[1], 3);
	InterpolateObstructions( Obs[1], Obs[2], 3);
}



// Utils
function XC_Obstruction SpawnObstruction( vector InLocation, float Radius, float Height)
{
	local XC_Obstruction Result;
	
	Result = Spawn( class'XC_Obstruction',,,InLocation);
	Result.SetCollisionsize( Radius, Height);
	
	return Result;
}

function InterpolateObstructions( XC_Obstruction Start, XC_Obstruction End, int ExtraObstructions)
{
	local int i;
	local float Alpha;
	local vector SpawnLocation;
	local float SpawnRadius, SpawnHeight;

	ExtraObstructions++;
	for ( i=1; i<ExtraObstructions; i++)
	{
		Alpha = float(i) / float(ExtraObstructions);
		SpawnLocation = Start.Location + ((End.Location - Start.Location) * Alpha);
		SpawnRadius = Lerp( Alpha, Start.CollisionRadius, End.CollisionRadius);
		SpawnHeight = Lerp( Alpha, Start.CollisionHeight, End.CollisionHeight);
		SpawnObstruction( SpawnLocation, SpawnRadius, SpawnHeight);
	}
}
