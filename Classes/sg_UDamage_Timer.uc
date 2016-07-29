//*************************************************
// Fix UDamage charge display
//*************************************************

class sg_UDamage_Timer expands SiegeActor;

var UDamage Item;
var int ItemCharge;

replication
{
	reliable if ( Role == ROLE_Authority )
		Item, ItemCharge;
}

//
// Called after PostBeginPlay.
//
simulated event SetInitialState()
{
	bScriptInitialized = true;
	if( Level.NetMode != NM_Client )
		GotoState( 'ServerOp' );
}

simulated event PostNetBeginPlay()
{
	GotoState( 'ClientOp');
}

state ServerOp
{
Begin:
	if ( PlayerPawn(Owner) != none && ViewPort(PlayerPawn(Owner).Player) != none )
	{
		ItemCharge = Item.Charge;
		GotoState( 'ClientOp');
		Stop;
	}
	Sleep(0.5 * Level.TimeDilation);
	if ( Item != none && !Item.bDeleteMe )
	{
		ItemCharge = Item.Charge;
		RemoteRole = ROLE_SimulatedProxy; //Init replication
	}
	Sleep( Level.TimeDilation);
	Destroy();
}

simulated state ClientOp
{
	simulated event BeginState()
	{
		SetTimer( 0.1, true);
	}
	simulated event Timer()
	{
		if ( Item != none && !Item.bDeleteMe )
			Item.Charge = --ItemCharge;
		if ( ItemCharge <= 0 )
			Destroy();
	}
}


defaultproperties
{
     RemoteRole=ROLE_None
	 bNetTemporary=True
	 LifeSpan=300
}