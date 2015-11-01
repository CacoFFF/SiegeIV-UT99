class sgBotController expands Info;

/*
NUKING PROFILES PER MAP
T (transloc)
J (jump only)
S (speed)
B (belt)
J (jetpack)
K (kanker boost)
number at end (amount required)

*/

var sgEquipmentSupplier MainSupplier, HealthSupplier;
var bool bTaskedSupplier;

var sgNukeLauncher FreeNuke;
var Pawn NukeSeeker;

var Pawn KillTarget; //Chase this player down

var SiegeGI Game;
var sgAIqueuer AIlist;
var int CurPriority;
var int NextBProject; //This build is what we aim for next
var sg_BOT_BuildingBase NextSpot; //We're placing it here
var sgAIqueuer NextMan; //Who's currently in charge of the project
var int ContBStart, ContBCount; //Container info

//*************************************
var byte TeamID; //This controller belongs to this team
var int AIcount; //Numbers of AI controlled players in this team
var int GameStage; //Basic stages
var int RUsLeft; //Quick fact for RU gatherers
var sgBaseCore Core;
var int StrategyCount; //CACUS NEEDS SET
//*************************************
// Stages:
// 0 > Initial Supplier and Core upgrade
// 1 > Dynamic project system
//*************************************



var int OnlyObjectives; //Switch this to 1 when we're doing the 'Attacking' routine only, (avoids secondary targets)

event Actor SpecialHandling(Pawn Other)
{
	local sgAIqueuer aQ;

	if ( Other == none || AIlist == none)
		return none;

	aQ = AIlist.FindBot( Other);
	if ( aQ != none )
	{
		if ( aQ.OverrideObjective != none )
			return aQ.OverrideObjective;
		if ( aQ.Objective != none )
			return aQ.Objective;
	}
	return RandomEnemyCore();
}

function CountRU()
{
	local WildcardsResources wRU;
	RUsLeft = 0;
	ForEach AllActors ( class'WildcardsResources', wRU)		RUsLeft++;
}
function bool FindSupplier()
{
	local sgEquipmentSupplier Best, Sup;
	
	ForEach AllActors (class'sgEquipmentSupplier', Sup )
	{
		if ( (Sup.Team != TeamID) || Sup.IsA('sgHealthPod') || Sup.IsA('sgHealthPodXXL') )
			continue;
		if ( Sup.bProtected )
		{
			MainSupplier = Sup;
			return true;
		}
		if ( (Best == none) || (Sup.BuildCost > Best.BuildCost) )
			Best = Sup;
	}
	if ( Best != none )
		MainSupplier = Best;
	return MainSupplier != none;
}

//Hardcoded proceeding formula, makes start faster
auto state Stage_Zero
{
	event BeginState()
	{
		GameStage = 0;
	}
	function BotRespawned( sgAIqueuer Bot)
	{
		if ( MainSupplier != none && (MainSupplier.Grade * 100 * FRand() < Bot.RU()) )
			Bot.TaskUpgrade( MainSupplier);
		else if ( (NextBProject >= 0) && (NextSpot != none) && (NextMan == none) && CanBuildProject() )
			Bot.TaskBuildTo( NextSpot, NextBProject);
	}
Begin:
	if ( RUsLeft != 0 )
		CountRU();
	if ( AIList == none )
		Goto('EndChecks');
	if ( MainSupplier == none )
	{
		if ( !FindSupplier() )
		{
			if ( sg_BOT_SupplyPoint(NextSpot) == none )
				ProjectFirstSupplier();
		}
		AssignGatherers( (NextBProject < 0) || (AIlist.TeamRU() < Game.CategoryInfo[TeamID].BuildCost(NextBProject)) ); //Needs gatherers
	}
	else if ( (MainSupplier.SCount > 5) && (Core.Grade < 5) )
		UpgradeCore();
	else if ( (MainSupplier.SCount <= 5) && (MainSupplier.Grade < 5) )
		UpgradeSupplier();
	else if ( MainSupplier.Grade >= 5 ) //Core upgrade may be delayed
	{
		GotoState('Stage_One','Begin');
		Stop;
	}
	if ( (MainSupplier != none) && TeamRequiresCapacity() && (Core.Grade < 5) ) //Team has too much RU, use it on core?
		UpgradeCore();
EndChecks:
	Sleep( 0.5 + FRand() );
	Goto('Begin');
}

state Stage_One
{
	event BeginState()
	{
		RUsLeft = 0; //We don't need this anymore
		GameStage = 1;
		Log("BotController for team "$TeamID$" has left initial phase");
	}
Begin:
	ScanPriority();
	if ( AIList != none )
	{
		TaskToProject();
		if ( FRand() < 0.3 )
			TaskToUpgrade();
		if ( FRand() < 0.6 )
			TaskToContainer();
	}
	Sleep( 0.5 + FRand() );
	Goto('Begin');
}


//General function that checks a target's validity!
function bool ValidTarget( Pawn Other, Actor aTarget)
{
	if ( aTarget.bDeleteMe )
		return false;
	if ( (Inventory(aTarget) != none) && (aTarget.Owner != none) )
		return false;
}



function BotHandling( Bot Other);


function int IncomingNuker()
{
	local sgNukeLauncher nuke;
	local int result;
	
	ForEach AllActors (class'sgNukeLauncher', nuke)
	{
		if ( nuke.Owner == none )
			FreeNuke = nuke;
		else if ( Pawn(Nuke.Owner) != none && Pawn(Nuke.Owner).PlayerReplicationInfo != none )
		{
			if ( Pawn(Nuke.Owner).PlayerReplicationInfo.Team != TeamID )
				result++;
		}
	}
	return result;
}

function Pawn FindNearestAI( vector Origin, float MaxDist)
{
	local Pawn P, best;
	local float BestD;
	
	BestD = MaxDist + 100;
	ForEach RadiusActors (class'Pawn', P, MaxDist, Origin)
	{
		if ( (P.PlayerReplicationInfo != none) && !P.IsA('PlayerPawn') && (P.PlayerReplicationInfo.Team == TeamID) )
		{
			if ( VSize( P.Location - Origin) < BestD )
			{
				best = P;
				BestD = VSize( best.Location - Origin);
			}
		}
	}
	return best;
}

//FAST, prioritize normal nukes first!
function sgWarhead SearchOwnNuke( Pawn Other)
{
	local sgWarhead InviWarhead, sgW;

	ForEach Other.ChildActors (class'sgWarhead', sgW)
	{
		if ( sgW.SCount > 0 )
			continue;
		if ( sgW.class != class'sgWarhead' )
			InviWarhead = sgW;
		else
			return sgW;
	}
	return InviWarhead;
}

function sgConstructor GetConstructor( Pawn Other)
{
	if ( Other.Weapon.class == class'sgConstructor' )
		return sgConstructor(Other.Weapon);
	return sgConstructor( Other.FindInventoryType(class'sgConstructor') );
}

function sgBaseCore RandomEnemyCore()
{
	local int i;
	local float Count;
	local sgBaseCore result;

	For ( i=0 ; i<4 ; i++ )
		if ( (Game.Cores[i] != none) && (Game.Cores[i].Team != TeamID) )
		{
			Count += 1f;
			if ( FRand() <= (1/Count) )
				result = Game.Cores[i];
		}
	return result;
}

function int GetPlayers( int Base, float Percent)
{	Percent *= AIcount;
	return Base + int(Percent);
}

//Used by stage 1
function AssignGatherers( bool bPreSup)
{
	local int D, O, S, G;
	local sgAIqueuer sA, sO;
	local int GatherReq;
	local sg_BOT_SupplyPoint aSup;

	if ( AIlist == none )
		return;
	
	//Defense, Offense, S(others)
	For ( sA=AIlist ; sA!=none ; sA=sA.nextQ )
	{
		if ( sA.BotRole == 'Defend' )
			D++;
		else if ( sA.BotRole == 'Attack' )
			O++;
		else
			S++;
		if ( WildcardsResources(sA.Objective) != none )
			G++;
	}

	
	//Assign players with nearby RU first
	if ( bPreSup )
	{
		GatherReq = GetPlayers( 1, 0.5);
		if ( (GatherReq -= G) <= 0 )
			return;
		GatherReq -= AIlist.AssignByNearbyRU(GatherReq);
		if ( GatherReq <= 0 )
			return;
		//Assign to distance RU, totally random
		if ( S > 0 )
			GatherReq -= AIlist.AssignByRandomRU(GatherReq,'Freelance'); //Assign freelancers
		if ( GatherReq > 0 && (O > 0) )
			GatherReq -= AIlist.AssignByRandomRU(GatherReq,'Attack'); //Assign attackers now
		if ( GatherReq > 0 )
			GatherReq -= AIlist.AssignByRandomRU(GatherReq, ''); //Assign everyone
		return;
	}


	//Task bots into the project
	aSup = sg_BOT_SupplyPoint(NextSpot);
	if ( aSup != none )
	{
		sA = NextMan;
		if ( sA == none )
		{
			sA = AIlist.BestUpgradeCandidate( aSup.Location,,,);
			sA.TaskBuildTo( aSup, NextBProject);
			sA.Bot.TeamBroadcast("Building Supplier");
		}
		GatherReq = AIlist.IncomingUpgradeRU( sA);
		aSup = sg_BOT_SupplyPoint(sA.Objective);
		if ( sA.CheatRU() + GatherReq > Game.CategoryInfo[TeamID].BuildCost(NextBProject) ) //Good
			return;
		//Send somebody to upgrade this AI
		sO = AIlist.BestUpgradeCandidate( sA.Bot.Location,,,sA);
		sO.TaskUpgrade( sA);
		return;
	}
	//We don't have a supplier point... LOL
}

//Global method
function UpgradeCore()
{
	local sgAIqueuer sA;
	
	For ( sA=AIlist ; sA!=none ; sA=sA.nextQ )
	{
		if( sA.Bot.Enemy != none || sA.Objective != none )
			continue;
		if ( sA.RU() > 30 + VSize(sA.Bot.Location - Core.Location) * 0.01 )
			sA.TaskUpgrade( Core);
	}

	if ( AIlist != none && RUsLeft > 0 )
		KeepGatherer();
}

//Global method
function UpgradeSupplier()
{
	local sgAIqueuer sA;

	For ( sA=AIlist ; sA!=none ; sA=sA.nextQ )
	{
		if( sA.Bot.Enemy != none || sA.Objective != none || VSize(sA.Bot.Location - MainSupplier.Location) > 300 )
			continue;
		if ( sA.RU() > 25 + Core.Grade * 5 )
			sA.TaskUpgrade( MainSupplier);
	}
	if ( !bTaskedSupplier )
	{
		bTaskedSupplier = true;
		For ( sA=AIlist ; sA!=none ; sA=sA.nextQ )
			if ( VSize(sA.Bot.Location - MainSupplier.Location) < 2500 )
				sA.SupplierTimer = 2;
	}
	if ( AIlist != none && RUsLeft > 0 )
		KeepGatherer();
}

//Keep one extra gatherer... unless theres visible RU
function KeepGatherer()
{
	local sgAIqueuer sA;
	if ( AIlist.AssignByNearbyRU( AIcount) > 0 )
		return;
	if ( AIlist.RUgatherers() < AIcount * 0.3 )
		AIlist.AssignByRandomRU(1,'');
}

//Called Post-Core and supplier upgrades
function bool TeamRequiresCapacity()
{
	if ( (AIlist == none) )
		return false;
	if ( GameStage == 0 )
		return AIlist.TeamRU() * 1.3 > AIlist.MaxRU() * AIcount;
	if ( AIlist.MaxRU() < 1600 )
		return AIlist.TeamRU() * 4 > AIlist.MaxRU() * AIcount;
	return AIlist.TeamRU() * 1.8 > AIlist.MaxRU() * AIcount;
}

function TaskCapacity()
{
	local sgAIqueuer CapBuilder; //Already assigned
}

function sgBuilding ContainerToUpgrade()
{
	local sgContainer aCont;
	local WildcardsSuperContainer sCont;
	local sgBuilding Best;
	local float fBest, weight;

	ForEach AllActors (class'sgContainer', aCont)
	{
	}
}

//Find what suppliers team can build, then find best locations
//The cheapest buildable supplier is hardcoded here
function ProjectFirstSupplier()
{
	local sgCategoryInfo sgC;
	local int i, iBest;
	local float fCur, fBest, TeamRU, fHigh;
	local bool bAffordable;
	local sg_BOT_BuildingBase BBase;
	local sg_BOT_SupplyPoint BBest;

	iBest = -1;
	sgC = Game.CategoryInfo[TeamID];
	TeamRU = AIList.TeamRU();
	fHigh = 99999;
	For ( i=0 ; i<sgC.iBuilds ; i++ ) //Choose the supplier
	{
		if ( ClassIsChildOf( sgC.GetBuild(i), class'sgSupplier') || (sgC.GetBuild(i) == class'sgSupplierXXL') )
		{
			if ( sgC.GetBuild(i).static.AI_Rate( self, sgC, i) > 0 )
			{
				fCur = sgC.BuildCost(i);
				if ( fCur < TeamRU ) //Cool, we already have RU
				{
					bAffordable = true;
					if ( fCur > fBest )
					{
						iBest = i;
						fBest = fCur;
					}
				}
				else if ( !bAffordable ) //We have no ru, and no buyable supplier, pick cheaper
				{
					if ( fCur < fHigh )
					{
						iBest = i;
						fHigh = fCur;
					}
				}
			}
		}
	}
	if ( iBest < 0 )
		return;
	NextBProject = iBest;
	iBest = -1;
	For ( BBase=Game.BuildMarkers[TeamID] ; BBase!=none ; BBase=BBase.NextBuild ) //Choose the marker
	{
		if ( sg_BOT_SupplyPoint(BBase) != none )
		{
			if ( BBase.Priority > iBest )
			{
				iBest = BBase.Priority;
				fCur = 1;
				BBest = none;
			}
			if ( BBase.Priority < iBest )
				continue;
			if ( FRand() * fCur <= 1 )
				BBest = sg_BOT_SupplyPoint(BBase);
			fCur += 1.0;
		}
	}
	NextSpot = BBest; //Fix for super supply point
}

function BotRespawned( sgAIQueuer Bot)
{
	if ( (Core.Grade < 5) && (Bot.RU() > 100 * Core.Grade) ) //Global method, everyone should upgrade the core
		Bot.TaskUpgrade( Core);
	//Our project can be built, let's task a bot
//	else if ( (NextBProject >= 0) && (NextSpot != none) && (NextMan == none) && CanBuildProject() )
//		Bot.TaskBuildTo( NextSpot, NextBProject);
}

function ScanPriority()
{
	local sg_BOT_BuildingBase sgB;
	local int i;

	i=-1;
	For ( sgB=Game.BuildMarkers[TeamID] ; sgB!=none ; sgB=sgB.NextBuild )
	{
		if ( sgB.Building == none )
			i = Max(sgB.Priority, i);
	}
	CurPriority = i;
}

function TaskToProject()
{
	local sgCategoryInfo sgC;
	local float Cost;
	local int MaxRole;
	local sgAIqueuer sgA;

	if ( (NextBProject >= 0) && (NextSpot != none) && CanBuildProject() )
	{
		if ( NextSpot.ShouldCancel() )
		{
			NextBProject = -1;
			NextSpot = none;
			Goto KILL_TASK;
		}
		MaxRole = NextSpot.Priority;
		MaxRole = Max( MaxRole-2, 0);
		if ( NextMan == none )
			NextMan = AIList.RoleUpgradeCandidate( NextSpot.Location,,,0,MaxRole);
		if ( NextMan != none )
		{
			sgC = Game.CategoryInfo[TeamID];
			if ( NextMan.TeamMode != TT_Build )
				NextMan.TaskBuildTo( NextSpot, NextBProject);
			Cost = sgC.BuildCost( NextBProject);
			if ( NextMan.RU() + AIList.IncomingUpgradeRU(NextMan) < Cost )
			{
				sgA = AIList.RoleUpgradeCandidate( NextMan.Location,,,0,MaxRole);
				if ( sgA != none )
					sgA.TaskUpgrade(NextMan);
			}
		}
//		if ( NextMan != none )
//			Log(NextMan@MaxRole@NextMan.Objective@Cost@NextMan.RU()@AIList.IncomingUpgradeRU(NextMan));
//		else
//			Log( AIList.IncomingUpgradeRU(NextMan) $" available RU");
	}
	else if ( NextMan != none && NextMan.TeamMode == TT_Build )
	{
		KILL_TASK:
		NextMan.TeamMode = TT_None;
		if ( sg_BOT_BuildingBase(NextMan.Objective) != none )
			sg_BOT_BuildingBase(NextMan.Objective).CancelBot();
		NextMan.Objective = none;
		NextMan = none;
	}
}

//Builder needs full RU for this shit?
function TaskToContainer()
{
	local float Cost, Rating;
	local sg_BOT_ContainmentPoint sgC;
	local int iCont, MaxRole;
	local sgAIqueuer Bot, Bot2;

	//Calculating RATING here will save processing time!
	iCont = SelectContainer( Rating);
	if ( iCont < 0 )
		return;

	//Pass 0: Find builders already tasked to containers
	Bot = AIList.BOTContGoal();
	if ( Bot != none )
	{
		if ( Bot.RU() + AIList.IncomingUpgradeRU(Bot) < Game.CategoryInfo[TeamID].BuildCost( iCont) )
		{
			MaxRole = sg_BOT_BuildingBase(Bot.Objective).Priority;
			MaxRole = Max( MaxRole-2, 0);
			Bot2 = AIList.RoleUpgradeCandidate( Bot.Location,,20,0,MaxRole);
			if ( Bot2 != none )
				Bot2.TaskUpgrade( Bot);
			if ( !class'SiegeStatics'.default.bRelease )
				Log("BOT NEEDED EXTRA RU FOR CONTAINER");
		}
		else if ( !class'SiegeStatics'.default.bRelease )
			Log("BOT HEADING TO BUILD CONTAINER");
		return;
	}

	//Pass 1: RU requirements
	if ( NextBProject >= 0 && NextSpot != none )
	{
		Cost = Game.CategoryInfo[TeamID].BuildCost( NextBProject);
		if ( Game.MaxFutureRUs[TeamID] < Cost )
			Goto FIND_BY_PRIORITY;
	}
	//Pass 2: Fill the priority list for 3 and 4 with obligatory containers
	else if ( ((CurPriority == 4) && Game.BuildMarkers[TeamID].OnlyContainersInPriority(4)) || ((CurPriority == 3) && Game.BuildMarkers[TeamID].OnlyContainersInPriority(3)) )
		Goto FIND_BY_PRIORITY;
	//Pass 3: Protect buildings

	return;
	FIND_BY_PRIORITY:
	sgC = Game.BuildMarkers[TeamID].FindPriorityCont( FRand() < 0.7, Rating);
	if ( !class'SiegeStatics'.default.bRelease )
		Log("FINDING CONTAINER POINT... "$sgC);
	MaxRole = sgC.Priority;
	MaxRole = Max( MaxRole-2, 0);
	Bot = AIList.RoleUpgradeCandidate( sgC.Location,,30f,0,MaxRole);
	if ( Bot != none )
	{
		if ( !class'SiegeStatics'.default.bRelease )
			Log("SENT BOT");
		Bot.TaskBuildTo( sgC, iCont);
	}
}

function TaskToUpgrade()
{
	local float Factor;
	local sg_BOT_BuildingBase sgBest;
	local int i, Times, MaxRole;
	local sgAIqueuer Bot;
	
	if ( Game.BuildMarkers[TeamID] == none )
		return;
	Times = 1 + AICount/6;
	Times += int( RoleRU(0,1,false) / 1500); //Defenders stockpiling RU?
	Times = Min(Times, 10); //10 loops max
	For ( i=0 ; i<Times ; i++ )
	{
		sgBest = Game.BuildMarkers[TeamID].NeedUpgrade(, FRand() * (Times-i) );
		if ( sgBest == none )
			continue;
		MaxRole = sgBest.Priority;
		MaxRole = Max( MaxRole-2, 0);
		Bot = AIList.RoleUpgradeCandidate( sgBest.Location,,35f + i*5,0,MaxRole); //Preset factor!
		if ( Bot != none )
			Bot.TaskUpgrade(sgBest);
	}
}

//*******************************************************
//********************************************
//************ Some other AI facts ***********
//********************************************
//*******************************************************

final function float MaxRUs()
{
	return Game.MaxRUs[TeamID];
}
final function float MaxFutureRUs()
{
	return Game.MaxFutureRUs[TeamID];
}
final function sgAIqueuer FromGoal( actor Other)
{
	if ( AIList != none )		return AIList.FromGoal(Other);
	return none;
}
final function float RoleRU( int MinRole, int MaxRole, bool bCountPlayers)
{
	local sgAIqueuer sgA;
	local float Result;
	
	For ( sgA=AIList ; sgA!=none ; sgA=sgA.nextQ )
	{
		if ( !bCountPlayers && sgA.bNoAI )
			continue;
		if ( sgA.RoleCode >= MinRole && sgA.RoleCode <= MaxRole )
			Result += sgA.RU();
	}
	return Result;
}
final function bool CanBuildProject( optional float ReservedRU)
{
	local sgCategoryInfo sgC;
	local float Cost;

	sgC = Game.CategoryInfo[TeamID];
	if ( sgC.RulesAllow(NextBProject) )
	{
		Cost = sgC.BuildCost( NextBProject);
		if ( Cost <= Game.MaxRUs[TeamID] )
			return RoleRU(0,Max(int(NextSpot.Priority)-2,0),true) >= (Cost + ReservedRU);
	} 
}

//Returns the best container index this team can build
function int SelectContainer( out float fBest)
{
	local sgCategoryInfo sgC;
	local int i, iBest;
	local float fCur;

	sgC = Game.CategoryInfo[TeamID];
	if ( (ContBStart == -1) || (ContBCount != sgC.iBuilds) )
		ScanOptCat( sgC);

	iBest = -1;
	For ( i=ContBStart ; i<ContBCount ; i++ )
	{
		if ( ClassIsChildOf(sgC.GetBuild(i),class'sgContainer') )
		{
			fCur = sgC.GetBuild(i).static.AI_Rate( self, sgC, i);
			if ( fCur > fBest )
			{
				fBest = fCur;
				iBest = i;
			}
		}
	}
	return iBest;
}

//If no build, return iBuild (container version)
//If something edits the iBuild, we'll check again
function ScanOptCat( sgCategoryInfo sgC)
{
	local int i;

	ContBCount = sgC.iBuilds;
	For ( i=0 ; i<ContBCount ; i++ )
	{
		if ( ClassIsChildOf(sgC.GetBuild(i),class'sgContainer') )
		{
			ContBStart = i;
			return;
		}
	}
	ContBStart = ContBCount;
}

defaultproperties
{
	RUsLeft=-1
	NextBProject=-1
	CurPriority=4
}