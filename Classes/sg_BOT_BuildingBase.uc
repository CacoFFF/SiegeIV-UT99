//*************************************
// Building marker for AI controller
//*************************************

class sg_BOT_BuildingBase expands KeyPoint;

var sg_BOT_BuildingBase nextBuild;
var vector FinalPos; //Position to build at
var float OwnRadius; //Catch a build as 'own'
var int Order;
var int Strategy; //Unique strategy
var byte Priority;
var class<sgEditBuilding> EditClass;
var bool bNoProject;

var(Debug) int TryCount; //Times a bot has tried building, after 5 tries cancel for 30 seconds
var(Debug) int CatBStart; //Optimize projection by starting catchecks here
var(Debug) int CatBCount;

var(Debug) byte Team; //Do i really need this?
var(Debug) sgBuilding Building;
var(Debug) sgBuilding PendingBuilding;

var(Debug) sgAIqueuer Bot;
var(Debug) sgConstructor BotConstructor;
var float TargetLevel;
var(Debug) int FailCount;
var(Debug) bool bUsable; //Never use during this stage

var(Debug) name CurState;

//AI pawn is requesting scripted build
function AIbuild( sgAIqueuer Other); //Delete?
function NotifyUpgrader( sgAIqueuer Incoming);
function bool AcceptBuild( sgBuilding Other);

function bool BuildNotify( sgBuilding Other)
{
	local sg_BOT_BuildingBase sgBB;

	if ( !AcceptBuild(Other) || (VSize(Other.Location - FinalPos) > OwnRadius) || !FastTrace(Other.Location, FinalPos) )
	{
		NEXT:
		if ( nextBuild != none )
			return nextBuild.BuildNotify( Other);
		return false;
	}
	if ( Building == none )
	{
		if ( NextBuild != none )
		{
			sgBB =  NextBuild.FindOtherNearest( Other, VSize(Other.Location - FinalPos));
			if ( sgBB != none )
				return sgBB.BuildNotify( Other);
		}
		Building = Other;
		SetNewState();
//		if ( !IsInState('MonitorBuilding') )
//			GotoState('MonitorBuilding');
		Goto FINISHED;
	}
	else if ( PendingBuilding == none )
	{
		if ( Other.BuildCost > Building.BuildCost )
		{
			if ( NextBuild != none )
			{
				sgBB =  NextBuild.FindOtherNearest( Other, VSize(Other.Location - FinalPos));
				if ( sgBB != none )
					return sgBB.BuildNotify( Other);
			}
			PendingBuilding = Other;
			Goto FINISHED_PENDING;
		}
	}
	if ( VSize(Other.Location - FinalPos) < VSize(Building.Location - FinalPos) )
	{
		if ( nextBuild != none )
			nextBuild.BuildNotify( Building);
		Building = Other;
		SetNewState();
//		if ( !IsInState('MonitorBuilding') )
//			GotoState('MonitorBuilding');
		Goto FINISHED;
	}
	Goto NEXT;

	FINISHED_PENDING:

	FINISHED:
	if ( !class'SiegeStatics'.default.bRelease )
		Log("BUILDING FINISHED "$Other$" AT "$self);
	CancelProject();
	return true;
}

function sg_BOT_BuildingBase FindOtherNearest( sgBuilding Other, float MaxRadius, optional sg_BOT_BuildingBase Best)
{
	if ( AcceptBuild( Other) && (VSize(Other.Location - FinalPos) < MaxRadius) && FastTrace(Other.Location) )
	{
		Best = self;
		MaxRadius = VSize(Other.Location - FinalPos);
	}
	if ( NextBuild != none )
		return NextBuild.FindOtherNearest( Other, MaxRadius, Best);
	return Best;
}

function CancelProject()
{
	local sgBotController sgB;
	sgB = SiegeGI(Level.Game).BotControllers[Team];
	if ( sgB.NextSpot == self )
	{
		if ( sgB.NextMan != none ) //Just in case
		{
			CancelBot();
			if ( sgB.NextMan.Objective == self )
			{
				Bot = sgB.NextMan;
				CancelBot();
			}
		}
		sgB.NextMan = none;
		sgB.NextBProject = -1;
		sgB.NextSpot = none;
	}
}

function GlobalSetTeam( byte NewTeam)
{
	Team = NewTeam;
	if ( nextBuild != none )
		nextBuild.GlobalSetTeam( NewTeam);
}

function sg_BOT_SupplyPoint GlobalFindSupplier()
{
	if ( nextBuild != none )
		return nextBuild.GlobalFindSupplier();
	return none;
}

function sg_BOT_ContainmentPoint FindPriorityCont( bool bCrowded, float Rating, optional int Pri, optional float Factor, optional sg_BOT_ContainmentPoint Best)
{
	if ( NextBuild != none )
		return NextBuild.FindPriorityCont( bCrowded, Rating, Pri, Factor, Best);
	return Best;
}

function bool OnlyContainersInPriority( int Pri, optional bool bFoundContainer)
{
	if ( Building == none && (Priority == Pri) )
		return false;
	if ( NextBuild != none )
		return NextBuild.OnlyContainersInPriority( Pri, bFoundContainer);
	if ( !class'SiegeStatics'.default.bRelease )
		Log("PRI "$Pri$", RESULT "$bFoundContainer);
	return bFoundContainer;
}

function CancelBot()
{
	if ( Bot != none )
	{
		Bot.Objective = none;
		Bot.BuildIndex = -1;
		Bot.TeamMode = TT_None;
	}
	Bot = none;
	BotConstructor = none;
	TargetLevel = 0;
}

function AddFail()
{
	if ( ++FailCount >= 5 )
		GotoState('CoolDown');
}



state AirInsert
{
Begin:
	if ( Owner == none || Owner.Physics != PHYS_Falling )
		Stop;
	SetLocation(Owner.Location);
	Sleep(0.0);
	Goto('Begin');
}

state CoolDown
{
	event BeginState()
	{
		bUsable = false;
		CurState = 'CoolDown';
	}
	event EndState()
	{
		bUsable = true;
		FailCount = 0;
	}
Begin:
	Sleep(30);
	SetNewState();
}

state QueuedByBot
{
	event BeginState()
	{
		CurState = 'QueuedByBot';
	}
Begin:
	Sleep(0.0);
	if ( PendingBuilding != none )
		Goto('Cancel');
	if ( (Bot == none) || Bot.bDeleteMe || (Bot.Objective != self) )
		Goto('Cancel');
	if ( (Bot.TeamMode != TT_Build && Bot.TeamMode != TT_DelayedBuild) )
		Goto('Cancel');
	if ( (BotConstructor == none || BotConstructor.bDeleteMe) && Bot.Bot.Health > 0 )
		BotConstructor = sgConstructor(Bot.Bot.FindInventoryType(class'sgConstructor'));
	else if ( Bot.Bot.Health <= 0 )
		Goto('Begin');
	if ( Bot.CheatRU() < SiegeGI(Level.Game).CategoryInfo[Team].BuildCost(Bot.BuildIndex) ) //TEAMMATES SHOULD UPGRADE THIS BOT
		Goto('Begin');

	//Do level relevancy checks here, has something else been constructed?
	if ( ShouldCancel() )
		Goto('Cancel');

	if ( VSize(Bot.Bot.Location - Location) < 200 )
	{
		if ( (Bot.Bot.Enemy == none) && (Bot.Bot.Weapon != BotConstructor) && (Bot.Bot.PendingWeapon != BotConstructor) )
		{
			Bot.Bot.PendingWeapon = BotConstructor;
			if ( Bot.Bot.Weapon != none )
				Bot.Bot.Weapon.PutDown();
		}
		if ( VSize(Bot.Bot.Location - Location) < 50 )
		{
			if ( BotConstructor.BotBuild( Bot.BuildIndex, SiegeGI(Level.Game).bBotCanCheat, FinalPos) )
			{
				Bot.CancelIncomingUpgrade();
				Goto('Cancel');
			}
			Sleep( 1);
		}
	}
	Sleep(0.1);
	Goto('Begin');
Cancel:
	CancelBot();
	if ( !class'SiegeStatics'.default.bRelease )
		Log("CANCELATION FORCED ON QUEUEDBYBOT");
	SetNewState();
}

state MonitorBuilding
{
	event BeginState()
	{
		CurState = 'MonitorBuilding';
	}
	event EndState()
	{
		if ( Bot != none )
		{	
			if ( Bot.TeamMode == TT_Remove )
			{
				Bot.TeamMode = TT_None;
				Bot.Objective = none;
			}
			Bot = none;
		}
	}
	function NotifyUpgrader( sgAIqueuer Incoming)
	{
		if ( Bot == none || Bot.TeamMode != TT_Remove )
			Bot = Incoming;
	}
Begin:
	if ( Building == none || Building.bDeleteMe )
	{
		Building = none;
		if ( PendingBuilding == none )
		{
			SetNewState();
			Stop;
		}
		Building = PendingBuilding;
		PendingBuilding = none;
	}
	if ( Bot != none && Bot.TeamMode == TT_Build )
	{
		SetNewState();
		Stop;
	}
	if ( CheckPending() )
	{
		if ( Bot != none && Bot.TeamMode == TT_Upgrade ) //Unregister current upgrader
			Bot = none;
		Goto('RemovePending');
	}
	if ( !bNoProject && PendingBuilding == none && FRand() < 0.01 )
	{
		GotoState('ProjectBuilding','ProjectOnce');
		Stop;
	}
	Sleep(0.1);
	Goto('Begin');
RemovePending:
	if ( !class'SiegeStatics'.default.bRelease )
		Log("PENDING REMOVE?");
	//Order a bot to remove!
	if ( Bot != none )
		Goto('PostRPChecks');
	if ( (Pawn(Building.Owner) != none) && (sgPRI(Pawn(Building.Owner).PlayerReplicationInfo) != none) )
	{
		Bot = sgPRI(Pawn(Building.Owner).PlayerReplicationInfo).AIQueuer; //Always prioritize building owner
		if ( Bot == none )
		{
			Sleep(1);
			if ( !Building.bOnlyOwnerRemove ) //Take another bot
			{
			}
			Goto('Begin'); //TODO: If built by another bot, take ownership and remove anyways
		}
		PostRPChecks:
		if ( (Bot.SupplierTimer > 0) && (Bot.TeamMode != TT_Remove) ) //Override main task when bot is in supplier
			Bot.TaskRemove(Building);
		else if ( (VSize(Bot.Location - Location) < 1000) && (Bot.TeamMode != TT_Remove) )
			Bot.TaskRemove(Building);
		else if ( (VSize(Bot.Location - Location) < 2500) && (Bot.TeamMode == TT_None) )
			Bot.TaskRemove(Building);
		else if ( !Bot.bNoAI && (Bot.TeamMode == TT_Remove) && (VSize(Bot.Bot.Location - Building.Location) < 80 + Building.CollisionRadius + FRand() * 40 + 300 * Bot.CheatMargin) )
		{
			Building.RemovedBy( Bot.Bot,, Bot.CheatMargin);
			Building = none;
			CancelBot();
		}
		Sleep(1);
	}
	Sleep(0.1);
	Goto('Begin');
}

//We are waiting in line until the bot controller's current project is finished
//Randomize timers will also randomize the project order
//Priority 4 always override expensive builds for cheap ones
auto state ProjectBuilding
{
	event BeginState()
	{
		CurState = 'ProjectBuilding';
	}
	function bool DoProjection()
	{
		local sgBotController sgBC;
		local sgCategoryInfo sgC;
		local int SelB;
		
		sgBC = SiegeGI(Level.Game).BotControllers[Team];
		if ( sgBC.MainSupplier == none || sgBC.GameStage == 0 || sgBC.CurPriority > Priority )
			return false;
		SelB = SelectBuilding();
		if ( SelB < 0 )
			return false;
		sgC = SiegeGI(Level.Game).CategoryInfo[Team];
		if ( Building != none )
		{
			if ( Building.iCatTag == SelB )
				return false;
			if ( sgC.GetBuild(SelB).static.AI_Rate( sgBC, sgC, SelB) <= Building.AI_Rate( sgBC, sgC, Building.iCatTag) )
				return false;
		}
		if ( sgBC.NextBProject >= 0 )
		{
			if ( sgBC.NextSpot != self )
			{
				if ( sgBC.NextMan != none ) //Don't override a project currently in process, unless project is here
					return false;
				if ( (Priority == 4) && (sgC.BuildCost(sgBC.NextBProject) < sgC.BuildCost(SelB)) ) //Keep cheapest
					return false;
			}
			else
			{
				if ( SelB == sgBC.NextBProject ) //Don't project multiple times the same stuff in this point
					return false;
			}
			sgBC.NextMan = none;
		}
		sgBC.NextBProject = SelB;
		sgBC.NextSpot = self;
		return true;
	}
Begin:
	Sleep(0.1);
	if ( !bNoProject && DoProjection() )
		if ( !class'SiegeStatics'.default.bRelease )
			Log("Projected "$Self$" on BotController");
	Sleep(2 + FRand() * (8-Priority) );
	Goto('Begin');
ProjectOnce:
	Sleep(0.1);
	if ( !bNoProject && DoProjection() )
		if ( !class'SiegeStatics'.default.bRelease )
			Log("Projected "$Self$" on BotController");
	Sleep(2 + FRand() * (8-Priority) );
	SetNewState();
}

//Return true if we MUST remove the current building
function bool CheckPending();

//Returns the best building index this team can build
function int SelectBuilding()
{
	return -1;
}

//Global method
function sg_BOT_BuildingBase NeedUpgrade( optional sg_BOT_BuildingBase Best, optional float Factor)
{
	local float fCur;
	local sgBuilding Cur;

	if ( PendingBuilding != none )	Cur = PendingBuilding;
	else							Cur = Building;

	if ( (Cur != none) && Cur.DoneBuilding && (Cur.Grade < 5) )
	{
		fCur = RateUpgrade( Cur) * (4+Priority);
		if ( Bot != none && Bot.TeamMode == TT_Upgrade )
			fCur *= 0.4;
	}
	if ( fCur > Factor )
	{
		Best = self;
		Factor = fCur;
	}
	if ( NextBuild != none )
		return NextBuild.NeedUpgrade( Best, Factor);
	return Best;
}

//Local method
function float RateUpgrade( sgBuilding Other)
{
	return -1;
}


function bool PendingToMain()
{
	if ( Building == none && PendingBuilding != none )
	{
		Building = PendingBuilding;
		PendingBuilding = none;
		return true;
	}
}

function SetNewState()
{
	PendingToMain();
	if ( (Bot == none) || (Bot.Objective != self) )
		Bot = SiegeGI(Level.Game).BotControllers[Team].FromGoal(self);
	if ( Bot != none && Bot.TeamMode == TT_Build )
		GotoState('QueuedByBot');
	else if ( Building != none )
		GotoState('MonitorBuilding');
	else if ( !bNoProject )
		GotoState('ProjectBuilding');
	else
		GotoState('');
}

//BOT ALWAYS EXISTS HERE
function bool ShouldCancel()
{
	if ( Building != none )
	{
		if ( Bot.BuildIndex == Building.iCatTag )
			return true;
		if ( SiegeGI(Level.Game).CategoryInfo[Team].BuildCost(Bot.BuildIndex) <= Building.BuildCost )
			return true;
	}
}

defaultproperties
{
	bStatic=False
	bNoDelete=False
	OwnRadius=100
	EditClass=class'sgEditBuilding'
	CatBStart=-1
	bUsable=true
}
