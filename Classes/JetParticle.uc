//=============================================================================
// JetParticle.
//=============================================================================
class JetParticle extends FlameParticle
	transient;

function PostBeginPlay()
{
    Texture = SpriteAnim[int(FRand()*5)];
    DrawScale = 0.6 * (FRand() + 1);
}
