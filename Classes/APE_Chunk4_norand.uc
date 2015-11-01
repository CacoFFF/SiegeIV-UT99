//=============================================================================
// FV_Chunk4 without randoms stuff
// Made by HIGOR
//=============================================================================
class APE_Chunk4_norand expands APE_Chunk4;

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( !Region.Zone.bWaterZone )
			Trail = Spawn(class'ChunkTrail',self);
		SetTimer(0.1, true);
	}

	Velocity = Vector(Rotation) * Speed;
	if (Region.zone.bWaterZone)
		Velocity *= 0.65;
	Super(Projectile).PostBeginPlay();
}

defaultproperties
{
     speed=3200.000000
     MaxSpeed=3200.000000
     CollisionRadius=3
     CollisionHeight=3
     Damage=18
}
