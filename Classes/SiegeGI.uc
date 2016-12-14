// SiegeGI.
// * Revised by nOs*Badger
// * Extended by WILDCARD
// * Optimized and improved by Higor
//=============================================================================
class SiegeGI extends TeamGamePlus config(SiegeIV_0028);

var class<Object> GCBind; //SiegeNative plugin ref to prevent GC cleaning

var sgRURecovery    RURecovery;
var config float    NumResources;
var config float    MaxCoreSnipeDistance;
var config int      MaxSiegeTeams;
var config int		MaxRUresources;
var config int		RUsPerTeam;

// Special Options
var config bool debug;
var() config int SpawnProtSecs;
var() config float TranslocBaseForce;
var() config float TranslocLevelForce;
var() config bool bUseDenied;
var() config bool bUseNukeDeco;
var() config bool bShareFingerPrints;
var() config bool bDisableIDropFix;
var() config bool bBotCanCheat;
var() config bool bCore5AddsEnforcer;
var() config bool bPlayersRelevant;

// The Map Specific List
var config vector RandomSpawnerLocation[32];
var config string RandomSpawnerMap[32];
var() config name GameProfile;

var bool CheckedRandomSpawner;
var bool bUseBotz;

var float           MaxRUs[4], MaxFutureRUs[4];
var globalconfig string Weapons[17];

var() class<Weapon> WeaponClasses[17];
var sgBaseCore      Cores[4];
var sgBotController	BotControllers[4];

var config string   SpecIPs[32];
var config bool     bPreventSpectate;
var() config float	BaseMotion;

// Cheat settings

var bool            FreeBuild;
var bool	    SupplierProtection;
var bool	    bStartedPlay;
var config float    StartingMaxRU,
                    StartingRU;

// Did we sucessfully Spawn a RandomSpawner actor sucessfully?
var bool SpawnedRandomItemSpawner;

var bool MonsterMadness;
var int MonstersLeft;

//Some more Higor stuff
var config bool bUseRemoveGuardian; //Admin alert stuff
var config bool bAutoconfigWeapons; //For mutator support
var bool bMutatedWeapons; //Mutate weapons after starting games > we must mutate SiegeGI, sgSupplier, sgSupplierXXL, sgSupplierX as far as I know
var bool bMutatingWeapons; //Intercept IsRelevant calls

var bool bMatchStarted;
var bool bRandomizeCores;
var bool bRoundMode;
var int RoundIndex; //0,1 NORMAL, 2 IS TIEBREAKER
var int RoundGames;
var int RoundRestart;
var float RoundRuScale;
var sgCategoryInfo CategoryInfo[4];
var Weapon theWeapon; //We keep this pointer during Weapon mutation

var sgBuildingMap BuildingMaps[4];
var Name BuildingMapNames[4];
var sg_BOT_BuildingBase BuildMarkers[4];
var Object ProfileObject;
var SiegeCategoryRules CategoryRules;
var CoreModifierRules CoreRules;

/*
replication
{
    // Things the server should send to the client.
    reliable if ( Role == ROLE_Authority )
        MaxRUs;
}
*/

//Higor: rotate teams starts (teams 0-5 to 100-105), then finish and put them back on 0-5
function SwapPlayerStarts( byte To, byte From)
{
	local PlayerStart P;
	ForEach AllActors (class'PlayerStart', P)
	{
		if ( P.TeamNumber == From )
			P.TeamNumber = To+100;
	}
}
function FinishStarts()
{
	local PlayerStart P;
	ForEach AllActors (class'PlayerStart', P)
	{
		if ( (P.TeamNumber >= 100) && (P.TeamNumber <= 105) )
			P.TeamNumber -= 100;
	}
}

function FinishBMaps()
{
	local int i, j;
	local sg_BOT_BuildingBase Tmp;

	While ( i<4 )
	{
		if ( BuildMarkers[i] == none )
			break;
		if ( BuildMarkers[i].Team == i )
		{
			i++;
			continue;
		}
		j = BuildMarkers[i].Team;
		Tmp = BuildMarkers[j];
		BuildMarkers[j] = BuildMarkers[i];
		BuildMarkers[i] = Tmp;
		BuildMarkers[j].GlobalSetTeam( j);
		BuildMarkers[i].GlobalSetTeam( i);
		i++;
	}
}

function InitGame(string options, out string error)
{
	local Actor f;
	local Inventory SuperItem;
	local sgBaseCore b;
	local int team;
	local string opt;
	local int i, j, k, Redeemers, DamageAmps, ShieldBelts, Invisibilitys, BigKegOfHealths;
	local WarheadLauncher WLT;
	local UDamage UDT;
	local UT_Shieldbelt SBT;
	local UT_Invisibility IVT;
	local HealthPack HPK;
	local Info aInfo;
	local string sParse;
	local flagBase FlagList[5], aFlg, fList[5];
	local float FlagTeamList[5];
	local sgBotController BController;

	GameName="Siege IV";
	bUseTranslocator = True;
	bMultiWeaponStay = false;
	bCoopWeaponMode = true;
	class'SiegeStatics'.static.DetectXCGE( self);
	Super.InitGame(options, error);

	opt = ParseOption(options, "FreeBuild");
	if ( opt == "1" || opt ~= "true" )
		FreeBuild = true;

	opt = ParseOption(options, "SwapCores");
	if ( opt == "1" || opt ~= "true" )
		bRandomizeCores = true;

	opt = ParseOption(options, "RoundMode");
	if ( opt == "1" || opt ~= "true" )
		bRoundMode = true;

	MaxRUs[0] = StartingMaxRU;
	MaxRUs[1] = StartingMaxRU;
	MaxRUs[2] = StartingMaxRU;
	MaxRUs[3] = StartingMaxRU;
	MaxFutureRUs[0] = StartingMaxRU;
	MaxFutureRUs[1] = StartingMaxRU;
	MaxFutureRUs[2] = StartingMaxRU;
	MaxFutureRUs[3] = StartingMaxRU;
	
	MaxTeams = 2;
	MaxSiegeTeams = Clamp(MaxSiegeTeams, 0, 4);

	//Parse external map parameters
	ForEach AllActors( class'Info', aInfo)
	{
		if ( aInfo.IsA('SiegeMapInfo') )
		{
			sParse = aInfo.GetPropertyText("bRandomizeCores");
			if ( Caps(sParse) == "TRUE" )
			{
				bRandomizeCores = true;
				Log("RANDOMIZE CORES!");
			}
			else if ( Caps(sParse) == "FALSE" )
			{
				bRandomizeCores = false;
				Log("NEVER RANDOMIZE CORES!");
			}
			sParse = aInfo.GetPropertyText("bRounds");
			if ( Caps(sParse) == "TRUE" )
			{
				bRoundMode = true;
				Log("ROUND GAME STARTED!");
			}
			else if ( Caps(sParse) == "FALSE" )
			{
				bRoundMode = false;
				Log("ROUND GAME DISABLED FOR THIS MAP!");
			}
			break;
		}
	}

	//List flagbases, randomize if more than 1 per team
	ForEach AllActors( class'FlagBase', aFlg)
	{
		FlagTeamList[aFlg.Team] += 1;
		if ( (FRand() * FlagTeamList[aFlg.Team]) <= 1.0 )
		{
			FlagList[aFlg.Team] = aFlg;
			if ( FlagTeamList[aFlg.Team] == 1 )
				j++;
		}
		//Initialize the required AI maps
		if ( BuildingMaps[aFlg.Team] == none )
		{
			BuildingMaps[aFlg.Team] = new(Outer,BuildingMapNames[aFlg.Team]) class'sgBuildingMap';
			BuildingMaps[aFlg.Team].Team = aFlg.Team;
			BuildingMaps[aFlg.Team].FullParse( self);
		}
	}
	For ( i=j ; i<5 ; i++ )
		if ( FlagList[i] != none )
			bRandomizeCores = False; //Do not randomize if map flags aren't properly set, our array is compacted
	if ( bRandomizeCores )
	{
		For ( i=j-1 ; i>=0 ; i-- ) //Randomize flags in a second array
		{
			k = Rand(j);
			fList[i] = FlagList[k];
			if ( BuildMarkers[i] != none ) //Change the team tag of this building map
				BuildMarkers[i].Team = k;
			FlagList[k] = FlagList[--j];
		}
		For ( i=0 ; i<5 ; i++ ) //Rebuild flaglist array we just cleared
		{
			if ( fList[i] == none )
			{
				j = i;
				break;
			}
			FlagList[ fList[i].Team] = fList[i];
		}
//		Log("Flags in team order FLIST: "$ fList[0].Team@fList[1].Team@fList[2].Team);
//		Log("Flags in team order FLAGLIST: "$ FlagList[0].Team@ FlagList[1].Team@ FlagList[2].Team);
		For ( i=0 ; i<j ; i++ ) //Swap navigation points between teams
		{
			k = fList[i].Team;
			if ( k == i ) //If equal, then we're not moving this one
				continue;
			SwapPlayerStarts( i, k);
			fList[i].Team = i; //fList[i] == FlagList[k]

		}
		FinishBMaps();
		FinishStarts();
	}
	else
	{
		For ( i=0 ; i<5 ; i++ )
			fList[i] = FlagList[i];
	}

	For ( i=0 ; i<5 ; i++ )
	{
		if ( i >= MaxSiegeTeams )
			break;
		if ( fList[i] != none  )
		{
			if ( Cores[i] == none )
			{
				b = Spawn(class'sgBaseCore',,, fList[i].Location);
				if ( b != none )
				{
                    b.Team = i;
					MaxTeams = Max(MaxTeams, i+1);
					Cores[i] = b;
					b.HitActor = FlagList[i]; //Hacky way to link a Core with it's flagbase
					b.bCoreDisabled = true;
					BController = Spawn(class'sgBotController',,'AIController');
					BController.TeamID = i;
					BController.Game = self;
					BController.Core = Cores[i];
					BotControllers[i] = BController;
				}
				else
					log("SiegeGI: Failed to spawn BaseCore for team" @ i $"!");
			}
		}
	}

    foreach AllActors( class'Inventory', SuperItem)
    {
		if ( WarheadLauncher(SuperItem) != None )
			Redeemers++;
		else if ( UDamage(SuperItem) != None )
			DamageAmps++;
		else if ( UT_Shieldbelt(SuperItem) != None )
			ShieldBelts++;
		else if ( UT_Invisibility(SuperItem) != None )
			Invisibilitys++;
		else if ( HealthPack(SuperItem) != None )
			BigKegOfHealths++;
		else if ( (WildcardsResources(SuperItem) != none) || (ScubaGear(SuperItem) != none) )
			continue;
		else
			SuperItem.Destroy();

		if ( !SuperItem.bDeleteMe ) //I haven't destroyed these items (stated above, except resources)
		{
			SuperItem.Inventory = Inventory;
			Inventory = SuperItem; //Build a temporary inv chain in this actor
		}
	}

	InsertRU();
//	Tester( 0);

	if ( GameProfile == '' )
		GameProfile = 'SiegeDefault';

	For ( i=0 ; i<4 ; i++ )
	{
		if ( Cores[i] == none )
			continue;
		CategoryInfo[i] = Spawn( class'sgCategoryInfo');
		CategoryInfo[i].Team = i;
	}

	//Load custom weapons, no package means load straight from this SiegeIV file
	sParse = string( class);
	sParse = Left( sParse, InStr(sParse,".") ) $ ".";
	for ( i=0; i<16 ; i++ )
		if ( Weapons[i] != "" )
		{
			opt = Weapons[i];
			if ( InStr(opt,".") == -1 )
				opt = sParse $ opt;
            WeaponClasses[i] = class<Weapon>(DynamicLoadObject(opt,class'Class'));
		}

    RURecovery = spawn(class'sgRURecovery');

	// Spawn Random Item Spawner
	if ( Redeemers == 1 && !SpawnedRandomItemSpawner )
		foreach AllActors( class'WarheadLauncher',WLT)
		{
			SpawnedRandomItemSpawner = true;
			Spawn(class'WeightedItemSpawner',,,WLT.Location);
		}
	if ( DamageAmps == 1 && !SpawnedRandomItemSpawner )
		foreach AllActors( class'UDamage',UDT)
		{
			SpawnedRandomItemSpawner = true;
			Spawn(class'WeightedItemSpawner',,,UDT.Location);
		}
	if ( BigKegOfHealths == 1 && !SpawnedRandomItemSpawner )
		foreach AllActors( class'HealthPack',HPK)
		{
			SpawnedRandomItemSpawner = true;
			Spawn(class'WeightedItemSpawner',,,HPK.Location);
		}
	if ( ShieldBelts == 1 && !SpawnedRandomItemSpawner )
		foreach AllActors( class'UT_Shieldbelt',SBT)
		{
			SpawnedRandomItemSpawner = true;
			Spawn(class'WeightedItemSpawner',,,SBT.Location);
		}
	if ( Invisibilitys == 1 && !SpawnedRandomItemSpawner )
		foreach AllActors( class'UT_Invisibility',IVT)
		{
			SpawnedRandomItemSpawner = true;
			Spawn(class'WeightedItemSpawner',,,IVT.Location);
		}

	//Delete saved inventory chain
	For ( SuperItem=Inventory ; SuperItem!=none ; SuperItem=SuperItem.Inventory )
		SuperItem.Destroy();
	Inventory = none;
	if ( bRoundMode )
		RoundGames = MaxTeams;

	//Clear defaults transferred from previous map
	class'sgSupplier'.static.ClearWeaponClasses();
	class'sgSupplierX'.static.ClearWeaponClasses();
	class'sgSupplierXXL'.static.ClearWeaponClasses();
}

function InsertRU()
{
	local vector vMin, vMax;
	local PathNode P;
	local NavigationPoint N, aS, aE;
	local float cCount[4], aDist;
	local float RUsLeft[4];
	local int i, j, iCount;

	if ( Level.NavigationPointList == none )
		return;

	vMin = Level.NavigationPointList.Location;
	vMax = vMin;
	For ( N=Level.NavigationPointList.NextNavigationPoint ; N!=none ; N=N.NextNavigationPoint )
	{
		vMin.X = fMin( N.Location.X, vMin.X);
		vMax.X = fMax( N.Location.X, vMax.X);
		vMin.Y = fMin( N.Location.Y, vMin.Y);
		vMax.Y = fMax( N.Location.Y, vMax.Y);
		vMin.Z = fMin( N.Location.Z, vMin.Z);
		vMax.Z = fMax( N.Location.Z, vMax.Z);
		N.Cost = 0;
		N.HitActor = none;
		N.bMeshCurvy = false;
	}

	aDist = VSize(vMax - vMin) * 0.2; //25% the total map
	
	For ( i=0 ; i<arrayCount(Cores) ; i++ )
		if ( Cores[i] != none )
			RUsLeft[i] = RUsPerTeam;

	//When this navigation point's Cost is > 0, it means that we already checked all of it's connections
	//When this path node has HitActor, it means that we already spawned a crystal

	//We will try to swarm as many RUs as we can using the c++ pathing
	For ( i=0 ; i<arrayCount(RUsLeft) ; i++ ) //This is the TEAM iterator
	{
		while ( RUsLeft[i] > RUsPerTeam * 0.3 )
		{
			//Find candidates, add ru to surroundings
			N = GetLinkedCandidate( NavigationPoint(Cores[i].HitActor),++iCount);
			if ( N == none )
				break;
			For ( j=0 ; (N.Paths[j]>0) && (j<16) && (RUsLeft[i]>(RUsPerTeam * 0.3)); j++ )
			{
				if ( N.HitActor == none )
				{
					N.HitActor = N;
					if ( FRand() > VSize(N.Location - Cores[i].Location) / (aDist * 0.3)  )
						continue;
					if ( N.IsA('PathNode') && (FRand() > 0.1) )
						N.HitActor = none;
					else if ( N.IsA('InventorySpot') && (FRand() > 0.7) )
						N.HitActor = none;

					if ( N.HitActor != none )
						continue;
					N.HitActor = Spawn(class'WRU50',,,N.Location);
					RUsLeft[i] -= 1;
				}
			}
		}
	}


	For ( i=0 ; i<arrayCount(RUsLeft) ; i++ ) //Expensive iterator, unfortunately
	{
		if ( RUsLeft[i] <= 0 )
			continue;
		ForEach Cores[i].RadiusActors (class'PathNode', P, aDist)
			if ( P.HitActor == none )
				cCount[i] += 1;
		ForEach Cores[i].RadiusActors (class'PathNode', P, aDist)
			if ( (P.HitActor == none) && (FRand()*(cCount[i]-=1) < RUsLeft[i] ) )
			{
				P.HitActor = Spawn(class'WRU50',,,P.Location);
				if ( (RUsLeft[i] -= 1) <= 0)
					break;
			}
	}
	
	aDist = 0;
	For ( i=0 ; i<arrayCount(RUsLeft) ; i++ ) //Last step, disregard teams
		aDist += RUsLeft[i];

	RUsLeft[0] = 0;
	if ( aDist > 0 )
	{
		ForEach AllActors (class'PathNode', P)
			if ( P.HitActor == none )
				RUsLeft[0] += 1;
		ForEach AllActors (class'PathNode', P)
			if ( (P.HitActor == none) && (FRand()*(RUsLeft[0]-=1) < aDist ) )
			{
				P.HitActor = Spawn(class'WRU50',,,P.Location);
				if ( (aDist -= 1) <= 0)
					break;
			}
	}

	//UT SDK compatibility
	For ( N=Level.NavigationPointList ; N!=none ; N=N.NextNavigationPoint )
	{
		N.Cost = 0;
		N.HitActor = none;
		N.bMeshCurvy = false;
	}
	For ( i=0 ; i<ArrayCount(Cores) ; i++ )
	{
		if ( Cores[i] != none )
			Cores[i].HitActor = none;
	}

}

//We're using this to swarm various RU crystals around the core
static function NavigationPoint GetLinkedCandidate( navigationPoint Base, int iCount) //iCount is our ID, to prevent endless loops
{
	local int i, j, h, k, n;
	local NavigationPoint nCur, Cached[16];
	local actor nS, nE;
	local bool bLog;

	//First iteration
	if ( Base.Cost == 0 )
	{
		Base.Cost = iCount;
		return Base;
	}

	if ( false )
	{
		Log("Call number "$iCount);
		bLog = true;
	}

	//Negative costed paths are out of choice!!!
	nCur = Base;
	CUR_AGAIN:
	Cached[n++] = nCur;
	if ( bLog )
		Log("Caching "$ nCur.Name $" to "$n);
	if ( nCur.Cost != 0 )
	{
		if ( nCur.Cost < 0 )
			Goto SKIP_ZERO;

		nCur.Cost = iCount;
		//Find 0 costed path
		For ( i=0 ; (i<16) && (nCur.Paths[i]>0) ; i++ )
		{
			nCur.describeSpec( nCur.Paths[ i ], nS, nE, h, k); 
			if ( NavigationPoint(nE).Cost == 0 )
			{
				NavigationPoint(nE).Cost = iCount;
				if ( bLog )
					Log("Found new 0 candidate "$ nE.Name);
				return NavigationPoint(nE);
			}
		}

		SKIP_ZERO:
		//Find positive costed and iterate here, also, mark this path as negative CUR
		nCur.Cost = -iCount; //Go negative for non-bounce back paths
		if ( bLog )
			Log("Using "$ nCur.Name $" as bridge to find candidate");
		For ( i=0 ; (i<16) && (nCur.Paths[i]>0) ; i++ )
		{
			nCur.describeSpec( nCur.Paths[ i ], nS, nE, h, k); 
			if ( (nS != nE) && (abs(NavigationPoint(nE).Cost) != iCount) && !nE.bMeshCurvy )
			{
				nCur = NavigationPoint(nE);
				if ( bLog )
					Log("Switching to new path: "$ nCur.Name );
				Goto CUR_AGAIN;
			}
		}
		//Dead end?
		if ( (nCur == Base) || (n > 15) )
		{
			if ( bLog )
			{	For ( i=0 ; i<n ; i++ )
					Log("Path "$i$" is: "$Cached[i].GetItemName(string(Cached[i]) ) );
			}
			return none; //Swarm ended
		}
		nCur.bMeshCurvy = true; //That's how we say, DEAD END
		nCur = Base;
		Goto CUR_AGAIN; //start over
	}
	else
		return nCur;
}

function EndGame( string Reason)
{
	local bool bOldOverTime;
	local int i;
	local sgBuildRuleCount RuleCounts;
	
	bOldOverTime = bOverTime;
	Super.EndGame( Reason);
	if ( !bOldOverTime && bOverTime )
	{
		for ( i=0 ; i<ArrayCount(Cores); i++ )
			Cores[i].Energy *= Cores[i].SuddenDeathScale;

		ForEach AllActors (class'sgBuildRuleCount', RuleCounts )
			if ( RuleCounts.bOverTime )
				RuleCounts.bOverTimeReached = true;
	}		
}

//Startmatch implementation to allow round based game
function StartMatch()
{
	local WeightedItemSpawner ExistingSpawner;
	local actor A;
	local int i;

	bMatchStarted = true;
	if ( bRoundMode )
	{
		RemainingTime = 30 * TimeLimit;
		ForEach AllActors (class'Actor',A,'RoundStart')
			A.Trigger(self,none);
	}

	Foreach AllActors(class'WeightedItemSpawner',ExistingSpawner)
		ExistingSpawner.GotoState('Spawning');

	For ( i=0 ; i<ArrayCount(Cores) ; i++ )
		if ( Cores[i] != none )
			Cores[i].bCoreDisabled = false;

	Super.StartMatch();
}

function StartRound()
{
	local sgBuilding aBuild;
	local sgPRI aPRI;
	local PathNode P;
	local WeightedItemSpawner ExistingSpawner;
	local vector aVec;
	local actor aBase;

	if ( bRandomizeCores && (Cores[2] == none) && (Cores[3] == none) )
	{
		SwapPlayerStarts(0,1);
		SwapPlayerStarts(1,0);
		FinishStarts();
		aVec = Cores[0].Location;
		aBase = Cores[0].Base;
		Cores[0].SetLocation( Cores[1].Location);
		Cores[0].SetBase( Cores[1].Base);
		Cores[1].SetLocation( aVec);
		Cores[1].SetBase( aBase);
	}

	bOverTime = false;
	RemainingTime = 30 * TimeLimit;
	ForEach AllActors (class'sgBuilding', aBuild )
	{
		aBuild.bNoNotify = true;
		if ( sgBaseCore(aBuild) != none )
		{
			aBuild.Grade = 0;
			aBuild.ScaleGlow = 1;
			aBuild.SetCollision(true,false,false);
			sgBaseCore(aBuild).bCoreDisabled = true;
			aBuild.bProjTarget = true;
			aBuild.Energy = aBuild.MaxEnergy;
			aBuild.Enable('TakeDamage');
			aBuild.GotoState('');
			aBuild.bHidden = false;
		}
		else
			aBuild.Destruct();
	}
	ForEach AllActors (class'PathNode', P)
		if ( FRand() < NumResources)
			Spawn(class'WRU50',,,P.Location);

	Foreach AllActors(class'WeightedItemSpawner',ExistingSpawner)
		ExistingSpawner.GotoState('Spawning');

	aBase = none;
	ForEach AllActors (class'Actor',aBase,'RoundStart')
		aBase.Trigger(self,none);

	ForEach AllActors (class'sgPRI',aPRI)
	{
		if ( aPRI.Team < 5 && Cores[aPRI.Team] != none )
		{
			aPRI.RU = StartingRU;
			if ( PlayerPawn(aPRI.Owner) != none )
			{
				PlayerPawn(aPRI.Owner).ViewTarget = none;
				PlayerPawn(aPRI.Owner).bBehindView = false;
				PlayerPawn(aPRI.Owner).ServerRestartPlayer();
			}
		}
	}
	MaxRUs[0] = StartingMaxRU;
	MaxRUs[1] = StartingMaxRU;
	MaxRUs[2] = StartingMaxRU;
	MaxRUs[3] = StartingMaxRU;
}

function RestoreAllPlayers()
{
	local sgPRI aPRI;
	local pawn P;

	ForEach AllActors (class'sgPRI',aPRI)
	{
		aPRI.RU = 0;
		if ( aPRI.Team < 5 && Cores[aPRI.Team] != none )
		{
			P = Pawn(aPRI.Owner);
			P.Weapon = none;
			DiscardInventory( P);
			P.Health = -1;
			if ( PlayerPawn(P) != none )
			{
			}
			RestorePlayer( Pawn(aPRI.Owner) );
		}
	}

}

function RoundEnded( sgBaseCore Winner)
{
	local int i, best;
	local bool bTie;
	local sgGameReplicationInfo sgGRI;
	local Pawn P;
	local PlayerPawn Player;
	local WeightedItemSpawner ExistingSpawner;
	local actor A;

	RoundIndex++;
	sgGRI = sgGameReplicationInfo(GameReplicationInfo);
	sgGRI.TeamRounds[Winner.Team]++;

	//Normal rounds
	if (RoundIndex < RoundGames)
	{
		if ( sgGRI.TeamRounds[Winner.Team] > RoundGames/2) //Premature end
		{
			EndGame("teamscorelimit");
			Log("SIEGEGI: Game ended on round "$RoundIndex);
			return;
		}
	}
	//Final round
	else if ( RoundIndex == RoundGames )
	{
		For ( i=1 ; i<4 ; i++ )
		{
			if ( sgGRI.TeamRounds[best] < sgGRI.TeamRounds[i] )
			{
				bTie = false;
				best = i;
			}
			else if ( sgGRI.TeamRounds[best] == sgGRI.TeamRounds[i] )
				bTie = true;
		}
		if ( !bTie )
		{
			EndGame("teamscorelimit");
			Log("SIEGEGI: Game ended on final round: "$RoundIndex);
			return;
		}
		For ( i=0 ; i<4 ; i++ ) //Eliminate teams that aren't tied
			if ( (Cores[i] != none) && (sgGRI.TeamRounds[i] != sgGRI.TeamRounds[best]) )
				Cores[i].Destruct();
			
	}
	//Tiebreaker, winning team should always be the one to survive
	else
	{
		EndGame("teamscorelimit");
		Log("SIEGEGI: Game ended on TieBreaker");
		return;
	}

	//Select this core as our viewtarget
	for ( P=Level.PawnList; P!=None; P=P.nextPawn )
	{
		Player = PlayerPawn(P);
		if ( Spectator(P) != none)
			continue;
		if ( Player != None )
		{
			Player.bBehindView = true;
			Player.ViewTarget = Winner;
			Player.ClientGameEnded();
		}
		P.GotoState('GameEnded');
	}
	Foreach AllActors(class'WeightedItemSpawner',ExistingSpawner)
		ExistingSpawner.GotoState('Setup');
	ForEach AllActors(class'Actor', A, 'RoundEnd')
		A.Trigger(self,none);
	RoundRestart = 10;
	BroadcastMessage( Teams[Winner.Team].TeamName$" wins the round", true, 'CriticalEvent'); // Broadcast message to all 
	sgGRI.RoundGame++;
}

function bool SetEndCams(string Reason)
{
	local int i;
	local float sTeams[4];
	local bool result;

	if ( !bRoundMode )
		return Super.SetEndCams( Reason);

	For ( i=0 ; i<4 ; i++ )
	{
		sTeams[i] = Teams[i].Score;
		Teams[i].Score = sgGameReplicationInfo(GameReplicationInfo).TeamRounds[i];
	}
	result = Super.SetEndCams( Reason);
	For ( i=0 ; i<4 ; i++ )
		Teams[i].Score = sTeams[i];
	return result;
}

function InitGameReplicationInfo()
{
	Super.InitGameReplicationInfo();
	if ( bRoundMode )
		sgGameReplicationInfo(GameReplicationInfo).RoundGame = 1;
}

event PostBeginPlay()
{
    local int i;

    Super.PostBeginPlay();

    for ( i = 0; i < 4; i++ )
        Teams[i].Score = GoalTeamScore;
		
	if ( bUseRemoveGuardian )
		Spawn(class'MSpec_Alerts');
}

function bool AddBot()
{
    // Ugly hack to spawn the correct type of PRI
	class'Bot'.default.PlayerReplicationInfoClass = class'sgPRI';
	SetHulls( false);
	Super.AddBot();
	SetHulls( true);
    class'Bot'.default.PlayerReplicationInfoClass = class'BotReplicationInfo';

}

event PlayerPawn Login(string portal, string options, out string error,
  class<PlayerPawn> spawnClass)
{ 	
	local PlayerPawn newPlayer;
    local class<PlayerReplicationInfo> priClass;

    // Ugly hack to spawn the correct type of PRI ===> MOVED TO SIEGEMUTATOR
//	priClass = spawnClass.default.PlayerReplicationInfoClass;
//	spawnClass.default.PlayerReplicationInfoClass = class'sgPRI';
	SetHulls( false);
	newPlayer = Super.Login(portal, options, error, spawnClass);
	SetHulls( true);
//	spawnClass.default.PlayerReplicationInfoClass = priClass;

	if ( newPlayer != none && (sgPRI(newPlayer.PlayerReplicationInfo) == none) )
		ChangePRI( newPlayer);

    return newPlayer;
}

function ChangePRI( pawn Other)
{
	local sgPRI aPRI;

	if ( sgPRI(Other.PlayerReplicationInfo) != none )
		return;
	
	aPRI = Spawn( class'sgPRI', Other);
	aPRI.PlayerName = Other.PlayerReplicationInfo.PlayerName;
	aPRI.PlayerID = Other.PlayerReplicationInfo.PlayerID;
	aPRI.TeamName = Other.PlayerReplicationInfo.TeamName;
	aPRI.Team = Other.PlayerReplicationInfo.Team;
	aPRI.TeamID = Other.PlayerReplicationInfo.TeamID;
	aPRI.Score = Other.PlayerReplicationInfo.Score;
	aPRI.Deaths = Other.PlayerReplicationInfo.Deaths;
	aPRI.VoiceType = Other.PlayerReplicationInfo.VoiceType;
	aPRI.bIsABot = Other.PlayerReplicationInfo.bIsABot;
	aPRI.bIsSpectator = Other.PlayerReplicationInfo.bIsSpectator;
	aPRI.bWaitingPlayer = Other.PlayerReplicationInfo.bWaitingPlayer;
	aPRI.bAdmin = Other.PlayerReplicationInfo.bAdmin;
	aPRI.TalkTexture = Other.PlayerReplicationInfo.TalkTexture;

	Other.PlayerReplicationInfo.Destroy();
	Other.PlayerReplicationInfo = aPRI;
}

simulated exec function SiegeSpecHelp()
{
	AnnounceAdmin("__________________");
	AnnounceAdmin("Siege Spectator List");
	AnnounceAdmin("-----------------------");
	AnnounceAdmin("Admin SiegeSpecHelp");
	AnnounceAdmin("Admin SiegeSpecAdd [PlayerName],[Player IP]");
	AnnounceAdmin("Admin SiegeSpecDel [PlayerName]");
	AnnounceAdmin("Admin SiegeSpecList");
}

simulated exec function SiegeSpecAdd(string sIP)
{	
	local int i;

	if (len(sIP)<10)
	{
		SiegeSpecHelp();
		return;
	}

	for(i=0; i<32; i++)
	{
		if (SpecIPs[i] == "")
		{
			SpecIPs[i]=sIP;
			SaveConfig();
			SiegeSpecList();
			AnnounceAdmin("Siege Spectator List: IP added to Spectator list.");
 			return;
		}
	}
	AnnounceAdmin("__________________");
	AnnounceAdmin("Siege Spectator List");
	AnnounceAdmin("-----------------------");
	AnnounceAdmin("Siege Spectator List: IP not addded to list - list is full.");
}

simulated exec function SiegeSpecDel(string sName)
{	
	local int i,j;

	if (len(sName)<1)
	{
		SiegeSpecHelp();
		return;
	}

	j=len(sName);
	for(i=0; i<32; i++)
	{
		if (SpecIPs[i] != "" && Left(SpecIPs[i],j)~= sName)
		{
			SpecIPs[i]="";
			SaveConfig();
			SiegeSpecList();
			AnnounceAdmin("Siege Spectator List: IP removed from Spectator list.");
 			return;
		}
	}	
	AnnounceAdmin("__________________");
	AnnounceAdmin("Siege Spectator List");
	AnnounceAdmin("-----------------------");
	AnnounceAdmin("Siege Spectator List:"@sName@"not found.");
}

simulated exec function SiegeSpecList()
{	
	local int i;
	AnnounceAdmin("__________________");
	AnnounceAdmin("Siege Spectator List");
	AnnounceAdmin("-----------------------");
	for(i=0; i<32; i++)
		if (SpecIPs[i] != "")
			AnnounceAdmin(SpecIPs[i]);
}

function AnnounceAdmin(string sMessage)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( p.bIsPlayer && p.PlayerReplicationInfo != None && p.PlayerReplicationInfo.bAdmin )
		    p.ClientMessage(sMessage);
}

function string GetIP(string sIP)
{
    local int j;
    j = InStr(sIP, ":");
    if(j != -1)
        return Left(sIP, j);
    return sIP;
}

function bool CheckSpecIPPolicy(string Address)
{
    local int i, j;
    local string Mask;
    local bool bAcceptAddress;
    
    // strip port number
    Address = GetIP(Address);

    bAcceptAddress = False;
    for(i=0; i<32; i++)
    {
	if (SpecIPs[i] != "")
		{
        	j = InStr(SpecIPs[i], ",");
        	if(j==-1)
        	    continue;

		Mask = Mid(SpecIPs[i], j+1);

        	j = InStr(Mask, "*");
        	if(j != -1)
        	{
        	    if(Left(Mask, j) == Left(Address, j))
        	        bAcceptAddress = true;
        	}
        	else
        	{
        	    if(Mask == Address)
        	        bAcceptAddress = true;
        	}
	}
    }

    return bAcceptAddress;
}


function PostLogin(playerpawn NewPlayer)
{
	local sgSpecInv SpecInv;
	
	Super.PostLogin(NewPlayer);
	if (NewPlayer.IsA('Spectator'))
	{
		if (bPreventSpectate && !CheckSpecIPPolicy(NewPlayer.GetPlayerNetworkAddress()) )
		{
			class'SiegeStatics'.static.AnnounceAll( self, NewPlayer.PlayerReplicationInfo.PlayerName@"has been denied Spectator access.");
			NewPlayer.Destroy();
			return;
		}
		SpecInv = NewPlayer.Spawn( class'sgSpecInv', NewPlayer);
		SpecInv.RespawnTime = 0.0;
		SpecInv.GiveTo(NewPlayer);
		SpecInv.bHeldItem = true;
	}
}

function AddDefaultInventory(Pawn playerPawn)
{
    local int i;
    local Weapon newWeapon;
	local inventory inv, previnv;

    if ( PlayerPawn.IsA('Spectator') || (bRequireReady && (CountDown > 0)) )
         return;

    GivePlayerWeapon(playerPawn, WeaponClasses[12]);

    for ( i = 0; i < 12; i++ )
        if ( WeaponClasses[i] != None )
            GivePlayerWeapon(playerPawn, WeaponClasses[i]);
	PlayerPawn.SwitchToBestWeapon(); //Now weapon priority is a thing
	BaseMutator.ModifyPlayer(PlayerPawn);
}

function bool PickupQuery( Pawn Other, Inventory item )
{
	local bool Result;

	Result = Super.PickupQuery( Other, Item);
	//Item was spawned in mid
	if ( Item.LightEffect == LE_Rotor
	 && Item.LightType == LT_Steady
	 && Item.LightHue == 85
	 && Other != none 
	 && sgPRI(Other.PlayerReplicationInfo) != none )
	{
		sgPRI(Other.PlayerReplicationInfo).sgInfoSpreeCount += 10;
	}
	return Result;
}

function Weapon GivePlayerWeapon(Pawn playerPawn, class<Weapon> weaponClass )
{
	local Weapon newWeapon;
	local Enforcer ExtraEnforcer;
    local int CoreLevel;
	//NUKE HACK
	newWeapon = Weapon(playerPawn.FindInventoryType(weaponClass));
	if ( newWeapon != None )
		return newWeapon;
	newWeapon = Spawn(weaponClass);
	if( newWeapon != None )
	{
		newWeapon.PickupAmmoCount = 0; //Better here
		newWeapon.RespawnTime = 0.0;
		newWeapon.GiveTo(playerPawn);
		newWeapon.bHeldItem = true;
		newWeapon.GiveAmmo(playerPawn);
		newWeapon.SetSwitchPriority(playerPawn);
		newWeapon.AmbientGlow = 0;
		playerPawn.PendingWeapon = None;
		if ( PlayerPawn(playerPawn) != None )
			newWeapon.SetHand(PlayerPawn(playerPawn).Handedness);
		else
			newWeapon.GotoState('Idle');

		if ( playerPawn.Weapon != None )
		{
			playerPawn.Weapon.GotoState('DownWeapon');
			playerPawn.Weapon = none; //Instant down
		}


		if ( Enforcer(newWeapon) != None )
		{
			if ( playerPawn.PlayerReplicationInfo != None && Cores[playerPawn.PlayerReplicationInfo.Team] != None )
			{
				CoreLevel = Cores[playerPawn.PlayerReplicationInfo.Team].Grade;
				if ( newWeapon.AmmoType != None )
					newWeapon.AmmoType.AmmoAmount = 15 + 8 * CoreLevel;
				newWeapon.SetPropertyText("HitDamage",string(15+coreLevel));
				newWeapon.SetPropertyText("AccuracyScale", string( 1.f - float(coreLevel)/10.f) );
				if ( bCore5AddsEnforcer && CoreLevel >= 5 )
				{
					ExtraEnforcer = Enforcer(Spawn( newWeapon.Class, playerPawn));
					if ( ExtraEnforcer != none && !ExtraEnforcer.bDeleteMe )
					{
						ExtraEnforcer.AmmoName = newWeapon.AmmoName;
						ExtraEnforcer.SetPropertyText("HitDamage",string(15+coreLevel));
						ExtraEnforcer.SetPropertyText("AccuracyScale", string( 1.f - float(coreLevel)/9.f) );
						ExtraEnforcer.BecomeItem();
						newWeapon.ItemName = ExtraEnforcer.DoubleName;
						Enforcer(newWeapon).SlaveEnforcer = ExtraEnforcer;
						Enforcer(newWeapon).SetTwoHands();
						newWeapon.AIRating = 0.4;
						ExtraEnforcer.SetUpSlave( playerPawn.Weapon == newWeapon );
						ExtraEnforcer.SetDisplayProperties( newWeapon.Style, newWeapon.Texture, newWeapon.bUnlit, newWeapon.bMeshEnviromap);
						Enforcer(newWeapon).SetTwoHands();
					}
				}
            }
        }
	}
	return newWeapon;
}

function Killed( pawn Killer, pawn Other, name damageType )
{
	if ( (killer == none || killer == other) && (sgPRI(other.PlayerReplicationInfo) != none) && (sgPRI(other.PlayerReplicationInfo).PushedBy != none) )
	{
		killer = sgPRI(other.PlayerReplicationInfo).PushedBy;
		sgPRI(Other.PlayerReplicationInfo).PushedBy = none;
	}
	Super.Killed( killer, other, damagetype);
}

function ScoreKill(Pawn killer, Pawn other)
{
    local int NukeAmmo;
	local float RuMult;
	local bool bTeamKill;
	local sgPRI aVictim, aKiller;
	local sgNukeLauncher Nuke;
	local vector TStart;

	if ( bRoundMode )		RuMult = RoundRuScale;
	else					RuMult = 1;
	
	if ( Other != none )	aVictim = sgPRI(other.PlayerReplicationInfo);
	if ( Killer != none )	aKiller = sgPRI(killer.PlayerReplicationInfo);

	if ( killer == other || killer == None )
	{
		if ( aVictim != None )
		{
			aVictim.Score -= 1;
			aVictim.AddRU( KillRUReward(none, true) * RuMult );
			aVictim.sgInfoSpreeCount = Max( 0, aVictim.sgInfoSpreeCount-1);
			aVictim.Deaths -= 1; //Prevents suicide altering eff
		}
	}
	else
	{
		if( aKiller != None )
			aKiller.sgInfoKiller++;
		killer.KillCount++;
		if ( killer.bIsPlayer && other.bIsPlayer )
   		{
			if ( aKiller.Team != aVictim.Team )
			{
				aKiller.Score += 1;
				if ( (aKiller != none) && (aVictim != none) && aVictim.bReachedSupplier && (aVictim.SupplierTimer > 0) )
				{
					aKiller.sgInfoSpreeCount += 5;
					aKiller.AddRU( KillRUReward(none, true) * RuMult);
					Cores[aKiller.Team].StoredRU -= aVictim.SupplierTimer + Teams[aKiller.Team].Size * 5 * Cores[aKiller.Team].Grade;
					PenalizeTeamForKill( Other, aKiller.Team);
					aVictim.AddRU(10 * RuMult);
					aVictim.sgInfoSpreeCount = 0;
				}
				else if ( aKiller != None )
				{
					SharedReward( aKiller, aKiller.Team, KillRUReward( aVictim, false) * RuMult, 0.5);
					aKiller.sgInfoSpreeCount += 1;
					aVictim.sgInfoSpreeCount = 0;
					//Camper
					if ( SniperRifle(Killer.Weapon) != None && (Killer.Physics == PHYS_Walking) && (VSize(Killer.Velocity) < Killer.GroundSpeed * 0.3) )
					{
						TStart = Killer.Location;
						TStart.Z += Killer.BaseEyeHeight - Killer.CollisionHeight * 0.5;
						if ( !FastTrace( Other.Location, TStart) && !FastTrace( Other.Location-vect(0,0,20), TStart) && !FastTrace( Other.Location+vect(0,0,20), TStart) )
							aKiller.sgInfoSpreeCount += 1;
					}
				}
			}
			else
			{
				bTeamKill = true;
				aKiller.Score -= 1;
				if ( aKiller != None )
				{
					aKiller.sgInfoKiller--; //Don't award the pusher with a kill
					aKiller.AddRU( KillRUReward( aVictim, true) * RuMult);
				}
			}
		}
        if ( aVictim != None )
            aVictim.AddRU(-10 * RuMult);
	}
	
    Nuke = sgNukeLauncher(other.FindInventoryType(class'sgNukeLauncher'));
	if( (aVictim != none) && (Nuke != None) )
	{
		NukeAmmo = Nuke.AmmoType.AmmoAmount;
		if (NukeAmmo == 1)
		{
			if (killer != None && (aKiller != None) && killer != other)
			{
				aKiller.AddRU(500 * abs(int(bTeamKill)-1) );
				aKiller.sgInfoWarheadKiller += abs(int(bTeamKill)-1);
				killer.PlayerReplicationInfo.Score += 5 * abs(int(bTeamKill)-1);
			}
			class'SiegeStatics'.static.AnnounceAll( self, aVictim.PlayerName@"was carrying a WARHEAD!!!" );
		}
         
		if (NukeAmmo > 1)
		{
			if (killer != None && (aKiller != None) && killer != other)
			{
				aKiller.AddRU(1000 * abs(int(bTeamKill)-1) );
				aKiller.sgInfoWarheadKiller += 2 * abs(int(bTeamKill)-1);
				killer.PlayerReplicationInfo.Score += 10 * abs(int(bTeamKill)-1);
			}
			class'SiegeStatics'.static.AnnounceAll( self, aVictim.PlayerName@"was carrying "$NukeAmmo$" WARHEADS!!!" );
		}
	}

	other.DieCount++;
    BaseMutator.ScoreKill(Killer, other);
}

function int ReduceDamage(int damage, name damageType, Pawn injured,  Pawn instigatedBy)
{
	local string sMessage;
	local bool bPlayerInstigated;

	//Fast condition
	bPlayerInstigated = (instigatedBy != none) && instigatedBy.bIsPlayer && (instigatedBy.PlayerReplicationInfo != none);

	//Spawn protection... and push!
	if ( bPlayerInstigated && (injured.PlayerReplicationInfo != none) )
	{
		if ( injured != instigatedBy )
			sgPRI(Injured.PlayerReplicationInfo).PushedBy = instigatedBy;
		if ( injured.bIsPlayer && (injured.PlayerReplicationInfo.Team != instigatedBy.PlayerReplicationInfo.Team) )
		{
			if (injured != instigatedBy)
			{
				if ( sgPRI(injured.PlayerReplicationInfo).ProtectCount > 0 )
				{
					//instigatedBy.TakeDamage(damage, instigatedBy, instigatedBy.Location, vect(0,0,0), 'exploded');
					instigatedBy.ClientMessage( "Player "@injured.PlayerReplicationInfo.PlayerName@" is spawn protected.");
					return 0;
				}
			}
			else
				sgPRI(injured.PlayerReplicationInfo).ProtectCount = 0;
		}
	}

	damage = Super.ReduceDamage(damage, damageType, injured, instigatedBy);

	//Building related
	if ( sgBuilding(injured) != none )
	{
		if ( sgBaseCore(injured) != None )
		{
			if ( bPlayerInstigated &&
				(DamageType == 'Decapitated' || SniperRifle(instigatedBy.Weapon) != None ||
				Ripper(instigatedBy.Weapon) != None) &&
				VSize(injured.Location - instigatedBy.Location) >
				MaxCoreSnipeDistance )
				return damage / 10;
		}
		else
		{
			if ( bPlayerInstigated && (sgBuilding(injured).Team != instigatedBy.PlayerReplicationInfo.Team) )
				sgPRI(instigatedBy.PlayerReplicationInfo).sgInfoBuildingHurt += damage;
		}
	}
	//Non-building related
	else
	{
		if ( (DamageType == 'sgSpecial') && (Injured.Health - Damage <= 10) )
		{
			injured.Health = 10;
			return 0;
		}
	}
	return damage;
}

function NavigationPoint FindPlayerStart(Pawn player, optional byte inTeam,
  optional string incomingName)
{
	local PlayerStart
                    dest,
                    candidate[16],
                    best;
	local float     score[16],
                    bestScore,
                    nextDist;
	local Pawn      otherPlayer;
	local int       i,
                    num;
	local Teleporter
                    tel;
	local NavigationPoint
                    n;
	local byte      team;
    local bool      spawnNearBase;

	if ( bStartMatch && Player != None && Player.IsA('TournamentPlayer') 
	  && Level.NetMode == NM_Standalone
      && TournamentPlayer(Player).StartSpot != None )
		return TournamentPlayer(Player).StartSpot;

	if ( Player != None && Player.PlayerReplicationInfo != None )
		team = Player.PlayerReplicationInfo.Team;
	else
		team = inTeam;

	if ( incomingName != "" )
		foreach AllActors(class 'Teleporter', tel)
			if ( string(Tel.Tag) ~= incomingName )
				return tel;

	if ( team == 255 )
		team = 0;
				
	//choose candidates	
	for ( N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint )
	{
		dest = PlayerStart(N);
		if ( dest != None && dest.bEnabled &&
          (!bSpawnInTeamArea || team == dest.TeamNumber) )
		{
			if ( num < 16 )
				candidate[num] = dest;
			else if ( Rand(num) < 16 )
				candidate[Rand(16)] = dest;
			num++;
		}
	}

	if ( num == 0 )
	{
		log("Didn't find any player starts in list for team"@Team@"!!!"); 
		foreach AllActors( class'PlayerStart', dest )
		{
			if ( num < 16 )
				candidate[num] = dest;
			else if ( Rand(num) < 16 )
				candidate[Rand(16)] = dest;
			num++;
		}
		if ( num == 0 )
			return None;
	}

	if ( num > 16 )
		num = 16;
	
	//assess candidates
	for ( i = 0; i < num; i++ )
	{
		if ( candidate[i] == LastStartSpot )
			score[i] = -6000.0;
		else
			score[i] = 4000 * FRand(); //randomize
	}

    if ( FRand() <= 0.85 )
        spawnNearBase = true;
	
	for ( otherPlayer = Level.PawnList; otherPlayer != None;
      otherPlayer = otherPlayer.NextPawn)
    {
        if ( otherPlayer.bIsPlayer && otherPlayer.Health > 0 &&
          !otherPlayer.IsA('Spectator') )
        {
            for ( i = 0; i < num; i++ )
				if ( otherPlayer.Region.Zone == candidate[i].Region.Zone ) 
				{
					score[i] -= 1500;
					nextDist = VSize(otherPlayer.Location -
                      candidate[i].Location);
					if ( nextDist < 2 * (CollisionRadius + CollisionHeight) )
						Score[i] -= 1000000.0;
					else if ( NextDist < 2000 &&
                      otherPlayer.PlayerReplicationInfo.Team != team &&
                      FastTrace(candidate[i].Location, otherPlayer.Location) )
						score[i] -= 10000.0 - nextDist;
				}
        }
        else if ( spawnNearBase &&
          (sgEquipmentSupplier(otherPlayer) != None ||
          sgBaseCore(otherPlayer) != None || 
          sgProtector(otherPlayer) != None) &&
          sgBuilding(otherPlayer).Team == team )
        {
            for ( i = 0; i < num; i++ )
            {
                nextDist = VSize(otherPlayer.Location - candidate[i].Location);
                if ( nextDist < 1200 )
                {
                    if ( FastTrace(candidate[i].Location,
                      otherPlayer.Location) )
                        score[i] += 6000.0 * FRand() *
                          (sgBuilding(otherPlayer).Grade + 1)/3;
                    else
                        score[i] += (20000.0 - nextDist) * FRand() *
                          (sgBuilding(otherPlayer).Grade + 1)/3;
                }
                else if ( FastTrace(candidate[i].Location,
                  otherPlayer.Location) )
                    score[i] += 15000.0 * FRand() *
                    (sgBuilding(otherPlayer).Grade + 1)/3;
            }
        }
    }
	
	bestScore = score[0];
	best = candidate[0];
	for ( i = 1; i < num; i++)
		if (score[i] > bestScore)
		{
			bestScore = score[i];
			best = candidate[i];
		}
	LastStartSpot = best;
				
	return best;
}

function bool IsOnTeam(Pawn other, int teamNum)
{
    if ( sgBuilding(other) != None )
        return (sgBuilding(other).Team == teamNum);
    else if ( other.bIsPlayer && other.PlayerReplicationInfo != None )
        return (other.PlayerReplicationInfo.Team == teamNum);
}

function int PickTeam(Pawn defeated)
{
    local int       i,
                    j;
    local TeamInfo  small[3],
                    lowScore[3];
    local int       numSmall,
                    numLow;

    // Find smallest teams
    for ( i = 0; i < 4; i++ )
        if ( Cores[i] != None )
        {
            if ( numSmall == 0 || Teams[i].Size == small[0].Size )
            {
                small[numSmall] = Teams[i];
                numSmall++;
            }
            else if ( Teams[i].Size < small[0].Size )
            {
                small[0] = Teams[i];
                numSmall = 1;
            }
        }
    
    i = int(FRand() * (numSmall-1));

    return i;
}

function bool RestartPlayer(Pawn p)
{
    local NavigationPoint
                    startSpot;
	local bool      foundStart;

	if ( (sgPRI(p.PlayerReplicationInfo) != none) && SpawnProtSecs > 0 )
	{
		p.ClientMessage("Siege spawn protection on");
		sgPRI(P.PlayerReplicationInfo).ProtectCount = SpawnProtSecs;
		sgPRI(P.PlayerReplicationInfo).bReachedSupplier = false;
		sgPRI(P.PlayerReplicationInfo).SupplierTimer = 3.3;
	}

	p.DrawScale = p.default.DrawScale;
	p.GroundSpeed = p.default.GroundSpeed;
	p.SetCollisionSize(p.default.CollisionRadius, p.default.CollisionHeight);

	if ( bRestartLevel && Level.NetMode != NM_DedicatedServer && Level.NetMode != NM_ListenServer )
		return true;

	if ( p.PlayerReplicationInfo != None &&
      (p.PlayerReplicationInfo.Team < 0 ||
      p.PlayerReplicationInfo.Team >= MaxSiegeTeams ||
      Cores[p.PlayerReplicationInfo.Team] == None || Cores[p.PlayerReplicationInfo.Team].bCoreDisabled ) )
    {
        if ( p.IsA('Bot') )
	    {
		    p.PlayerReplicationInfo.bIsSpectator = true;
		    p.PlayerReplicationInfo.bWaitingPlayer = true;
		    p.GotoState('GameEnded');
		    return false;
	    }
		SetHulls( false);
	    startSpot = FindPlayerStart(p, 255);
		SetHulls( true);
	    if ( startSpot == None )
		    return false;
		
	    foundStart = p.SetLocation(startSpot.Location);
	    if ( foundStart )
	    {
		    startSpot.PlayTeleportEffect(p, true);
		    p.SetRotation(startSpot.Rotation);
		    p.ViewRotation = p.Rotation;
		    p.Acceleration = vect(0,0,0);
		    p.Velocity = vect(0,0,0);
		    p.Health = p.Default.Health;
		    p.ClientSetRotation( startSpot.Rotation );
		    p.SoundDampening = p.Default.SoundDampening;
			p.PlayerRestartState = 'PlayerSpectating';
	    }
	    return foundStart;
    }
    //else
        //p.PlayerRestartState = 'PlayerWalking';



    return Super.RestartPlayer(p);


}

function bool ChangeTeam(Pawn other, int newTeam)
{
	local bool bPendingRestart;
    /*local int i;
    if ( newTeam < 0 || newTeam > 3 || Cores[newTeam] == None )
    {
        for ( i = 0; i < 4; i++ )
            if ( Cores[i] != None )
                break;
        if ( i == 4 )
            newTeam = 0;
        else
            newTeam = i;
    }

    if ( !Super.ChangeTeam(other, newTeam) )
        return false;

    if ( other.IsInState('PlayerSpectating') && !other.IsA('Spectator') )
    {
        other.PlayerRestartState = other.default.PlayerRestartState;
        other.GotoState(other.default.PlayerRestartState);
        if ( !other.IsA('Commander') && !RestartPlayer(other) )
            other.GotoState('Dying');
        other.RestartPlayer();
    }

    return true;*/

    local int i, smallest, desiredTeam;
	local Pawn aPlayer, p;
	local TeamInfo SmallestTeam;

	if ( bRatedGame && Other.PlayerReplicationInfo.Team != 255 )
		return false;
	if ( Other.IsA('Spectator') )
	{
		Other.PlayerReplicationInfo.Team = 255;
		if (LocalLog != None)
			LocalLog.LogTeamChange(Other);
		if (WorldLog != None)
			WorldLog.LogTeamChange(Other);
		return true;
	}

    for ( i = 0; i < MaxTeams; i++ )
        if ( Cores[i] != None )
        {
            smallest = i;
            break;
        }
    if ( i >= MaxTeams )
        return false;


	for( i = smallest+1; i < MaxTeams; i++ )
	{
		if ( Cores[i] == none )
			continue;
		if ( Other.PlayerReplicationInfo.Team == smallest )
		{
			if ( Teams[i].Size < Teams[smallest].Size-1 ) //Prevent bouncing a player back and forth
				smallest = i;
		}
		else if ( Other.PlayerReplicationInfo.Team == i )
		{
			if ( Teams[i].Size-1 < Teams[smallest].Size  ) //Prevent bouncing a player back and forth
				smallest = i;
		}
		else
		{
			if ( Teams[i].Size < Teams[smallest].Size )
				smallest = i;
		}
	}

	if ( newTeam == 255 || newTeam >= MaxTeams || Cores[newTeam] == None )
		newTeam = smallest;

	if ( bPlayersBalanceTeams && Level.NetMode != NM_Standalone )
	{
		if ( Teams[newTeam].Size > Teams[smallest].Size )
			newTeam = smallest;
		if ( NumBots == 1 )
		{
			// join bot's team if sizes are equal, because he will leave
			for ( p = Level.PawnList; p != None; p = p.NextPawn )
				if ( p.IsA('Bot') )
					break;
			
			if ( p != None && p.PlayerReplicationInfo != None &&
              p.PlayerReplicationInfo.Team != 255 &&
              Teams[p.PlayerReplicationInfo.Team].Size ==
              Teams[smallest].Size )
				newTeam = p.PlayerReplicationInfo.Team;
		}
	}

	if ( (PlayerPawn(other) != none) && (other.PlayerReplicationInfo.Team == newTeam) && (PlayerPawn(other).GameReplicationInfo != none) ) //TESTING, the GRI being none means that this player has just joined
		return false;

	if ( other.PlayerReplicationInfo.Team == newTeam && bNoTeamChanges )
		return false;

    if ( (other.PlayerReplicationInfo.Team < 5) && (Cores[other.PlayerReplicationInfo.Team] == none) && !other.IsA('Spectator') )
    {
        other.PlayerRestartState = 'PlayerWalking';
	other.Health = -1;
	bPendingRestart = true;
//        other.GotoState(other.default.PlayerRestartState);
        if ( !other.IsA('Commander') )
            other.GotoState('Dying');
 //       other.RestartPlayer();
    }

	if ( other.IsA('TournamentPlayer') )
		TournamentPlayer(Other).StartSpot = None;

	if ( other.PlayerReplicationInfo.Team != 255 )
	{
		ClearOrders(Other);
		Teams[Other.PlayerReplicationInfo.Team].Size--;
	}

	if ( Teams[newTeam].Size < MaxTeamSize )
	{
		AddToTeam(newTeam, Other);
		return true;
	}

	if ( other.PlayerReplicationInfo.Team == 255 )
	{
		AddToTeam(smallest, Other);
		return true;
	}

	return false;
}

function PlayTeleportEffect( actor Incoming, bool bOut, bool bSound)
{
 	local UTTeleportEffect PTE;

	if ( bRequireReady && (Countdown > 0) )
		return;

	if ( Incoming.bIsPawn && (Incoming.Mesh != None) )
	{
		if ( bSound )
		{
 			PTE = Spawn(class'UTTeleportEffect',Incoming,, Incoming.Location, Incoming.Rotation);
 			PTE.Initialize(Pawn(Incoming), bOut);
			PTE.PlaySound(sound'Resp2A',, 7.0 * Square(Pawn(Incoming).SoundDampening) );
		}
	}
}

function CoreDestroyed(sgBaseCore core)
{
    local int       remainingTeams,
                    i;
    local Pawn      defeated;

    if ( cores[core.Team] != core )
        return;

    cores[core.Team] = None;
    Teams[core.Team].Score = 0;

    for ( i = 0; i < 4; i++ )
        if ( cores[i] != None )
            remainingTeams++;

	if ( remainingTeams <= 1 )
	{
		EndGame("teamscorelimit");
		return;
	}

	BroadcastLocalizedMessage(class'sgDefeatedMsg', core.Team);
	DefeatTeam( Core.Team);
}

function DefeatTeam( byte aTeam)
{
	local Pawn defeated;

	foreach AllActors(class'Pawn', defeated)
	{
		if ( sgBuilding(defeated) != None )
		{
			if ( sgBuilding(defeated).Team == aTeam && sgBaseCore(defeated) == None )
			{
				sgBuilding(defeated).bNoNotify = true;
				sgBuilding(defeated).Destruct();
			}
		}
		else if ( defeated.PlayerReplicationInfo != None && defeated.PlayerReplicationInfo.Team == aTeam)
		{
			if ( sgPRI(defeated.PlayerReplicationInfo) != None )
				sgPRI(defeated.PlayerReplicationInfo).RU = 0;
			defeated.Died(None, '', defeated.Location);
		}
	}
	RURecovery.ClearTeamRU( aTeam);
}

final function DebugShout(String DebugMessage)
{
	if ( debug )
	{
		log(DebugMessage);
		class'SiegeStatics'.static.AnnounceAll( self, DebugMessage);
	}
}

function CheckRandomSpawner()
{
    local int i;
	local actor a;
	local WeightedItemSpawner ExistingSpawner;
	local bool OverideLocation;
	local bool MapIsInList;

	DebugShout("Checking if a random spawner is needed or if an existing one needs to be replaced");
	DebugShout("Reading the list...");

	for ( i = 0; i != 32; i++ )
	{
		DebugShout("RandomSpawnerMap["$string(i)$"]: "$RandomSpawnerMap[i]);
		DebugShout("GetURLMap("$string(i)$"): "$GetURLMap());
		if ( GetURLMap() ~= RandomSpawnerMap[i] )
		{
			DebugShout("Found a map location in the INI!");
			
			MapIsInList = true;
			OverideLocation = SpawnedRandomItemSpawner;
			break;
		}
	}

	if ( OverideLocation && MapIsInList )
	{
		// Move the existing random spawner to a better location we define in the INI
	    foreach AllActors(class'WeightedItemSpawner',ExistingSpawner)
			ExistingSpawner.SetLocation(RandomSpawnerLocation[i]);
		DebugShout("Moved the random spawner to a better location defined in the INI!");
	}

	if ( !SpawnedRandomItemSpawner && !OverideLocation && MapIsInList )
	{
		// Make a new RandomSpawneer at location defined in the INI for maps without the RandomSpawneer
		Spawn(class'WeightedItemSpawner',,,RandomSpawnerLocation[i]);
		SpawnedRandomItemSpawner = true;
		DebugShout("Created the random spawner at INI defined location!");
	}
	else
	{
		if ( !OverideLocation )
			DebugShout("Random Spawner Cannot Spawn!");
	}


	if ( SpawnedRandomItemSpawner && !OverideLocation )
		DebugShout("Spawned the random spawner Normally");

	CheckedRandomSpawner = true;
}

simulated Event Timer()
{
	local PlayerPawn ThisPawn;
	local Bot ThisBot;
	local int BestCore, i;
	local bool bTied;

	if ( bRoundMode && (RoundRestart > 0) )
	{
		if ( --RoundRestart > 0 )
		{
			ForEach AllActors (class'PlayerPawn', ThisPawn)
			{
				ThisPawn.ClearProgressMessages();
				if ( (RoundRestart < 6) && ThisPawn.IsA('TournamentPlayer') )
					TournamentPlayer(ThisPawn).TimeMessage(RoundRestart);
				else
					ThisPawn.SetProgressMessage(RoundRestart$" seconds for next round", 0);
			}
		}
		else
			StartRound();
		if ( RoundRestart == 1 )
		{
			For ( i=0 ; i<4 ; i++ )
				if ( Cores[i] != none )
					Cores[i].bCoreDisabled = false;
			RestoreAllPlayers();
		}
	}

	//Game will end right now! Stop it
	if ( bRoundMode && (RemainingTime == 1) )
	{
		For ( i=1 ; i<4 ; i++ )
		{
			if ( Cores[i] == none )
				continue;
			if ( Cores[BestCore].Energy < Cores[i].Energy )
			{
				bTied = False;
				BestCore = i;
			}
			else if ( Cores[BestCore].Energy == Cores[i].Energy )
				bTied = True;
		}
		bOverTime = true; //Prevent game end

		//Handle round tie by putting cores at 5% health
		if ( bTied )
		{
			For ( i=0 ; i<4 ; i++ )			
			{
				if ( (Cores[i] == none) || Cores[i].bCoreDisabled )
					continue;
				Cores[i].Energy = Cores[i].MaxEnergy * 0.05;
			}
			BroadcastLocalizedMessage( DMMessageClass, 0 );
		}
		//Pick a winner
		else
			RoundEnded( Cores[BestCore]);
		RemainingTime--;
	}
	
	Super.Timer();
	if ( !CheckedRandomSpawner )
		CheckRandomSpawner();

	if ( bAutoconfigWeapons && !bMutatedWeapons )
		MutateWeapons();

	if ( bPlayersRelevant )
	{
		foreach AllActors(Class'PlayerPawn', ThisPawn)
			if ( Spectator(ThisPawn) == none )
				ThisPawn.bAlwaysRelevant=True;
		foreach AllActors(Class'Bot', ThisBot)
			ThisBot.bAlwaysRelevant=True;
	}
}

function Logout( pawn Exiting )
{
	local bool bMessage;
	local PlayerPawn P;
	
	bMessage = true;
	if ( Exiting.IsA('PlayerPawn') )
	{
		if ( Exiting.IsA('Spectator') )
		{
			bMessage = false;
			if ( Level.NetMode == NM_DedicatedServer )
				NumSpectators--;
		}
		else
			NumPlayers--;
	}
	if( bMessage && (Level.NetMode==NM_DedicatedServer || Level.NetMode==NM_ListenServer) )
	{
		BroadcastMessage( Exiting.PlayerReplicationInfo.PlayerName$LeftMessage, false );
		ForEach AllActors( class'PlayerPawn', P)
			if ( P != Exiting )
				P.PlaySound(Sound'RageQuit',,10);
	}

	if ( Exiting.PlayerReplicationInfo != none )
		CleanupProjectiles( Exiting);
	
	if ( LocalLog != None )
		LocalLog.LogPlayerDisconnect(Exiting);
	if ( WorldLog != None )
		WorldLog.LogPlayerDisconnect(Exiting);
}

//Prevent disconnect + damage exploits
function CleanupProjectiles( Pawn Other)
{
	local Projectile Proj;
	local byte OutTeam;
	local bool bDestructProj;

	OutTeam = Other.PlayerReplicationInfo.Team;
	if ( OutTeam < 5 )
	{
		bDestructProj = Cores[OutTeam] == none || Cores[OutTeam].bDeleteMe;
		ForEach AllActors (class'Projectile', Proj)
			if ( Proj.Instigator == Other )
			{
				if ( bDestructProj )
					Proj.Destroy();
				else
				{
					Proj.Instigator = Cores[OutTeam];
					Proj.SetOwner( Cores[OutTeam]);
				}
			}
	}
}

//General event system, a building has been created and initialized
function BuildingCreated( sgBuilding sgNew)
{
	local sgBuilding sgB;
	local sgPRI aPRI;
	
	if ( sgNew.Owner != none )
		ForEach AllActors (class'sgPRI', aPRI)
			if ( aPRI.bAdmin || (aPRI.Team == Pawn(sgNew.Owner).PlayerReplicationInfo.Team) )
				aPRI.ReceiveMessage( Pawn(sgNew.Owner).PlayerReplicationInfo.PlayerName @"built a"@sgNew.BuildingName, Pawn(sgNew.Owner).PlayerReplicationInfo.Team, false);

	if ( bRoundMode )
		sgB.RuRewardScale *= RoundRuScale;

	if ( (CategoryInfo[sgNew.Team] != none) && (CategoryInfo[sgNew.Team].RuleList != none) )
		CategoryInfo[sgNew.Team].RuleList.NotifyIn( sgNew);

	ForEach AllActors (class'sgBuilding', sgB)
	{
		if ( sgB.bNotifyCreated && (sgB != sgNew) )
			sgB.BuildingCreated( sgNew);
	}
	
	if ( (sgEditBuilding(sgNew) == none) && (BuildMarkers[sgNew.Team] != none) )
		BuildMarkers[sgNew.Team].BuildNotify( sgNew);
}

//General event system, a building has been destroyed
function BuildingDestroyed( sgBuilding sgOld)
{
	local sgBuilding sgB;
	
	if ( (CategoryInfo[sgOld.Team] != none) && (CategoryInfo[sgOld.Team].RuleList != none) )
		CategoryInfo[sgOld.Team].RuleList.NotifyOut( sgOld);

	ForEach AllActors (class'sgBuilding', sgB)
	{
		if ( sgB.bNotifyDestroyed && (sgB != sgOld) )
			sgB.BuildingDestroyed( sgOld);
	}
}

//General event system, a building has been removed
function BuildingRemoved( sgBuilding sgRem, pawn Remover, optional bool bWasLeech)
{
	local sgPRI aPRI;
	local string LeechString;
	
	if ( bWasLeech )
		LeechString = " leech";
	
	ForEach AllActors (class'sgPRI', aPRI)
		if ( aPRI.bIsSpectator || (aPRI.Team == Remover.PlayerReplicationInfo.Team) )
		{
			if ( sgRem.Owner != none )
			{
				aPRI.ReceiveMessage( Pawn(sgRem.Owner).PlayerReplicationInfo.PlayerName $"'s"$LeechString@sgRem.BuildingName @ "has been removed by" @ Remover.PlayerReplicationInfo.PlayerName, Remover.PlayerReplicationInfo.Team, sgRem.Owner != Remover);
			}
			else
				aPRI.ReceiveMessage( "A"$LeechString@sgRem.BuildingName @ "has been removed by" @ Remover.PlayerReplicationInfo.PlayerName, Remover.PlayerReplicationInfo.Team, true);
		}
}

function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
	local sgBuilding sgB;
	
	sgB = sgBuilding(Other);
	if ( sgB != none )
	{
		if ( sgB.Team == aBot.PlayerReplicationInfo.Team )
			return 3;
	}

	return Super.AssessBotAttitude(aBot, Other);
}

//TEAM MUST BE SET BEFORE RESTORING THE PLAYER!!!
//Higor: taken from my AdvancedTeamBalancer
function RestorePlayer( Pawn P)
{
	if ( Spectator(P) != none )
		return;

	if ( p.IsA('Bot') )
    {
		p.PlayerReplicationInfo.bIsSpectator = False;
		p.PlayerReplicationInfo.bWaitingPlayer = False;
		P.GotoState('Dying');
		RestartPlayer(p);
	}
	else if ( P.IsA('Botz') )
	{
		p.PlayerReplicationInfo.bIsSpectator = False;
		p.PlayerReplicationInfo.bWaitingPlayer = False;
		p.bHidden = False;
		P.Visibility = 127;
		P.GotoState('Dead','Go');
	}
	else if ( PlayerPawn( P) != none )
	{
		P.SoundDampening = P.Default.SoundDampening;
		p.Visibility = 128;
		P.Mesh = P.Default.Mesh;
		P.PlayerReplicationInfo.bIsSpectator = False;
		P.PlayerRestartState = 'PlayerWalking';
		P.bHidden = True;
		P.GotoState('Dying');
//		RestartPlayer(P);
		PlayerPawn(P).ServerReStartPlayer();
	}
}

function bool IsRelevant( actor Other )
{
	local bool result;

	if ( !bMutatingWeapons )
		return Super.IsRelevant(Other);

	result = Super.IsRelevant(Other);
	if ( result && !Other.bDeleteMe && (Weapon(Other) != none) ) //This weapon wasn't replaced by the relevancy checks
		theWeapon = Weapon(Other);
	return result;
}

function float PlayerJumpZScaling()
{
	return 1.0;
}

function MutateWeapons()
{
	local class<Weapon> BaseWeapons[32];
	local class<Weapon> MutatedWeapons[32]; //I doubt we're mutating more than this
	local class<Weapon> W;
	local int i, j, iM;
	local WeightedItemSpawner RND;
	local Weapon aWeapon;

//Let's create our main list
		
	//Mirror SiegeGI!!!
	//I assume the supplier's weapon class group is included into the SiegeGI weapon class group
	For ( i=0 ; i<ArrayCount(WeaponClasses) ; i++ )
	{
		if ( WeaponClasses[i] != none )
			BaseWeapons[j++] = WeaponClasses[i];
	}

	//Now the RandomItemSpawner
//	if ( SpawnedRandomItemSpawner )
//		ForEach AllActors (class'WeightedItemSpawner', RND )
//			break;
	
//	if ( RND != none )
//	{
//		For ( i=0 ; i<16 ; i++ )
//		{
//			W = class<Weapon>(RND.RandomItem[i]);
//			if ( W != none )
//			{
//				For ( iM=0 ; iM<j ; iM++ )
//					if ( W == BaseWeapons[iM] )
//						iM = 1000;
//				if ( iM < 999 )
//					BaseWeapons[j++] = W;
//			}
//		}
//	}

	//I should check for individual sgItems, but i'll skip that for now.
	
	//Now mutate the weapons
	bMutatingWeapons = True;
	For ( i=0 ; i<j ; i++ )
	{
		aWeapon = Spawn( BaseWeapons[i], none,'', Cores[0].Location);
		if ( (aWeapon == none) || aWeapon.bDeleteMe ) //This weapon was mutated, let's see our product
		{
			if ( (theWeapon == none) || theWeapon.bDeleteMe ) //THIS IS BAD!!! MUTATOR SIMPLY REMOVED THE WEAPON.
				continue;
			if ( theWeapon.Class != BaseWeapons[i] ) //Just in case we didn't mutate to self
				MutatedWeapons[i] = theWeapon.Class;
			theWeapon.Destroy();
			theWeapon = none;
		}
		else
		{
			aWeapon.Destroy();
			aWeapon = none;
		}
	}
	bMutatingWeapons = false;

	//Compact the mutated list now
	i=0;
	While ( i<j )
	{
		if ( MutatedWeapons[i] == none )
		{
			if ( i == --j )
				BaseWeapons[j] = none;
			else
			{
				BaseWeapons[i] = BaseWeapons[j];
				MutatedWeapons[i] = MutatedWeapons[j];
			}
		}
		else
			i++;
	}

	//Change the weapon settings in all weapon related objects, if we managed to mutate
	if ( j > 0 )
	{
		//SiegeGI weapon list
		For ( i=0 ; i<ArrayCount(WeaponClasses) ; i++ )
		{
			For ( iM=0 ; iM<j ; iM++ )
				if ( BaseWeapons[iM] == WeaponClasses[i] )
				{
					WeaponClasses[i] = MutatedWeapons[iM];
					break;
				}
		}

		//Supplier
		class'sgSupplier'.static.LoadWeaponClasses();
		For ( i=0 ; i<9 ; i++ )
		{
			For ( iM=0 ; iM<j ; iM++ )
				if ( class'sgSupplier'.default.WeaponClasses[i] == BaseWeapons[iM] )
				{
					class'sgSupplier'.default.WeaponClasses[i] = MutatedWeapons[iM];
					break;
				}
		}
		//SupplierX
		class'sgSupplierX'.static.LoadWeaponClasses();
		For ( i=0 ; i<9 ; i++ )
		{
			For ( iM=0 ; iM<j ; iM++ )
				if ( class'sgSupplierX'.default.WeaponClasses[i] == BaseWeapons[iM] )
				{
					class'sgSupplierX'.default.WeaponClasses[i] = MutatedWeapons[iM];
					break;
				}
		}
		//SupplierXXL
		class'sgSupplierXXL'.static.LoadWeaponClasses();
		For ( i=0 ; i<9 ; i++ )
		{
			For ( iM=0 ; iM<j ; iM++ )
				if ( class'sgSupplierXXL'.default.WeaponClasses[i] == BaseWeapons[iM] )
				{
					class'sgSupplierXXL'.default.WeaponClasses[i] = MutatedWeapons[iM];
					break;
				}
		}
/*
		if ( RND != none )
		{
			For ( i=0 ; i<16 ; i++ )
			{
				W = class<Weapon>(RND.RandomItem[i]);
				if ( W != none )
				{
					For ( iM=0 ; iM<j ; iM++ )
						if ( W == BaseWeapons[iM] )
						{
							RND.RandomItem[i] = MutatedWeapons[iM];
							break;
						}
				}
			}
		}
*/	}

	bMutatedWeapons = true;
}


function PenalizeTeamForKill( Pawn Killed, byte aTeam)
{
	local sgPRI aPRI;
	local sgEquipmentSupplier sS;
	local float penalty;
	
	ForEach Killed.RadiusActors( class'sgEquipmentSupplier', sS, 100)
	{
		if ( sS.bProtected && (sS.Team == Killed.PlayerReplicationInfo.Team) )
			penalty += sS.PenaltyFactor * 10;
	}

	if ( penalty <= 0 )
		return;

	ForEach AllActors (class'sgPRI', aPRI)
		if ( aPRI.Team == aTeam )
			aPRI.AddRu( -penalty);
}

function float KillRUReward( sgPRI Victim, bool bNegative)
{
	local float Factor, Eff2;
	
	if ( bNegative )
		Factor = -1;
	else
		Factor = 1;

	if ( Victim == none )
		return 50 * Factor;
	Eff2 = Victim.GetEff2();
	Factor *= fMax(1,(Eff2 - 60) / 20.f); //Eff 80 starts multiplying
	return (42 + float(Victim.sgInfoSpreeCount)**1.3) * Factor;
}

function SharedReward( sgPRI Awarded, byte Team, float Award, optional float Waste)
{
	Waste = fClamp( Waste, 0, 1);
	if ( (Team < 4) && (Awarded != none) && (Awarded.RU < MaxRUs[Team]) && (Awarded.Team == Team) )
	{
		if ( Awarded.RU <= (MaxRUs[Team] - Award) )
		{
			Awarded.AddRU( Award);
			Award = 0;
		}
		else
		{
			Award -= MaxRUs[Team] - Awarded.RU;
			Awarded.AddRU( MaxRUs[Team] - Awarded.RU);
		}
	}
	
	if ( Award > 0 )
		Cores[Team].StoredRU += Award * (1-Waste);
}

function SetHulls( bool bEnable)
{
	local sgBuildingCH CH;
	ForEach AllActors (class'sgBuildingCH', CH)
		CH.SetCollision(bEnable);
}

defaultproperties
{
     MutatorClass=Class'SiegeMutator'
     RUsPerTeam=14
     bAutoconfigWeapons=False
     RoundRuScale=2
     bUseNukeDeco=False
     bCore5AddsEnforcer=True
     BaseMotion=70
     TranslocBaseForce=800
     TranslocLevelForce=120
     SpawnProtSecs=8
     bUseDenied=True
     NumResources=0.500000
     MaxCoreSnipeDistance=1024.000000
     MaxSiegeTeams=4
     debug=False
     RandomSpawnerLocation(0)=(X=-850.669739,Y=64.548409,Z=-750.570618)
     RandomSpawnerLocation(1)=(X=191.679642,Y=1536.169678,Z=-262.000000)
     RandomSpawnerLocation(2)=(X=3958,Y=-124,Z=40)
     RandomSpawnerLocation(3)=(X=0,Y=0,Z=1624)
     RandomSpawnerLocation(4)=(X=1125,Y=-74,Z=336)
	 RandomSpawnerLocation(5)=(X=-450,Y=927,Z=-130)
     RandomSpawnerMap(0)="CTF-Niven.unr"
     RandomSpawnerMap(1)="CTF-McSwartzly2004]I[x.unr"
     RandomSpawnerMap(2)="CTF-DeNovo.unr"
     RandomSpawnerMap(3)="CTF-Clarion[SwS].unr"
     RandomSpawnerMap(4)="CTF-'uK-BraveHeart[REVISED]"
	 RandomSpawnerMap(5)="CTF-Icepost"
     Weapons(0)="Botpack.ImpactHammer"
     Weapons(1)="sgPulseGun"
     Weapons(2)="Botpack.ShockRifle"
     Weapons(3)="Botpack.UT_FlakCannon"
     Weapons(4)="Botpack.ut_biorifle"
     Weapons(5)="sgMinigun"
     Weapons(6)="Botpack.SniperRifle"
     Weapons(7)="Botpack.ripper"
     Weapons(8)="Botpack.UT_Eightball"
     Weapons(9)="sgNukeLauncher"
     Weapons(10)="sgConstructor"
     Weapons(11)="sgEnforcer"
     Weapons(12)="Botpack.Chainsaw"
	 Weapons(13)="FlameThrower"
	 Weapons(14)="ASMDPulseRifle"
	 Weapons(15)="HyperLeecher"
	 Weapons(16)="SiegeInstagibRifle"
     WeaponClasses(0)=Class'Botpack.ImpactHammer'
     WeaponClasses(1)=Class'sgPulseGun'
     WeaponClasses(2)=Class'Botpack.ShockRifle'
     WeaponClasses(3)=Class'Botpack.UT_FlakCannon'
     WeaponClasses(4)=Class'Botpack.ut_biorifle'
     WeaponClasses(5)=Class'sgMinigun'
     WeaponClasses(6)=Class'Botpack.SniperRifle'
     WeaponClasses(7)=Class'Botpack.ripper'
     WeaponClasses(8)=Class'Botpack.UT_Eightball'
     WeaponClasses(9)=Class'sgNukeLauncher'
     WeaponClasses(10)=Class'sgConstructor'
     WeaponClasses(11)=Class'sgEnforcer'
     WeaponClasses(12)=Class'Botpack.ChainSaw'
	 WeaponClasses(13)=Class'FlameThrower'
	 WeaponClasses(14)=Class'ASMDPulseRifle'
	 WeaponClasses(15)=Class'HyperLeecher'
	 WeaponClasses(16)=Class'SiegeInstagibRifle'
     SupplierProtection=True
     StartingMaxRU=300.000000
     StartingRU=1.000000
     bSpawnInTeamArea=True
     bBalanceTeams=False
     MaxTeams=2
     GoalTeamScore=20.000000
     MinPlayers=0
     FragLimit=0
     TimeLimit=80
     bChangeLevels=True
     StartUpMessage="4th Generation Siege"
     TourneyMessage=""
     ReadyMessage="You are READY for Battle!"
     StartMessage="The Battle has begun!"
     GameEndedMessage="has won the Battle!"
     gamegoal="times better than any other version of Siege!"
     InitialBots=0
     OvertimeMessage="Score tied. Overtime!"
     AdminPassword="admin"
     ScoreBoardType=Class'sgScore'
     HUDType=Class'sgHUD'
     MapListType=Class'Botpack.CTFMapList'
     MapPrefix="CTF"
     GameName="Siege IV"
     GameReplicationInfoClass=Class'sgGameReplicationInfo'
     BuildingMapNames(0)=RedTeam
     BuildingMapNames(1)=BlueTeam
     BuildingMapNames(2)=GreenTeam
     BuildingMapNames(3)=YellowTeam
     bBotCanCheat=true
     GameProfile=OldSiege
}
