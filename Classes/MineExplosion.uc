//=============================================================================
// MineExplosion.
//=============================================================================
class MineExplosion extends AnimSpriteEffect;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( !Level.bHighDetailMode ) 
		Drawscale = 1.9;
	PlaySound (EffectSound1,,12.0,,3000);	
    Texture = Default.Texture;
}

defaultproperties
{
     NumFrames=18
     Pause=0.0
     EffectSound1=Sound'SharpExplosion'
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.75
     DrawType=DT_SpriteAnimOnce
     Style=STY_Translucent
     Texture=Texture'MineExplosion001'
     DrawScale=1
     LightEffect=LE_NonIncidence
     LightRadius=15
     bCorona=False
}
