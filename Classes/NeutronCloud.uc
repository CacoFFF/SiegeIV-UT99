//=============================================================================
// NeutronCloud
//=============================================================================
class NeutronCloud extends AnimSpriteEffect;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( !Level.bHighDetailMode ) 
		Drawscale = 16;	
    Texture = Default.Texture;
}

defaultproperties
{
     NumFrames=18
     Pause=0.0
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.75
     DrawType=DT_SpriteAnimOnce
     Style=STY_Translucent
     Texture=Texture'MineExplosion001'
     DrawScale=16
     bUnlit=True
     bCorona=False
}
