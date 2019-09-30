//=============================================================================
// NeutronWave
//=============================================================================
class NeutronWave extends Effects;

var float ShockSize;
var rotator HitNorm;

event PostBeginPlay()
{
    local Pawn P;

    for ( P=Level.PawnList; P!=None; P=P.NextPawn )
        if ( P.IsA('PlayerPawn') && VSize(P.Location - Location) < 4096 )
            PlayerPawn(P).ShakeView(0.5, 800000.0/VSize(P.Location - Location),
              10);

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
		ShockSize = 100 - (100 * LifeSpan / default.LifeSpan);
		ScaleGlow = Lifespan / default.LifeSpan;
		AmbientGlow = ScaleGlow * 128;
		DrawScale = ShockSize;
	}
}

simulated event Timer()
{
    local rotator   randRot;
    local actor     victim;
	local float     dist,
                    moScale;
    local vector    dir;
    local int       i;

    ShockSize = 100 - 100 * LifeSpan / default.LifeSpan;

    if ( Level.NetMode != NM_DedicatedServer )
    {
        for ( i = 0; i < 4+rand(3); i++ )
        {
            randRot = HitNorm;
            randRot.Pitch += Rand(32750)-16375;
            randRot.Roll += Rand(32750)-16375;
            randRot.Yaw += Rand(32750)-16375;
        }
    }

    if ( Role == ROLE_Authority )
        foreach VisibleCollidingActors( class 'Actor', victim, ShockSize*29,
          Location )
        {
            dir = Location - victim.Location;
            dist = VSize(dir); 
            dir = normal(dir);

            moScale = 1 - dist / (ShockSize*29);

            if ( Pawn(victim) != None || Mover(victim) != None ||
              sgWarshell(victim) != None )
                victim.TakeDamage(moScale*300, Instigator,victim.Location -
                  0.5 * (victim.CollisionHeight + victim.CollisionRadius) * dir,
                  vect(0,0,0), 'exploded');
	    }
		
	if ( Role == ROLE_Authority )
		foreach RadiusActors( class 'Actor', victim, ShockSize*29,
          Location )
        {
            dir = Location - victim.Location;
            dist = VSize(dir); 
            dir = normal(dir);

            moScale = 1 - dist / (ShockSize*29);

            if ( Pawn(victim) != None || Mover(victim) != None ||
              sgWarshell(victim) != None )
                victim.TakeDamage(moScale*110, Instigator,victim.Location -
                  0.5 * (victim.CollisionHeight + victim.CollisionRadius) * dir,
                  vect(0,0,0), 'exploded');
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
     MultiSkins(1)=Texture'Botpack.TOP'
     bFixedRotationDir=True
}
