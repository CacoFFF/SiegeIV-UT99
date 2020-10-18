//=============================================================================
// sgBaseCore.
// * Revised by 7DS'Lust
//=============================================================================
class sgBaseCore extends sgBuilding;

var float LastMsgSpam;
var bool bCoreDisabled;
var bool bLimitRepair;
var float RuMultiplier;
var float StoredRU; //Spare RU in core
var float SuddenDeathScale;
var float RepairableEnergy;
var PlayerPawn LocalClient;
var TeamInfo MyTeam;

replication
{
	reliable if ( !bNetInitial && (Role==ROLE_Authority) )
		RuMultiplier, StoredRU, RepairableEnergy;
}

event PostBeginPlay()
{
	if ( TeamGamePlus(Level.Game) == None )
	{
		Destroy();
		return;
	}
	if ( (SiegeGI(Level.Game) == None) || (SiegeGI(Level.Game).GoalTeamScore <= 0) )
		MaxEnergy = 20000;
	else
		MaxEnergy = TeamGamePlus(Level.Game).GoalTeamScore * 1000;
	Super.PostBeginPlay();
}

simulated event PostNetBeginPlay()
{
	local PlayerPawn P;
	local sgGameReplicationInfo GRI;
	
	Super.PostNetBeginPlay();
	if ( Level.NetMode == NM_Client )
	{
		ForEach AllActors (class'PlayerPawn', P)
			if ( ViewPort(P.Player) != none )
			{
				LocalClient = P;
				break;
			}
		if ( LocalClient == none )
			Log("Replication messed up: Core replicated before local pawn");
		else
		{
			GRI = sgGameReplicationInfo(LocalClient.GameReplicationInfo);
			if ( (GRI != None) && (GRI.Cores[Team] == None) )
				GRI.Cores[Team] = self;
		}
	}
}

function Destruct( optional pawn instigatedBy)
{
    if ( SiegeGI(Level.Game) != None )
        SiegeGI(Level.Game).CoreDestroyed(Self);
	Spawn(class'sgFlash');
	Spawn(class'shockWave');
	Spawn(class'shockRifleWave');
	Destroy();
}

simulated function TeamInfo GetTeamInfo( byte nTeam)
{
	local TeamInfo T;
	ForEach AllActors (class'TeamInfo', T)
		if ( T.TeamIndex == nTeam )
			return T;
}

simulated function int GetTeamSize()
{
	local sgPRI PRI;
	local int i;

	//Get team size optimally
	if ( MyTeam == none || (MyTeam.TeamIndex != Team) )
		MyTeam = GetTeamInfo( Team);
	if ( MyTeam != none )
		return MyTeam.Size;
	//Count players, non optimal
	ForEach AllActors (class'sgPRI', PRI)
	{
		if ( PRI.Team == Team )
			i++;
	}
	return i;
}

//Returns how many are maxed out
simulated final function int AddRuToPlayers( float SetRU, float MaxRU)
{
	local sgPRI PRI;
	local int MaxedOut;

	ForEach AllActors(class'sgPRI', PRI)
		if( PRI.Team == Team )
		{
			if ( PRI.RU >= MaxRU )
				MaxedOut++;
			else
				PRI.AddRU( SetRU, true);
		}
	return MaxedOut;
}

//XC_Engine version
simulated final function int AddRuToPlayers_XC( float SetRU, float MaxRU)
{
	local sgPRI PRI;
	local int MaxedOut;
	
	ForEach DynamicActors(class'sgPRI', PRI)
		if( PRI.Team == Team )
		{
			if ( PRI.RU >= MaxRU )
				MaxedOut++;
			else
				PRI.AddRU( SetRU, true);
		}
	return MaxedOut;
}

simulated function Timer()
{
	local float SetRU;
	local float MaxRU;
	local int WithdrawExtra;
	local int TeamSize, MaxedOut;

	Super.Timer();
	if ( RuMultiplier <= 0 )
		RuMultiplier = 1;

	UpdateScore();

	if ( bCoreDisabled )
		return;
	
	if ( bDisabledByEMP || (Level.NetMode == NM_Client) && class'sgClient'.default.bHighPerformance )
		Goto NO_INCREASE;

	//Auto-upgrade core if there's a big excedent
	if ( (Grade < 1) && (StoredRU > Default.StoredRU) )
	{
		SetRU = fMin( (1.0-Grade) * UpgradeCost, StoredRU);
		StoredRU -= SetRU;
		Grade += SetRU / UpgradeCost;
	}

	//Do not simulate RU generation on enemy players
	if ( LocalClient == none || LocalClient.PlayerReplicationInfo == none || LocalClient.PlayerReplicationInfo.Team == Team )
	{
		TeamSize = GetTeamSize();
		if ( SiegeGI(Level.Game) != none )
			MaxRU = SiegeGI(Level.Game).MaxRUs[Team];
		else if ( (LocalClient != none) && (sgGameReplicationInfo(LocalClient.GameReplicationInfo) != none) )
			MaxRU = sgGameReplicationInfo(LocalClient.GameReplicationInfo).MaxRUs[Team];
		else
			MaxRU = 9999;
		SetRU = fMax(0.05, (10-float(TeamSize)) * 0.05) + Grade * 0.85;
		SetRU *= RuMultiplier * 0.05;
		if ( SetRU*TeamSize <= 0.0001 ) //Do not substract
		{}
		else if ( (StoredRU < 0) && (SetRU*TeamSize < Abs(StoredRU) ) )
			StoredRU += SetRU*TeamSize;
		else
		{
			WithdrawExtra = int(Sqrt(Abs(StoredRU / (SetRU * TeamSize * 2))));

			MaxedOut = AddRuToPlayers( SetRU * (1+WithdrawExtra), MaxRU);
			if ( MaxedOut > 0 )
				StoredRU += SetRU * 0.75 * MaxedOut; //Those maxed out give 75% their RU to core
			StoredRU -= SetRU * WithdrawExtra * (TeamSize-MaxedOut); //Those not maxed out have substracted additional RU from store

		}
	}
	NO_INCREASE:

	if (myFX != None)
	{
		myFX.RotationRate.Yaw = Energy*0.25;
		myFX.bHidden = Energy <= 0;
		if ( VSize(myFX.Location - Location) > 50 )
			myFX.SetLocation( Location);
	}
}
//**************************************
// Flags:
// 0x00000100 = bCoreDisabled
function PackStatusFlags()
{
	Super.PackStatusFlags();
	if ( bCoreDisabled )
		PackedFlags += 0x00000100;
	if ( bLimitRepair )
		PackedFlags += 0x00000200;
}
simulated function UnpackStatusFlags()
{
	Super.UnpackStatusFlags();
	bCoreDisabled = (PackedFlags & 0x00000100) != 0;
	bLimitRepair  = (PackedFlags & 0x00000200) != 0;
}

simulated function FinishBuilding()
{
    Super.FinishBuilding();

    if ( Team < 0 || Team > 4 )
        Team = 0;

	//Team checks? they all use the same texture, sue me.
   	Texture = SpriteRedTeam;

	if (myFX!=None)
		myFX.RotationRate.Yaw = Energy;
}


simulated function bool RepairedBy( Pawn Other, sgConstructor Constructor, float DeltaRep)
{
	local float RepairAmount, RepairValue;
	local sgPRI PRI;
	
	if ( bDisabledByEMP || bIsOnFire )
	{
		BackToNormal();
		Constructor.SpecialPause = 1;
		return true;
	}
	
	Constructor.SpecialPause = DeltaRep;
	RepairAmount = FMin( MaxEnergy - Energy, 60.0 * DeltaRep);
	if ( bLimitRepair && (RepairableEnergy < RepairAmount) )
		return false;
	RepairValue = RepairAmount * 0.25;
	PRI = sgPRI(Other.PlayerReplicationInfo);
	if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
	{
		if ( PRI.RU < RepairAmount )
			return false;
		PRI.AddRU( -RepairValue);
	}
	RepairableEnergy -= RepairAmount;
	Energy += RepairAmount;
	PRI.Score += RepairValue/20;
	Constructor.AddCoreRepairAmount( RepairAmount);
	return true;
}


simulated function MonsterDamage(int Damage, Pawn instigatedBy)
{
    if ( (Energy-=Damage) <= 0 )
	{
		Energy = 0;
		class'SiegeStatics'.static.AnnounceAll( self, "Game Over! The monsters have killed the BaseCore!");
		Destruct();
	}
}

simulated event TakeDamage( int Damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType)
{
	local float actualDamage;
	local float tempScore;
	local TournamentPlayer p;
	local SiegeStatPlayer Stat;

	if ( Role < ROLE_Authority || Level.Game == None || bCoreDisabled || instigatedBy == self )
		return;
	
	actualDamage = Level.Game.ReduceDamage( Damage, DamageType, Self, instigatedBy);

	if ( instigatedBy != None && instigatedBy.bIsPlayer )
	{
		if ( TeamGamePlus(Level.Game) != None && instigatedBy.PlayerReplicationInfo.Team == Team )
		{
			actualDamage *= TeamGamePlus(Level.Game).FriendlyFireScale;
			tempScore = -1 * FMin(Energy, actualDamage);
		}
		else
			tempScore = FMin( Energy, actualDamage);

		tempScore *= (1 + Grade/10);
		if (tempScore < 0 || tempScore > 100000)
			return;

		instigatedBy.PlayerReplicationInfo.Score += tempScore/100;
		instigatedBy.PlayerReplicationInfo.sgInfoCoreDmg = int(instigatedBy.PlayerReplicationInfo.sgInfoCoreDmg + actualDamage);
		if ( sgPRI(instigatedBy.PlayerReplicationInfo) != None )
		{
			sgPRI(instigatedBy.PlayerReplicationInfo).AddRU((tempScore/7)*RuRewardScale);
			LeechRU( (tempScore/7)*RuRewardScale );
		}
	}
	else if ( sgBuilding(instigatedBy) != None && TeamGamePlus(Level.Game) != None && sgBuilding(instigatedBy).Team == Team )
		actualDamage *= TeamGamePlus(Level.Game).FriendlyFireScale;


	if ( (Level.TimeSeconds - LastMsgSpam) > 2 )
	{
		if ( actualDamage > 0 && instigatedBy != None && ((instigatedBy.bIsPlayer && 
		instigatedBy.PlayerReplicationInfo.Team != Team) || (sgBuilding(instigatedBy) != None && 
		sgBuilding(instigatedBy).Team != Team)) )
			ForEach AllActors (class'TournamentPlayer', P)
				if ( p.PlayerReplicationInfo.Team == Team )
				{
					if ((Energy-actualDamage)/1000 > 2)
						P.ReceiveLocalizedMessage(class'sgCoreWarnMsg', actualDamage);
					else
						P.ReceiveLocalizedMessage(class'sgCoreDyingMsg', actualDamage);
				}
		LastMsgSpam = Level.TimeSeconds;
	}
	
	if ( actualDamage > 0 )
	{
		Energy -= actualDamage;
		Stat = class'SiegeStatics'.static.GetPlayerStat( instigatedBy );
		if ( Stat != None )
			Stat.CoreDamageEvent( actualDamage);
		Spawn(class'sgFlash');
	}

	if (myFX!=None)
		myFX.RotationRate.Yaw = Energy;

	if ( Energy <= 0 )
	{
		Energy = 0;
		class'SiegeStatics'.static.AnnounceAll( self, "Game Over! "@instigatedBy.PlayerReplicationInfo.PlayerName@"killed the BaseCore!");
		Destruct( instigatedBy);
	}

	UpdateScore();
}

function UpdateScore()
{
	if ( SiegeGI(Level.Game) != None )
		SiegeGI(Level.Game).Teams[Team].Score = EnergyScale() * 100.0;
}

function SetMaxRepair( float MaxRepair)
{
	if ( MaxRepair >= 0 )
	{
		RepairableEnergy = MaxEnergy * MaxRepair / 100.0;
		bLimitRepair = true;
	}
	else
		bLimitRepair = false;
}

function string GetHumanName()
{
	local TeamGamePlus Game;
	
	Game = TeamGamePlus(Level.Game);
	if ( (Game != None) && (Game.Teams[Team] != None) )
		return Game.Teams[Team].TeamName@"team";

	return Super.GetHumanName();
}



defaultproperties
{
     NetPriority=2.1
	 bNoRemove=True
	 StoredRU=10
     RuMultiplier=1
     bOnlyOwnerRemove=True
     bExpandsTeamSpawn=True
     RuRewardScale=1
     BuildingName="Base Core"
     UpgradeCost=80
     MaxEnergy=20000.000000
     SpriteScale=1.000000
     Model=LodMesh'Botpack.Diamond'
     SkinRedTeam=Texture'CoreSkinTeam0'
     SkinBlueTeam=Texture'CoreSkinTeam1'
     SkinGreenTeam=Texture'CoreSkinTeam2'
     SkinYellowTeam=Texture'CoreSkinTeam3'
     SpriteRedTeam=Texture'SKFlare'
     SpriteBlueTeam=Texture'SKFlare'
     SpriteGreenTeam=Texture'SKFlare'
     SpriteYellowTeam=Texture'SKFlare'
     DSofMFX=2.600000
     bAlwaysRelevant=True
     MultiSkins(0)=Texture'SKFlare'
     MultiSkins(1)=Texture'SKFlare'
     MultiSkins(2)=Texture'SKFlare'
     MultiSkins(3)=Texture'SKFlare'
     GUI_Icon=Texture'GUI_Core'
     bCollideWorld=True
     DoneBuilding=True
}
