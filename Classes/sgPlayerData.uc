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
var float BaseEyeHeight;
var float SoundDampening;
var float MaxStepHeight;
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

var Actor DebugAttachment[8];

replication
{
	unreliable if ( !bNetOwner && Role==ROLE_Authority )
		BaseEyeHeight;
	unreliable if ( !bNetOwner && bReplicateHealth && Role==ROLE_Authority )
		RealHealth;
	unreliable if ( bNetOwner && Role==ROLE_Authority )
		SoundDampening, MaxStepHeight;
	reliable if ( Role==ROLE_Authority )
		OwnerID, bSpawnProtected;

	unreliable if ( Role==ROLE_Authority )
		AdjustPlayerLocation;
	reliable if ( Role<ROLE_Authority ) //Client should report this
		FoundXCGEHash, DebugInfo;
}

event PostBeginPlay()
{
	POwner = Pawn(Owner);
	if ( Owner.IsA('bbPlayer') )
		bReplicateHealth = true;
	OwnerPRI = sgPRI(POwner.PlayerReplicationInfo);
	bReplicateLoc = true;
}

simulated event PostNetBeginPlay()
{
	FindPRI();
}

simulated event SetInitialState()
{
	bScriptInitialized = true;

	if ( Level.NetMode == NM_Client )
		GotoState('Client');
	else if ( OwnerPRI == None || Level.NetMode == NM_Standalone || SiegeGI(Level.Game) == none )
		GotoState('Standalone');
	else
		GotoState('Server');
}



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


// Run on Siege servers
state Server
{
	function bool IsPlayerReady()
	{
		local PlayerPawn P;
		
		if ( (POwner != None) && !POwner.bCollideActors && POwner.bHidden )
			return false;
			
		P = PlayerPawn(POwner);
		return (P == None) || (P.CurrentTimeStamp != 0) || (Viewport(P.Player) != None); //Bot or active player
	}
	
Begin:
	Sleep(0.0);
	OwnerID = POwner.PlayerReplicationInfo.PlayerID;
	SetPropertyText("bRelevantIfOwnerIs","1"); //XC_Engine future feature
WaitForReady:
	Sleep(0.0);
	if ( !IsPlayerReady() )
		Goto('WaitForReady');
	RemoteRole = ROLE_SimulatedProxy; //Init replication
CheckPlayer:
	BaseEyeHeight = POwner.BaseEyeHeight;
	SoundDampening = POwner.SoundDampening;
	MaxStepHeight = POwner.MaxStepHeight;
	if ( POwner.bHidden )
		NetUpdateFrequency = 1.5;
	else
		NetUpdateFrequency = POwner.NetUpdateFrequency * 0.5;
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
		if ( POwner.Role == ROLE_AutonomousProxy ) //DemoManager doesn't like this
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
	DebugScan( !POwner.bHidden );
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
		SpawnProtEffectStatus();
		AffectMovement( DeltaTime);
		if ( POwner != None )
		{
			POwner.SoundDampening = SoundDampening;
			POwner.MaxStepHeight = MaxStepHeight;
		}
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

function DebugInfo( string Data)
{
	Log( Data, 'DebugInfo');
}

simulated function DebugScan( bool DebugEnable)
{
	local bool bFound;
	local int i;
	local sgPlayerData PD;
	local Actor A;

	if ( (FRand() > 0.2) || (POwner == None) )
		return;
	
	if ( DebugEnable )
	{
		if ( PlayerPawn(POwner) != None && Viewport(PlayerPawn(POwner).Player) != None ) //Local player
		{
		}
		else //Other player
		{
			if ( POwner.Style == STY_Translucent )
			{
				ForEach POwner.RadiusActors( class'Actor', A, 10)
					if (	(A.Mesh == POwner.Mesh) && (Pawn(A) == None) && (Carcass(A) == None)
						&&	(A.Class.Outer.Name != Class.Outer.Name) )
					{
						bFound = false;
						for ( i=0 ; i<ArrayCount(DebugAttachment) && !bFound ; i++ )
							if ( DebugAttachment[i] == A )
								bFound = true;
						if ( !bFound )
						{
							for ( i=0 ; i<ArrayCount(DebugAttachment) ; i++ )
								if ( DebugAttachment[i] == None )
								{
									DebugAttachment[i] = A;
									ForEach AllActors( class'sgPlayerData', PD)
										if ( PD.IsInState('OwnerClient') )
										{
											PD.DebugInfo( PD.OwnerPRI.PlayerName$": [ATTACH] "$A.Name@"("$A.Class$")"@A.Tag@A.Owner);
											PD.DebugEntry();
										}
									
									break;
								}
						}
					}
			}
		}
	}
	else
	{
		For ( i=0 ; i<ArrayCount(DebugAttachment) ; i++ )
			DebugAttachment[i] = None;
	}
}

simulated function DebugEntry()
{
	local PlayerPawn P;
	local LevelInfo Entry;
	local Actor A;
	
	P = PlayerPawn(POwner);
	if ( P == None )
		P = class'SiegeStatics'.static.FindLocalPlayer(self);
	if ( P != None )
	{
		Entry = P.GetEntryLevel();
		ForEach Entry.AllActors( class'Actor', A)
			if	(	!A.bStatic
				&&	A.Class.Outer.Name != 'Engine'
				&&	A.Class.Outer.Name != 'Botpack'
				&&	A.Class.Outer.Name != 'UBrowser' )
				DebugInfo( P.PlayerReplicationInfo.PlayerName$": [ENTRY] "$A.Name@"("$A.Class$")"@A.Tag@A.Owner);
	}
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
	return false;
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
	SoundDampening=1
	MaxStepHeight=25
}