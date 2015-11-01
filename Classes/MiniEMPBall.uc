//=============================================================================
// MiniEMPBall
//=============================================================================
class MiniEMPBall extends EMPBall;

simulated function Tick(float deltaTime)
{
	DrawScale = 2 + (default.DrawScale - default.DrawScale *
      LifeSpan / default.LifeSpan);
	ScaleGlow = 0.5 * LifeSpan / default.LifeSpan;
	AmbientGlow = 200 * ScaleGlow;
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.700000
     DrawType=DT_Sprite
     Style=STY_Translucent
     DrawScale=5.000000
}
