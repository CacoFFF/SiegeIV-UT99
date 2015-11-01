//=============================================================================
// SpawnFX.
//=============================================================================
class SpawnFX expands WildcardsFX;

simulated event PostBeginPlay()
{
	local rotator randRot;
	local sgParticle pt;
	local float velo;
    local int Particals;

	if ( Level.NetMode != NM_DedicatedServer)
		{
			Spawn(class'ForceFieldFlash');
			for ( Particals = 0; Particals < 50; Particals++ )
				{
					randRot.Pitch += Rand(32768)-16384;
					randRot.Roll += Rand(32768)-16384;
					randRot.Yaw += Rand(32768)-16384;
					velo = rand(400);
					pt = Spawn(class'sgParticle',,, Location+vector(randRot)*velo);
						if ( pt != None )
							{
								pt.Texture = texture'RuParticle';
								pt.Velocity = Normal(Location - pt.Location)*velo;
							}
				}
		}
	SetTimer(10,false);
}

simulated event timer()
{
	destroy();
}

defaultproperties
{
     DrawType=DT_None
}
