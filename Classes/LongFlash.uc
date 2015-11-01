//=============================================================================
// LongFlash
// by SK
//=============================================================================
class LongFlash extends Effects;

simulated function Tick(float deltaTime)
{
	DrawScale = default.DrawScale * LifeSpan / default.LifeSpan;
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=2.000000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgFlash'
     DrawScale=16.000000
     ScaleGlow=3.000000
     AmbientGlow=255
     bUnlit=True
}