class sgAIqueuer expands SiegeActor;

/*
AI queuer for bots
*/

var(Debug) Actor Objective;
var(Debug) Actor OverrideObjective; //Send the Bot here for the moment
var string NukeString;
var sgAIqueuer nextQ;
var sgBotController Master;
var(Debug) sgConstructor Constructor;
var(Debug) Pawn Bot;
var(Debug) sgPRI sgPRI;
var(Debug) int BuildIndex;
var float Escrow;
var(Debug) float CheatMargin;
var(Debug) name BotRole; //'Defend', 'Attack', 'Freelance', 'SpecOps' //Defend = 0, Freelance and specops = 1, Attack = 2 (for RoleCode)
var(Debug) byte RoleCode;
var(Debug) float SupplierTimer;
var(Debug) float LastIdleTime;

var(Debug) bool bNoAI; //Players


var(Debug) enum ETeamTask
{
	TT_None,
	TT_Upgrade,
	TT_Support,
	TT_Repair,
	TT_Hunt,
	TT_Build,
	TT_DelayedBuild,
	TT_Item,
	TT_Remove
} TeamMode;
var ETeamTask OldTeamMode;
var name TaskName[9];

var(Debug) bool bDead;


event PostBeginPlay()
{
	Bot = Pawn(Owner);
	sgPRI = sgPRI(Bot.PlayerReplicationInfo);
	if ( Bot == none || sgPRI == none )
		Destroy();
	SetMaster();
	Respawned();
	bNoAI = PlayerPawn(Owner) != none;
}

event Tick( float DeltaTime)
{
	if ( Bot == none || Bot.bDeleteMe )
		Destroy();
	else if ( Bot.PlayerReplicationInfo.Team != Master.TeamID )
	{
		NoMaster();
		SetMaster();
		Objective = none;
	}
	else if ( (Bot.Health <= 0) && !bDead )
		Died();
	else if ( bDead && Bot.Health > 0 )
		Respawned();
	else if ( Objective != none && Objective.bDeleteMe )
	{
		//Process deleted objective!
		//Ask for new objective?
		Objective = none;
		TeamMode = TT_None;
		GotoState('AIloop','Begin');
	}
	else if ( MaxedRU() && (Level.TimeSeconds - LastIdleTime > 5) )
	{ //Hack fix for bots hanging around with 300 RU
		LastIdleTime = Level.TimeSeconds;
		Master.BotRespawned(self);
	}
	else if ( OverrideObjective != none && OverrideObjective.bDeleteMe )
		OverrideObjective = none;
	else if ( SupplierTimer > 0 )
	{
		OverrideObjective = Master.MainSupplier;
		if ( Master.MainSupplier == none || Master.MainSupplier.bDeleteMe )
		{
			SupplierTimer = 0;
			OverrideObjective = none;
		}
		else if ( VSize(Bot.Location - Master.MainSupplier.Location) < Master.MainSupplier.SupplyRadius )
			if ( (SupplierTimer -= DeltaTime) <= 0 )
			{
				OverrideObjective = none;
				if ( bNoAI )
					Bot.SwitchToBestWeapon();
			} //ELSE, UPGRADE TEAMMATES
	}
	
	if ( Bot.Physics == PHYS_Walking || Bot.Physics == PHYS_Swimming )
		SetLocation( Bot.Location);
}

auto state AIloop
{

Begin:
	Sleep(0.0);
	Goto( 'CheckObjective' );
Upgrade:
	Sleep(0.0);
	TryUpgrade();
	Sleep(0.97);
	Goto( 'CheckObjective' );
Repair:
	Sleep(0.0);
	Sleep(1);
	Goto( 'CheckObjective' );
Support:
	Sleep(0.0);
	Sleep(2);
	Goto( 'CheckObjective' );
Hunt:
	Sleep(0.0);
	Sleep(2);
	Goto( 'CheckObjective' );
DelayedBuild:
	Sleep(0.0);
	Sleep(1);
	Goto( 'CheckObjective' );
Build:
	Sleep(0.3); //Set to 0 later
	CheckBuild();
	Goto( 'CheckObjective' );
Item:
	//Chain more items here!
	Sleep(0.3); //Set to 0 later?
	if ( WildcardsResources(Objective) != none && MaxedRU() )
		Objective = none;
	Goto( 'CheckObjective' );
Remove:
	Sleep(0.3);
	Goto( 'CheckObjective' );
CheckObjective:
	if (/* Objective != none */ TeamMode != TT_None )
	{
		if ( (OverrideObjective == none) && (Master.RUsLeft > 0) && (WildcardsResources(Objective) == none) && (FRand() < 0.2) && !MaxedRU() )
			OverrideObjective = NearbyRU();
		if ( OldTeamMode != TeamMode )
		{
			if ( !class'SiegeStatics'.default.bRelease )
				Log("GOING TO "$TaskName[TeamMode]);
			OldTeamMode = TeamMode;
		}
		Goto( TaskName[ TeamMode] );
	}
	Goto('Begin');
}

function bool TryUpgrade()
{
	local bool bResetObjective;
	local sgPRI aPRI;
	local sgAIqueuer Other;
	local sg_BOT_BuildingBase BBase;
	local float RUtarget;

	if ( Constructor == none )
	{
		Constructor = sgConstructor(Bot.FindInventoryType( class'sgConstructor'));
		return false;
	}

	if ( Objective == none || Objective.bDeleteMe )
		bResetObjective = true;
	else if ( sgBuilding(Objective) != none )
	{
		if ( sgBuilding(Objective).Grade == 5 )
			bResetObjective = true;
		if ( !bNoAI && Constructor.BotUpgrade(Pawn(Objective), sgBuilding(Objective).Grade + 1 + CheatMargin/15) )
			bResetObjective = true;
	}
	else if ( Pawn(Objective) != none && sgPRI(Pawn(Objective).PlayerReplicationInfo) != none )
	{
		aPRI = sgPRI(Pawn(Objective).PlayerReplicationInfo);
		//Give all RU, no AI queuer specified!
		if ( RU() <= 30 )
			bResetObjective = true;
		RUtarget = RUtoMax();
		if ( RUtarget <= 0 )
			bResetObjective = true;
		else if ( !bNoAI )
			Constructor.BotUpgrade( Pawn(Objective), RUtarget);
	}
	else if ( sgAIqueuer(Objective) != none )
	{
		Other = sgAIqueuer(Objective);
		aPRI = sgPRI(Other.Bot.PlayerReplicationInfo);
		if ( sg_BOT_BuildingBase(Other.Objective) != none )
			RUtarget = SiegeGI(Level.Game).CategoryInfo[Master.TeamID].BuildCost(Other.BuildIndex) - Other.CheatRU();
//		else MORE CASES HERE

		if ( (RUtarget <= 0) || RU() <= 1 )
			bResetObjective = true;
		else if ( !bNoAI )
			Constructor.BotUpgrade( Other.Bot, RUtarget);
	}
	else if ( sg_BOT_BuildingBase(Objective) != none )
	{
		BBase = sg_BOT_BuildingBase(Objective);
		if ( BBase.Building == none && BBase.PendingBuilding == none )
			bResetObjective = true;
		else if ( BBase.PendingBuilding != none && BBase.PendingBuilding.Grade < 5 )
		{
			if ( !bNoAI && Constructor.BotUpgrade( BBase.PendingBuilding, BBase.PendingBuilding.Grade + 1 + CheatMargin/15) )
				bResetObjective = true;
		}
		else if ( BBase.Building != none &&  BBase.Building.Grade < 5 )
		{
			if ( !bNoAI && Constructor.BotUpgrade( BBase.Building, BBase.Building.Grade + 1 + CheatMargin/15) )
				bResetObjective = true;
		}
		else
			bResetObjective = true;
	}

	if ( bResetObjective )
	{
		Objective = none;
		TeamMode = TT_None;
	}
}

function bool TryRemove()
{
	//Removed already!
	if ( (sgBuilding(Objective) == none) || Objective.bDeleteMe )
	{
		Objective = none;
		return true;
	}

}

function CheckBuild()
{
	if ( Objective == none )
		TeamMode = TT_None;
	else if ( sg_BOT_BuildingBase(Objective) != none )
	{
		if ( sg_BOT_BuildingBase(Objective).Bot == none )
			sg_BOT_BuildingBase(Objective).Bot = self;
	}
}

event Destroyed()
{
	if ( Master == none )
		return;

//Propagate objective to another bot?
	NoMaster();
}

function NoMaster()
{
	local sgAIqueuer aQ;

	Master.AIcount--;
	if ( Master.AIlist == self )
		Master.AIlist = nextQ;
	else
	{
		For ( aQ=Master.AIlist ; aQ.nextQ != none ; aQ=aQ.nextQ )
			if ( aQ.nextQ == self )
			{
				aQ.nextQ = nextQ;
				break;
			}
	}
	nextQ = none;
	Master = none;
}

function SetMaster()
{
	local sgBotController BC;

	if ( Master != none )		return;
	ForEach AllActors (class'sgBotController', BC)
		if ( BC.TeamID == Bot.PlayerReplicationInfo.Team )
		{
			Master = BC;
			nextQ = Master.AIlist;
			Master.AIlist = self;
			Master.AIcount++;
			return;
		}
	Log("SETMASTER BUG");
}

function Died()
{
	bDead = true;
	Constructor = none;
}

function Respawned()
{
	bDead = false;
	Constructor = sgConstructor(Bot.FindInventoryType( class'sgConstructor'));
	if ( Master.MainSupplier != none && Master.MainSupplier.SCount <= 0 )
		SupplierTimer = sqrt(Master.MainSupplier.BuildCost * 0.2) / 8;
	Master.BotRespawned( self);
}

function sgAIqueuer FindBot( pawn Other)
{
	if ( Bot == Other )
		return self;
	if ( nextQ != none )
		return nextQ.FindBot( Other);
	return none;
}

function sgAIqueuer FindUntasked()
{
	if ( Objective == none )
		return self;
	if ( nextQ != none )
		return nextQ.FindUntasked();
	return none;
}

function TaskUpgrade( actor Other)
{
	Objective = Other;
	TeamMode = TT_Upgrade;
	if ( sg_BOT_BuildingBase(Other) != none )
		sg_BOT_BuildingBase(Other).NotifyUpgrader(self);
}

function TaskBuildTo( sg_BOT_BuildingBase aBuild, int NewIndex)
{
	Objective = aBuild;
	TeamMode = TT_Build;
	BuildIndex = NewIndex;
	if ( Master.NextSpot == aBuild )
		Master.NextMan = self;
	aBuild.Bot = self;
	aBuild.GotoState('QueuedByBot');
}

function TaskItem( Inventory Other)
{
	Objective = Other;
	TeamMode = TT_Item;
}

function TaskRemove( sgBuilding Other)
{
	Objective = Other;
	TeamMode = TT_Remove;
}

//*******************************************
// Linked methods

function float TeamRU( optional float fBase)
{
	if ( nextQ != none )
		return nextQ.TeamRU( fBase + sgPRI.RU);
	return fBase + sgPRI.RU;
}

final function float RU() {	return sgPRI.RU;	}
final function float MaxRU() {	return SiegeGI(Level.Game).MaxRUs[sgPRI.Team];	}
final function bool MaxedRU() {	return sgPRI.RU >= SiegeGI(Level.Game).MaxRUs[sgPRI.Team];	}
final function float RUtoMax() {	return SiegeGI(Level.Game).MaxRUs[sgPRI.Team] - sgPRI.RU;	}

function bool CanRepair()
{
	if ( (Master.GameStage == 0) || (Master.Core.Grade < 1) || (Master.MainSupplier == none) || (RU() < 20) || (Bot.Enemy != none) )		return false;
	return true;
}

function bool RequiresCapacity()
{
	local float Decision;

	if ( (Master.Core.Grade < 1.1) || (Master.MainSupplier == none) )
		return false;
	if ( MaxRU() < 1500 )
		Decision = 0.5 - MaxRU() / 3000;
	Decision += (MaxRU() - (TeamRU() / Master.AIcount)) * 0.01;
	return Decision >= 1;
}

function sgAIqueuer FromGoal( actor Goal)
{
	if ( Objective == Goal )
		return self;
	if ( nextQ != none )
		return nextQ.FromGoal( Goal);
	return none;
}


function sgAIqueuer BOTContGoal()
{
	if ( (TeamMode == TT_Build) && (sg_BOT_ContainmentPoint(Objective) != none) )
		return self;
	if ( nextQ != none )
		return nextQ.BOTContGoal();
	return none;
}

function int RUgatherers( optional int iBase)
{
	if ( WildcardsResources(Objective) != none )
		iBase += 1;
	if ( nextQ != none )
		return nextQ.RUgatherers( iBase);
	return iBase;
}

function float CheatRU()
{
	if ( !SiegeGI(Level.Game).bBotCanCheat )
		return RU();
	return RU() * (1 + CheatMargin / 100);
}

//Returns the amount of assigned players
function int AssignByNearbyRU( int AssignCount)
{
	local WildcardsResources aRU;
	local int Found;
	if ( AssignCount <= 0 )
		return 0;
	aRU = NearbyRU();
	if (aRU != none)
	{
		TaskItem( aRU);
		Found = 1;
	}
	if ( nextQ != none )
		return nextQ.AssignByNearbyRU( AssignCount - Found ) + Found;
	return Found;
}

function WildcardsResources NearbyRU()
{
	local WildcardsResources aRU;

	if ( MaxedRU() || (WildcardsResources(Objective) != none) )
		return none;
	ForEach Bot.VisibleCollidingActors( class'WildcardsResources', aRU, 350)
		return aRU;
	ForEach RadiusActors (class'WildcardsResources', aRU, 450)
		return aRU;
	return none;
}

//Returns the amount of assigned players
function int AssignByRandomRU( int AssignCount, name DesiredRole)
{
	local WildcardsResources aRU;
	if ( AssignCount <= 0 )
		return 0;
	if ( nextQ == none || DesiredRole == '' || BotRole == DesiredRole ) //Assign if role matches... or if there's no other choice
		aRU = RandomRU();
	if ( aRU != none )
		TaskItem( aRU);
	if ( nextQ != none )
		return nextQ.AssignByNearbyRU( AssignCount - int(aRU != none) ) + int(aRU != none);
	return int(aRU != none);
}

function WildcardsResources RandomRU()
{
	local float Chance;
	local WildcardsResources aRU;
	
	if ( MaxedRU() || (WildcardsResources(Objective) != none) )
		return none;
	Chance = Master.RUsLeft;
	ForEach AllActors (class'WildcardsResources', aRU)
	{
		if ( FRand() < 1/Chance )
			return aRU;
		Chance -= 1;
	}
	return aRU; //I wonder if it will ever return NONE after the iterator
}


function sgAIqueuer CurSupplierCandidate()
{
	if ( sg_BOT_SupplyPoint(Objective) != none )
		return self;
	if ( nextQ != none )
		return nextQ.CurSupplierCandidate();
	return none;
}

function sgAIqueuer BestUpgradeCandidate( vector Loc, optional sgAIqueuer Best, optional float Factor, optional sgAIqueuer Exclude)
{
	local float curF;
	//Exclude anyone already tasked to upgrade this player, or tasked to upgrade anything
	if ( (Exclude != none && (Exclude == self || Exclude == Objective || TeamMode == TT_Upgrade)) || TeamMode == TT_Build || (RU() < (4 * Master.Core.Grade - 2)) )
		Goto NEXT;

	curF = fMax(5 - VSize(Location - Bot.Location)*0.001, 1) * CheatRU();
//	Log("CURF "$curF$" ON "$Bot.PlayerReplicationInfo.PlayerName);
	if ( curF > Factor )
	{
		Best = self;
		Factor = curF;
	}
	NEXT:
	if ( nextQ != none )
		return nextQ.BestUpgradeCandidate( Loc, Best, Factor, Exclude);
	return Best;
}

function sgAIqueuer RoleUpgradeCandidate( vector Loc, optional sgAIqueuer Best, optional float Factor, optional int MinRole, optional int MaxRole)
{
	local float curF;
	//Exclude anyone tasked to build, upgrade or repair
	if ( TeamMode == TT_Upgrade || TeamMode == TT_Build || TeamMode == TT_Repair || RoleCode < MinRole || RoleCode > MaxRole || (RU() < (4 * Master.Core.Grade - 2)) )
		Goto NEXT;
	if ( Loc == Location )
		Goto NEXT; //Upgrading myself...

	curF = fMax(5 - VSize(Location - Bot.Location)*0.001, 1) * CheatRU();
//	Log("CURF "$curF$" ON "$Bot.PlayerReplicationInfo.PlayerName);
	if ( curF > Factor )
	{
		Best = self;
		Factor = curF;
	}
	NEXT:
	if ( nextQ != none )
		return nextQ.RoleUpgradeCandidate( Loc, Best, Factor, MinRole, MaxRole);
	return Best;
}

function float IncomingUpgradeRU( sgAIqueuer UpgradeTarget)
{
	local float added;
	if ( Objective == UpgradeTarget && TeamMode == TT_Upgrade )
		added = RU();
	if ( nextQ != none )
		return added + nextQ.IncomingUpgradeRU( UpgradeTarget);
	return added;
}

function CancelIncomingUpgrade()
{
	local sgAIqueuer aQ;

	For ( aQ=Master.AIlist ; aQ!=none ; aQ=aQ.nextQ )
		if ( aQ.Objective == self )
			aQ.Objective = none;
}

function SetRole( name RoleName)
{
	if ( RoleName == 'Defend' )
	{
		BotRole = 'Defend';
		RoleCode = 0;
	}
	else if ( RoleName == 'Attack' )
	{
		BotRole = 'Attack';
		RoleCode = 2;
	}
	else if ( RoleName == 'SpecOps' )
	{
		BotRole = 'SpecOps';
		RoleCode = 1;
	}
	else
	{
		BotRole = 'Freelance';
		RoleCode = 1;
	}
}

/*
Function name list:
RU, MaxRU, MaxedRU, RUtoMax, TeamRU, RequiresCapacity, FromGoal, CanRepair,
CheatRU, RUgatherers, RandomRU, NearbyRU, AssignByRandomRU, AssignByNearbyRU,
NewSupplierCandidate, BestUpgradeCandidate, IncomingUpgradeRU,
RoleUpgradeCandidate

Fact list:
BotRole, RoleCode, CheatMargin, Objective, OverrideObjective

Master actor Fact list:
AIcount, TeamID, Core, GameStage, RUsLeft, MaxFutureRUs(), MaxRUs(), RoleRU(),
CanBuildProject(), CurPriority



*/

defaultproperties
{
	TaskName(0)=Begin
	TaskName(1)=Upgrade
	TaskName(2)=Support
	TaskName(3)=Repair
	TaskName(4)=Hunt
	TaskName(5)=Build
	TaskName(6)=DelayedBuild
	TaskName(7)=Item
	TaskName(8)=Remove
	BuildIndex=-1
}