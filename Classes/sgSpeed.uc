//=============================================================================
// sgItemSpeed
// nOs*Badger
//=============================================================================

class sgSpeed extends TournamentPickup
    config;

var XC_MA_sgSpeed Affector;
	
replication
{
    reliable if ( Role < ROLE_Authority )
        ToggleSpeed;
}

function PostBeginPlay()
{
	bAutoActivate = false;
	Super.PostBeginPlay();
}

function GiveTo(Pawn other)
{
    Super.GiveTo(other);
    if ( Owner == Other )
        GotoState('Activated');
}

function CheckAffector()
{
	local sgPlayerData PlayerData;

	if ( Affector != None && !Affector.bDeleteMe )
	{
		if ( Affector.Owner != Owner )
			Affector.Destroy();
		return;
	}
	PlayerData = class'SiegeStatics'.static.GetPlayerData( Pawn(Owner));
	if ( PlayerData != None )
	{
		Affector = Spawn( class'XC_MA_sgSpeed', Owner);
		Affector.Item = self;
		PlayerData.AddMAffector( Affector);
	}
}

/*--- Console Functions. ----------------------------------------------------*/

exec function ToggleSpeed()
{
    Activate();
}


/*-----------------------------------------------------------------------------
 * STATES Activated.
 * --------------------------------------------------------------------------*/

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		CheckAffector();
		Owner.AmbientSound = Sound'SpeedWind';
		Owner.SoundRadius = 64;
	}

	function EndState()
	{
		Super.EndState();
		Owner.AmbientSound = None;
		Owner.SoundRadius = Owner.default.SoundRadius;
	}
}

state DeActivated
{
	simulated event BeginState()
	{
		if ( Level.NetMode == NM_Client )
			bActive = false; //For client sim
	}
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
