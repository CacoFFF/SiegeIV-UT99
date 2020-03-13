//Queuer actor for RU recovery
//By Higor

class SiegeStatPlayer expands SiegeActor;

const GRI_CoreDamage     = 0;
const GRI_CoreRepair     = 1;
const GRI_BuildingDamage = 2;
const GRI_Kill           = 3;
const GRI_Build          = 4;
const GRI_WarheadBuild   = 5;
const GRI_WarheadDestroy = 6;
const GRI_UpgradeRepair  = 7;

var SiegeStatPool Pool;
var Pawn Player;
var string MyFP; //Quick fingerprint access
var byte Team;

var SiegeStatPlayer NextStat;


var float InfoCoreDamage, InfoCoreRepair, InfoBuildingDamage, InfoUpgradeRepair;
var int	InfoKill, InfoBuild, InfoWarheadBuild, InfoWarheadDestroy;

var int CarryingWarheads;

var float RU, Score;
var int Deaths;

//TO BE IMPLEMENTED
var int iSeconds;


//Hack
native(256) final function SleepModify( float Seconds );

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
	local int OldCarryingWarheads;
	
	OldCarryingWarheads = CarryingWarheads;
	CarryingWarheads = SGS.static.GetAmmoAmount( Player, class'WarheadAmmo');
	if ( (CarryingWarheads != OldCarryingWarheads) && (sgGameReplicationInfo(Level.Game.GameReplicationInfo) != None) )
		sgGameReplicationInfo(Level.Game.GameReplicationInfo).UpdateNukerStats();
	
	PRI = sgPRI(Player.PlayerReplicationInfo);
	if ( PRI == none )
		return;
	PRI.sgInfoKiller = InfoKill;
	PRI.sgInfoBuildingMaker = InfoBuild;
	PRI.sgInfoWarheadMaker = InfoWarheadBuild;
	PRI.sgInfoWarheadKiller = InfoWarheadDestroy;
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
	PRI.sgInfoKiller = InfoKill;
	PRI.sgInfoBuildingMaker = InfoBuild;
	PRI.sgInfoWarheadMaker = InfoWarheadBuild;
	PRI.sgInfoWarheadKiller = InfoWarheadDestroy;
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
	Sleep( (1 + FRand()) * Level.TimeDilation);
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
	local SiegeGI Game;
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
	Game = SiegeGI(Level.Game);
	if ( (Game != none) && !Game.FreeBuild && (Game.Cores[Team] != none) )
	{
		SiegeGI(Level.Game).Cores[Team].StoredRU += RUtoGive;
		RU -= RUtoGive;
	}
}

//========================================
//======= Stat Events
//========================================

function PropagateToGRI( int i, float Value)
{
	local sgGameReplicationInfo GRI;
	
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (GRI != None) && (Value > GRI.StatTop_Value[i]) )
	{
		GRI.StatTop_Name[i]  = Player.PlayerReplicationInfo.PlayerName;
		GRI.StatTop_PRI[i]   = Player.PlayerReplicationInfo;
		GRI.StatTop_Team[i]  = Player.PlayerReplicationInfo.Team;
		GRI.StatTop_Value[i] = Value;
	}
}


function CoreDamageEvent( float Amount)
{
	InfoCoreDamage += Amount;
	PropagateToGRI( GRI_CoreDamage, InfoCoreDamage);
}

function CoreRepairEvent( float Amount)
{
	InfoCoreRepair += Amount;
	PropagateToGRI( GRI_CoreRepair, InfoCoreRepair);
}

function BuildingDamageEvent( float Amount)
{
	InfoBuildingDamage += Amount;
	PropagateToGRI( GRI_BuildingDamage, InfoBuildingDamage);
}

function KillEvent( int Change)
{
	InfoKill += Change;
	PropagateToGRI( GRI_Kill, float(InfoKill) + 0.01 ); //Corrects rounding down
	if ( sgPRI(Player.PlayerReplicationInfo) != None )
		sgPRI(Player.PlayerReplicationInfo).sgInfoKiller = InfoKill;
}

function BuildEvent( int Change)
{
	InfoBuild += Change;
	PropagateToGRI( GRI_Build, float(InfoBuild) + 0.01); //Corrects rounding down
}

function WarheadBuildEvent( int Change)
{
	local SiegeStatPlayer Stat;
	local sgGameReplicationInfo GRI;

	InfoWarheadBuild += Change;
	PropagateToGRI( GRI_WarheadBuild, float(InfoWarheadBuild) + 0.01); //Corrects rounding down
	
	//Fix substraction!
	GRI = sgGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( (Change < 0) && (GRI.StatTop_PRI[GRI_WarheadBuild] == Player.PlayerReplicationInfo) )
	{
		GRI.StatTop_Reset(GRI_WarheadBuild);
		For ( Stat=Pool.Active ; Stat!=None ; Stat=Stat.NextStat )
			if ( Stat.InfoWarheadBuild > GRI.StatTop_Value[GRI_WarheadBuild] )
				Stat.PropagateToGRI( GRI_WarheadBuild, float(Stat.InfoWarheadBuild) + 0.01);
/*		For ( Stat=Pool.Inactive ; Stat!=None ; Stat=Stat.NextStat )
			if ( Stat.InfoWarheadBuild > GRI.StatTop_Value[GRI_WarheadBuild] )
				Stat.PropagateToGRI( GRI_WarheadBuild, float(Stat.InfoWarheadBuild) + 0.01);*/
	}
}

function WarheadDestroyEvent( int Change)
{
	InfoWarheadDestroy += Change;
	PropagateToGRI( GRI_WarheadDestroy, float(InfoWarheadDestroy) + 0.01); //Corrects rounding down
}

function UpgradeRepairEvent( float Amount)
{
	InfoUpgradeRepair += Amount;
	PropagateToGRI( GRI_UpgradeRepair, InfoUpgradeRepair);
}

function WarheadPickupEvent()
{
	if ( LatentFloat > (0.1 * Level.TimeDilation) )
		SleepModify( 0.05);
}







defaultproperties
{
    bAlwaysTick=True
    RemoteRole=ROLE_None
}
