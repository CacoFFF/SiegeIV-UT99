//================================================================================
// BubbleTrail.
//================================================================================

class BubbleTrail extends Effects;

var float OriginalScale;

simulated function PostBeginPlay()
{
	DrawScale += FRand() * 0.2;
	OriginalScale = DrawScale;
	Velocity = Vect( 0, 0, 1 ) * 80;
}

simulated function ZoneChange( Zoneinfo NewZone )
{
	if ( !NewZone.bWaterZone )
		Destroy();
}



function Tick (float DeltaTime)
{
	if ( FRand() < 0.5  && DrawScale < OriginalScale - 0.25 )
		DrawScale += 0.1;
	else if ( DrawScale > OriginalScale + 0.25 )
		DrawScale -= 0.1;
}

defaultproperties
{
    Physics=6
    LifeSpan=200.00
    DrawType=1
    Style=3
    Texture=Texture'UnrealShare.S_bubble1'
    DrawScale=0.05
    Buoyancy=3.75
}