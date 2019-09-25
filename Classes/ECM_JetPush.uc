//=============================================================================
// ECM_JetPush.
// ECM Element containing jetpack push events.
//
// The Jetpack push is delayed after player move, so push must also be applied
// on ClientAdjustPosition.
//=============================================================================
class ECM_JetPush expands ECM_Element;

var JetPack CurJet;

var float PushTimeStamp[20];
var vector ClientPosition[20];
var byte Hover[20];


event Tick( float DeltaTime)
{
	if ( ECM == None || ECM.LocalPlayer == None )
		Error( "Bad client ECM");
	bActive = bActive && HasActivePush();
}


function PushEvent( PlayerPawn P, float ServerOffset)
{
	local int i, Lowest;
	
	if ( (Level.NetMode != NM_Client) || (ECM == None) || (P != ECM.LocalPlayer) )
		return;

	For ( i=i ; i<ArrayCount(Hover) ; i++ )
		if ( PushTimeStamp[i] < PushTimeStamp[Lowest] )
			Lowest = i;

	bActive = true;
	PushTimeStamp[Lowest] = Level.TimeSeconds/* + ServerOffset * 0.5*/;
	ClientPosition[Lowest] = P.Location;
	Hover[Lowest] = byte(P.bRun == 0);
}

function bool HasActivePush()
{
	local int i, Active;

	For ( i=0 ; i<ArrayCount(Hover) ; i++ )
	{
		if ( PushTimeStamp[i] >= ECM.LocalPlayer.CurrentTimeStamp )
			Active++;
		else
			PushTimeStamp[i] = 0;
	}
	return Active > 0;
}




function ClientAdjustPosition( PlayerPawn Client, optional SavedMove NextMove)
{
	if ( NextMove != None )
		ProcessBoost( Client, Client.CurrentTimeStamp, NextMove.TimeStamp);
	else 
		ProcessBoost( Client, Client.CurrentTimeStamp, Level.TimeSeconds);
}

function ClientUpdatePosition( PlayerPawn Client, SavedMove CurrentMove)
{
	if ( CurrentMove.NextMove != None )
		ProcessBoost( Client, CurrentMove.TimeStamp, CurrentMove.NextMove.TimeStamp);
	else
		ProcessBoost( Client, CurrentMove.TimeStamp, Level.TimeSeconds);
}




function ProcessBoost( PlayerPawn Client, float BaseTimeStamp, float BeforeTimeStamp) // [Base,Before)
{
	local int i, Highest;
	local float HighestTimeStamp;
	local bool bOldUpdating, bOldCanTeleport;
	
	if ( CurJet == None || ECM == None || ECM.LocalPlayer == None )
		return;
		
	Highest = -1;
	For ( i=0 ; i<ArrayCount(Hover) ; i++ )
		if ( (PushTimeStamp[i] > 0) && (PushTimeStamp[i] >= BaseTimeStamp) && (PushTimeStamp[i] < BeforeTimeStamp) )
		{
			ECM.LocalPlayer.Velocity = CurJet.PushVel( Hover[i] > 0, true);
			if ( PushTimeStamp[i] > HighestTimeStamp )
			{
				HighestTimeStamp = PushTimeStamp[i];
				Highest = i;
			}
		}
		
		
	if ( Highest >= 0 )
		AdjustClientLocation( Client, Client.Location * 0.8 + ClientPosition[Highest] * 0.2 );
}




defaultproperties
{
    RemoteRole=ROLE_None
    bCollideWorld=False
    bHidden=True
}