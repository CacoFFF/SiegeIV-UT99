// Critical extended data for players
// To be used to fix mods and expand a player's replication properties
// BaseEyeHeight should fix ZeroPing and SiegeInstagibRifles

class sgPlayerData expands ReplicationInfo;

struct PreciseVector
{
	var() config float X;
	var() config float Y;
	var() config float Z;
};

var Pawn POwner;
var PlayerPawn PPOwner;
var float BaseEyeHeight;
var int OwnerID;
var sgPRI OwnerPRI;
var SiegeGI SiegeGame;
var XC_MovementAffector MA_List;
var int RealHealth;
var vector LastRepLoc;
var float LastRepLocTime;
var bool bReplicateLoc;
var bool bReplicateHealth;
var bool bHudEnforceHealth;
var bool bClientXCGEHash;
var bool bForceMovement;
var bool bSpawnProtected;

var SpawnProtEffect SPEffect;
var Engine ClientEngine;


replication
{
	unreliable if ( !bNetOwner && Role==ROLE_Authority )
		BaseEyeHeight;
	unreliable if ( !bNetOwner && bReplicateHealth && Role==ROLE_Authority )
		RealHealth;
	reliable if ( Role==ROLE_Authority )
		OwnerID, bSpawnProtected;

	unreliable if ( Role==ROLE_Authority )
		AdjustPlayerLocation;
	reliable if ( Role<ROLE_Authority ) //Client should report this
		FoundXCGEHash;
}

event PostBeginPlay()
{
	POwner = Pawn(Owner);
	PPOwner = PlayerPawn(Owner);
	if ( Owner.IsA('bbPlayer') )
		bReplicateHealth = true;
	OwnerPRI = sgPRI(POwner.PlayerReplicationInfo);
	bReplicateLoc = true;
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if ( Level.NetMode != NM_Client )
	{
		if ( OwnerPRI == None || Level.NetMode == NM_Standalone || SiegeGI(Level.Game) == none )
			GotoState('Standalone');
		else
			GotoState('Server');
	}
}

simulated event PostNetBeginPlay()
{
	GotoState('Client');
}


//========== Tick (authority) - begin ==========//
//
// Process tick on servers and standalone games
// This is called before state code execution
//
event Tick( float DeltaTime)
{
	if ( POwner == None || POwner.bDeleteMe )
	{
		Destroy(); //This disables state code execution
		return;
	}
	SpawnProtEffectStatus();
	AffectMovement( DeltaTime);
}
//========== Tick (authority) - end ==========//


// Run on Siege servers
state Server
{
Begin:
	Sleep(0.0);
	OwnerID = POwner.PlayerReplicationInfo.PlayerID;
	SetPropertyText("bRelevantIfOwnerIs","1"); //XC_Engine future feature
WaitForReady:
	Sleep(0.0);
	if ( PPOwner != none && (NetConnection(PPOwner.Player) != none) && (PPOwner.CurrentTimeStamp == 0) ) //Network player not ready
		Goto('WaitForReady');
	RemoteRole = ROLE_SimulatedProxy; //Init replication
CheckPlayer:
	BaseEyeHeight = POwner.BaseEyeHeight;
	if ( POwner.bHidden )	NetUpdateFrequency = 1.5;
	else					NetUpdateFrequency = POwner.NetUpdateFrequency * 0.5;
	if ( ShouldReplicateLoc() )
		ReplicateLoc();
	if ( bReplicateHealth )
		RealHealth = POwner.Health;
	Sleep(0.0);
	Goto('CheckPlayer');
}

//Run on non-Siege/local games
state Standalone
{
}

//Run on remote clients
simulated state Client
{
	simulated event Tick( float DeltaTime)
	{
		SpawnProtEffectStatus();
	}
Begin:
	//Find PRI
	if ( !FindPRI() )
	{
		Sleep(0.3 * Level.TimeDilation);
		Goto('Begin');
	}
FindPawn:
	POwner = Pawn(OwnerPRI.Owner);
	if ( POwner != none )
	{
		SetOwner( POwner);
		PPOwner = PlayerPawn(POwner);
		if ( (PPOwner != none) && ViewPort(PPOwner.Player) != none )
		{
			GotoState('OwnerClient');
			Stop;
		}
	}
SetProps:
	if ( POwner == none || POwner.bDeleteMe )
	{
		Sleep(0.0);
		Goto('FindPawn');
	}
	POwner.BaseEyeHeight = BaseEyeHeight;
	POwner.EyeHeight = BaseEyeHeight;
	Sleep(0.0);
	Goto('SetProps');
}

// Owner client pawn is never gone
state OwnerClient
{
	simulated event BeginState()
	{
		DetectXCGE_Octree();
	}
	simulated event Tick( float DeltaTime)
	{
		AffectMovement( DeltaTime);
	}
}

//This only happens once
simulated function DetectXCGE_Octree()
{
	Role = ROLE_AutonomousProxy;
	SetPropertyText( "ClientEngine", XLevel.GetPropertyText("Engine")); //XC_Engine will indeed print something here
	if ( ClientEngine != none )
		SetPropertyText( "bClientXCGEHash", ClientEngine.GetPropertyText("bCollisionHashHook") );
	if ( bClientXCGEHash )
	{
		Log( "Detected XC_Engine collision octree, enabling image drop fixer if possible", 'SiegeIV');
		FoundXCGEHash();
	}
}

function FoundXCGEHash()
{
	bClientXCGEHash = true;
}

simulated function SetHealth()
{
	if ( (POwner != none) && (RealHealth != -1337) )
		POwner.Health = RealHealth;
}

simulated function bool FindPRI()
{
	local sgPRI PRI;

	ForEach AllActors (class'sgPRI', PRI)
		if ( PRI.PlayerID == OwnerID )
		{
			if ( PRI.bAdmin && PRI.bIsSpectator ) //This is most likely a playerless bot
				continue;
			OwnerPRI = PRI;
			PRI.PlayerData = self;
			return true;
		}
	//No return equals False
}

function bool ShouldReplicateLoc()
{
	if ( bReplicateLoc && !SiegeGI(Level.Game).bDisableIDropFix && (POwner.Acceleration == vect(0,0,0)) && (POwner.Base != none) && (POwner.Velocity == vect(0,0,0)) && (POwner.Base.Velocity == vect(0,0,0)) )
	{
		if ( (LastRepLocTime < (Level.TimeSeconds - 1 * Level.TimeDilation)) || (POwner.Location != LastRepLoc) )
			return POwner.FastTrace( POwner.Location - vect(0,0,1.2) * POwner.CollisionHeight);
	}
}

function ReplicateLoc()
{
	local sgPlayerData sgP;
	LastRepLoc = POwner.Location;
	LastRepLocTime = Level.TimeSeconds;
	ForEach AllActors (class'sgPlayerData', sgP)
		if ( (sgP != self) && sgP.bClientXCGEHash )
			sgP.AdjustPlayerLocation( POwner, POwner.Location.X, POwner.Location.Y, POwner.Location.Z);
}

simulated function AdjustPlayerLocation( Pawn Other, float LX, float LY, float LZ)
{
	local vector aVec;
	local bool bOldCol;

	if ( Other == none || !bClientXCGEHash ) //Pawn not yet replicated? Also, no XCGE
		return;
	aVec.X = LX; aVec.Y = LY; aVec.Z = LZ;
	bOldCol = Other.bCollideWorld;
	Other.bCollideWorld = false;
	Other.bCollideWhenPlacing = false;
	Other.SetLocation( aVec);
	Other.bCollideWorld = bOldCol;
	Other.bCollideWhenPlacing = true;
}

simulated function AddMAffector( XC_MovementAffector Other)
{
	if ( MA_List == none )
		MA_List = Other;
	else
		MA_List = MA_List.InsertSorted( Other);
}

simulated function XC_MovementAffector FindMAffector( class<XC_MovementAffector> AffectorClass)
{
	local XC_MovementAffector Aff;
	For ( Aff=MA_List ; Aff!=None ; Aff=Aff.NextAffector )
		if ( Aff.Class == AffectorClass && !Aff.bDeleteMe )
			return Aff;
}

//========== AffectMovement - begin ==========//
//
// Alters a player's movement variables.
// This is done in a way that various movement buffs/debuffs
// can interact at the same time without breaking each other.
//
simulated function AffectMovement( float DeltaTime)
{
	local XC_MovementAffector M, N;
	
	if ( MA_List != None || bForceMovement )
	{
		bForceMovement = False;
		POwner.GroundSpeed = POwner.default.GroundSpeed;
		POwner.WaterSpeed = POwner.default.WaterSpeed;
		POwner.AirSpeed = POwner.default.AirSpeed;
		POwner.AccelRate = POwner.default.AccelRate;
		//Loop allows self-destruction
		For ( M=MA_List ; M!=None ; M=N )
		{
			N = M.NextAffector;
			if ( !M.bDeleteMe )
				M.AffectMovement( DeltaTime);
		}
	}
}
//========== AffectMovement - end ==========//


//========== SpawnProtEffectStatus - begin ==========//
//
// Controls the visibility of spawn protection
//
simulated function SpawnProtEffectStatus()
{
	if ( Level.NetMode == NM_DedicatedServer )
		return;
		
	if ( !bSpawnProtected || (POwner == None) || POwner.bDeleteMe || (POwner.Health <= 0) || POwner.bHidden )
	{
		if ( SPEffect != None )
		{
			SPEffect.GotoState('Expiring');
			SPEffect = None;
		}
	}
	else
	{
		if ( SPEffect == None ) //POwner guaranteed to exist
		{
			SPEffect = Spawn( class'SpawnProtEffect', POwner);
			SPEffect.PlayerData = self;
		}
	}
}
//========== SpawnProtEffectStatus - end ==========//




static final function vector ToVector( PreciseVector A)
{
	local vector V;
	V.X = A.X;
	V.Y = A.Y;
	V.Z = A.Z;
	return V;
}
static final function bool IsZero( PreciseVector A)
{
	return (A.X == 0) && (A.Y == 0) && (A.Z == 0);
}


defaultproperties
{
	RemoteRole=ROLE_None
	OwnerID=-1
	RealHealth=-1337
}