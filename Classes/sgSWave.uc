//=============================================================================
// sgSWave.
// * Revised by 7DS'Lust
//=============================================================================
class sgSWave extends Effects;

var float ShockSize;
var rotator HitNorm;

event PostBeginPlay()
{
    local PlayerPawn P;

	ForEach RadiusActors (class'PlayerPawn', P, 3000)
		P.ShakeView(0.5, 800000.0/VSize(P.Location - Location), 10);

    HitNorm = Rotation;
    RotationRate = RotRand()-RotRand()*1.5;

    if ( Instigator != None )
        MakeNoise(10.0);

    SetTimer(0.1, true);
}

simulated event PostNetBeginPlay()
{
    SetTimer(0.1, true);
}

simulated event Tick( float DeltaTime )
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		ShockSize = FMax(0.1, 100 - 100 * LifeSpan / default.LifeSpan);
		ScaleGlow = Lifespan / default.LifeSpan;
		AmbientGlow = ScaleGlow * 128;
		DrawScale = ShockSize;
	}
}

simulated event Timer()
{
    local rotator   randRot;
    local actor     victim;
	local float     damageScale,
                    dist,
                    moScale;
    local vector    dir;
    local int       i;

    ShockSize = FMax( 0.1, 100 - 100 * LifeSpan / default.LifeSpan);

	if ( Level.NetMode != NM_DedicatedServer )
	{
		for ( i = 0; i < 4+rand(3); i++ )
		{
			randRot = HitNorm;
			randRot.Pitch += Rand(32750)-16375;
			randRot.Roll += Rand(32750)-16375;
			randRot.Yaw += Rand(32750)-16375;
			Spawn(class'sgNukeFlame',,, Location + vector(randRot) * ShockSize * 14.5);
		}
	}

	if ( Role == ROLE_Authority )
		foreach VisibleCollidingActors( class 'Actor', victim, ShockSize*29, Location )
		{
			if ( Pawn(victim) != None || Mover(victim) != None || Projectile(victim) != None )
			{
				dir = Location - victim.Location;
				dist = VSize(dir); 
				dir = normal(dir);
	
				moScale = 1 - dist / (ShockSize*29);
				victim.TakeDamage(moScale*220, Instigator,victim.Location -
					0.5 * (victim.CollisionHeight + victim.CollisionRadius) * dir,
					vect(0,0,0), 'exploded');
			}
		}		
}

defaultproperties
{
     bAlwaysRelevant=True
     Physics=PHYS_Rotating
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=1.900000
     DrawType=DT_Mesh
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.ShockWavem'
     bUnlit=True
     MultiSkins(1)=Texture'sgMedia.GFX.sgSWave'
     bFixedRotationDir=True
}
