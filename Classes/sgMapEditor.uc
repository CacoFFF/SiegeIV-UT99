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
