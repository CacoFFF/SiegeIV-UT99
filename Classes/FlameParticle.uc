//=============================================================================
// FlameParticle
//=============================================================================
class FlameParticle extends SpriteBallChild
	transient;

function PostBeginPlay()
{
    Texture = SpriteAnim[int(FRand()*5)];
    DrawScale = 1.0 * (FRand() + 1);
}

defaultproperties
{
     bHighDetail=False
     Physics=PHYS_Projectile
     RemoteRole=ROLE_None
     LifeSpan=1.000000
     CollisionRadius=10.000000
     CollisionHeight=10.000000
     bCollideWorld=True
}
