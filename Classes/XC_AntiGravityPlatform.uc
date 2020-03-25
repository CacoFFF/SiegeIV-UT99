//=============================================================================
// AntiGravityPlatform.
// Made by Higor
//=============================================================================
class XC_AntiGravityPlatform expands sgBuilding;

var sgBuildingCH myCollision;
var float RepairTimer;

var Pawn rPlayers[16];
var float rTime[16];
var int iP;

var PlayerPawn LocalPush;
var float LocalTime;
var ECM_AntigravPush ClientPush;
var float LastDelta;


replication
{
	reliable if ( Role==ROLE_Authority)
		rPlayers, rTime, iP;
}

simulated event PreBeginPlay()
{
	local Teleporter T;

	Super.PreBeginPlay(); //Not executed in clients

	bCollideWhenPlacing = False;
	SetCollision( false);
	if ( Level.NetMode != NM_Client )
	{
		SetLocation( Location - vect(0,0,7));
		SetCollisionSize( CollisionRadius / 0.75, CollisionHeight / 0.75);
		ForEach RadiusActors (class'Teleporter', T, CollisionRadius * 1.2)
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
	if ( Level.NetMode == NM_Client && ClientPush == none )
	{
		ForEach AllActors (class'ECM_AntigravPush', ClientPush)
			break;
		if ( ClientPush == none )
			ClientPush = Spawn(class'ECM_AntigravPush', none,, vect(30100, 30100, 30100));
	}
}

simulated event PostNetBeginPlay()
{
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
		myCollision.Setup( Self, 62, 8, vect(0,0,-1));
	}
	Texture = None;
	if (myFX!=None)
	{
		myFX.AmbientGlow=5;
		myFX.ScaleGlow=1.5;
		myFX.PrePivot.Z = 6;
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
			if ( (rTime[i] > 0) && (rPlayers[i].Physics == PHYS_Falling) ) //Touching ground immediately cancels effect
				rTime[i] -= DeltaTime;
			else
			{
				rPlayers[i] = rPlayers[--iP];
				rTime[i] = rTime[iP];
				rPlayers[iP] = none;
				continue;
			}
		}
		ModifyVelocity( rPlayers[i], DeltaTime);
		i++;
	}

	if ( LocalPush != None )
	{
		if ( LocalPush.Physics != PHYS_Falling || !InPushZone(LocalPush) )
		{
			if ( (LocalTime > 0) && (LocalPush.Physics == PHYS_Falling) )
				LocalTime -= DeltaTime;
			else
			{
				if ( ClientPush != None )
					ClientPush.AntigravEnd( self, LocalPush);
				LocalPush = None;
				LocalTime = 0;
			}
		}
		if ( LocalPush != None )
			ModifyVelocity( LocalPush, DeltaTime);
	}
}

simulated function ModifyVelocity( Pawn Other, float DeltaTime)
{
	Other.Velocity.Z -= Other.Region.Zone.ZoneGravity.Z * DeltaTime * 0.93;
}


simulated function RegisterNew( pawn Other)
{
	local int i;

	if ( !Other.bIsPlayer || !InPushZone( Other) || (Other.PlayerReplicationInfo == none) || (Other.PlayerReplicationInfo.Team != Team) /*|| (Other.Velocity.Z <= 0)*/ )
		return;

	For ( i=0 ; i<iP ; i++ )
		if ( rPlayers[i] == Other )
		{
			rTime[i] = Grade * 0.25;
			return;
		}

	rTime[iP] = Grade * 0.25;
	rPlayers[iP++] = Other;
	if ( (Level.NetMode == NM_Client) && (Other.Role == ROLE_AutonomousProxy) && (PlayerPawn(Other) != none) )
	{
		LocalPush = PlayerPawn(Other);
		LocalTime = Grade * 0.25;
		if ( !LocalPush.bUpdating && LocalPush.bCanTeleport )
			ClientPush.AntigravStart( self, LocalPush);
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
	SetMaxEnergy( BaseEnergy * (1 + Grade/5));
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
     bDragable=True
     bStandable=True
     bReplicateEMP=True
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
     CollisionRadius=49.000000
     CollisionHeight=10.000000
     BuildDistance=52
     GUI_Icon=Texture'GUI_AGPlatform'
}
