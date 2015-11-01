//=============================================================================
// sxDashPad.
// Written By WILDCARD
//
// Higor notes:
// We've got to fix this, probably rewrite it from scratch
// We could use a simple 3d model that actually looks like a dash pad too
// And in the meantime, make it directional as in Sonic games LELEL
// The build could look like a simple platform...
// but above a holographic pad is drawn with arrows and all marking direction
//=============================================================================
class sxDashPad extends sgBuilding;

var DashPlayer Dash;
var bool InUse;

// DEBUG
var() config bool DEBUG_DoNotApplyFix;
var() config float DEBUG_IgnoreEventTime;
var() config float DEBUG_TapAndLeaveDistance;

// For Fine Tuning
var() config float DashTime;
var() config float DashFactor;
var() config float DoubleDashFactor;
var() config float DashChargeRate;
var() config int   DashMultiDashLimit;

// Yes this is just for sound!
var Pawn Listener;

replication
{
	reliable if ( Role==ROLE_Authority )
		DoubleDashClient, Dash, Listener;
}

simulated event Timer()
{
	Enable('UnTouch');
	Enable('Touch');
	
	if ( Dash != None && InUse == true )
		{
			if ( DEBUG_TapAndLeaveDistance == 0 )
				DEBUG_TapAndLeaveDistance = 1.5;
				
			if ( VSize((Dash.DashPawn).Location - Location) > CollisionRadius*DEBUG_TapAndLeaveDistance )
				UnTouch(Dash.DashPawn);
			
			
		}
	
	Super.Timer();
}

simulated event Touch(Actor other)
{
	local int Matches;
	
	if ( DEBUG_DoNotApplyFix == false && DoneBuilding == true )
		{
		
			if ( DEBUG_IgnoreEventTime == 0 )
				DEBUG_IgnoreEventTime = 0.25;
				
			SetTimer(DEBUG_IgnoreEventTime,false);
			Disable('UnTouch');
			Disable('Touch');
		}

	if ( Role == ROLE_Authority )
		{
			if ( DoneBuilding == false || InUse == true || SCount > 0 || 
				Pawn(other) == None || !Pawn(other).bIsPlayer ||
				Pawn(other).PlayerReplicationInfo == None || 
				Pawn(other).PlayerReplicationInfo.Team != Team )
				{
					return;
				}

			Matches = 0;
				
			foreach AllActors(class'DashPlayer',Dash)
				{
					if ( Dash.DashPawn == Pawn(other) )
						{
							Matches++;
							
							if ( Dash.UsedPad(Self) == false )
								{
									DoubleDashClient(Dash.DashPawn);
									log("sxDashPad: DOUBLE DASH!!!");
									Listener = Dash.DashPawn;
									Dash.DoubleDash(Self);
									return;
								}
							else
								{
									return;
								}
						}
				}
				
			Dash = Spawn(Class'DashPlayer',Owner,,Location);

			//Disable('Touch');
			
			Dash.DashPawn = Pawn(other);
			Dash.Chargeing = True;
			Dash.DashChargeRate = DashChargeRate;
			Dash.MaxCharge = DashTime;
			Dash.DashFactor = (Grade+1)*DashFactor;
			Dash.PadHistory[Dash.PadIndex] = self;
			Dash.PadIndex++;
			Dash.Begin();
			
			InUse = true;
			
		}
	else
		{
			if ( DoneBuilding == false || InUse == true || SCount > 0 || 
			Pawn(other) == None || !Pawn(other).bIsPlayer ||
			Pawn(other).PlayerReplicationInfo == None || 
			Pawn(other).PlayerReplicationInfo.Team != Team )
			{
				return;
			}
			
			foreach AllActors(class'DashPlayer',Dash)
				{
					if ( Dash.DashPawn == Pawn(other) )
						{
							if ( Dash.UsedPad(Self) == true )
								{
									return;
								}
						}
				}
			PlaySound(Sound'DashCharge');
		}
}

simulated function DoubleDashClient(actor other)
{
	log("Played Double Dash Sound! Other = "$other);
	Pawn(other).PlaySound(Sound'DashBoost');
	PlaySound(Sound'DashBoost');
}

simulated event Tick(float deltaTime)
{
	// All of this just to play a F234ing sound.
	// Yep, I'm officially annoyed after following the rules this function refuses to run on the client 
	// after the player reconnects so I'm saying F#@#$ it and making another workaround
	if ( Role != ROLE_Authority )
		{
			log("This shall always happen on the client NO MATTER WHAT.");
			if ( Listener != None )
				{
					Listener = None;
					DoubleDashClient(Listener);
				}
		}
	
	// Do other building stuff.. whatever
	Super.Tick(deltaTime);
}

simulated event UnTouch(Actor other)
{
	//Disable('UnTouch');
	Enable('Touch');
	
	if ( DoneBuilding == false || Dash.Chargeing == False )
		return;
		
    if ( SCount <= 0 && Pawn(other) != None && Pawn(other).bIsPlayer &&
      Pawn(other).PlayerReplicationInfo != None &&
      Pawn(other).PlayerReplicationInfo.Team == Team )
    {
		if ( Role != ROLE_Authority )
			PlaySound(Sound'DashOut');
		else
			{
				Dash.Chargeing = False;
				InUse = false;
			}
    }
}

simulated function Upgraded()
{
	local float Percent;
	
    if ( Role == ROLE_Authority )
		{
			Percent = Energy/MaxEnergy;
			MaxEnergy = default.MaxEnergy * (1 + Grade/2);
			Energy = Percent * MaxEnergy;
		}
}

function Destruct( optional pawn instigatedBy)
{
	Dash.Destroy();
	super.Destruct( instigatedBy);
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BuildingName="Dash Pad"
     BuildCost=600
     UpgradeCost=90
     BuildTime=10.000000
     MaxEnergy=3500.000000
     Model=LodMesh'UnrealI.CryopodM'
     SkinRedTeam=Texture'SuperProtectorSkinT0'
     SkinBlueTeam=Texture'SuperProtectorSkinT1'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     DSofMFX=0.65
     MFXrotX=(Yaw=20000)
     CollisionHeight=30.000000
	 DashTime=2.5
	 DashFactor=1
	 DoubleDashFactor=1.25
	 DashChargeRate=0.10
}
