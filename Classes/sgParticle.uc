//=============================================================================
// sgParticle.
// * Revised by 7DS'Lust
//=============================================================================
class sgParticle extends Effects;

simulated function Tick(float deltaTime)
{
	if ( LifeSpan > default.LifeSpan / 2 )
        DrawScale = default.DrawScale * (default.LifeSpan - LifeSpan) * 2 /
          default.LifeSpan;
	else
        DrawScale = LifeSpan * default.DrawScale * 2 / default.LifeSpan;
	ScaleGlow = 2 - 2 * LifeSpan / default.LifeSpan;
	AmbientGlow = 127 * ScaleGlow;
}

defaultproperties
{
     Physics=PHYS_Projectile
     RemoteRole=ROLE_None
     LifeSpan=1.000000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'SKFlare'
     ScaleGlow=0.000000
     bUnlit=True
}
