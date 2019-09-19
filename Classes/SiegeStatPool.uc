//=============================================================================
// SiegeStatPool
// Major serverside stat collector.
//=============================================================================
class SiegeStatPool extends SiegeActor;

var SiegeStatPlayer Active, Inactive;


function SetupPlayer( Pawn Player)
{
	local SiegeStatPlayer Stat;
	local sgPRI PRI;

	local string sInfo, sCode;
	local int i, k;

	if ( Player == none || !Player.bIsPlayer || Player.IsA('Spectator') || Player.PlayerReplicationInfo == none || Player.PlayerReplicationInfo.PlayerName == "Player" )
		return;

	PRI = sgPRI(Player.PlayerReplicationInfo);

	//Bug
	if ( LocateFingerPrint( Active, PRI.PlayerFingerPrint) != None )
		return;

	Stat = LocateFingerPrint( Inactive, PRI.PlayerFingerPrint);
	if ( Stat == none )
		Stat = Spawn(class'SiegeStatPlayer');
	Stat.Setup( Player, self);
}

function ClearTeamRU( byte Team)
{
	local SiegeStatPlayer Stat;
	
	For ( Stat=Active ; Stat!=none ; Stat=Stat.NextStat )
		if ( Stat.Team == Team )
			Stat.RU = 0;
}


function SiegeStatPlayer LocateFingerPrint( SiegeStatPlayer List, string FP)
{
	while ( (List != None) && (List.MyFP != FP) )
		List = List.NextStat;
	return List;
}



defaultproperties
{
    bGameRelevant=True
    RemoteRole=ROLE_None
}
