// Bridge class between EXM plugin and SiegeIV
// By Higor

class JetPushPool expands Info;

var ViewPort Player;
var JetPack CurJet;
var info EXMPlugin;

var float PushDelta[32];
var byte CrouchPush[32];
var int iPush;

var bool bNextDelta;
var SavedMove CurMove;
var int CurAdj;
var int OldAdj;

var float CurTimeSeconds;
var float AccMoveTimer;

event PostBeginPlay()
{
	SetLocation( vect(30100, 30100, 30100) );
}

event Tick( float DeltaTime)
{
	local int j;
	local SavedMove aMove;

	while ( (j<iPush) && (PushDelta[j] < Player.Actor.CurrentTimeStamp) )
		j++;
	if ( j > 0 )
		PopList(j);

	CurMove = none;

	// Prepare player for next frame
	if ( iPush > 0 )
	{
		class'sg_TouchUtil'.static.SetTouch( Player.Actor, self);
		class'sg_TouchUtil'.static.SetTouch( self, Player.Actor);
	}
}

//This event doesn't appear to be called at all times, this makes it a problem
event UnTouch( Actor Other)
{
	local byte i;
	local int iC;
	
	if ( Other == Player.Actor && (iPush > 0) )
	{
		if ( !Player.Actor.bCanTeleport ) //ClientAdjustPosition
		{
			bNextDelta = true;
			CurAdj = 0;
			OldAdj = 0;
			CurTimeSeconds = Level.TimeSeconds;
			Player.Actor.MoveTimer = 0;
			CurMove = class'SiegeStatics'.static.FindMoveBeyond( Player.Actor, Player.Actor.CurrentTimeStamp);
		}
		else if ( Player.Actor.bUpdating ) //Mandatory
		{
			if ( bNextDelta && CurTimeSeconds != Level.TimeSeconds ) //Activator, frame passed and client is adjusting position
			{
				bNextDelta = false;
				AccMoveTimer = 0;
				CurTimeSeconds = Level.TimeSeconds;
			}
			if ( CurMove != none && CurTimeSeconds == Level.TimeSeconds )
			{
				AccMoveTimer -= CurMove.Delta;
				while ( Player.Actor.MoveTimer < AccMoveTimer )
				{
//					Log( "Skipping:" @ CurMove.Name @ Player.Actor.MoveTimer @ AccMoveTimer );
					CurMove = CurMove.NextMove;
					if ( CurMove == none )
						Goto NOPE;
					AccMoveTimer -= CurMove.Delta;
				}
				if ( CurAdj < iPush )
				{
//					Log("DEBUG_3_HERE: "@CurMove.Name@CurMove.TimeStamp@"vs PushDelta["$CurAdj$"]="$PushDelta[CurAdj]@"Timer:"@AccMoveTimer);
					if ( CurMove.TimeStamp >= PushDelta[CurAdj] )
					{
						PendingTouch = none; //Safety cleanup
						if ( !IsInTouchChain(Player.Actor) )
						{
							PendingTouch = Player.Actor.PendingTouch; //Buffer touch list
							Player.Actor.PendingTouch = self; //Add to first in list
						}
						CurAdj++;
					}
				}
				CurMove = CurMove.NextMove;
				NOPE:
			}
		}
		class'sg_TouchUtil'.static.SetTouch( Other, self);
		class'sg_TouchUtil'.static.SetTouch( self, Other);
	}
}

function AddNewPush( vector PushVel, bool bDuck)
{
	local info I;

	if ( Level.NetMode != NM_Client )
		return;
	if ( iPush < 32 )
	{
		PushDelta[iPush] = Level.TimeSeconds;
		CrouchPush[iPush] = byte(bDuck);
		iPush++;
	}
}

event PostTouch( Actor Other)
{
	local int i;
	local vector NewVel;
	if ( Other != Player.Actor || CurJet == none )
		return;
	For ( i=OldAdj ; i<CurAdj ; i++ )
	{
		NewVel = CurJet.PushVel( bool(CrouchPush[i]) );
//		Log("Altered velocity: "$NewVel@ "from"@  Player.Actor.Velocity );
		Player.Actor.Velocity = NewVel;
	}
	OldAdj = CurAdj;
//	class'sg_TouchUtil'.static.SetTouch( Other, self);
//	class'sg_TouchUtil'.static.SetTouch( self, Other);

	//Allow multiple PendingTouch, since i'm not doing a physics alteration, i will manually call it here
	if ( PendingTouch != none && PendingTouch != self )
	{
		Player.Actor.PendingTouch = PendingTouch;
		PendingTouch = none; //Break up any possible infinite loop
		Player.Actor.PendingTouch.PostTouch( Player.Actor);
	}
}

function bool IsInTouchChain( Actor Other)
{
	local Actor First;

	For ( First=Other ; Other!=None ; Other=Other.PendingTouch )
	{
		if ( Other.PendingTouch == First )
			Other.PendingTouch = None;
		if ( Other == self )
			return true;
	}
}

function PopList( int PopCount)
{
	local int i, j;

	assert( iPush > 0 );
	assert( PopCount > 0);
	assert( PopCount <= iPush);
	iPush -= PopCount;
//	Log("Removing "$PopCount$" pushes from list");
	while ( i < iPush )
	{
		PushDelta[i] = PushDelta[i+PopCount];
		CrouchPush[i] = CrouchPush[i+PopCount];
		i++;
	}
}

defaultproperties
{
    RemoteRole=ROLE_None
    bCollideWorld=False
    bHidden=True
}