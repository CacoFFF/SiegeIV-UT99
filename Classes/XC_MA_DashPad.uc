// sgSpeed's speed affector
class XC_MA_DashPad expands XC_MovementAffector;

var DashPad DashPad;
var float HitTimestamp;

var float FullTimer;
var float PushTimer;
var float MaxFadeTimer;
var float AngleFalloff;
var float LastSpeedMult; //So it gets properly passed to the list

var vector PushDir; //Running in this direction will maximize push

var float ClientTimeout;
var bool bClientDisable; //I've been replaced!
var bool bSpawnedByClient;

struct BufferedMove
{
	var() float Timestamp;
	var() float SpeedFactor; //If negative then force speed
};
var BufferedMove PreviousMoves[64]; //512 bytes, roughly the size of class Actor
var int iPrev;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		DashPad, HitTimestamp; //Simulate FullTimer
}


simulated event PostNetBeginPlay()
{
	local float Latency;
	
	if ( DashPad == None || PlayerPawn(Owner) == None ) //Attempt to recover by scanning nearby dashpads
	{
		LifeSpan = 1;
		return;
	}
	Setup( DashPad);
	Latency = float(Pawn(Owner).PlayerReplicationInfo.Ping) * 0.001 * Level.TimeDilation;
	FullTimer -= Latency;
	PushTimer -= Latency;
	Super.PostNetBeginPlay(); //Registers as affector
}

simulated function Setup( DashPad Other, optional bool bClientSim)
{
	FullTimer = default.FullTimer * (1+Other.Grade/5); //1.2 to 2.4
	AngleFalloff = 1;
	if ( Other.PushDir == vect(0,0,0) )
		PushDir = vector(Other.DashRot);
	else
		PushDir = Normal(Other.PushDir);
	DashPad = Other;
	bSpawnedByClient = bClientSim;
	if ( bClientSim )
	{
		ClientTimeout = 1; //Refactor for ping
		bClientDisable = false;
	}
}

simulated function AffectMovement( float DeltaTime)
{
	local Pawn P;
	local float DotProduct;
	local float CurrentTimer;
	local float SpeedMult;

	local string S;
	
	P = Pawn(Owner);
	if ( P == none )
	{
		Destroy();
		return;
	}
	if ( P.Physics != PHYS_Walking )
		DeltaTime *= 2;
	
	//This is only supposed to alter speed for the next movement
	if ( Level.NetMode == NM_Client )
	{
		if ( bSpawnedByClient )
			bClientDisable = ((ClientTimeout -= DeltaTime) < 0 );
		if ( bClientDisable || (DashPad == None) )
			return;
		//Push list, buffer previous moves
		PushPrevs();
		//This actor changes player speed after player tick
		//So player speed change has an effect on next frame
		//This means that the current frame's player speed effect was last frame's value
		//So i should buffer last frame's value first, then alter for next frame
		PreviousMoves[0].Timestamp = Level.TimeSeconds;
		//We got a problem, the very first frame of the 'readjustment' will
		//have previous' frame speed value unless i directly tackle PlayerAdjustPosition
		PreviousMoves[0].SpeedFactor = LastSpeedMult;
		
		if ( class'SiegeStatics'.static.BadFloat(PlayerPawn(P).WalkBob.X) )
		{
			Log("BAD DASH! A["$int(P.Acceleration.X)$","$int(P.Acceleration.Y)$"] V["$int(P.Velocity.X)$","$int(P.Velocity.Y)$
					"] G["$P.GroundSpeed$"] W["$PlayerPawn(P).LandBob$"]");
			Log("VSIZE: WalkBob="$VSize(PlayerPawn(P).WalkBob)@"Location="$VSize(P.Location));
		}
	}

	//Substracting timer here allows me to return anywhere
	CurrentTimer = FullTimer;
	FullTimer -= DeltaTime;
	
	//Speed constant until timer reaches MaxFadeTimer
	SpeedMult = Lerp( fMin(CurrentTimer,MaxFadeTimer) / MaxFadeTimer, 0, 3);
	LastSpeedMult = SpeedMult;
	
	//Angle falloff cannot be undone if player steers away from dash optimal direction
	DotProduct = Normal(P.Acceleration) dot PushDir;
	AngleFalloff = fMin( AngleFalloff, Square( fMax(DotProduct,0)) ); 
	
	//FullTimer just expired
	if ( (CurrentTimer < 0) || (AngleFalloff <= 0) || (Square(SpeedMult) <= 0.001) ) 
	{
		if ( Role == ROLE_Authority )
			Destroy();
		else if ( (iPrev == 0) || (PreviousMoves[iPrev-1].SpeedFactor == 0) )
			Destroy(); //This was never fully implemented (use ImpactEvents to intercept ClientUpdatePosition ticks)

		return; //Stop processing physics
	}
	SpeedMult *= AngleFalloff;
	P.GroundSpeed += P.Default.GroundSpeed * SpeedMult;
	P.WaterSpeed += P.Default.WaterSpeed * SpeedMult;
	P.AirSpeed += P.Default.AirSpeed * SpeedMult;

	//Force velocity after touching the dashpad
	if ( (PushTimer > 0) && (default.PushTimer > 0) )
	{
		LastSpeedMult *= -1; //Never implemented

		DotProduct = P.Velocity dot PushDir;
		SpeedMult = PushTimer / default.PushTimer;
		P.Velocity += PushDir * ((P.GroundSpeed - DotProduct) * PushTimer / default.PushTimer);
		P.Acceleration = P.Acceleration * (1-SpeedMult) + PushDir * (P.AccelRate * SpeedMult);
	}
	PushTimer -= DeltaTime;
}

simulated function PushPrevs()
{
	local int i;
	iPrev = Min( iPrev, ArrayCount(PreviousMoves)-1);
	while ( i>0 )
		PreviousMoves[i] = PreviousMoves[--i];
	iPrev++;
}

simulated function XC_MovementAffector InsertSorted( XC_MovementAffector Other)
{
	// I'm being replaced, self destruct on next tick
	// Replacement usually occurs when the server confirms the client hit the dashpad
	if ( (Other.Class == Class) && (Other != self) )
	{
		//Copy other dashpad's angle fallof if both come from the same pad
		//Also copy buffered moves!!
//		DashPad = none; 
	}
	return Super.InsertSorted( Other);
}



defaultproperties
{
	 AffectorPriority=9
	 FullTimer=1.2
	 PushTimer=0.4
	 MaxFadeTimer=1.5
	 AngleFalloff=1
}
