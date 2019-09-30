//=========================================================
// DashPad
// 
// * Sonic styled dash pad!
// * Made by Higor
//=========================================================

class DashPad expands sgBooster;

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


var vector PushDir;
var rotator DashRot;

replication
{
	reliable if ( bNetInitial && ROLE==ROLE_Authority )
		DashRot;
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();

	SetRotation( DashRot );
	if ( Level.NetMode != NM_DedicatedServer ) //Setup custom MFX
	{
		myFX = Spawn(class'WildcardsMeshFX', Self, 'DashPadFX', Location, Rotation);
		myFX.Mesh = Mesh'DashPadBase';
		myFX.SetPhysics( PHYS_None);
		myFX.NextFX = Spawn( class'sgMeshFX_DashPadPanel', Self, 'DashPadFX', Location, Rotation);
		if ( Level.NetMode == NM_Client )
			LocalPlayer = class'SiegeStatics'.static.FindLocalPlayer(self);
	}
}

function CompleteBuilding()
{
	Super.CompleteBuilding();
	if ( !bDisabledByEMP && !bIsOnFire ) //NEED AN EVENT HERE!!!
		Texture = Texture'MiniammoLedBase';
}

simulated function DoBoost( Pawn Other)
{
	local sgPlayerData sgPD;
	local XC_MA_DashPad MA;
	
	if ( Level.NetMode == NM_Client )
	{
		return;
	}
	
	sgPD = class'SiegeStatics'.static.GetPlayerData( Other);
	if ( sgPD != None )
	{
		MA = XC_MA_DashPad(sgPD.FindMAffector( class'XC_MA_DashPad'));
		if ( MA == None )
		{
			MA = Spawn(class'XC_MA_DashPad', Other,,Location);
			sgPD.AddMAffector( MA);
		}
		if ( MA != None )
		{
			MA.Setup( self);
		}
	}
}

simulated function Actor CollideTrace( out vector HitLocation, out vector HitNormal, vector TraceEnd, vector TraceStart)
{
	local Actor A;

	ForEach TraceActors( class'Actor', A, HitLocation, HitNormal, TraceEnd, TraceStart)
	{
		if ( (A == Level) || (!A.bIsPawn && A.bBlockPlayers && A.bBlockActors) )
			return A;
	}
	HitLocation = TraceEnd;
	HitNormal = vect(0,0,0);
	return None;
}

//First event in creation order?
event Spawned()
{
	local vector CenterOffset, X, Y;
	local vector CenterPoint, CenterNormal;
	local Actor Hit;
	local rotator View;
	local int i;
	local vector Offset[4], HitLocation[4], HitNormal[4];

	Super.Spawned();

	//Setup Center
	Hit = CollideTrace( CenterPoint, CenterNormal, Location - vect(0,0,60), Location);
	if ( (Hit == None) || (CenterNormal.Z < 0.706) )
	{
		Destroy();
		return;
	}

	//Setup Forward
	View.Yaw = Rotation.Yaw - 16384;
	X = CenterNormal cross vector(View);
	
	//Setup Right
	View.Yaw = Rotation.Yaw;
	Y = CenterNormal cross vector(View);
	
	Offset[0] = CenterNormal * 2 + X *  20;
	Offset[1] = CenterNormal * 2 + X * -20;
	Offset[2] = CenterNormal * 2 + Y *  20;
	Offset[3] = CenterNormal * 2 + Y * -20;
	
	For ( i=0 ; i<ArrayCount(Offset) ; i++ )
	{
		CenterOffset = CenterPoint + Offset[i];
		// CenterPoint >> CenterOffset >> CenterOffset into floor
		if ( CollideTrace( HitLocation[i], HitNormal[i], CenterOffset, CenterPoint) != None
		|| CollideTrace( HitLocation[i], HitNormal[i], CenterOffset - CenterNormal * 4, CenterOffset) == None )
		{
			Destroy();
			return;
		}
	}
	
	bCollideWhenPlacing = false;
	bCollideWorld = false;
	SetLocation( CenterPoint);
	
	PushDir = X;
	DashRot = rotator(X);
	View = rotator(Y);
	DashRot.Roll = -View.Pitch;
	SetRotation( DashRot);
}

defaultproperties
{
     BoostSound=Sound'sgUMedia.StrengthUse'
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
     CollisionHeight=8
     CollisionRadius=44
	 SpriteScale=1.00000
     DSofMFX=1.0
	 NumOfMFX=0
}
