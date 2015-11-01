//Queuer actor for RU recovery
//By Higor

class sgRURecoveryQueuer expands SiegeActor;

var sgRURecovery Master;
var Pawn Player;
var string MyFP; //Quick fingerprint access
var byte Team;

var sgRURecoveryQueuer nextQ;


var float sgInfoCoreKiller, sgInfoCoreRepair, sgInfoBuildingHurt, sgInfoUpgradeRepair;
var int	sgInfoKiller, sgInfoBuildingMaker, sgInfoWarheadMaker, sgInfoWarheadKiller;

var float RU, Score;
var int Deaths;

//TO BE IMPLEMENTED
var int iSeconds;


//Setup always puts the queuer in the Active player list
function Setup( Pawn Other, sgRURecovery aMut)
{
	if ( Other == none || aMut == none )
	{
		Destroy();
		return;
	}
	//DATA ALREADY EXISTS!
	Player = Other;
	if ( Master != none )
		RestoreData();
	else
	{
		Master = aMut;
		MyFP = sgPRI(Player.PlayerReplicationInfo).PlayerFingerPrint;
	}
	GotoState( 'Active');
}

function UpdateData()
{
	local sgPRI aPRI;
	
	aPRI = sgPRI(Player.PlayerReplicationInfo);
	if ( aPRI == none )
		return;
	sgInfoCoreKiller = aPRI.sgInfoCoreKiller;
	sgInfoCoreRepair = aPRI.sgInfoCoreRepair;
	sgInfoBuildingHurt = aPRI.sgInfoBuildingHurt;
	sgInfoUpgradeRepair = aPRI.sgInfoUpgradeRepair;
	sgInfoKiller = aPRI.sgInfoKiller;
	sgInfoBuildingMaker = aPRI.sgInfoBuildingMaker;
	sgInfoWarheadMaker = aPRI.sgInfoWarheadMaker;
	sgInfoWarheadKiller = aPRI.sgInfoWarheadKiller;
	Team = aPRI.Team;
	RU = aPRI.RU;
	Score = aPRI.Score;
	Deaths = aPRI.Deaths;
}

function RestoreData()
{
	local sgPRI ePRI;
	
	ePRI = sgPRI(Player.PlayerReplicationInfo);
	if ( ePRI == none )
		return;
	ePRI.sgInfoCoreKiller = sgInfoCoreKiller;
	ePRI.sgInfoCoreRepair = sgInfoCoreRepair;
	ePRI.sgInfoBuildingHurt = sgInfoBuildingHurt;
	ePRI.sgInfoUpgradeRepair = sgInfoUpgradeRepair;
	ePRI.sgInfoKiller = sgInfoKiller;
	ePRI.sgInfoBuildingMaker = sgInfoBuildingMaker;
	ePRI.sgInfoWarheadMaker = sgInfoWarheadMaker;
	ePRI.sgInfoWarheadKiller = sgInfoWarheadKiller;
	ePRI.RU = RU;
	ePRI.Score = Score;
	ePRI.Deaths = Deaths;
//Announce recovery
	Master.AnnounceAll("Siege RU-Recovery:"@int(RU)@"RU recovered for"@ePRI.PlayerName);

}

state Active
{
	event Tick( float DeltaTime)
	{
		if ( Player == none || Player.bDeleteMe )
		{
			Player = none;
			GotoState('Inactive');
		}
	}
	event BeginState()
	{
		nextQ = Master.Active;
		Master.Active = self;
		Log("DEBUG ENTERED ACTIVE");
	}
	event EndState()
	{
		local sgRURecoveryQueuer aQ;
		
		if ( Master.Active == self )
			Master.Active = nextQ;
		else
		{
			For ( aQ=Master.Active ; aQ.nextQ != none ; aQ=aQ.nextQ )
				if ( aQ.nextQ == self )
				{
					aQ.nextQ = nextQ;
					break;
				}
		}
		nextQ = none;
		Log("DEBUG LEFT ACTIVE");
	}
Begin:
	UpdateData();
	Sleep( 1 + FRand() * Level.TimeDilation);
	Goto('Begin');
}

state InActive
{
	event BeginState()
	{
		nextQ = Master.Inactive;
		Master.Inactive = self;
		Log("DEBUG ENTERED INACTIVE");
	}
	event EndState()
	{
		local sgRURecoveryQueuer aQ;
		
		if ( Master.Inactive == self )
			Master.Inactive = nextQ;
		else
		{
			For ( aQ=Master.Inactive ; aQ.nextQ != none ; aQ=aQ.nextQ )
				if ( aQ.nextQ == self )
				{
					aQ.nextQ = nextQ;
					break;
				}
		}
		nextQ = none;
		Log("DEBUG LEFT INACTIVE");
	}
Begin:
}


function sgRURecoveryQueuer LocateFP( string sFP)
{
	if ( MyFP == sFP )
		return self;
	if ( nextQ != none )
		return nextQ.LocateFP( sFP);
	return none;
}

defaultproperties
{
    RemoteRole=ROLE_None
}
