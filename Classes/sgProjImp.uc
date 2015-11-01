//=============================================================================
// sgProjImp.
// * Revised by 7DS'Lust
//=============================================================================
class sgProjImp extends Effects;

var XC_ProtProjStorage Store;
var sgProjImp nextImp;
var float GlowTime;

state Inactive
{
	event BeginState()
	{
		bHidden = true;
		nextImp = Store.ImpPool;
		Store.ImpPool = self;
	}
	event EndState()
	{
		if ( Store.ImpPool == self )
		{
			Store.ImpPool = nextImp;
			nextImp = none;
		}
		bHidden = false;
	}
}

state Active
{
	event BeginState()
	{
		GlowTime = default.GlowTime;
	}
	event Tick( float DeltaTime)
	{
		DrawScale = 0.2 + (default.DrawScale - default.DrawScale * 
	      (GlowTime / default.GlowTime));
		ScaleGlow = 2 * (GlowTime / default.GlowTime);
		GlowTime -= DeltaTime;
	}
Begin:
	Sleep( GlowTime);
	GotoState('Inactive');
}

simulated function Tick(float deltaTime)
{
	DrawScale = 0.2 + (default.DrawScale - default.DrawScale * 
      (LifeSpan / default.LifeSpan));
	ScaleGlow = 2 * (LifeSpan / default.LifeSpan);
}

defaultproperties
{
     RemoteRole=ROLE_None
     GlowTime=0.200000
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgProjImp'
     DrawScale=0.800000
     bUnlit=True
     LifeSpan=0
}
