//=============================================================================
// Jetpack.
// Revised by AnthraX & Scarface (Shiva)
// HIGOR: Client states and clientside movement correction
// HIGOR: Compatible with Extended Client Move
//=============================================================================
class Jetpack extends sgSuit
    config;

#exec OBJ LOAD File=Extro.uax

/*--- Data. -----------------------------------------------------------------*/

var() float         MaxFuel,
                    RechargeRate,
                    Thrust,
                    MaxVel,
                    HorizThrust,
                    MaxHorizVel,
                    ThrustFrequency;
var float           Fuel;           // Fuel left, measured in seconds
var Effects         Trail;

var float aTimer;
var float deltaUpdate; //Fuel variation since last update
var float LastFuel; //Client last fuel
var vector PendingVel;

var JetPushPool PushPool;
var bool bDelayActivate;
var bool bOldFly;
var bool bOldFalling;
var bool bOldWalking;
var bool bLogNow;
var bool bFly;
var bool bInstructions;
var bool bClientForceWalk;

var float LastToggleStamp; //For correction in cases of packet loss
var int LastStatusStamp; //Last registered stamp from server
//Pair stamp means no-fly, impair means fly.

replication
{
    unreliable if ( Role == ROLE_Authority )
        Trail, Fuel, MaxFuel, RechargeRate, Thrust, MaxVel,
        HorizThrust, MaxHorizVel, ThrustFrequency;
}



function PostBeginPlay()
{
    Super.PostBeginPlay();
    bAutoActivate = false;
    Fuel = MaxFuel;
}

simulated event Destroyed()
{
	Super.Destroyed();
	if ( Trail != none )
	{
		Trail.Destroy();
		Trail = none;
	}
	if ( Pawn(Owner) != none )
	{
		Pawn(Owner).bRun = 0; //Bugfix
		bClientForceWalk = false;
		JetEnd();
	}
	if ( (PushPool != none) && (PushPool.CurJet == self) ) //Unregister
		PushPool.CurJet = none;
	PushPool = none;
}


/*--- Client Functions. -----------------------------------------------------*/
simulated exec function SetJetpack( bool bEnable)
{
	if ( Pawn(Owner) == none )
		return;
	if ( bEnable && (!bDelayActivate && (Pawn(Owner).bRun > 0)) ) //Pawn already hitting walk
		return;
	if ( !bEnable && !bClientForceWalk ) //Pawn flying in walk mode
		return;
	if ( !bEnable || !bOldFalling || Owner.Physics != PHYS_Falling )
	{
		bClientForceWalk = false;
		Pawn(Owner).bRun = 0;
		return;
	}
	bClientForceWalk = true;
}

simulated event Tick( float DeltaTime)
{
	local bool bTryFly;
	local Pawn P;

	P = Pawn(Owner);
	if ( P == none )
		return;

	if ( bClientForceWalk )
	{
		if ( P.Physics != PHYS_Falling )
		{
			bClientForceWalk = false;
			P.bRun = 0;
		}
		else
			P.bRun = 1;
	}

	if ( !bInstructions && Owner.Physics == PHYS_Falling )
	{
		bInstructions = true;
		if ( PlayerPawn(P) != none && ViewPort(PlayerPawn(P).Player) != none )
		{	P.ReceiveLocalizedMessage( class'JetPackMessagePlus', 1);
			P.ReceiveLocalizedMessage( class'JetPackMessagePlus', 0);
		}
	}
	
	//Just left ground
	if ( bOldWalking && (P.Physics == PHYS_Falling) )
	{
		if ( (P.bRun > 0) && (P.JumpZ > P.default.JumpZ * Level.Game.PlayerJumpZScaling()) && (P.Velocity.Z <= P.default.JumpZ) )
			bDelayActivate = true; //Do not fly if player has boots
		else if ( (P.bDuck > 0) && (P.Velocity.Z > 0) )
			bDelayActivate = true; //Got hit while ducking
	}

	bTryFly = ((P.bDuck + P.bRun) > 0) && (P.Physics == PHYS_Falling);
	if ( !bTryFly )
		bDelayActivate = false;
	if ( !bFly && !bOldFly && bTryFly && !bDelayActivate )
	{
		bFly = true;
		JetStart();
	}
	else if ( bFly && (!bTryFly || Fuel <= 0) )
	{
		if ( Fuel <= 0 )
			bDelayActivate = true;
		bFly = false;
		JetEnd();
	}
	if ( bFly )
		JetPush( DeltaTime);
	else
		Fuel = FMin(Fuel + RechargeRate * deltaTime, MaxFuel);

	bOldFly = bFly;
	bOldFalling = (P.Physics == PHYS_Falling);
	bOldWalking = (P.Physics == PHYS_Walking);
}

simulated function JetPush( float DeltaTime)
{
	if ( aTimer <= 0 )
	{
		aTimer += 1 / ThrustFrequency;
		UserTimer();
	}

	aTimer -= DeltaTime;
	if ( Role == ROLE_Authority )
		Fuel = FMax(Fuel - DeltaTime, 0);
	else
	{
		if ( LastFuel != Fuel ) //Server update fuel!
		{
			Fuel += deltaUpdate;
			deltaUpdate = 0;
		}
		deltaUpdate -= DeltaTime;
		Fuel = FMax(Fuel - DeltaTime, 0);
		LastFuel = Fuel;
	}
}

simulated function JetStart()
{
	local UT_Invisibility inv;
	if ( Role == ROLE_Authority )
	{
		bActive = true;
		// Effects
		if ( Trail == None )
		{
			inv = UT_Invisibility(Pawn(Owner).FindInventoryType(class'UT_Invisibility'));
			if ( inv == None || inv.charge < 160)
				Trail = Spawn(class'JetTrail', Owner);
		}
	}
	if ( Level.NetMode == NM_Client )
	{
		DeltaUpdate = 0;
		CheckPool();
	}
	aTimer = 0;
}

simulated function JetEnd()
{
	local sgSpeed sp;
	if ( Role == ROLE_Authority )
	{
		bActive = false;
		// Effects
		if ( Trail != None )
		{
			Trail.Destroy();
			Trail = None;
		}

		sp = sgSpeed(Pawn(Owner).FindInventoryType(class'sgSpeed'));
		if (sp != None)
			sp.GotoState('Activated');
	}
}

//bClientAdjust is set when player is readjusting position after server correction
simulated function UserTimer()
{
	local sgSpeed sp;
	local vector VelAdd;

	//Tick should handle this
	if ( Fuel <=  0 )
		return;
	
	sp = sgSpeed(Pawn(Owner).FindInventoryType(class'sgSpeed'));
	if (sp != None && sp.bActive )
		sp.GotoState('');
	VelAdd = PushVel( Pawn(Owner).bRun == 0 );
//	Log("Real velocity is: "$VelAdd@"from"@Owner.Velocity);
	if ( PushPool != none )
		PushPool.AddNewPush( VelAdd - Owner.Velocity, Pawn(Owner).bRun == 0);
	if ( Level.NetMode == NM_Client )
	{
		Owner.PendingTouch = self;
		PendingVel = VelAdd;
	}
	Owner.Velocity = VelAdd;
}

simulated function vector PushVel( bool bHover)
{
	local vector horizVel, VelAdd;
	local rotator rot;
	local float fThrust;

	horizVel = Owner.Velocity * vect(1,1,0);
	rot.Yaw = Owner.Rotation.Yaw;
	VelAdd = Owner.Velocity;
	if ( cos((rotator(horizVel).Yaw - rot.Yaw)/32768*pi) * VSize(horizVel) < MaxHorizVel )
		VelAdd += vector(rot) * HorizThrust * 1 / ThrustFrequency;
	fThrust = Thrust / ThrustFrequency;
	if ( VelAdd.Z < MaxVel )
		VelAdd.Z = FMin(VelAdd.Z + fThrust, MaxVel);
	//Hovering
	if ( bHover && Owner.Velocity.Z > (-fThrust * 0.33) )
	{
		VelAdd.Z -= fThrust * 0.5;
		Fuel += (0.5f / ThrustFrequency);
	}
	return VelAdd;
}

//Clientside corrections
simulated function CheckPool()
{
	if ( PlayerPawn(Owner) == none || ViewPort(PlayerPawn(Owner).Player) == none )
		return;

	if ( PushPool == none )
	{
		ForEach AllActors (class'JetPushPool', PushPool)
			break;
		if ( PushPool == none )
		{
			PushPool = Spawn(class'JetPushPool', Owner);
			PushPool.Player = ViewPort(PlayerPawn(Owner).Player);
		}
	}
	PushPool.CurJet = self;
}


defaultproperties
{
    MaxFuel=3.00
    RechargeRate=0.80
    Thrust=1500.00
    MaxVel=350.00
    HorizThrust=250.00
    MaxHorizVel=400.00
    ThrustFrequency=20.00
    bActivatable=True
    bDisplayableInv=True
    PickupMessage="You got the Jetpack."
    ItemName="Jetpack"
    RespawnTime=60.00
    PickupViewMesh=LodMesh'UnrealI.AsbSuit'
    ProtectionType1=ProtectNone
    ProtectionType2=ProtectNone
    Charge=150
    MaxDesireability=3.00
    PickupSound=Sound'UnrealI.Pickups.FieldSnd'
    Icon=Texture'UnrealShare.Icons.I_ShieldBelt'
    bOwnerNoSee=True
    bTrailerSameRotation=True
    Mesh=LodMesh'Botpack.ShieldBeltMeshM'
    bGameRelevant=True
    CollisionRadius=25.00
    CollisionHeight=10.00
}
