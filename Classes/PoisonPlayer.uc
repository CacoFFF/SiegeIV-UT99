//=============================================================================
// PoisonPlayer.
// Higor: rewritten as a XC_MovementAffector
//=============================================================================
class PoisonPlayer expands XC_MovementAffector;

var() float Slowness;
var() float RecoverRate;
var Pawn PoisonedPlayer;
var PlayerReplicationInfo PRI;

replication
{
	reliable if ( Role==ROLE_Authority )
		RecoverRate, Slowness;
}

simulated event BeginPlay()
{
	SetTimer(0.125, True);
	if ( Level.NetMode != NM_Client )
		Register();
}

simulated event PostNetBeginPlay()
{
	if ( Owner != none && Owner.Role == ROLE_AutonomousProxy ) //Only local player
		Register();
}

simulated function Register()
{
	local sgPlayerData PD;
	PoisonedPlayer = Pawn(Owner);
	if ( Level.NetMode == NM_Client )
		PRI = PoisonedPlayer.PlayerReplicationInfo;
	PD = Class'SiegeStatics'.static.GetPlayerData( PoisonedPlayer, true);
	if ( PD != none )
		PD.AddMAffector( self);
}

//Slow as usual if player is slow, slow slightly less if player is too fast
simulated function AffectMovement( float DeltaTime)
{
	local float fSlowness;
	
	if ( PoisonedPlayer == None || PoisonedPlayer.bDeleteMe || PoisonedPlayer.Health <= 0 )
	{
		if ( Role == ROLE_Authority && LifeSpan > 0.01 )
			Destroy();
		return;
	}
	
	fSlowness = Slowness;
	if ( PRI != none )
		fSlowness -= float(PRI.Ping) * 0.001 * Level.TimeDilation * RecoverRate; //Compensate for lag

	if ( fSlowness > 1 )
	{
		fSlowness = 1 / (Slowness*2);
		PoisonedPlayer.GroundSpeed = fMax(PoisonedPlayer.GroundSpeed*2,(PoisonedPlayer.GroundSpeed + PoisonedPlayer.default.GroundSpeed)) * fSlowness;
		PoisonedPlayer.AirSpeed = fMax(PoisonedPlayer.AirSpeed*2,(PoisonedPlayer.AirSpeed + PoisonedPlayer.default.AirSpeed/Slowness)) * fSlowness;
	}

	if ( (Slowness -= DeltaTime*RecoverRate) < 1 )
		Destroy();
}

function Timer()
{
	local int Choice;
	local AnimatedSprite FX;

	if ( (PoisonedPlayer != None) && PoisonedPlayer.bIsPlayer )
	{
		Choice = Rand(32);
		if ( Choice == 0 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough01',,4.0);
		}
		if ( Choice == 1 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough02',,4.0);
		}
		if ( Choice == 2 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough03',,4.0);
		}
		if ( Choice == 3 )
		{
			FX = Spawn(Class'PoisonCloud', Owner, ,PoisonedPlayer.Location);
			FX.DrawScale = 0.5;
			FX.AnimationLength = 1;
			PoisonedPlayer.PlaySound(sound'PoisonCough04',,4.0);
		}
	}
}

defaultproperties
{
     Slowness=3.000000
     LifeSpan=10.0
     RecoverRate=0.30
	 AffectorPriority=2
}
