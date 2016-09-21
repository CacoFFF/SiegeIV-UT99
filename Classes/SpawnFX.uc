//=============================================================================
// SpawnFX.
//=============================================================================
class SpawnFX expands WildcardsFX;

var EffectsPool EffectsPool;

simulated function GetParticles( int Count)
{
	local sgParticle pt;
    local int i;

	for ( i=0; i<Count; i++ )
	{
		pt = EffectsPool.RequestGenericParticle( self, 400);
		if ( pt != None )
			pt.Texture = Texture'RuParticle';
	}
}

auto simulated state ParticleSpawn
{

Begin:
	ForEach AllActors (class'EffectsPool', EffectsPool)
		break;
	Spawn(class'ForceFieldFlash');
	if ( EffectsPool == None )
		Stop;
	GetParticles( 6 + class'SiegeStatics'.static.GetDetailMode(Level)*2);
	Sleep( 0.05);
	GetParticles( 6 + class'SiegeStatics'.static.GetDetailMode(Level)*2);
	Sleep( 0.05);
	GetParticles( 6 + class'SiegeStatics'.static.GetDetailMode(Level)*2);
	Sleep( 0.05);
	GetParticles( 6 + class'SiegeStatics'.static.GetDetailMode(Level)*2);
	Sleep( 0.05);
}


defaultproperties
{
     DrawType=DT_None
	 LifeSpan=3
}
