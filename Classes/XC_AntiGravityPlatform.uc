//=============================================================================
// AntiGravityPlatform.
// Made by Higor
//=============================================================================
class XC_AntiGravityPlatform expands sgBuilding;

var sgBuildingCH myCollision;
var float BaseEnergy;
var float RepairTimer;

var Pawn rPlayers[16];
var int iP;

var PlayerPawn LocalPush;
var XC_AntigravityToucher Toucher;
var float LastDelta;


replication
{
	reliable if ( Role==ROLE_Authority)
		rPlayers, iP;
}

simulated event PreBeginPlay()
{
	local Teleporter T;

	Super.PreBeginPlay(); //Not executed in clients

	bCollideWhenPlacing = False;
	SetCollision( false);
	if ( Level.NetMode != NM_Client )
	{
		SetLocation( Location - vect(0,0,5));
		ForEach RadiusActors (class'Teleporter', T, CollisionRadius * 1.1)
			if ( T.bCollideActors )
			{
				Destroy();
				return;
			}
	}
	else
		SetLocation( Location - vect(0,0,1));
	SetCollision( true);
}


simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Level.NetMode == NM_Client && Toucher == none )
	{
		ForEach AllActors (class'XC_AntigravityToucher', Toucher)
			break;
		if ( Toucher == none )
			Toucher = Spawn(class'XC_AntigravityToucher', none,,vect(30100, 30100, 30100));
	}
}

simulated event PostNetBeginPlay()
{
	local info I;
	Super.PostNetBeginPlay();
	if ( myCollision != none )
		myCollision.MyBuild = self;
}

function CompleteBuilding()
{
	if ( RepairTimer > 0 )
		RepairTimer -= 0.1;
	else
		Energy = FMin( Energy + 10, MaxEnergy);
}

simulated function FinishBuilding()
{
	Super(sgBuilding).FinishBuilding();
	if ( (Level.NetMode != NM_Client) && (myCollision == None) )
	{
		myCollision=Spawn(class'sgBuildingCH',Self,'',Location,Rotation);
		myCollision.Setup( Self, 63, 8, vect(0,0,-5));
	}
	BaseEnergy = MaxEnergy;
	Texture = None;
	if (myFX!=None)
	{
		myFX.AmbientGlow=5;
		myFX.ScaleGlow=1.5;
	}
}

simulated event TakeDamage( int dam, Pawn instBy, Vector hitLoc, Vector mom, name dmgType )
{
	local float PistonCharge;
	local vector aVec;
	RepairTimer = 10;
	Super.TakeDamage( dam, instBy, hitLoc, mom, dmgType);
	//PISTON! NEED CLIENT SIM HERE!
	if ( (instBy != none) && (dmgType == 'impact') && (ImpactHammer(instBy.Weapon) != none) )
	{
		PistonCharge = dam;
		PistonCharge /= 60;
		aVec = instBy.Velocity;
		instBy.TakeDamage(36.0 / (Grade+1.0), instBy, hitLoc, -69000.0 * PistonCharge * vector(instBy.ViewRotation), 'impact');
	}
}

simulated function Tick( float DeltaTime)
{
	local int i;

	Super.Tick(DeltaTime);


	if ( SCount > 0 || bDisabledByEMP )
		return;

	While ( i<iP )
	{
		if ( (rPlayers[i] == none) || rPlayers[i].bDeleteMe || (rPlayers[i].Physics != PHYS_Falling) || !InPushZone(rPlayers[i]) )
		{
			if ( rPlayers[i].Role == ROLE_AutonomousProxy )
				LocalPush = none;
			rPlayers[i] = rPlayers[--iP];
			rPlayers[iP] = none;
			continue;
		}
		rPlayers[i].Velocity.Z -= rPlayers[i].Region.Zone.ZoneGravity.Z * DeltaTime * 0.93;
		i++;
	}

	if ( (LocalPush != none) && (Level.NetMode == NM_Client) && (Toucher.CurPlat == self) )
	{
		LastDelta = DeltaTime;
		class'sg_TouchUtil'.static.SetTouch( Toucher, LocalPush);
		class'sg_TouchUtil'.static.SetTouch( LocalPush, Toucher);
	}
}

simulated function PlayerUpdatePush()
{
	if ( InPushZone(LocalPush) )
		LocalPush.Velocity.Z -= LocalPush.Region.Zone.ZoneGravity.Z * LastDelta * 0.93;
}

simulated function RegisterNew( pawn Other)
{
	local int i;

	if ( !Other.bIsPlayer || !InPushZone( Other) || (Other.PlayerReplicationInfo == none) || (Other.PlayerReplicationInfo.Team != Team) || (Other.Velocity.Z <= 0) )
		return;

	For ( i=0 ; i<iP ; i++ )
		if ( rPlayers[i] == Other )
			return;

	rPlayers[iP++] = Other;
	if ( (Level.NetMode == NM_Client) && (Other.Role == ROLE_AutonomousProxy) && (PlayerPawn(Other) != none) )
	{
		Toucher.CurPlat = self;
		LocalPush = PlayerPawn(Other);
	}
}

simulated function CollisionJump( Pawn Other)
{
	RegisterNew( Other);
}

simulated function bool InPushZone( pawn Other)
{
	if ( Other.Location.Z - Location.Z > 800 + 270 * Grade)
		return false;
	return VSize( (Other.Location - Location) * vect(1,1,0) ) < CollisionRadius * (2+Grade*0.5);
}

function Upgraded()
{
	local float percent, scale;

	percent = Energy/BaseEnergy;
	MaxEnergy = BaseEnergy * (1 + Grade/5);
	Energy = percent * MaxEnergy;
}

// Bring the building back to normal
function BackToNormal()
{
	Super.BackToNormal();
	LightType=LT_None;
	Texture=None;
}


defaultproperties
{
     bAlwaysRelevant=True
     bStandable=True
     bReplicateEMP=True
     bBlocksPath=True
     BuildingName="Antigravity Platform"
     BuildCost=500
     UpgradeCost=70
     BuildTime=12.000000
     MaxEnergy=2500.000000
     SpriteScale=0.500000
     Model=LodMesh'Botpack.CircleStud'
     SkinRedTeam=Texture'ContainerXSkinTeam0'
     SkinBlueTeam=Texture'ContainerXSkinTeam1'
     SpriteRedTeam=Texture'ProtectorSkinTeam0'
     SpriteBlueTeam=Texture'ProtectorSkinTeam1'
     DSofMFX=4.800000
     SkinGreenTeam=Texture'ContainerXSkinTeam2'
     SkinYellowTeam=Texture'ContainerXSkinTeam3'
     SpriteGreenTeam=Texture'ProtectorSkinTeam2'
     SpriteYellowTeam=Texture'ProtectorSkinTeam3'
     MFXrotX=(Yaw=10000)
     CollisionRadius=65.000000
     CollisionHeight=17.000000
     BuildDistance=52
     GUI_Icon=Texture'GUI_AGPlatform'
}
