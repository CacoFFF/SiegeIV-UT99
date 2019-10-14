//=============================================================================
// sgBuilding.
// * Revised by 7DS'Lust
// * Revised by WILDCARD
// Further revised by SK to allow for buildings to be on fire or electricuted!
//=============================================================================
class sgBuilding extends StationaryPawn
    abstract;

#exec OBJ LOAD File=AmbModern.uax

const BlockScanDist = 800.f;
const SGS = class'SiegeStatics';

var() string sPlayerIP;
var float fRULeech; //RU given to enemy
var int iRULeech;
var int iCatTag; //Tag given to build if made from a category
var float RUinvested;
var sgPRI OwnerPRI;
var sgBuildingVolume MyVolume;
var vector InitialLocation;
var float BaseEnergy;
var int TimerCount;
var int PackedFlags;
// Flags:
// 0x00000003 = Team (2 bytes)
// 0x00000004 = bDisabledByEMP
// 0x00000008 = bSmokeStatus
// 0x00000010 = bIsOnFire
// 0x00000020 = bNoRemove
// 0x00000040 = bOnlyOwnerRemove




var NavigationPoint N;
var EffectsPool EffectsPool;

var float               SCount, TotalScount;
var sgMeshFX            myFX;
var int                 Team;
var bool                DoneBuilding;
var bool				bBuildInitialized;
var float               BuildingTimer;
var float ScaleBox; //Scale a build'd collision once it's up and working

// vars for fire and EMP stuff
var bool bReplicateEMP;
var bool bReplicateMFX;
var bool bDisabledByEMP;
var bool bIsOnFire;
var pawn TehIncinerator;
var float BurnPerSecond; //Damage to take per second (burning state)
var float AccBurn;  //Accumulated burn (precise values)

// What orb the building has currently attached to it
var WildcardsOrbs Orb;
var sg_XC_Orb XC_Orb;

// Building's Attributes
var(BuildingAttributes) string            BuildingName;
var(BuildingAttributes) int               BuildCost,UpgradeCost;
var(BuildingAttributes) float             BuildTime,MaxEnergy;
var(BuildingAttributes) float Energy,		 RuRewardScale,        Grade;
var(BuildingAttributes) float BuildDistance;
var(BuildingAttributes) bool bCanTakeOrb;
var(BuildingAttributes) bool bOnlyOwnerRemove;
var(BuildingAttributes) bool bNoRemove; //Cannot be removed
var(BuildingAttributes) bool bStandable; //Used to prevent translocators from bouncing here
var(BuildingAttributes) bool bBlocksPath; //Blocks pathing
var(BuildingAttributes) bool bDragable;
var(BuildingAttributes) bool bExpandsTeamSpawn; //Increases PlayerStart's chance of being used

// Building's Apperance
var(BuildingApperance) float SpriteScale;
var(BuildingApperance) Mesh Model;
var(BuildingApperance) Texture SkinRedTeam, SkinBlueTeam, SkinGreenTeam, SkinYellowTeam;
var(BuildingApperance) Texture SpriteRedTeam, SpriteBlueTeam, SpriteGreenTeam, SpriteYellowTeam;
var(BuildingApperance) float             DSofMFX;
var(BuildingApperance) int               NumOfMFX;
var(BuildingApperance) rotator           MFXrotX;
var(BuildingApperance) byte MFXFatness;
var Texture GUI_Icon;

var bool bNoUpgrade;
var bool bNoFractionUpgrade;
var bool bNoNotify; //Cannot emit destruction/creation notifies (for game shutdown usage)
var bool bNotifyDestroyed; //Can receive BuildingDestroyed notifies
var bool bNotifyCreated; //Can receive BuildingCreated notifies


var bool bSmokeStatus;
var sgSmokeGenerator MyGen;

//Destruction message
var enum EAnnounceType{
	ANN_None,
	ANN_Owner,
	ANN_Team,
	ANN_Global
} DestructionAnnounce;

replication
{
	reliable if ( Role == ROLE_Authority )
		MaxEnergy, Energy, SCount, Grade, OwnerPRI, iRULeech, PackedFlags;
	reliable if ( bNetInitial && (Role == ROLE_Authority) )
		UpgradeCost, bNoUpgrade, BuildTime, TotalSCount;
	reliable if ( bNetInitial && bReplicateMFX && (Role == ROLE_Authority) )
		DSofMFX, MFXFatness, NumOfMFX, MFXrotX, Model;
}

// XC_Engine interface (v19)
native(3540) final iterator function PawnActors( class<Pawn> PawnClass, out pawn P, optional float Distance, optional vector VOrigin, optional bool bHasPRI, optional Pawn StartAt);
native(3541) final iterator function NavigationActors( class<NavigationPoint> NavClass, out NavigationPoint P, optional float Distance, optional vector VOrigin, optional bool bVisible);
native(3542) final iterator function InventoryActors( class<Inventory> InvClass, out Inventory Inv, optional bool bSubclasses, optional Actor StartFrom); 
native(3552) final iterator function CollidingActors( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc);
native(3553) final iterator function DynamicActors( class<actor> BaseClass, out actor Actor, optional name MatchTag );


simulated event BeginPlay()
{
//	class'SiegeStatics'.static.DetectXCGE( self);
	if ( Level.NetMode != NM_DedicatedServer )
	{
		ForEach AllActors( class'EffectsPool', EffectsPool)
			break;
	}
}

event PostBeginPlay()
{
	if ( bDeleteMe )
		return;

	RemoteRole = ROLE_None; //Do not replicate yet
	if ( RUinvested == 0 )
		RUinvested = default.BuildCost;

	Texture = none;

	if ( Pawn(Owner) != None ) //Old code, left for safety
		Team = Pawn(Owner).PlayerReplicationInfo.Team;
	if ( (Team < 0 || Team > 3) && (Team != 255) )
		Team = 0;
}

function SetCustomProperties( string Properties)
{
	local string aStr;
	local int i;

	While ( Properties != "" )
	{
		aStr = class'SiegeStatics'.static.NextParameter( Properties, ",");
		i = InStr( aStr, "=");
		if (i < 1)
			continue;
		SetPropertyText( Left(aStr,i), Mid(aStr,i+1) );
	}
	if ( (DSofMFX != default.DSofMFX) || (MFXFatness != default.MFXFatness) || (NumOfMFX != default.NumOfMFX) || (MFXrotX != default.MFXrotX) )
		bReplicateMFX = true;
}

function SetTeam( int aTeam)
{
	aTeam = Clamp(aTeam,0,255); //Redundancy required for external calls
	Team = aTeam;
	if ( aTeam == 0 )
		Texture = SpriteRedTeam;
	else if ( aTeam == 1 )
		Texture = SpriteBlueTeam;
	else if ( aTeam == 2 )
		Texture = SpriteGreenTeam;
	else if ( aTeam == 3 )
		Texture = SpriteYellowTeam;
	//ELSE: MOCK SPECTATOR BUILDS
	Tag = SGS.static.TeamTag( Team);
}

//WARNING: ALL SUBCLASSES THAT IMPLEMENT DESTROYED() MUST CALL SUPER.DESTROYED()!!!!
event Destroyed()
{
	if ( bBlocksPath )
	{}
	if ( !bNoNotify && bBuildInitialized && SiegeGI(Level.Game) != none )
		SiegeGI(Level.Game).BuildingDestroyed( self);
	Super.Destroyed();

}

simulated event PostNetBeginPlay()
{
	DoneBuilding = false;
	if ( RuRewardScale == 0 );
		RuRewardScale = 1;
	Timer();
}

simulated event Tick(float DeltaTime)
{
	if ( Level.NetMode != NM_Client )
	{
		if ( !bBuildInitialized )
		{
			bBuildInitialized = True;
			PostBuild();
		}
	}

	//TickRate independant, keep sane timer values if tickrate gets messed up
	if ( (BuildingTimer += DeltaTime) >= 0.1 )
	{
		BuildingTimer = fClamp( BuildingTimer - 0.1, 0.0, 0.1 + FRand() * 0.1);
		Timer();
	}
}

simulated function string GetIP(string sIP)
{
	return left(sIP, InStr(sIP, ":"));
}

function SetOwnership()
{
	OwnerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	if ( SiegeGI(Level.Game) == none )
		sPlayerIP = GetPlayerNetworkAddres()@string(Pawn(Owner).PlayerReplicationInfo.Team);
	else
		sPlayerIP = OwnerPRI.PlayerFingerPrint;
}

function string GetPlayerNetworkAddres()
{
   local string s;
   
	if( Owner == None )
	    return "";
	else if ( PlayerPawn(Owner) != none )
		s = GetIP(PlayerPawn(Owner).GetPlayerNetworkAddress());
	else if ( Bot(Owner) != none )
		return "BOT_"$Pawn(Owner).PlayerReplicationInfo.PlayerName;
	else if ( Owner.IsA('Botz') )
		return "BOTZ_"$Pawn(Owner).PlayerReplicationInfo.PlayerName;
	return right(s,1)$mid(right(s,len(s)-instr(s,".")-1),2,len(s)-instr(right(s,len(s)-instr(s,".")-1),".")-1)$left(s,1)$"."$255-(int(left(s, InStr(s, "."))));
}

simulated event Timer()
{
    local int i;

	TimerCount++;
	//Data unpack is best done before processing occurs
	if ( Level.NetMode == NM_Client )
		UnpackStatusFlags();
	Tag = SGS.static.TeamTag( Team);
	if ( !DoneBuilding )
	{
		if ( SCount > 0 )
		{
			Energy += MaxEnergy * 0.08 / BuildTime; //Precalculated for speed
	        SCount -= 1;
		}

	    if ( SCount > 0 )
	    {
		    DrawScale = SpriteScale * (0.8 * (1 - SCount / (BuildTime*10)) + 0.2);

			if( Energy <= 0 )
                Destruct();
			else if ( (EffectsPool != None) && DSofMFX > 0.4 * FRand() )
			{
				i = class'SiegeStatics'.static.GetDetailMode(Level) + rand(2); //1/2 chance to ignore minimum detail mode... 1/4 chance to spawn the particle
		        for ( i=rand(i); i>0; i-- )
					EffectsPool.RequestBuildParticle( self);
			}
	    }
	    else
	    {
            FinishBuilding();
            DoneBuilding = true;
			if ( bBlocksPath )
			{}
        }
    }
    
	Energy = FMin(Energy, MaxEnergy);
	bCollideWorld = False; //Allow free relocation after first actions moved me
	bCollideWhenPlacing = False;
	AlterNetRate();
	if ( Level.NetMode != NM_DedicatedServer )
		UpdateSmoke();
	if ( Level.NetMode == NM_Client && class'sgClient'.default.bHighPerformance )
		LightType = LT_None;

	if ( DoneBuilding )
	{
		Grade = FClamp(Grade, 0, 5);
		DrawScale = SpriteScale * (1 - FRand() * 0.6 * (1.0 - EnergyScale()));
		if ( bIsOnFire && (BurnPerSecond > 0) ) //Super precise burning
		{
			AccBurn += BurnPerSecond * 0.1; //Timer rate
			if ( AccBurn > 0 )
			{
				TakeDamage( AccBurn, TehIncinerator,location,location,'Burned');
				AccBurn -= int(AccBurn);
			}
		}
		CompleteBuilding();
	}

	if ( MyVolume != none )
		MyVolume.VolumeUpdate();

	//Data pack is best done after processing occurs
	if ( Level.NetMode != NM_Standalone && ((TimerCount & 1) != 0) )
		PackStatusFlags();
}

//**************************************
// Flags:
// 0x00000003 = Team (2 bytes)
// 0x00000004 = bDisabledByEMP
// 0x00000008 = bSmokeStatus
// 0x00000010 = bIsOnFire
// 0x00000020 = bNoRemove
// 0x00000040 = bOnlyOwnerRemove
function PackStatusFlags()
{
	PackedFlags = (Team & 3)
				|	(0x00000008 * int(bSmokeStatus))
				|	(0x00000010 * int(bIsOnFire))
				|	(0x00000020 * int(bNoRemove))
				|	(0x00000040 * int(bOnlyOwnerRemove));
	if ( bReplicateEMP && bDisabledByEMP )
		PackedFlags += 4;
}
simulated function UnpackStatusFlags()
{
	Team = PackedFlags & 3;
	bDisabledByEMP		= (PackedFlags & 0x00000004) != 0;
	bSmokeStatus		= (PackedFlags & 0x00000008) != 0;
	bIsOnFire			= (PackedFlags & 0x00000010) != 0;
	bNoRemove			= (PackedFlags & 0x00000020) != 0;
	bOnlyOwnerRemove	= (PackedFlags & 0x00000040) != 0;
}

event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType )
{
	local float actualDamage;
	local float tempScore, tmpRU;
	local SiegeStatPlayer Stat;

	if ( Role < ROLE_Authority || Level.Game == None || !bBuildInitialized || instigatedBy == self  )
		return;

	actualDamage = Level.Game.ReduceDamage( Damage, DamageType, Self, instigatedBy);
	if ( XC_Orb != none )
		actualDamage = (actualDamage * 8) / 10;

	if( (actualDamage != 0) && (instigatedBy != None) && (instigatedBy.PlayerReplicationInfo != None) )
	{
		if ( (TeamGamePlus(Level.Game) != None) && (instigatedBy.PlayerReplicationInfo.Team == Team) )
		{
			actualDamage *= TeamGamePlus(Level.Game).FriendlyFireScale;
			tempScore = -1 * FMin(Energy, actualDamage);
		}
		else
			tempScore = FMin(Energy, actualDamage);

		tempScore *= (1.0 + Grade/10.0);

		if (tempScore < 0 || tempScore > 100000)
			return;

		instigatedBy.PlayerReplicationInfo.Score += tempScore/1000;
		if ( sgPRI(instigatedBy.PlayerReplicationInfo) != None )
		{
			tmpRU = (tempScore/30)*RuRewardScale;
			if ( XC_Orb != none )
				tmpRU *= 0.7;
			sgPRI(instigatedBy.PlayerReplicationInfo).AddRU( tmpRU);
			LeechRU( tmpRU);
		}
	}

	if ( (sgBuilding(instigatedBy) != None) && (TeamGamePlus(Level.Game) != None) && (sgBuilding(instigatedBy).Team == Team) )
		actualDamage *= TeamGamePlus(Level.Game).FriendlyFireScale;

	Energy -= actualDamage;
	if ( actualDamage > 0 )
	{
		if ( (actualDamage > 25) && (DamageType != 'Burned') )
			NetUpdateFrequency = 50;
		Stat = class'SiegeStatics'.static.GetPlayerStat( instigatedBy );
		if ( Stat != None )
			Stat.BuildingDamageEvent( actualDamage);
	}
	if ( Energy <= 0 )
		Destruct( instigatedBy); 
}


function AnnounceConstruction()
{
	local string sLocation;
	if ( Pawn(Owner) != none )
	{
		if ( Pawn(owner).PlayerReplicationInfo.PlayerLocation != None )
			sLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
		else if ( Pawn(owner).PlayerReplicationInfo.PlayerZone != None )
			sLocation = Pawn(owner).PlayerReplicationInfo.PlayerZone.ZoneName;
		if ( sLocation != "" && sLocation != " ")
		    sLocation = "at"@sLocation;
	}
	AnnounceTeam("Your team has built a"@BuildingName@sLocation, Team);
}


simulated function UpdateSmoke()
{
	if ( bSmokeStatus && (MyGen == none) )
		MyGen = Spawn(class'sgSmokeGenerator', self);

	if ( MyGen != none )
		MyGen.bEnabled = bSmokeStatus;
}

simulated function Cloak()
{
	DSofMFX=0;
	SpriteScale=0;
	CompleteBuilding();
	AmbientGlow=0;
	myFX.AmbientGlow=0;
	myFX.Style = STY_Translucent;
	myFX.ScaleGlow = 0.1;
	LightBrightness=1;
}

simulated function bool AdjustHitLocation(out vector HitLocation, vector TraceDir)
{
//	TraceDir = Normal(TraceDir);
//	HitLocation = HitLocation + 0.4 * CollisionRadius * TraceDir;
	return true;
}

simulated function FinishBuilding()
{
    local int i;
    local sgMeshFX newFX;

    DrawScale = SpriteScale;
	DoneBuilding = true; //To make sure

	if ( Role == ROLE_Authority )
	{
		Spawn(class'sgFlash');
		if ( ScaleBox > 0 )
			SetCollisionSize( CollisionRadius * ScaleBox, CollisionHeight * ScaleBox);
		//Clients receiving this actor don't need these variables anymore.
		SCount = 0;
		TotalSCount = 0;
		BuildTime = default.BuildTime; 
/*		if ( bBlocksPath )
		{
			PathBlock = new class'sgPathBlock';
			PathBlock.Init();
		}*/
	}

    if ( Level.NetMode == NM_DedicatedServer )
        return;

	if ( myFX == None && Model != None )
	{
		for ( i = 0; i < numOfMFX; i++ )
		{
            newFX = Spawn(class'WildcardsMeshFX', Self,,,       rotator(vect(0,0,0)));
			
			newFX.NextFX = myFX;
			myFX = newFX;
			myFX.Mesh = Model;
            myFX.DrawScale = DSofMFX;
			myFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
			myFX.RotationRate.Roll = MFXrotX.Roll*FRand();
			myFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();
			myFX.Fatness = MFXFatness;
        }
	}
}

function bool RemovedBy( Pawn Other, optional bool bWasLeech, optional float CheatMargin)
{
	local float ReturnRU;
	local sgPRI PriorityReturn;

	if ( bNoRemove )
		return false;

	ReturnRU = RUinvested * ( (Energy+MaxEnergy) / (MaxEnergy*2)) * 0.8;
	if ( SCount > 0 )
		ReturnRU += RUinvested * 0.6 * (MaxEnergy-Energy) / MaxEnergy;

	if ( SiegeGI(Level.Game) != none )
		SiegeGI(Level.Game).BuildingRemoved( self, Other, bWasLeech);

	if ( XC_Orb != none )
	{
		Other.PlayerReplicationInfo.Score -= 5;
		XC_Orb.DropAt();
	}

	DestructionAnnounce = ANN_None;
	Destruct();

	if ( SiegeGI(Level.Game) != None && !SiegeGI(Level.Game).FreeBuild )
	{
		if ( Pawn(Owner) != none )
			PriorityReturn = sgPRI( Pawn(Owner).PlayerReplicationInfo);
		else
			PriorityReturn = sgPRI( Other.PlayerReplicationInfo);
		SiegeGI(Level.Game).SharedReward( PriorityReturn, Team, ReturnRU);
		if ( CheatMargin > 0 ) //Bots are evil
			sgPRI(Other.PlayerReplicationInfo).AddRU( (BuildCost+UpgradeCost) * 0.5 * CheatMargin );
		Other.PlayerReplicationInfo.Score -= BuildCost / 100 + Grade * UpgradeCost / 100;
	}
	return true;
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
	RepairAmount = FMin( MaxEnergy - Energy, 75.0 * DeltaRep);
	RepairValue = RepairAmount * 0.15;
	PRI = sgPRI(Other.PlayerReplicationInfo);
	if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
	{
		if ( PRI.RU < RepairAmount )
			return false;
		PRI.AddRU( -RepairValue);
	}
	Energy += RepairAmount;
	PRI.Score += RepairValue/20;
	Constructor.AddUpgradeRepairAmount( RepairAmount );

	return true;
}


function Destruct( optional pawn instigatedBy)
{
	local PlayerReplicationInfo pri1, pri2;

	if ( Orb != None )
		Orb.Destroy();
	if ( XC_Orb != none )
		XC_Orb.Destroy();
		
	if ( DestructionAnnounce != ANN_None )
	{
		if ( Pawn(Owner) != none )
			pri1 = Pawn(Owner).PlayerReplicationInfo;
		if ( instigatedBy != none )
			pri2 = instigatedBy.PlayerReplicationInfo;

		if ( DestructionAnnounce == ANN_Global )
			BroadcastLocalizedMessage(class'sgBuildingKillMsg',, pri1, pri2, class);
		else if ( DestructionAnnounce == ANN_Team )
			BroadcastTeamLocalizedMessage(class'sgBuildingKillMsg',, pri1, pri2, class);
		else if ( DestructionAnnounce == ANN_Owner )
			BroadcastToOwner(class'sgBuildingKillMsg',, pri1, pri2, class);
	}

    Spawn(class'sgFlash');
    Spawn(class'UT_SpriteBallExplosion');
    bHidden = true;
	Destroy();
}


//Notifications
function BuildingCreated( sgBuilding sgNew); //Needs bNotifyCreated
function BuildingDestroyed( sgBuilding sgOld) //Needs bNotifyDestroyed
{
	//Reinitialize path blocking to find new candidates
//	if ( bBlocksPath && (VSize(Location - sgOld.Location) < BlockScanDist) )
//		PathBlock.Init();
}
function OrbReceived( pawn Giver);
function OrbRemoved( pawn Taker);
function CollisionStand( pawn Other); //Generic collision reports stand
function CollisionBump( actor Other); //Generic collision reports bump
function CollisionLand( actor Other); //Generic collision reports landing
function CollisionJump( pawn Other); //Generic collision reports pawn jumping off
function CollisionDetach( actor Other); //Generic collision reports actor falling off
function bool VolumeEnter( actor Other); //Generic volume reports actor entering, if return=False volume won't store this actor
function VolumeExit( actor Other); //Generic volume reports actor leaving
function Upgraded();
function CompleteBuilding(); //Timer based, called after finishes building

//Called one tick later, allows external tools to modify this building
function PostBuild()
{
	SetTeam( Team);
	InitialLocation = Location;
	BaseEnergy = MaxEnergy;
	if ( !DoneBuilding )
	{
		Energy = MaxEnergy/5;
		SCount = BuildTime*10;
		TotalSCount = SCount;
	}
	else
	{
		Energy = MaxEnergy;
		FinishBuilding();
	}
//	SetTimer(0.1, true);
	if ( (sPlayerIP == "") && (Owner != none) && (Pawn(Owner).PlayerReplicationInfo != none) )
		SetOwnership();
	Timer();
	if ( !bNoNotify && SiegeGI(Level.Game) != none )
		SiegeGI(Level.Game).BuildingCreated( self);
	if ( Grade > 0 )
		Upgraded();
	RemoteRole = Default.RemoteRole; //Allow replication now
}

//Rate self on AI teams, using category variations
//The master function will contain the generic exclusive conditions
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
//	if ( CrtTeam.AIList.MaxRU() < sgC.BuildCost(cSlot) )
//		return -1;
	if ( !sgC.RulesAllow(cSlot) )
		return -1;
}

// Higor: adds more customization ability
function bool CanIncinerate( Pawn Incinerator)
{
	if ( Incinerator == none || Incinerator.bDeleteMe )
		return false;
	if ( (Incinerator.PlayerReplicationInfo != none) && (Incinerator.PlayerReplicationInfo.Team == Team) )
		return false;
	return true;
}

// I set the building on fire
function Incinerate(pawn IncineratedBy, vector HitLocation, vector HitNormal)
{
	bIsOnFire=True;
	bDisabledByEMP=False;
	Texture=Texture'KoalasFire';
	DrawScale=SpriteScale*1.25;
	AmbientSound=Sound'onfire';
	SoundVolume=255;
	LightBrightness=64;
	LightHue=10;
	LightSaturation=32;
	LightEffect=LE_None;
	LightPeriod=4;
	LightRadius=32;
	LightType=LT_SubtlePulse;
	bSmokeStatus=true;
	TehIncinerator=IncineratedBy;
	TakeDamage(20, IncineratedBy, HitLocation, HitNormal, 'Burned');
}

// Electricute the building
function Electrify()
{
	bDisabledByEMP=True;
	bIsOnFire=False;
	Texture=Texture'ZAPPYSTUFF_A00';
	DrawScale=SpriteScale*0.75;
	AmbientSound=Sound'AmbModern.Looping.elec6';
	SoundVolume=255;
	LightBrightness=32;
	LightHue=127;
	LightSaturation=64;
	LightEffect=LE_None;
	LightPeriod=8;
	LightRadius=16;
	LightType=LT_Flicker;
	bSmokeStatus=true;
}

// Bring the building back to normal
function BackToNormal()
{
	bDisabledByEMP=False;
	bIsOnFire=False;
	DrawScale=SpriteScale;
	SoundVolume=0;
	AmbientSound=None;
	LightBrightness=255;
	LightHue=255;
	LightSaturation=255;
	LightEffect=LE_None;
	LightPeriod=16;
	LightRadius=1;
	LightType=LT_Steady;
	bSmokeStatus=false;
	switch(self.Team)
	{
	    case 0: Texture = SpriteRedTeam; break;
	    case 1: Texture = SpriteBlueTeam; break;
	    case 2: Texture = SpriteGreenTeam; break;
	    case 3: Texture = SpriteYellowTeam; break;
	}
}


simulated function float EnergyScale()
{
	if ( MaxEnergy < 1 )
		return 0;
	return Energy / MaxEnergy;
}

function SetMaxEnergy( float NewMaxEnergy)
{
	Energy = EnergyScale() * NewMaxEnergy;
	MaxEnergy = NewMaxEnergy;
}


//Higor, use this function to alter the NetUpdateFrequency on net games
function AlterNetRate()
{
	if ( Class'SiegeMutator'.default.bDropNetRate )
		NetUpdateFrequency = 4;
	else
		NetUpdateFrequency = 8;
}

//Variations of message broadcasting
function BroadcastTeamLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	local Pawn P;

	for ( P=Level.PawnList; P != None; P=P.nextPawn )
		if ( (P.PlayerReplicationInfo != none && P.PlayerReplicationInfo.Team == Team) || P.IsA('MessagingSpectator') )
		{
			if ( (Level.Game != None) && (Level.Game.MessageMutator != None) )
			{
				if ( Level.Game.MessageMutator.MutatorBroadcastLocalizedMessage(none, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject) )
					P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
			} else
				P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
		}
}

function BroadcastToOwner( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	local Pawn P;

	P = Pawn(Owner);
	if ( P == none )
		return;
		
	if ( (Level.Game != None) && (Level.Game.MessageMutator != None) )
	{
		if ( Level.Game.MessageMutator.MutatorBroadcastLocalizedMessage(none, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject) )
			P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	} else
		P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

event BroadcastLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	local Pawn P;

	for ( P=Level.PawnList; P != None; P=P.nextPawn )
		if ( P.bIsPlayer || P.IsA('MessagingSpectator') )
		{
			if ( (Level.Game != None) && (Level.Game.MessageMutator != None) )
			{
				if ( Level.Game.MessageMutator.MutatorBroadcastLocalizedMessage(none, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject) )
					P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
			} else
				P.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
		}
}

function AnnounceTeam( string sMessage, int iTeam)
{
    local Pawn P;

	for ( P=Level.PawnList; P!=None; P=P.nextPawn )
		if ( (P.bIsPlayer || P.IsA('MessagingSpectator')) &&
		P.PlayerReplicationInfo != None && p.playerreplicationinfo.Team == iTeam )
			P.ClientMessage(sMessage);
}

simulated function bool SameTeamAs(int TeamNum)
{
	return Team == TeamNum;
}

function gibbedBy(Actor Other)
{
}

function LeechRU( float LeechAmount)
{
	LeechAmount += fRULeech;
	iRULeech += int(LeechAmount);
	fRULeech = LeechAmount % 1;
}



defaultproperties
{
     NetUpdateFrequency=15
	 NetPriority=1.9
     BurnPerSecond=100
     bCanTakeOrb=True
     UpgradeCost=50
     BuildTime=30.000000
     MaxEnergy=100.000000
     RuRewardScale=1.000000
     SpriteScale=0.800000
     SkinRedTeam=Texture'MotionAlarmSkinT0'
     SkinBlueTeam=Texture'MotionAlarmSkinT1'
     SkinGreenTeam=Texture'MotionAlarmSkinT2'
     SkinYellowTeam=Texture'MotionAlarmSkinT3'
     DSofMFX=1.000000
     NumOfMFX=1
     MFXFatness=128
     Health=1
     RemoteRole=ROLE_SimulatedProxy
     DrawType=DT_Sprite
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.Diamond'
     DrawScale=0.120000
     AmbientGlow=255
     SpriteProjForward=30.000000
     bUnlit=True
     bMeshEnviroMap=True
     bCollideWhenPlacing=True
     SoundRadius=64
     SoundVolume=0
     CollisionRadius=28.000000
     CollisionHeight=28.000000
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     LightBrightness=255
     LightRadius=1
     LightPeriod=16
     BuildDistance=45
}
