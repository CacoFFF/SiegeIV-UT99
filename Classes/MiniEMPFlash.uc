//=============================================================================
// EMPFlash
//=============================================================================
class MiniEMPFlash extends EMPFlash;

simulated function Tick(float deltaTime)
{
	DrawScale = default.DrawScale * LifeSpan / default.LifeSpan;
}

defaultproperties
{
     LifeSpan=3.000000
     DrawScale=8.00000
 SpriteProjForward=32.000000
     ScaleGlow=3.000000
}
