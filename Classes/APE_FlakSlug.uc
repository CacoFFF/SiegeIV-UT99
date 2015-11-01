//=============================================================================
// FV_FlakSlug.
// Made by HIGOR
//=============================================================================
class APE_FlakSlug expands flakslug;

var bool bLast;

function Explode(vector HitLocation, vector HitNormal)
{
	local vector start;
	local rotator aRot;

	HurtRadius(damage, 170, 'FlakDeath', MomentumTransfer, HitLocation);	
	start = Location + 12 * HitNormal;
 	Spawn( class'ut_FlameExplosion',,,Start);
	aRot = rotator( vector(rotation)*2 + hitnormal);
	if ( bLast )
		Spawn( class 'flakslug',, '', Start, aRot);
	else if ( FRand() > 0.05 )
		Spawn( class'APE_FlakSlug',, '', Start, aRot).bLast = True;
 	Destroy();
}

defaultproperties
{
}
