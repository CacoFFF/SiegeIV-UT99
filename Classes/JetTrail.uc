//=============================================================================
// JetTrail.
//=============================================================================
class JetTrail extends Effects;

#exec OBJ LOAD FILE="..\Sounds\Extro.uax" PACKAGE=Extro

simulated event PostNetBeginPlay()
{
	Timer();
}

event PostBeginPlay()
{
	Timer();
}

simulated event Timer()
{
	local float rate;
	local JetParticle particle;

	if ( Owner == none )
	{
		Destroy();
		if ( Role == ROLE_Authority )
			AmbientSound = none;
		return;
	}

	if ( Level.bHighDetailMode )
		rate = 0.03;
	else
		rate = 0.1;

	if ( class'sgClient'.default.bHighPerformance )
		rate += 0.2;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		particle = Spawn(class'JetParticle', Self,, Owner.Location + vect(0,0,0.3) * Owner.CollisionHeight - vector(Owner.Rotation) * 20 );
		if ( particle != None )
			particle.Velocity = vector(Owner.Rotation) * vect(-20,-20,0) - vect(0,0,40);
	}

	SetTimer(rate, false);
}

defaultproperties
{
     bNetTemporary=False
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     SoundRadius=60
     SoundVolume=192
     AmbientSound=Sound'Extro.Light5'
}
