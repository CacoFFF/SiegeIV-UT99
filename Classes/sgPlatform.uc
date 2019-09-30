//=============================================================================
// sgPlatform 4th gen
// New platform prototype for 4th gen siege
// Made by Higor
//=============================================================================
class sgPlatform expands sgBuilding;

var sgBuildingCH TCH;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		TCH;
}

simulated event PreBeginPlay()
{
	local Teleporter T;

	Super.PreBeginPlay(); //Not executed in clients

	bCollideWhenPlacing = False;
	SetCollision( false);
	if ( Level.NetMode != NM_Client )
	{
		SetLocation( Location - vect(0,0,10));
		SetCollisionSize( CollisionRadius / 0.75, CollisionHeight / 0.75);
		ForEach RadiusActors (class'Teleporter', T, CollisionRadius * 1.3)
			if ( T.bCollideActors )
			{
				Destroy();
				return;
			}
	}
	else
		SetLocation( Location - vect(0,0,2));
	SetCollision( true);
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( TCH != none )
		TCH.MyBuild = self;
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();
	if ( (Level.NetMode != NM_Client) && (TCH == None) )
	{
		TCH=Spawn(class'sgBuildingCH',Self,'',Location,Rotation);
		TCH.Setup( Self, 60, 15, vect(0,0,0));
	}

	Texture = None;
	if (myFX!=None)
	{
		myFX.AmbientGlow=5;
		myFX.ScaleGlow=1.5;
	}
}

simulated function Destruct( optional pawn instigatedBy)
{
	local Pawn p;

	foreach VisibleCollidingActors(class'Pawn', p, 95)
		if ( p.bIsPlayer && (p.Health > 0) && (p.PlayerReplicationInfo != None) )
			p.TakeDamage((Grade/2)+1 , instigator, vect(10,10,0), vect(10,10,0), 'sgSpecial');

	Super(sgBuilding).Destruct( instigatedBy);
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

simulated event TakeDamage( int dam, Pawn instBy, Vector hitLoc, Vector mom, name dmgType )
{
	local float PistonCharge;
	local vector aVec;
	Super.TakeDamage( dam, instBy, hitLoc, mom, dmgType);
	//PISTON!
	if ( (instBy != none) && (dmgType == 'impact') && (ImpactHammer(instBy.Weapon) != none) )
	{
		PistonCharge = dam;
		PistonCharge /= 60;
		aVec = instBy.Velocity;
		instBy.TakeDamage(36.0 / (Grade+1.0), instBy, hitLoc, -69000.0 * PistonCharge * vector(instBy.ViewRotation), 'impact');
	}
}


defaultproperties
{
     bDragable=true
     BuildingName="Platform"
     BuildCost=200
     UpgradeCost=20
     BuildTime=5.000000
     MaxEnergy=2000.000000
     SpriteScale=1.000000
     Model=LodMesh'Botpack.DiscStud'
     SkinRedTeam=Texture'PlatformSkinT0'
     SkinBlueTeam=Texture'PlatformSkinT1'
     SpriteRedTeam=Texture'PlatformSpriteT0'
     SpriteBlueTeam=Texture'PlatformSpriteT1'
     DSofMFX=4.000000
     SkinGreenTeam=Texture'PlatformSkinT2'
     SkinYellowTeam=Texture'PlatformSkinT3'
     SpriteGreenTeam=Texture'PlatformSpriteT2'
     SpriteYellowTeam=Texture'PlatformSpriteT3'
     MFXrotX=(Yaw=10000)
     MultiSkins(0)=Texture'PlatformSpriteT0'
     MultiSkins(1)=Texture'PlatformSpriteT1'
     MultiSkins(2)=Texture'PlatformSpriteT2'
     MultiSkins(3)=Texture'PlatformSpriteT3'
     CollisionRadius=45.750000
     CollisionHeight=12.750000
     BuildDistance=50
     bStandable=True
     bBlocksPath=True
     GUI_Icon=Texture'GUI_Platform'
}
