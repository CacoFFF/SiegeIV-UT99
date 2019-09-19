//Queuer actor for RU recovery
//By Higor

class SiegeStatPlayer expands SiegeActor;

var SiegeStatPool Pool;
var Pawn Player;
var string MyFP; //Quick fingerprint access
var byte Team;

var SiegeStatPlayer NextStat;


var float sgInfoCoreKiller, sgInfoCoreRepair, sgInfoBuildingHurt, sgInfoUpgradeRepair;
var int	sgInfoKiller, sgInfoBuildingMaker, sgInfoWarheadMaker, sgInfoWarheadKiller;

var int CarryingWarheads;

var float RU, Score;
var int Deaths;

//TO BE IMPLEMENTED
var int iSeconds;


//========================================
//======= Container logic
//========================================

//Setup always puts the queuer in the Active player list
function Setup( Pawn Other, SiegeStatPool InPool)
{
	local sgPRI PRI;

	if ( Other == none || InPool == none )
	{
		Destroy();
		return;
	}
	//DATA ALREADY EXISTS!
	Player = Other;
	PRI = sgPRI(Player.PlayerReplicationInfo);
	if ( Pool != none )
		RestoreData();
	else
	{
		Pool = InPool;
		if ( PRI != None )
			MyFP = PRI.PlayerFingerPrint;
	}
	if ( PRI != None )
		PRI.Stat = self;
	GotoState( 'Active');
}

function UpdateData()
{
	local sgPRI PRI;
	
	CarryingWarheads = SGS.static.GetAmmoAmount( Player, class'WarheadAmmo');
	PRI = sgPRI(Player.PlayerReplicationInfo);
	if ( PRI == none )
		return;
	sgInfoKiller = PRI.sgInfoKiller;
	sgInfoBuildingMaker = PRI.sgInfoBuildingMaker;
	sgInfoWarheadMaker = PRI.sgInfoWarheadMaker;
	sgInfoWarheadKiller = PRI.sgInfoWarheadKiller;
	Team = PRI.Team;
	RU = PRI.RU;
	Score = PRI.Score;
	Deaths = PRI.Deaths;
}

function RestoreData()
{
	local sgPRI PRI;
	
	CarryingWarheads = 0;
	PRI = sgPRI(Player.PlayerReplicationInfo);
	if ( PRI == none )
		return;
	PRI.sgInfoKiller = sgInfoKiller;
	PRI.sgInfoBuildingMaker = sgInfoBuildingMaker;
	PRI.sgInfoWarheadMaker = sgInfoWarheadMaker;
	PRI.sgInfoWarheadKiller = sgInfoWarheadKiller;
	PRI.RU = RU;
	PRI.Score = Score;
	PRI.Deaths = Deaths;
//Announce recovery
	if ( PRI.RU > 5 )
		class'SiegeStatics'.static.AnnounceAll( Pool, "Siege RU-Recovery:"@int(RU)@"RU recovered for"@PRI.PlayerName);

}

state Active
{
	event Tick( float DeltaTime)
	{
		if ( Player == none || Player.bDeleteMe )
		{
			Player = none;
			GotoState('Inactive');
			return;
		}
		Team = Player.PlayerReplicationInfo.Team;
	}
	event BeginState()
	{
		Enable('Tick');
		NextStat = Pool.Active;
		Pool.Active = self;
		iSeconds = 0;
	}
	event EndState()
	{
		local SiegeStatPlayer aQ;
		
		if ( Pool.Active == self )
			Pool.Active = NextStat;
		else
		{
			For ( aQ=Pool.Active ; aQ.NextStat != none ; aQ=aQ.NextStat )
				if ( aQ.NextStat == self )
				{
					aQ.NextStat = NextStat;
					break;
				}
		}
		NextStat = none;
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
		local sgEquipmentSupplier sgE;

		Disable('Tick');
		NextStat = Pool.Inactive;
		Pool.Inactive = self;
		
		if ( SiegeGI(Level.Game) != none && !SiegeGI(Level.Game).FreeBuild )
		{
			ForEach AllActors (class'sgEquipmentSupplier', sgE)
				if ( sgE.Team == Team )
					return;
			GiveRUtoTeam( true);
		}
	}
	event EndState()
	{
		local SiegeStatPlayer aQ;
		
		if ( Pool.Inactive == self )
			Pool.Inactive = NextStat;
		else
		{
			For ( aQ=Pool.Inactive ; aQ.NextStat != none ; aQ=aQ.NextStat )
				if ( aQ.NextStat == self )
				{
					aQ.NextStat = NextStat;
					break;
				}
		}
		NextStat = none;
	}
Begin:
	Sleep( 1 * Level.TimeDilation);
	if ( iSeconds++ > 60)
		GiveRUtoTeam();
	Goto('Begin');
}


//========================================
//======= RU events
//========================================


function GiveRUtoTeam( optional bool bForceAll)
{
	local float RUtoGive;
	if ( Team > 3 )
		return;
	if ( bForceAll )
		RUtoGive = RU;
	else
	{
		RUtoGive = Level.TimeDilation * (iSeconds / 60);
		if ( RUtoGive > RU )
			return;
	}
	if ( (SiegeGI(Level.Game) != none) && (SiegeGI(Level.Game).Cores[Team] != none) )
	{
		SiegeGI(Level.Game).Cores[Team].StoredRU += RUtoGive;
		RU -= RUtoGive;
	}
}

//========================================
//======= Stat Events
//========================================

function CoreKillerEvent( float Amount)
{
	local sgGameReplicationInfo GRI;
	
	sgInfoCoreKiller += Amount;
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (GRI != None) && (sgInfoCoreKiller > GRI.TopCoreKillerValue) )
	{
		GRI.TopCoreKiller = Player.PlayerReplicationInfo.PlayerName;
		GRI.TopCoreKillerPRI = Player.PlayerReplicationInfo;
		GRI.TopCoreKillerTeam = Player.PlayerReplicationInfo.Team;
		GRI.TopCoreKillerValue = sgInfoCoreKiller;
	}
}

function CoreRepairEvent( float Amount)
{
	local sgGameReplicationInfo GRI;
	
	sgInfoCoreRepair += Amount;
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (GRI != None) && (sgInfoCoreRepair > GRI.TopCoreRepairValue) )
	{
		GRI.TopCoreRepair = Player.PlayerReplicationInfo.PlayerName;
		GRI.TopCoreRepairPRI = Player.PlayerReplicationInfo;
		GRI.TopCoreRepairTeam = Player.PlayerReplicationInfo.Team;
		GRI.TopCoreRepairValue = sgInfoCoreRepair;
	}
}

function BuildingHurtEvent( float Amount)
{
	local sgGameReplicationInfo GRI;
	
	sgInfoBuildingHurt += Amount;
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (GRI != None) && (sgInfoBuildingHurt > GRI.TopBuildingHurtValue) )
	{
		GRI.TopBuildingHurt = Player.PlayerReplicationInfo.PlayerName;
		GRI.TopBuildingHurtPRI = Player.PlayerReplicationInfo;
		GRI.TopBuildingHurtTeam = Player.PlayerReplicationInfo.Team;
		GRI.TopBuildingHurtValue = sgInfoBuildingHurt;
	}
}

function UpgradeRepairEvent( float Amount)
{
	local sgGameReplicationInfo GRI;
	
	sgInfoUpgradeRepair += Amount;
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (GRI != None) && (sgInfoUpgradeRepair > GRI.TopUpgradeRepairValue) )
	{
		GRI.TopUpgradeRepair = Player.PlayerReplicationInfo.PlayerName;
		GRI.TopUpgradeRepairPRI = Player.PlayerReplicationInfo;
		GRI.TopUpgradeRepairTeam = Player.PlayerReplicationInfo.Team;
		GRI.TopUpgradeRepairValue = sgInfoUpgradeRepair;
	}
}








defaultproperties
{
    bAlwaysTick=True
    RemoteRole=ROLE_None
}
