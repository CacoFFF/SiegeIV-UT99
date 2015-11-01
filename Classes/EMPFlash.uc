//=============================================================================
// EMPFlash
//=============================================================================
class EMPFlash extends Effects;

simulated function Tick(float deltaTime)
{
	DrawScale = default.DrawScale * LifeSpan / default.LifeSpan;
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=4.000000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'Botpack.ASMDEX_A00'
     DrawScale=80.00000
	 SpriteProjForward=320.000000
     ScaleGlow=3.000000
     AmbientGlow=255
     bUnlit=True
}
