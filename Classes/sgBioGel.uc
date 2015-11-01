//=============================================================================
// sgBioGel.
//=============================================================================
class sgBioGel extends UT_BioGel;

event PostBeginPlay()
{
    SetTimer(4.0, false);
    Super.PostbeginPlay();
}

auto state Flying
{
    function ProcessTouch(Actor other, vector hitLocation)
    {
        if ( sgBioGel(other) == None )
            Super.ProcessTouch(other, hitLocation);
    }
}


function Timer()
{
	local ut_GreenGelPuff f;

	f = spawn(class'ut_GreenGelPuff',,,Location + SurfaceNormal*8); 
	f.numBlobs = numBio;
	if ( numBio > 0 )
		f.SurfaceNormal = SurfaceNormal;	
	PlaySound (MiscSound,,3.0*DrawScale);	
	if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )
		Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
	
	HurtRadius2(damage * Drawscale, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location);
	Destroy();	
}

final function HurtRadius2( float DamageAmount, float DamageRadius, name DamageName, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	
	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		if( Victims != self )
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			if ( (Victims.class == class) && (Victims.Physics == PHYS_Falling) )
				dist *= 0.2;
			dir = dir/dist; 
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			if ( Victims.IsA('sgItemSpawner') )
				damageScale *= 2;
			else if ( Victims.IsA('sgBuilding') )
				damageScale *= 1.2;
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator, 
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageName
			);
		} 
	}
	bHurtEntry = false;
}

defaultproperties
{
     Speed=1000
}
