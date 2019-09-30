//////////////////////////////
// Toxic Grenade
// By Higor

class ToxicGrenade expands sg_Grenade;

var bool bExplodeOnHit;

function Explosion(vector HitLocation)
{
	HurtRadius( damage, 270, MyDamageType, MomentumTransfer, Location );
	Spawn(class'ToxicSpawner');
	Destroy();
}

//Assisted explosion
simulated function HitWall( vector HitNormal, actor Wall )
{
	if ( bExplodeOnHit )
		Explosion( Location + HitNormal);
	else
		Super.HitWall( HitNormal, Wall);
	bExplodeOnHit = true;
}

defaultproperties
{
	ExplodeTime=2.5
	damage=35
	Skin=Texture'Jsg_grenade4'
	MyDamageType=corroded
	MomentumTransfer=16000
}