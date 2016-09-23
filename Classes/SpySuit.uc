//=============================================================================
// SpySuit
// Higor: It's trollin' time
//=============================================================================
class SpySuit expands sgSuit;

var byte Spying;

replication
{
	reliable if ( Role==ROLE_Authority )
		Spying;
}

function ApplySkin()
{
	local Pawn P;
	local string SkinName, FaceName;

	P = GetOwner();
	if ( P == none )
		return;

	P.static.GetMultiSkin( P, SkinName, FaceName);
	Spying = PickTeam();
	P.static.SetMultiSkin( P, SkinName, FaceName, Spying );
	if ( sgPRI(P.PlayerReplicationInfo) != none )
		sgPRI(P.PlayerReplicationInfo).bHideIdentify = true;
}

function RemoveSkin()
{
	local pawn P;
	local string SkinName, FaceName;

	P = GetOwner();
	if ( P == none )
		return;

	P.static.GetMultiSkin( P, SkinName, FaceName );
	P.static.SetMultiSkin( P, SkinName, FaceName, P.PlayerReplicationInfo.Team);
	if ( sgPRI(P.PlayerReplicationInfo) != none )
		sgPRI(P.PlayerReplicationInfo).bHideIdentify = false;
	if ( P.Visibility == 7 )
		P.Visibility = 127;
}

//Picks closest enemy core
function byte PickTeam()
{
	local int i, best, switch;
	local byte aTeam;
	local SiegeGI SG;
	local PlayerReplicationInfo aPRI1, aPRI2;
	local Pawn P;
	local Object OptionalObject;
	local class<LocalMessage> Message;


	aPRI1 = Pawn(Owner).PlayerReplicationInfo;
	aTeam = aPRI1.Team;
	SG = SiegeGI(Level.Game);
	best = -1;
	Pawn(Owner).Visibility = 7;

	For ( i=0 ; i<4 ; i++ )
	{
		if ( (i==aTeam) || (SG.Cores[i] == none) )
			continue;
		if ( best < 0 )
			best = i;
		else if ( VSize(SG.Cores[i].Location - Owner.Location) < VSize(SG.Cores[best].Location - Owner.Location) )
			best = i;
	}

	//Pick somebody on the INFILTRATED team
	For ( i=0 ; i<32 ; i++ )
		if ( (SG.GameReplicationInfo.PRIArray[i] != none) && (SG.GameReplicationInfo.PRIArray[i].Team == Best) )
		{
			aPRI2 = SG.GameReplicationInfo.PRIArray[i];
			break;
		}

	Message = class'sgSpyMsg';

	//Broadcast to infiltration (avoid multi-broadcast bug)
	if ( sgPRI(aPRI1) != none && !sgPRI(aPRI1).bHideIdentify )
	{
		for ( P=Level.PawnList; P != None; P=P.nextPawn )
			if ( P.bIsPlayer || P.IsA('MessagingSpectator') )
			{
				if ( (Level.Game != None) && (Level.Game.MessageMutator != None) )
				{
					if ( Level.Game.MessageMutator.MutatorBroadcastLocalizedMessage(none, P, Message, Switch, aPRI1, aPRI2, OptionalObject) )
						P.ReceiveLocalizedMessage( Message, Switch, aPRI1, aPRI2, OptionalObject );
				} else
					P.ReceiveLocalizedMessage( Message, Switch, aPRI1, aPRI2, OptionalObject );
			}
	}

	return best;
}


defaultproperties
{
    PickupMessage="You got the Spy suit"
    RespawnTime=80.00
    PickupSound=Sound'UnrealShare.Pickups.suitsnd'
    RespawnSound=Sound'PickUpRespawn'
    Texture=Texture'RubberSuitSkin'
    Mesh=LodMesh'UnrealI.AsbSuit'
    bNoProtectors=True
}
