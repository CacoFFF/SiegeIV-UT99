//=============================================================================
// sgItemSpeed
// nOs*Badger
//=============================================================================

class sgSpeed extends TournamentPickup
    config;

var bool               bActivated;

replication
{
    reliable if ( Role < ROLE_Authority )
        SetSpeed;

    reliable if ( Role == ROLE_Authority )
        ClientActivate, ClientDeactivate,bActivated;
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    bAutoActivate = false;
}

function GiveTo(Pawn other)
{
    Super.GiveTo(other);
    if ( Owner == other )
    {
        if ( PlayerPawn(Owner) != None )
        {
            ClientActivate();
        }
        GotoState('Activated');
    }
}

/*--- Client Functions. -----------------------------------------------------*/

simulated function ClientActivate()
{
    if ( Role == ROLE_Authority )
        return;

    GotoState('Activated');
}

simulated function ClientDeactivate()
{
    if ( Role == ROLE_Authority )
        return;

    GotoState('DeActivated');
}

/*--- Console Functions. ----------------------------------------------------*/

exec function SetSpeed(bool enabled)
{
    if ( enabled )
        GotoState('Activated');
    else
        GotoState('DeActivated');
}


/*-----------------------------------------------------------------------------
 * STATES Activated.
 * --------------------------------------------------------------------------*/


state Activated
{
	function BeginState()
	{

		SetTimer(0.2, True);

		Super.BeginState();


		// Alter player's stats.
		Pawn(Owner).AirControl = 0.65;
		//Pawn(Owner).JumpZ *= 1.1;
		Pawn(Owner).GroundSpeed *= 1.5;
		Pawn(Owner).WaterSpeed *= 1.5;
		Pawn(Owner).AirSpeed *= 1.5;
		Pawn(Owner).Acceleration *= 1.5;

		// Add wind blowing.
		Pawn(Owner).AmbientSound = sound'SpeedWind';
		Pawn(Owner).SoundRadius = 64;
		bActivated=true;
	}

	function EndState()
	{
		local float SpeedScale;
		SetTimer(0.0, False);

		Super.EndState();

		if ( Level.Game.IsA('DeathMatchPlus') && DeathMatchPlus(Level.Game).bMegaSpeed )
			SpeedScale = 1.3;
		else
			SpeedScale = 1.0;

		// Restore player's stats.
		Pawn(Owner).AirControl = DeathMatchPlus(Level.Game).AirControl;
		//Pawn(Owner).JumpZ = Pawn(Owner).Default.JumpZ * Level.Game.PlayerJumpZScaling();
		Pawn(Owner).GroundSpeed = Pawn(Owner).Default.GroundSpeed * SpeedScale;
		Pawn(Owner).WaterSpeed = Pawn(Owner).Default.WaterSpeed * SpeedScale;
		Pawn(Owner).AirSpeed = Pawn(Owner).Default.AirSpeed * SpeedScale;
		Pawn(Owner).Acceleration = Pawn(Owner).Default.Acceleration * SpeedScale;

		// Remove sound.
		Pawn(Owner).AmbientSound = None;
		bActivated=false;
	}
}

state DeActivated
{
}

defaultproperties
{
     bActivatable=True
     bDisplayableInv=True
     PickupMessage="You've got Super Speed!"
     ItemName="Speed"
     RespawnTime=60.000000
     PickupViewMesh=LodMesh'Botpack.ArrowStud'
     Mesh=LodMesh'Botpack.ArrowStud'
     CollisionRadius=15.000000
     CollisionHeight=10.000000
}
