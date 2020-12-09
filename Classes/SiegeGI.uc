// SiegeGI.
// * Revised by nOs*Badger
// * Extended by WILDCARD
// * Optimized and improved by Higor
//=============================================================================
class SiegeGI extends TeamGamePlus config(SiegeIV_FWBv1a);

const SGS = class'SiegeStatics';

var class<Object> GCBind; //SiegeNative plugin ref to prevent GC cleaning

var SiegeStatPool   StatPool;
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
var sgCategoryInfo CategoryInfo[4];
var sgTeamNetworth NetworthStat[4];
var int NetworthTimer;


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
var Weapon theWeapon; //We keep this pointer during Weapon mutation
var sgPRI LastMidSpawnToucher;
var string LastMidSpawnItemName;

var sgBuildingMap BuildingMaps[4];
var Name BuildingMapNames[4];
var sg_BOT_BuildingBase BuildMarkers[4];
var Object ProfileObject;
var SiegeCategoryRules CategoryRules;
var CoreModifierRules CoreRules;



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
	local vector MidSpawnLocation;
	local Inventory Item;
	local sgBaseCore b;
	local string opt;
	local int i, j, k;
	local Info aInfo;
	local string sParse;
	local flagBase FlagList[5], aFlg, fList[5];
	local float FlagTeamList[5];
	local sgBotController BController;

	GameName="Siege IV";
	bUseTranslocator = True;
	bMultiWeaponStay = false;
	bCoopWeaponMode = true;
	SGS.static.DetectXCGE( self);
	Super.InitGame(options, error);

	opt = ParseOption(options, "FreeBuild");
	if ( opt == "1" || opt ~= "true" )
		FreeBuild = true;

	opt = ParseOption(options, "SwapCores");
	if ( opt == "1" || opt ~= "true" )
		bRandomizeCores = true;

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

	InsertRU();

	if ( GameProfile == '' )
		GameProfile = 'SiegeDefault';

	For ( i=0 ; i<4 ; i++ )
	{
		if ( Cores[i] == none )
			continue;
		CategoryInfo[i] = Spawn( class'sgCategoryInfo');
		CategoryInfo[i].Team = i;
		NetworthStat[i] = Spawn( class'sgTeamNetworth');
		NetworthStat[i].SetTeam( i);
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

    StatPool = Spawn(class'SiegeStatPool');

	if ( !SpawnedRandomItemSpawner &&
	(  UniqueActorLocation( class'WarheadLauncher', MidSpawnLocation)
	|| UniqueActorLocation( class'UDamage',         MidSpawnLocation)
	|| UniqueActorLocation( class'HealthPack',      MidSpawnLocation)
	|| UniqueActorLocation( class'UT_Shieldbelt',   MidSpawnLocation)
	|| UniqueActorLocation( class'UT_Invisibility', MidSpawnLocation)) )
	{
		SpawnedRandomItemSpawner = true;
		Spawn( class'WeightedItemSpawner',,, MidSpawnLocation);
	}

	ForEach AllActors( class'Inventory', Item)
    {
		if ( (WildcardsResources(Item) != none) || (ScubaGear(Item) != none) )
			continue;
		Item.Destroy();
	}

	ModifyLevel();
	
	//Clear defaults transferred from previous map
	class'sgSupplier'.static.ClearWeaponClasses();
	class'sgSupplierX'.static.ClearWeaponClasses();
	class'sgSupplierXXL'.static.ClearWeaponClasses();
}


function bool UniqueActorLocation( class<Actor> ActorClass, out vector ActorLocation)
{
	local Actor A, Found;
	
	ForEach AllActors( ActorClass, A)
	{
		if ( Found != None )
			return false;
		Found = A;
	}

	if ( Found != None )
	{
		ActorLocation = Found.Location;
		return true;
	}
	
	return false;
}


function InsertRU()
{
	local vector vMin, vMax;
	local PathNode P;
	local Light L;
	local WRU50 R;
	local NavigationPoint N;
	local float cCount[4], aDist;
	local float RUsLeft[4];
	local int i, iCount;

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
		while ( (RUsLeft[i] > RUsPerTeam * 0.3) && (iCount < 1000) )
		{
			//Find candidates, add ru to surroundings
			N = GetLinkedCandidate( NavigationPoint(Cores[i].HitActor),++iCount);
			if ( N == none )
				break;
			if ( N.HitActor == none )
			{
				N.HitActor = N;
				if ( FRand() > VSize(N.Location - Cores[i].Location) / (aDist * 0.3)  )
					continue;

				if ( (N.IsA('PathNode') && (FRand() > 0.1))
				|| (N.IsA('InventorySpot') && (FRand() > 0.8)) //Gets checked again in below condition
				|| (!N.bSpecialCost && !N.bCollideActors && (N.ExtraCost <= 0) && !N.IsA('PlayerStart')&& (FRand() > 0.8))  )
					N.HitActor = none;

				if ( N.HitActor == none && N.Region.ZoneNumber != 0 ) //Don't spawn RU in BSP walls
				{
					ForEach N.RadiusActors( class'WRU50', R, 75)
					{
						N.HitActor = N;
						break;
					}
					if ( N.HitActor == None )
					{
						N.HitActor = Spawn(class'WRU50',,,N.Location);
						RUsLeft[i] -= 1;
					}
				}
			}
		}
	}

	For ( i=0 ; i<arrayCount(RUsLeft) ; i++ ) //Expensive iterator, unfortunately
	{
		if ( RUsLeft[i] <= 0 )
			continue;
		ForEach Cores[i].RadiusActors (class'PathNode', P, aDist)
			if ( P.HitActor == none && P.Region.ZoneNumber != 0 )
				cCount[i] += 1;
		ForEach Cores[i].RadiusActors (class'PathNode', P, aDist)
			if ( (P.HitActor == none) && (P.Region.ZoneNumber != 0) && (FRand()*(cCount[i]-=1) < RUsLeft[i] ) )
			{
				P.HitActor = Spawn(class'WRU50',,,P.Location);
				if ( (RUsLeft[i] -= 1) <= 0)
					break;
			}
		//0027: Use lights!!!
		cCount[i] = 0;
		if ( RUsLeft[i] <= 0 )
			continue;
		ForEach Cores[i].RadiusActors (class'Light', L, aDist)
			if ( L.Region.ZoneNumber != 0 )
				cCount[i] += 1;
		ForEach Cores[i].RadiusActors (class'Light', L, aDist)
			if ( (L.Region.ZoneNumber != 0) && (FRand()*(cCount[i]-=1) < RUsLeft[i] ) )
			{
				if ( L.Region.Zone.bWaterZone && L.Region.Zone.DamagePerSec > 0 )
					L.HitActor = Spawn(class'WRU50',,,L.Location );
				else
				{
					if ( L.Trace( vMin, vMax, L.Location - vect(0,0,800) ) == None )
						vMin = L.Location - vect(0,0,800);
					L.HitActor = Spawn(class'WRU50',,,vMin + vect(0,0,35));
				}
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
	local int i, n;
	local int ReachFlags, Distance;
	local NavigationPoint nCur, nLast, Cached[16];
	local actor nS, nE;

	//Negative costed paths are out of choice!!!
	nCur = Base;
	CUR_AGAIN:
	if ( nCur.bMeshCurvy ) //Base has become a dead end
		return None;
	else if ( nCur.Cost != 0 )
	{
		//Find 0 costed path, randomize
		if ( nCur.Cost > 0 ) //Negative means already checked
		{
			n = 0;
			nCur.Cost = iCount;
			For ( i=0 ; (i<16) && (nCur.Paths[i]>=0) ; i++ )
			{
				nCur.describeSpec( nCur.Paths[ i ], nS, nE, ReachFlags, Distance);
				if ( NavigationPoint(nE).Cost == 0 )
					Cached[n++] = NavigationPoint(nE);
			}
			if ( n > 0 )
			{
				nCur = Cached[Rand(n)];
				nCur.Cost = iCount;
				nCur.bMeshCurvy = nCur.Paths[0] < 0; //Pre-emptively mark as dead end
				return nCur;
			}
		}

		//Find positive costed and iterate here, also, mark this path as negative CUR
		n = 0;
		nCur.Cost = -iCount; //Go negative for non-bounce back paths
		For ( i=0 ; (i<16) && (nCur.Paths[i]>=0) ; i++ )
		{
			nCur.describeSpec( nCur.Paths[ i ], nS, nE, ReachFlags, Distance);
			if ( (abs(NavigationPoint(nE).Cost) != iCount) && !nE.bMeshCurvy )
				Cached[n++] = NavigationPoint(nE);
		}
		if ( n > 0 )
		{
			nLast = nCur; //Keep record of our last path
			nCur = Cached[Rand(n)];
			Goto CUR_AGAIN;
		}

		//This is a dead end by extension
		nCur.bMeshCurvy = true;
		nCur = Base;
		if ( nLast != None )
		{
			nCur = nLast;
			nLast = None;
		}
		Goto CUR_AGAIN; //start over
	}
	else
	{
		nCur.Cost = iCount;
		return nCur;
	}
}

function ModifyLevel()
{
	local LavaZone LavaZone;
	local string LevelName;

	LevelName = String(Outer.Name);

	if ( LevelName ~= "CTF-Kosov" )
		Spawn(class'sgMapEditor').EditKosov();
	else if ( LevelName ~= "CTF-DeNovo" )
		Spawn(class'sgMapEditor').EditDeNovo();
	else if ( LevelName ~= "CTF-(EoW)Kanjar" )
		Spawn(class'sgMapEditor').EditKanjar();
	else if ( LevelName ~= "CTF-BlackRiverUltimateV5" )
		Spawn(class'sgMapEditor').EditBlackRiverUltimateV5();
	else if ( LevelName ~= "CTF-'uK-MiniCivilWarV3]FIXED[" )
		Spawn(class'sgMapEditor').EditMiniCivilWarV3();
	else if ( LevelName ~= "CTF-Clarion[SwS]" )
		Spawn(class'sgMapEditor').EditClarionSwS();
//	else if ( LevelName ~= "CTF-'uK-BraveHeart[REVISED]" )

	// Lava Zones no longer destructive.
	ForEach AllActors( class'LavaZone', LavaZone)
		LavaZone.bNoInventory = false;
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
			if ( Cores[i] != None )
				Cores[i].Energy *= Cores[i].SuddenDeathScale;

		ForEach AllActors (class'sgBuildRuleCount', RuleCounts )
			if ( RuleCounts.bOverTime )
				RuleCounts.bOverTimeReached = true;
	}
}

function StartMatch()
{
	local WeightedItemSpawner ExistingSpawner;
	local int i;

	bMatchStarted = true;

	Foreach AllActors(class'WeightedItemSpawner',ExistingSpawner)
		ExistingSpawner.GotoState('Spawning');

	For ( i=0 ; i<ArrayCount(Cores) ; i++ )
		if ( Cores[i] != none )
			Cores[i].bCoreDisabled = false;

	sgGameReplicationInfo(GameReplicationInfo).bTeamDrag = bTournament;
			
	Super.StartMatch();
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

function InitGameReplicationInfo()
{
	Super.InitGameReplicationInfo();
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
	local bool bAdded;

    // Ugly hack to spawn the correct type of PRI
	class'Bot'.default.PlayerReplicationInfoClass = class'sgPRI';
	SetHulls( false);
	bAdded = Super.AddBot();
	SetHulls( true);
    class'Bot'.default.PlayerReplicationInfoClass = class'BotReplicationInfo';

	return bAdded;
}

event PlayerPawn Login( string portal, string options, out string error, class<PlayerPawn> spawnClass)
{
	local PlayerPawn newPlayer;
//    local class<PlayerReplicationInfo> priClass;

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
			SGS.static.AnnounceAll( self, NewPlayer.PlayerReplicationInfo.PlayerName@"has been denied Spectator access.");
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

	if ( PlayerPawn.IsA('Spectator') || (bRequireReady && (CountDown > 0)) )
		return;

	GivePlayerWeapon(playerPawn, WeaponClasses[12]);

	For ( i=0 ; i<12 ; i++ )
		if ( WeaponClasses[i] != None )
			GivePlayerWeapon(playerPawn, WeaponClasses[i]);
	PlayerPawn.SwitchToBestWeapon(); //Now weapon priority is a thing
	BaseMutator.ModifyPlayer(PlayerPawn);
}

function bool PickupQuery( Pawn Other, Inventory item )
{
	local bool Result;
	local bool bIsMidSpawn;

	bIsMidSpawn = Item.LightEffect == LE_Rotor && Item.LightType == LT_Steady && Item.LightHue == 85;
	Result = Super.PickupQuery( Other, Item); //This may destroy the item!
	if ( bIsMidSpawn && (Other != None) )
	{
		LastMidSpawnToucher = sgPRI( Other.PlayerReplicationInfo);
		if( Item.ItemName == "" )
			LastMidSpawnItemName = Item.default.ItemName;
		else
			LastMidSpawnItemName = Item.ItemName;
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

function ScoreKill( Pawn killer, Pawn other)
{
    local int NukeAmmo;
	local float RuMult, SpamFactor;
	local bool bTeamKill;
	local sgPRI aVictim, aKiller;
	local vector TStart;
	local sgEquipmentSupplier Supplier;
	local int SupplierTicks;
	local SiegeStatPlayer Stat, VictimStat;
	local byte KillerTeam, VictimTeam;

	RuMult = 1;

	if ( Other != none )	aVictim = sgPRI(other.PlayerReplicationInfo);
	if ( Killer != none )	aKiller = sgPRI(killer.PlayerReplicationInfo);
	Stat = SGS.static.GetPlayerStat( killer);
	KillerTeam = SGS.static.GetTeam(killer);
	VictimTeam = SGS.static.GetTeam(other);
	VictimStat = SGS.static.GetPlayerStat(other);

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
		if( (Stat != None) && (KillerTeam != VictimTeam) )
			Stat.KillEvent( 1 );
			
		killer.KillCount++;
		if ( killer.bIsPlayer && other.bIsPlayer && (aKiller != None) && (aVictim != None) )
   		{
			if ( aKiller.Team != aVictim.Team )
			{
				aKiller.Score += 1;
				if ( killer.BaseEyeHeight < killer.default.BaseEyeHeight )
					aKiller.sgInfoSpreeCount += 2;
					
				ForEach RadiusActors( class'sgEquipmentSupplier', Supplier, 250, Other.Location)
					if ( Supplier.Team == aVictim.Team )
					{
						SpamFactor = 1 + (250 - VSize(Other.Location-Supplier.Location)) / 25; //0 to 11.9
						SupplierTicks += (1 + int(Supplier.bProtected)*2) * SpamFactor;
						aKiller.sgInfoSpreeCount += 2;
					}
				Cores[aVictim.Team].StoredRU += SupplierTicks * Teams[aVictim.Team].Size;
					
				if ( (aKiller != none) && (aVictim != none) && aVictim.bReachedSupplier && (aVictim.SupplierTimer > 0) )
				{
					aKiller.sgInfoSpreeCount += 10;
					aKiller.AddRU( KillRUReward(none, true) * RuMult);
					Cores[aKiller.Team].StoredRU -= aVictim.SupplierTimer + Teams[aKiller.Team].Size * 5 * Cores[aKiller.Team].Grade;
					PenalizeTeamForKill( Other, aKiller.Team);
					aVictim.AddRU(10 * RuMult);
					aVictim.sgInfoSpreeCount = 0;
					SupplierTicks += 20 + int(aVictim.SupplierTimer) * 5;
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
							aKiller.sgInfoSpreeCount += 2;
					}
				}
				
				if ( SupplierTicks > 0 )
					ForEach AllActors( class'sgEquipmentSupplier', Supplier, class'SiegeStatics'.static.TeamTag(aVictim.Team) )
						Supplier.MultiSupplyTicks += SupplierTicks;
			}
			else
			{
				bTeamKill = true;
				aKiller.Score -= 1;
				if ( aKiller != None )
					aKiller.AddRU( KillRUReward( aVictim, true) * RuMult);
			}
		}
        if ( aVictim != None )
            aVictim.AddRU(-10 * RuMult);
	}

	NukeAmmo = SGS.static.GetAmmoAmount( Other, class'WarheadAmmo');
	if( (NukeAmmo > 0) && (Other.PlayerReplicationInfo != none) )
	{
		if ( NukeAmmo == 1 )
			SGS.static.AnnounceAll( self, Other.PlayerReplicationInfo.PlayerName@"was carrying a WARHEAD!!!" );
		else
			SGS.static.AnnounceAll( self, Other.PlayerReplicationInfo.PlayerName@"was carrying "$NukeAmmo$" WARHEADS!!!" );
		
		NukeAmmo = Min( NukeAmmo, 2);
		if ( KillerTeam != VictimTeam )
		{
			if ( aKiller != None )
			{
				aKiller.AddRU( 500 * NukeAmmo);
				aKiller.Score += 5 * NukeAmmo;
			}
			if ( Stat != None )
				Stat.WarheadDestroyEvent( NukeAmmo );
		}
		
		if(VictimStat != None)
			VictimStat.WarheadFailEvent(NukeAmmo);

		if ( (KillerTeam < 4) && (KillerTeam != VictimTeam) && (NetworthStat[KillerTeam] != None) )
			NetworthStat[KillerTeam].AddEvent( 1);
		if ( (VictimTeam < 4) && (NetworthStat[VictimTeam] != None) )
			NetworthStat[VictimTeam].AddEvent( 2 + Min(KillerTeam,3) );
	}

	other.DieCount++;
    BaseMutator.ScoreKill(Killer, other);
}

function int ReduceDamage( int damage, name damageType, Pawn injured,  Pawn instigatedBy)
{
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

	if ( (sgBuilding(instigatedBy) != None) && (sgBuilding(instigatedBy).Team == SGS.static.GetTeam(injured)) )
		damage *= FriendlyFireScale;
	
	damage = Super.ReduceDamage( damage, damageType, injured, instigatedBy);

	//Building related
	if ( sgBuilding(injured) != none )
	{
		if ( (sgBaseCore(injured) != None) && bPlayerInstigated )
			damage *= BaseCoreDamageScale( sgBaseCore(Injured), instigatedBy, DamageType);
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

// Util for previous TakeDamage
function float BaseCoreDamageScale( sgBaseCore BaseCore, Pawn DamageInstigator, name DamageType)
{
	if ( VSize(BaseCore.Location - DamageInstigator.Location) > MaxCoreSnipeDistance )
	{
		if ( DamageType == 'Decapitated' )
			return 0.1;
		if ( (DamageType == 'Shot') && SniperRifle(DamageInstigator.Weapon) != None )
			return 0.1;
		if ( (DamageType == 'Shredded') && (Ripper(DamageInstigator.Weapon) != None) )
			return 0.15;
	}
	return 1.0;
}

function NavigationPoint FindPlayerStart( Pawn Player, optional byte InTeam, optional string IncomingName)
{
	local PlayerStart Start, StartList[32];
	local Pawn P;
	local int i, LowestWeight, StartCount, WeightSum;
	local Teleporter Tele;
	local NavigationPoint N;
	local byte      Team;
    local bool bSpawnNearBase;

	if ( bStartMatch && (Player != None) && Player.IsA('TournamentPlayer')
	  && (Level.NetMode == NM_Standalone)
      && (TournamentPlayer(Player).StartSpot != None) )
		return TournamentPlayer(Player).StartSpot;



	if ( IncomingName != "" )
		ForEach AllActors(class 'Teleporter', Tele)
			if ( string(Tele.Tag) ~= IncomingName )
				return Tele;

	if ( (Player != None) && (Player.PlayerReplicationInfo != None) )
		Team = Player.PlayerReplicationInfo.Team;
	else
		Team = InTeam;

	// Choose candidates
	for ( N=Level.NavigationPointList ; N!=None ; N=N.nextNavigationPoint )
	{
		Start = PlayerStart(N);
		if ( (Start != None) && Start.bEnabled && (!bSpawnInTeamArea || Team == Start.TeamNumber) )
		{
			if ( StartCount < 32 )
				StartList[StartCount] = Start;
			else if ( Rand(StartCount) < 32 )
				StartList[Rand(32)] = Start;
			StartCount++;
		}
	}

	if ( StartCount == 0 )
	{
		if ( Team != 255 )
			log("Didn't find any player starts in list for team"@Team@"!!!");
		foreach AllActors( class'PlayerStart', Start )
		{
			if ( StartCount < 32 )
				StartList[StartCount] = Start;
			else if ( Rand(StartCount) < 32 )
				StartList[Rand(32)] = Start;
			StartCount++;
		}
		if ( StartCount == 0 )
			return None;
	}
	StartCount = Min( StartCount, 32); //Cap at 32

	// Assess candidates
	For ( i=0 ; i<StartCount ; i++ )
	{
		StartList[i].visitedWeight = 1000;
		if ( StartList[i] != LastStartSpot )
			StartList[i].visitedWeight += Rand(5); //randomize
	}
	bSpawnNearBase = FRand() <= 0.85;

	for ( P=Level.PawnList ; P!=None ; P=P.nextPawn )
	{
		if ( P.bIsPlayer && P.bCollideActors && (P.Health > 0) && (P.PlayerReplicationInfo != None) ) //bCollideActors discards dead and spectators
		{
			for ( i=0 ; i<StartCount ; i++ )
			{
				StartList[i].visitedWeight -= 10000 * int(SGS.static.ActorsTouchingExt( P, StartList[i], 10, 20)); //This spawn should not be used
				StartList[i].visitedWeight -= int( P.Region.Zone == StartList[i].Region.Zone);
				if ( P.PlayerReplicationInfo.Team != Team ) //Reduce chance of selecting spawn in presence of enemies
				{
					StartList[i].visitedWeight -= 1 * int(VSize( P.Location - StartList[i].Location) < 2000);
					StartList[i].visitedWeight -= 2 * int(VSize( P.Location - StartList[i].Location) < 1000);
					StartList[i].visitedWeight -= 2 * int(P.FastTrace( StartList[i].Location));
				}
			}
        }
        else if ( bSpawnNearBase && (sgBuilding(P) != None) && sgBuilding(P).bExpandsTeamSpawn && (sgBuilding(P).Team == Team) )
		{
			for ( i=0 ; i<StartCount ; i++ )
			{
				//Buildings that have taken damage have a chance to deny the spawn expansion
				StartList[i].visitedWeight += int( (FRand() < sgBuilding(P).EnergyScale()) && (VSize( P.Location - StartList[i].Location) < 1000) );
				StartList[i].visitedWeight += int( (FRand() < sgBuilding(P).EnergyScale()) && P.FastTrace(StartList[i].Location) );
			}
		}
    }

	// Normalize weights to have a minimum of 2
	LowestWeight = MaxInt;
	for ( i=0 ; i<StartCount ; i++ )
		if ( StartList[i].visitedWeight >= 0 )
			LowestWeight = Min( StartList[i].visitedWeight - 2, LowestWeight);
	WeightSum = 0;
	for ( i=0 ; i<StartCount ; i++ )
		if ( StartList[i].visitedWeight >= 0 )
		{
			StartList[i].visitedWeight -= LowestWeight;
			WeightSum += StartList[i].visitedWeight;
		}

	// Select one Player start
	if ( WeightSum <= 0 )
		LastStartSpot = StartList[Rand(StartCount)];
	else
	{
		LowestWeight = 0;
		WeightSum = Rand(WeightSum); //Pick one weight value (this will select the start point)
		for ( i=0 ; i<StartCount ; i++ )
			if ( StartList[i].visitedWeight >= 0 )
			{
				if ( WeightSum < LowestWeight + StartList[i].visitedWeight )
				{
					LastStartSpot = StartList[i];
					break;
				}
				LowestWeight += StartList[i].visitedWeight;
			}
	}
	return LastStartSpot;
}

function bool IsOnTeam(Pawn other, int teamNum)
{
    if ( sgBuilding(other) != None )
        return (sgBuilding(other).Team == teamNum);
    else if ( other.bIsPlayer && other.PlayerReplicationInfo != None )
        return (other.PlayerReplicationInfo.Team == teamNum);
}

function bool RestartPlayer( Pawn P)
{
	local PlayerReplicationInfo PRI;
    local NavigationPoint startSpot;
	local bool foundStart;

	PRI = P.PlayerReplicationInfo;
	if ( (sgPRI(PRI) != none) && SpawnProtSecs > 0 )
		sgPRI(PRI).SetProtection(SpawnProtSecs);

	P.DrawScale = P.default.DrawScale;
	P.GroundSpeed = P.default.GroundSpeed;
	P.SetCollisionSize( P.default.CollisionRadius, P.default.CollisionHeight);

	if ( bRestartLevel && Level.NetMode != NM_DedicatedServer && Level.NetMode != NM_ListenServer )
		return true;

	if ( PRI != None &&
		(PRI.Team < 0 || PRI.Team >= MaxSiegeTeams ||
		Cores[PRI.Team] == None || Cores[PRI.Team].bCoreDisabled ) )
	{
		if ( P.IsA('Bot') )
		{
			PRI.bIsSpectator = true;
			PRI.bWaitingPlayer = true;
			P.GotoState('GameEnded');
		    return false;
	    }
		SetHulls(false);
	    startSpot = FindPlayerStart(P, 255);
		SetHulls(true);
	    if ( startSpot == None )
		    return false;

	    foundStart = p.SetLocation(startSpot.Location);
	    if ( foundStart )
	    {
			startSpot.PlayTeleportEffect(p, true);
			P.SetRotation(startSpot.Rotation);
			P.ViewRotation = P.Rotation;
			P.Acceleration = vect(0,0,0);
			P.Velocity = vect(0,0,0);
			P.Health = P.Default.Health;
			P.ClientSetRotation( startSpot.Rotation );
			P.SoundDampening = p.Default.SoundDampening;
			P.PlayerRestartState = 'PlayerSpectating';
	    }
	    return foundStart;
    }
    //else
        //p.PlayerRestartState = 'PlayerWalking';

    return Super.RestartPlayer(P);


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

    local int i, smallest;
	local Pawn P;

	if ( bRatedGame && Other.PlayerReplicationInfo.Team != 255 )
		return false;

	if ( Other.IsA('Spectator') )
	{
		Other.PlayerReplicationInfo.Team = 255;
		if (LocalLog != None) LocalLog.LogTeamChange(Other);
		if (WorldLog != None) WorldLog.LogTeamChange(Other);
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

	if ( bPlayersBalanceTeams && (Level.NetMode != NM_Standalone) )
	{
		if ( Teams[newTeam].Size > Teams[smallest].Size )
			newTeam = smallest;
		if ( NumBots == 1 )
		{
			// join bot's team if sizes are equal, because he will leave
			for ( P=Level.PawnList; P!=None; P=P.NextPawn )
				if ( p.IsA('Bot') )
					break;

			if ( P != None && P.PlayerReplicationInfo != None &&
              P.PlayerReplicationInfo.Team != 255 &&
              Teams[P.PlayerReplicationInfo.Team].Size ==
              Teams[smallest].Size )
				newTeam = P.PlayerReplicationInfo.Team;
		}
	}

	//Just rejoined a programmed game, go to smallest team.
	if ( bMatchStarted && bTournament && (PlayerPawn(Other) != none) && (PlayerPawn(other).GameReplicationInfo == none) )
	{
		newTeam = smallest;
	}
	
	if ( (PlayerPawn(Other) != none) && (Other.PlayerReplicationInfo.Team == newTeam) && (PlayerPawn(Other).GameReplicationInfo != none)
		&& (Other.Health > 0) && Other.bCollideActors && Other.bBlockActors ) //TESTING, the GRI being none means that this player has just joined
		return false;

	if ( Other.PlayerReplicationInfo.Team == newTeam && bNoTeamChanges )
		return false;

    if ( (Other.PlayerReplicationInfo.Team < 5) && (Cores[Other.PlayerReplicationInfo.Team] == none) && !Other.IsA('Spectator') )
    {
        Other.PlayerRestartState = 'PlayerWalking';
		Other.Health = -1;
		bPendingRestart = true;
//        other.GotoState(other.default.PlayerRestartState);
        if ( !other.IsA('Commander') )
            other.GotoState('Dying');
 //       other.RestartPlayer();
    }

	if ( Other.IsA('TournamentPlayer') )
		TournamentPlayer(Other).StartSpot = None;

	if ( Other.PlayerReplicationInfo.Team != 255 )
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

function CoreDestroyed( sgBaseCore Core)
{
	local int i, remainingTeams;

	if ( Cores[Core.Team] != Core )
		return;

	Cores[Core.Team] = None;
	Teams[Core.Team].Score = 0;
	sgGameReplicationInfo(GameReplicationInfo).Cores[Core.Team] = None;

	for ( i=0; i<4; i++ )
		if ( Cores[i] != None )
			remainingTeams++;

	if ( remainingTeams <= 1 )
	{
		EndGame("teamscorelimit");
		return;
	}

	BroadcastLocalizedMessage(class'sgDefeatedMsg', Core.Team);
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
	StatPool.ClearTeamRU( aTeam);
}

function CheckRandomSpawner()
{
    local int i, Override;
	local WeightedItemSpawner ExistingSpawner;
	local string MapName, OtherMap;

	MapName = string(Outer.Name);
	Override = -1;
	for ( i=0; i!=32 && Override!=-1; i++)
	{
		OtherMap = Caps(RandomSpawnerMap[i]);
		if ( InStr(OtherMap,".UNR") >= 0 )
			OtherMap = Left( OtherMap, InStr(OtherMap,".UNR"));

		if ( MapName ~= OtherMap )
			Override = i;
	}

	if ( Override >= 0 )
	{
		ForEach AllActors( class'WeightedItemSpawner', ExistingSpawner)
		{
			ExistingSpawner.SetLocation( RandomSpawnerLocation[Override] );
			break;
		}
		if ( ExistingSpawner == None )
		{
			Spawn( class'WeightedItemSpawner',,, RandomSpawnerLocation[Override]);
			SpawnedRandomItemSpawner = true;
		}
	}
	CheckedRandomSpawner = true;
}

simulated event Timer()
{
	local PlayerPawn ThisPawn;
	local Bot ThisBot;

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
	
	NetworthTimerProc();
}

function NetworthTimerProc()
{
	local Pawn P;
	local int i, Index;
	local float OldMaximum[4];
	local float Maximum[4];
	local float BiggestMaximum;
	
	if ( NetworthTimer-- <= 0 )
	{
		NetWorthTimer += 15;
		
		For ( i=0 ; i<4 ; i++ )
			if ( NetworthStat[i] != None )
			{
				Index = NetworthStat[i].CurrentIndex + 1;
				break;
			}
			
		For ( i=0 ; i<4 ; i++ )
			if ( NetworthStat[i] != None )
			{
				NetworthStat[i].CurrentIndex = Index;
				OldMaximum[i] = NetworthStat[i].TotalNetworth( Index );
				NetworthStat[i].ResetNetworth( Index );
			}
		
		ForEach AllActors( class'Pawn', P)
		{
			if ( (sgPRI(P.PlayerReplicationInfo) != None) && (P.PlayerReplicationInfo.Team < 4) )
			{
				if ( NetworthStat[P.PlayerReplicationInfo.Team] != None )
					NetworthStat[P.PlayerReplicationInfo.Team].EvaluatePlayer( P);
			}
			else if ( sgBuilding(P) != None && (sgBuilding(P).Team < 4) )
			{
				if ( NetworthStat[sgBuilding(P).Team] != None )
					NetworthStat[sgBuilding(P).Team].EvaluateBuilding( sgBuilding(P));
			}
		}
		
		For ( i=0 ; i<4 ; i++ )
			if ( NetworthStat[i] != None )
			{
				Maximum[i] = NetworthStat[i].TotalNetworth( Index );
				if ( (Maximum[i] > OldMaximum[i]) || (Maximum[i] > NetworthStat[i].MaxTeamNetworth) ) 
					NetworthStat[i].MaxTeamNetworth = fMax( NetworthStat[i].MaxTeamNetworth, Maximum[i] ); //Fast
				else
					NetworthStat[i].MaxTeamNetworth = NetworthStat[i].MaximumNetworth(); //Slow
				BiggestMaximum = Max( BiggestMaximum, NetworthStat[i].MaxTeamNetworth);
			}
			
		For ( i=0 ; i<4 ; i++ )
			if ( NetworthStat[i] != None )
				NetworthStat[i].MaxTotalNetworth = BiggestMaximum;
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

// Log internal F3 stats when a mid item is picked
function MidItemPicked(sgPRI Owner, string ItemName)
{
	local sgPRI aPRI;
	local string MidItemPickedUpString;

	MidItemPickedUpString = " picked up";
	ForEach AllActors( class'sgPRI', aPRI)
	{
		if( aPRI.bIsSpectator || (aPRI.Team == Owner.Team) )
			aPRI.ReceiveMessage( "[MID SPAWN] "@Owner.PlayerName $MidItemPickedUpString @ItemName, Owner.Team, false);
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
//	local class<Weapon> W;
	local int i, j, iM;
//	local WeightedItemSpawner RND;
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
			penalty += sS.PenaltyFactor * 15;
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
     bUseNukeDeco=False
     bCore5AddsEnforcer=True
     BaseMotion=70
     TranslocBaseForce=800
     TranslocLevelForce=130
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
