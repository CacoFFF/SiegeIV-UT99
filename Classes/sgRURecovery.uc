//HIGOR: Major edition
//HIGOR: Now with queuers
class sgRURecovery extends SiegeActor;

var bool	bInitialized;
var sgRURecoveryQueuer Active, Inactive;

function RecoverRU( Pawn pp)
{
	local sgRURecoveryQueuer aQ;

	local string sInfo, sCode;
	local int i, k;

	if (pp == none || !pp.bIsPlayer || pp.IsA('Spectator') || pp.PlayerReplicationInfo == none || pp.PlayerReplicationInfo.PlayerName == "Player" )
		return;

	//Bug
	if ( Active != none && Active.LocateFP(sgPRI(pp.PlayerReplicationInfo).PlayerFingerPrint) != none )
		return;
	if ( Inactive != none )
		aQ = Inactive.LocateFP(sgPRI(pp.PlayerReplicationInfo).PlayerFingerPrint);
	if ( aQ == none )
		aQ = Spawn(class'sgRURecoveryQueuer');
	aQ.Setup( pp, self);
}

function ClearTeamRU( byte Team)
{
	local sgRURecoveryQueuer curQ;
	
	For ( curQ=Active ; curQ!=none ; curQ=curQ.nextQ )
		if ( curQ.Team == Team )
			curQ.RU = 0;
}

function AnnounceAll(string sMessage)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( (p.bIsPlayer || p.IsA('MessagingSpectator')) &&
          p.PlayerReplicationInfo != None  )
		    p.ClientMessage(sMessage);
}

defaultproperties
{
    bGameRelevant=True
    RemoteRole=ROLE_None
}
