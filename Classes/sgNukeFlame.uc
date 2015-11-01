//=============================================================================
// sgNukeFlame.
// * Revised by 7DS'Lust
//=============================================================================
class sgNukeFlame extends Effects;

simulated function Tick(float deltaTime)
{
	DrawScale = 20 + (default.DrawScale - default.DrawScale *
      LifeSpan / default.LifeSpan);
	ScaleGlow = 2 * LifeSpan / default.LifeSpan;
	AmbientGlow = 128 * ScaleGlow;
}

defaultproperties
{
     RemoteRole=ROLE_None
     LifeSpan=0.800000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgNukeFlame'
     DrawScale=50.000000
     AmbientGlow=255
     bUnlit=True
}
