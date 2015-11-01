//=============================================================================
// sgFlash.
// * Revised by 7DS'Lust
//=============================================================================
class sgFlash extends Effects;

simulated function Tick(float deltaTime)
{
	DrawScale = default.DrawScale * LifeSpan / default.LifeSpan;
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.300000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgFlash'
     DrawScale=1.500000
     ScaleGlow=3.000000
     AmbientGlow=255
     bUnlit=True
}
