//=============================================================================
// AnimatedSprite.
//=============================================================================
class AnimatedSprite expands WildcardsFX;

var() texture SpriteFrame[30];
var() int Frames;
var() float AnimationLength;
var int CurrentFrame;

simulated event BeginPlay()
{
	CurrentFrame = 0;
	Texture = SpriteFrame[CurrentFrame];
	SetTimer(AnimationLength/Frames,true);
	if ( class'sgClient'.default.bHighPerformance )
		SetTimer(AnimationLength*0.5/Frames,true);
}

simulated function timer()
{
	if ( ++CurrentFrame >= Frames )
		Destroy();
	else
		Texture = SpriteFrame[CurrentFrame];
}

defaultproperties
{
}
