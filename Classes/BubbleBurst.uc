// Imported from UPak

class BubbleBurst expands Bubble;


simulated function BeginPlay()
{
	Super.BeginPlay();
	PlaySound( EffectSound2 ); 
	LifeSpan = 10 * FRand();

	if ( FRand() < 0.3 )
		Texture = texture'S_Bubble2';
	else if ( FRand() < 0.3 )
 		Texture = texture'S_Bubble3';

	LoopAnim( 'Flying', 0.6 );
        if( Pawn( Owner ) != none )
                Velocity = 60 * Vector( Pawn( Owner ).ViewRotation ) + vect( 0, 0, 50 );
        else
     	   Velocity = 60 * vect( 0, 0, 60 );
}

simulated function ZoneChange( Zoneinfo NewZone )
{
	if ( !NewZone.bWaterZone )
		Destroy();
}

defaultproperties
{
    Physics=6
    LifeSpan=140.00
    Buoyancy=3.75
}