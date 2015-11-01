//=============================================================================
// DashPlayer.
//=============================================================================
class DashPlayer expands WildcardsPlayerAffecters;

var() float Slowness;
var() float RecoverRate;
var int choice;
var AnimatedSprite FX;
var Pawn DashPawn;
var bool Chargeing;
var float Charge;
var float ClientLifeSpan;

// Information from the DashPad
var float MaxCharge;
var float DashFactor;
var float DashChargeRate;

var sxDashPad PadHistory[16];
var int PadIndex;

// Previous stats from the player
var float BaseGroundSpeed;
var float BaseAirSpeed;
var float BaseWaterSpeed;
var vector BaseAcceleration;

replication
{
	reliable if ( Role==ROLE_Authority )
		DashPawn, MaxCharge, ClientLifeSpan, PadHistory, Chargeing;
	reliable if ( Role<=ROLE_Authority )
		ForceDestrution;	
}

function Begin()
{
	BaseGroundSpeed		= DashPawn.GroundSpeed;
	BaseAirSpeed		= DashPawn.AirSpeed;
	BaseWaterSpeed		= DashPawn.WaterSpeed;
	BaseAcceleration	= DashPawn.Acceleration;
}

simulated function bool UsedPad( sxDashPad DP )
{
	local int i;
	local int PadsVisited;
	local int MultiDashLimit;
	
	PadsVisited = 0;
	
	for ( i = 0; i < 16; i++ ) 
		{

			if ( PadHistory[i] != None )
				{
					MultiDashLimit = PadHistory[i].DashMultiDashLimit;
					PadsVisited++;
				}
				
					
			if ( PadsVisited > MultiDashLimit )
				return true;		

			if ( DP == PadHistory[i] )
				return true;
		}

	return false;
}

function DoubleDash( sxDashPad DP )
{
	local float CurrentSpeed;
	local float MaxSpeed;
	local float PercentSpeed;
	
	CurrentSpeed = Sqrt( DashPawn.Velocity.X * DashPawn.Velocity.X + DashPawn.Velocity.Y * DashPawn.Velocity.Y);
	MaxSpeed = DashPawn.default.GroundSpeed + DashPawn.default.GroundSpeed*(MaxCharge*DashFactor);
	PercentSpeed = CurrentSpeed / MaxSpeed;

	DashChargeRate = DP.DashChargeRate;
	Charge = LifeSpan+((DP.DashTime*PercentSpeed)*2);
	DashFactor *= (DP.DoubleDashFactor)*PercentSpeed;
	PadHistory[PadIndex] = DP;
	PadIndex++;
}

simulated function Tick( float DeltaTime )
{
	local float Speed2D;
	local DashTrail DT;
	local Actor a;

    if ( DashPawn != None && ROLE != ROLE_Authority )
		{
			// Turn On HUD
			
			foreach AllActors( class'Actor',a)
				{
					if ( sgHUD(a) != None )
						{
							if ( sgHUD(a).Owner == DashPawn )
								sgHUD(a).DashPlayerInstance = self;
						}
				}

			// sgHUD(PlayerPawn(DashPawn).MyHUD).DashPlayerInstance = self;
			
			if ( Chargeing == true || DashPawn.Velocity == vect(0, 0, 0) )
				{
					DT = DashPawn.Spawn(class'DashTrail', DashPawn, , DashPawn.Location, DashPawn.Rotation);
					DT.Velocity = ( (30+(40*FRand())) * Vect(0, 0, 1 ) );
				}
			// DashTrail
			if ( !Level.bDropDetail && (DashPawn.Velocity != vect(0, 0, 0)) && Chargeing == false )
				DashPawn.Spawn(class'DashTrail', DashPawn, , DashPawn.Location, DashPawn.Rotation);
		}

	if ( Role != ROLE_Authority )
		return;
	  
    if ( DashPawn == None || DashPawn.bIsPlayer == false ||
	DashPawn.PlayerReplicationInfo == None || DashPawn.Health <= 0 )
		{
			
			Destroy();
		}
	if ( Chargeing == true )
		{
			if ( Charge < MaxCharge )
				Charge += DashChargeRate;
			else
				AmbientSound = Sound'DashCharged';
			ClientLifeSpan = Charge;
		}
	else
		{
			if ( Charge != 0 )
				{
					LifeSpan = Charge;
					Charge = 0;
					DashPawn.AmbientSound = Sound'DashAmbient';
				}
			else
				{
					if ( LifeSpan <= 0 )
						Destroy();
				}
			
			Speed2D = Sqrt( DashPawn.Velocity.X * DashPawn.Velocity.X + DashPawn.Velocity.Y * DashPawn.Velocity.Y);
			//if ( ( Speed2D / Pawn(Owner).GroundSpeed ) < 0.1 );
			if ( DashPawn.Velocity == vect(0, 0, 0) )
				LifeSpan -= DeltaTime;
			
			ClientLifeSpan = LifeSpan;
			
			// GroundSpeed
			DashPawn.GroundSpeed = BaseGroundSpeed + 
			BaseGroundSpeed*(LifeSpan*DashFactor);
			// AirSpeed
			DashPawn.AirSpeed = BaseAirSpeed + 
			BaseAirSpeed*(LifeSpan*DashFactor);
			// WaterSpeed
			DashPawn.WaterSpeed = BaseWaterSpeed + 
			BaseWaterSpeed*(LifeSpan*DashFactor);
			// Acceleration
			DashPawn.Acceleration = BaseAcceleration + 
			BaseAcceleration*((LifeSpan*DashFactor)*100000);
		}
}

function ForceDestrution()
{
	destroy();
}

simulated Event Destroyed()
{
	local actor a;

	DashPawn.AmbientSound = None;
	
	DashPawn.GroundSpeed	= BaseGroundSpeed;
	DashPawn.AirSpeed		= BaseAirSpeed;
	DashPawn.WaterSpeed		= BaseWaterSpeed;
	DashPawn.Acceleration	= BaseAcceleration;
	
	// Turn the dashpad charge HUD off
	if ( Role != ROLE_Authority )
		{
			if ( DashPawn != None )
				{
					foreach AllActors( class'Actor',a)
						{
							if ( sgHUD(a) != None )
								{
									if ( sgHUD(a).Owner == DashPawn )
										sgHUD(a).DashPlayerInstance = self;
								}
						}
				}
			ForceDestrution();
		}
}

defaultproperties
{
     Slowness=4.000000
     RecoverRate=0.125000
     bHidden=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     Style=STY_Translucent
     Texture=Texture'ToxicCloud015'
}
