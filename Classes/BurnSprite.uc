//=============================================================================
// BurnSprite.
//=============================================================================
class BurnSprite expands AnimatedSprite;

simulated function timer()
{
	ScaleGlow = sqrt(1 - (float(CurrentFrame) / float(Frames)));
	if ( ++CurrentFrame >= Frames )
		Destroy();
	else
		Texture = SpriteFrame[CurrentFrame];
}

defaultproperties
{
     RemoteRole=ROLE_None
     SpriteFrame(0)=Texture'S_Exp020'
     SpriteFrame(1)=Texture'S_Exp019'
     SpriteFrame(2)=Texture'S_Exp018'
     SpriteFrame(3)=Texture'S_Exp017'
     SpriteFrame(4)=Texture'S_Exp016'
     SpriteFrame(5)=Texture'S_Exp015'
     SpriteFrame(6)=Texture'S_Exp014'
     SpriteFrame(7)=Texture'S_Exp013'
     SpriteFrame(8)=Texture'S_Exp012'
     SpriteFrame(9)=Texture'S_Exp011'
     SpriteFrame(10)=Texture'S_Exp010'
     SpriteFrame(11)=Texture'S_Exp009'
     SpriteFrame(12)=Texture'S_Exp008'
     SpriteFrame(13)=Texture'S_Exp007'
     SpriteFrame(14)=Texture'S_Exp006'
     SpriteFrame(15)=Texture'S_Exp005'
     Frames=16
     AnimationLength=0.600000
     DrawScale=0.8
}