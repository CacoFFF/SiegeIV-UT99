//=============================================================================
// sgInnerWave.
// * Revised by 7DS'Lust
//=============================================================================
class sgInnerWave extends sgSWave;

event PostBeginPlay()
{
	local Pawn P;

	RotationRate = (RotRand()-RotRand()*2)/2;

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
    local float life;
    life = LifeSpan / default.LifeSpan;
    
    if ( life > 0.5 )
        ShockSize = 20 - 40 * (life - 0.5);
    else if (life < 0.5 )
        ShockSize = 40 * life;

    ScaleGlow = 0;
    AmbientGlow = 0;
    DrawScale = 0;
    LightBrightness = 0;
    LightRadius = 0;
}

event Timer()
{
    local float     life;
    local Actor     victim;
    local float     damageScale,
                    dist,
                    moScale;
    local vector    dir;

    foreach RadiusActors( class 'Actor', victim, ShockSize*29, Location )
    {
        dir = Location - victim.Location;
        dist = VSize(dir); 
        dir = normal(dir); 

        MoScale = ((ShockSize*29)-dist)/(shocksize*29);

        if ( Pawn(victim) != None || Mover(victim) != None )
            victim.TakeDamage(moScale*75, Instigator, victim.Location -
              0.5 * (victim.CollisionHeight + victim.CollisionRadius)*dir,
              vect(0,0,0), 'exploded');
	}		
}

defaultproperties
{
     LifeSpan=0.000000
     ScaleGlow=0.000000
     AmbientGlow=0
     SpriteProjForward=0.000000
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightBrightness=0
     LightHue=0
     LightSaturation=0
     LightRadius=0
}
