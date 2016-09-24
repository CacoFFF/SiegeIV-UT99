// sgSpeed's speed affector
class XC_MA_DashPad expands XC_MovementAffector;

var DashPad DashPad;
var float HitTimestamp;

var float FullTimer;
var float FadeTimer;
var float MaxFadeTimer;
var float AngleFalloff;
var float CurFactor; //So it gets properly passed to the list

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
	if ( DashPad == None || PlayerPawn(Owner) == None ) //Attempt to recover by scanning nearby dashpads
	{
		LifeSpan = 1;
		return;
	}
	FullTimer = default.FullTimer * (1+DashPad.Grade/5);
	FullTimer -= float(Pawn(Owner).PlayerReplicationInfo.Ping) * 0.001 * Level.TimeDilation;
	Super.PostNetBeginPlay(); //Registers as affector
}

simulated function Setup( DashPad Other, optional bool bClientSim)
{
	FullTimer = default.FullTimer * (1+Other.Grade/5); //1.2 to 2.4
	AngleFalloff = 1;
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
	local float TempFactor;
	
	
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
		if ( bClientDisable )
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
		PreviousMoves[0].SpeedFactor = CurFactor;
	}

//Important!!!
	if ( FullTimer > MaxFadeTimer )
		TempFactor = 3;
	else
		TempFactor = Lerp( FullTimer / MaxFadeTimer, 0, 3);
	AngleFalloff = fClamp( Square(Normal(P.Acceleration) dot PushDir), 0, AngleFalloff);
	TempFactor *= AngleFalloff;
	P.GroundSpeed += P.Default.GroundSpeed * TempFactor;
	P.WaterSpeed += P.Default.WaterSpeed * TempFactor;
	P.AirSpeed += P.Default.AirSpeed * TempFactor;
	P.AccelRate += P.Default.AccelRate * TempFactor;

	CurFactor = TempFactor;
	//Force velocity
	if ( FullTimer + 0.3 > (default.FullTimer)*2 )
	{
		TempFactor = P.Velocity dot PushDir;
		if ( TempFactor < P.GroundSpeed ) //Not fully boosted, boost!
			P.Velocity += Pushdir * (P.GroundSpeed-TempFactor);
		P.Acceleration = PushDir * P.GroundSpeed;
		CurFactor *= -1;
	}

	if ( ((FullTimer >= 0) && ((FullTimer -= DeltaTime) < 0)) || (Square(CurFactor) <= 0.001) ) //FullTimer just expired, excedent passed to FadeTimer
	{
		if ( Role == ROLE_Authority )
			Destroy();
		else if ( (iPrev == 0) || (PreviousMoves[iPrev-1].SpeedFactor == 0) )
			Destroy(); //Simulated plat no longer needed
	}
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
	 FadeTimer=1.5
	 MaxFadeTimer=1.5
	 AngleFalloff=1
}
