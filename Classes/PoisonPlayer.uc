//=============================================================================
// PoisonPlayer.
// Higor: 100% reliable now, more optimized too.
//=============================================================================
class PoisonPlayer expands WildcardsPlayerAffecters;

var() float Slowness;
var() float RecoverRate;
var int choice;
var AnimatedSprite FX;
var Pawn PoisonedPlayer;

replication
{
	reliable if ( Role==ROLE_Authority )
		PoisonedPlayer, RecoverRate, Slowness;
}

simulated event BeginPlay()
{
    SetTimer(0.125,true);
	if ( PoisonedPlayer == none )
		return;
	PoisonedPlayer.GroundSpeed = PoisonedPlayer.default.GroundSpeed/Slowness;
 	//PoisonedPlayer.WaterSpeed = PoisonedPlayer.default.WaterSpeed/Slowness;
	PoisonedPlayer.AirSpeed = PoisonedPlayer.default.AirSpeed/Slowness;
}

simulated function timer()
{
	if ( (Slowness > 1) && (PoisonedPlayer != None) && !PoisonedPlayer.bDeleteMe )
	{
		if (PoisonedPlayer.Health <= 0)
			destroy();
	}
	else
		destroy();

	if ( bDeleteMe )
		return;

	if ( PlayerPawn(PoisonedPlayer) != None )
	{
		choice = Rand(32);
		if ( choice == 0 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough01',,4.0);
		}
		if ( choice == 1 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough02',,4.0);
		}
		if ( choice == 2 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough03',,4.0);
		}
		if ( choice == 3 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough04',,4.0);
		}
	}

	Slowness -= RecoverRate;
	PoisonedPlayer.GroundSpeed = PoisonedPlayer.default.GroundSpeed/Slowness;
	//PoisonedPlayer.WaterSpeed = PoisonedPlayer.default.WaterSpeed/Slowness;
	PoisonedPlayer.AirSpeed = PoisonedPlayer.default.AirSpeed/Slowness;
}

simulated event Destroyed()
{
	if ( PoisonedPlayer != none )
	{
		PoisonedPlayer.GroundSpeed = PoisonedPlayer.default.GroundSpeed;		
		PoisonedPlayer.AirSpeed = PoisonedPlayer.default.AirSpeed;
	}
}

defaultproperties
{
     Slowness=4.000000
     LifeSpan=10.0
     RecoverRate=0.125000
     bHidden=True
     bAlwaysRelevant=True
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
     Style=STY_Translucent
     Texture=Texture'ToxicCloud015'
}
