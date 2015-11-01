//=============================================================================
// JetParticle.
//=============================================================================
class JetParticle extends SpriteBallChild;

#exec OBJ LOAD File=AmbAncient.uax

function PostBeginPlay()
{
    Texture = SpriteAnim[int(FRand()*5)];
    DrawScale = 0.6 * (FRand() + 1);
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
