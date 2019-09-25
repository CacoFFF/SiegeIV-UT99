//=============================================================================
// ECM_TranslocatorEvent.
// ECM Element containing a single translocator teleportation.
//=============================================================================
class ECM_TranslocatorEvent expands ECM_Element;

var float TranslocateTimeStamp;
var vector TranslocateLocation;


event Tick( float DeltaTime)
{
	if ( ECM == None || ECM.LocalPlayer == None )
		Error( "Bad client ECM");
		
	if ( ECM.LocalPlayer.CurrentTimeStamp >= TranslocateTimeStamp )
	{
		bActive = false;
		Destroy();
	}
}


function ClientUpdatePosition( PlayerPawn Client, SavedMove CurrentMove)
{
	local float NextTimeStamp;

	if ( CurrentMove.NextMove != None )
		NextTimeStamp = CurrentMove.NextMove.TimeStamp;
	else
		NextTimeStamp = Level.TimeSeconds;
		
	if ( (TranslocateTimeStamp >= CurrentMove.TimeStamp) && (TranslocateTimeStamp < NextTimeStamp) )
		TranslocateClient( Client);
}


function SetupTranslocation( TranslocatorTarget TT)
{
	local PlayerPawn P;
	local float Ping;
	local vector TmpLocation, TmpVelocity;
	
	P = PlayerPawn(TT.Instigator);
	if ( (P == None) || (P.Role != ROLE_AutonomousProxy) || P.PlayerReplicationInfo == None )
		return;

	TmpLocation = TT.Location;
	TmpVelocity = TT.Velocity;
	Ping = float(P.PlayerReplicationInfo.Ping) * Level.TimeDilation / 1000;
	while ( Ping > 0 )
	{
		TT.AutonomousPhysics( fMin( Ping, 0.1));
		Ping -= 0.1;
	}
	TranslocateTimeStamp = Level.TimeSeconds;
	TranslocateLocation = TT.Location;
	TT.SetLocation( TmpLocation);
	TT.Velocity = TmpVelocity;
	
	if ( TT.Physics == PHYS_None )
		TranslocateLocation.Z += 40;

	TranslocateClient( P);
}

function TranslocateClient( PlayerPawn Client)
{
	if ( Client.Physics == PHYS_Walking )
		Client.SetPhysics( PHYS_Falling);
	AdjustClientLocation( Client, TranslocateLocation);
	Client.Velocity.X = 0;
	Client.Velocity.Y = 0;
}


defaultproperties
{
	bActive=True
}