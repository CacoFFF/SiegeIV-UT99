//=============================================================================
// ECM_AntigravPush.
// ECM Element containing antigravity push events.
//
// The Antigravity push is initiated by a Detach event so it's possible to
// precisely determine it's starting point and instead run checks here.
//=============================================================================
class ECM_AntigravPush expands ECM_Element;

var XC_AntigravityPlatform Controller;
var float StartTimeStamp;
var float EndTimeStamp;

var float LastModify;
var int ModifyCount;

event Tick( float DeltaTime)
{
	if ( ECM == None || ECM.LocalPlayer == None )
		Error( "Bad client ECM");
	bActive = bActive && HasActivePush();
	if ( !bActive )
		Controller = None;
}


function bool HasActivePush()
{
	local float ClientTimeStamp;
	
	if ( Controller != None )
	{
		ClientTimeStamp = ECM.LocalPlayer.CurrentTimeStamp;
		if ( ClientTimeStamp == 0 )
		{
			StartTimeStamp = 0;
			EndTimeStamp = 0;
			return false;
		}
		
		if ( StartTimeStamp > EndTimeStamp ) //Not yet ended!
			return true;
		return EndTimeStamp > ClientTimeStamp;
	}
	return false;
}

function AntigravStart( XC_AntigravityPlatform Platform, PlayerPawn P)
{
	if ( ECM == None || ECM.LocalPlayer != P )
		return;
	bActive = true;
	Controller = Platform;
	StartTimeStamp = Level.TimeSeconds;
	EndTimeStamp = 0;
}

function AntigravEnd( XC_AntigravityPlatform Platform, PlayerPawn P)
{
	if ( ECM == None || ECM.LocalPlayer != P || Controller != Platform )
		return;
	EndTimeStamp = Level.TimeSeconds;
}



function ClientAdjustPosition( PlayerPawn Client, optional SavedMove NextMove)
{
	if ( NextMove != None )
		ProcessAntigrav( Client, Client.CurrentTimeStamp, NextMove.TimeStamp);
	else
		ProcessAntigrav( Client, Client.CurrentTimeStamp, Level.TimeSeconds);
}

function ClientUpdatePosition( PlayerPawn Client, SavedMove CurrentMove)
{
	if ( CurrentMove.NextMove != None )
		ProcessAntigrav( Client, CurrentMove.TimeStamp, CurrentMove.NextMove.TimeStamp);
	else
		ProcessAntigrav( Client, CurrentMove.TimeStamp, Level.TimeSeconds);
}



function ProcessAntigrav( PlayerPawn Client, float StartTime, float EndTime)
{
	if ( (Controller != None) && (Client.Physics == PHYS_Falling) && (StartTimeStamp <= StartTime) && (EndTimeStamp == 0 || EndTimeStamp > EndTime) )
	{
		if ( LastModify != Level.TimeSeconds )
		{
			LastModify = Level.TimeSeconds;
			ModifyCount = 0;
		}
		ModifyCount++;
		Controller.ModifyVelocity( Client, EndTime - StartTime);
	}
}

