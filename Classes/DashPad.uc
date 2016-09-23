//=========================================================
// DashPad
// 
// * Sonic styled dash pad!
// * Made by Higor
//=========================================================

class DashPad expands sgBuilding;

//Base model > bMeshEnviroMap with team texture
#exec mesh import mesh=DashPadBase anivfile=Models\DashPadBasePrefab_a.3d datafile=Models\DashPadBasePrefab_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=DashPadBase x=0 y=-259 z=0 pitch=0 yaw=64 roll=0
#exec mesh sequence mesh=DashPadBase seq=All startframe=0 numframes=1

#exec meshmap new meshmap=DashPadBase mesh=DashPadBase
#exec meshmap scale meshmap=DashPadBase x=0.07 y=0.07 z=0.14

//Panel model > unlit, 2 skins
#exec mesh import mesh=DashPadPanel anivfile=Models\DashPadPanelPrefab_a.3d datafile=Models\DashPadPanelPrefab_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=DashPadPanel x=0 y=0 z=0 pitch=0 yaw=64 roll=0
#exec mesh sequence mesh=DashPadPanel seq=All startframe=0 numframes=1

#exec meshmap new meshmap=DashPadPanel mesh=DashPadPanel
#exec meshmap scale meshmap=DashPadPanel x=0.073 y=0.073 z=0.146


var float RepairTimer;
var vector PushDir;

replication
{
	reliable if ( bNetInitial && ROLE==ROLE_Authority )
		PushDir;
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();

	SetRotation( rotator(PushDir) );
	if ( Level.NetMode != NM_DedicatedServer ) //Setup custom MFX
	{
		myFX = Spawn(class'WildcardsMeshFX', Self, 'DashPadFX', Location, Rotation);
		myFX.Mesh = Mesh'DashPadBase';
		myFX.SetPhysics( PHYS_None);
		myFX.NextFX = Spawn( class'sgMeshFX_DashPadPanel', Self, 'DashPadFX', Location, Rotation);
	}
}

function CompleteBuilding()
{
	if ( RepairTimer > 0 )
		RepairTimer -= 0.1;
	else
		Energy = FMin( Energy + 18, MaxEnergy);
	if ( !bDisabledByEMP && !bIsOnFire ) //NEED AN EVENT HERE!!!
		Texture = Texture'MiniammoLedBase';
}

event TakeDamage( int Damage, Pawn instigatedBy, vector HitLocation, Vector momentum, name DamageType)
{
	RepairTimer = 6;
	Super.TakeDamage(Damage * (1.0 - Grade*0.05), instigatedBy, HitLocation, momentum, DamageType);
}


//First event in creation order?
event Spawned()
{
	local vector HitLocation, HitNormal, TraceStart, TraceEnd;
	local plane CenterPlane;
	local Actor A;
	local rotator MyRot;
	local float PlaneDist;
	
	Super.Spawned();

	MyRot = Rotation;
	MyRot.Pitch = 0;
	TraceEnd = Location;
	TraceEnd.Z -= 60;
	ForEach TraceActors (class'Actor', A, HitLocation, HitNormal, TraceEnd)
	{
		if ( A != Level && !A.bBlockPlayers && !A.bBlockActors )
			continue;
		CenterPlane.X = HitNormal.X;
		CenterPlane.Y = HitNormal.Y;
		CenterPlane.Z = HitNormal.Z;
		CenterPlane.W = HitLocation dot HitNormal;
		break;
	}
	if ( CenterPlane.Z < 0.8 )
	{
		Destroy();
		return;
	}
	bCollideWhenPlacing = false;
	bCollideWorld = false;
	SetLocation( HitLocation + HitNormal * 2);
	
	TraceStart = Location + vector(MyRot) * 20;
	TraceEnd = TraceStart;
	TraceEnd.Z -= 60;
	ForEach TraceActors (class'Actor', A, HitLocation, HitNormal, TraceEnd, TraceStart)
	{
		if ( A != Level && !A.bBlockPlayers && !A.bBlockActors )
			continue;
		if ( VSize( CenterPlane - HitNormal) > 0.1 )
		{
			Destroy();
//			Log("Mismatching normals");
			return;
		}
		PlaneDist = HitLocation dot CenterPlane;
		if ( Abs(PlaneDist) < 3 )
		{
			Destroy();
//			Log("Not coplanar");
			return;
		}
		HitLocation += HitNormal * 2;
		PushDir = HitLocation - Location;
		SetRotation( Rotator(PushDir));
		break;
	}
	if ( A == none )
		Destroy();
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BuildingName="Dash Pad"
     BuildCost=800
     UpgradeCost=45
     MaxEnergy=2500
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
     CollisionHeight=7
     CollisionRadius=44
	 SpriteScale=1.00000
     DSofMFX=1.0
	 NumOfMFX=1
}
