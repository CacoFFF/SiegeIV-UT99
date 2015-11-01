//=============================================================================
// sg_Grenade.
//=============================================================================
class sg_Grenade extends Projectile;

#exec MESH IMPORT MESH=sg_Grenade ANIVFILE=GLauncher\sg_Grenade_a.3d DATAFILE=GLauncher\sg_Grenade_d.3d
#exec MESH LODPARAMS MESH=sg_Grenade HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=sg_Grenade X=0.00 Y=0.00 Z=0.00 YAW=0.00 ROLL=0.00 PITCH=0.00

#exec MESH SEQUENCE MESH=sg_Grenade SEQ=All       STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=sg_Grenade SEQ=sg_Grenade   STARTFRAME=0 NUMFRAMES=1

#exec TEXTURE IMPORT NAME=Jsg_grenade1 FILE=GLauncher\sg_Jgrenade1.PCX GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=Jsg_grenade2 FILE=GLauncher\sg_Jgrenade2.PCX GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=Jsg_grenade3 FILE=GLauncher\sg_Jgrenade3.PCX GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=Jsg_grenade4 FILE=GLauncher\sg_Jgrenade4.PCX GROUP=Skins LODSET=2

#exec MESHMAP SCALE MESHMAP=sg_Grenade X=0.10 Y=0.10 Z=0.20

var float ExplodeTime;
var bool bCanHitOwner, bHitWater;
var float Count, SmokeRate;
var int NumExtraGrenades;
var bool bSmoking, bBubbling, bVelDecreaser, bAvoiderSet;
var float TrailModifier;

function PostBeginPlay()
{
	local vector X,Y,Z;
	local rotator RandRot;
	local BubbleBurst BB;
	
	Super.PostBeginPlay();

	GetAxes( Instigator.ViewRotation, X, Y, Z );	
	Velocity = X * ( Instigator.Velocity Dot X ) * 0.4 + Vector( Rotation ) * Speed + FRand() * 100 * Vector( Rotation );
	Velocity.Z += 210;
	SetTimer( ExplodeTime, false );                 
	MaxSpeed = 1500;
	RotationRate.Pitch = ( 100000 * FRand() );
	RotationRate.Roll = 90000 * 2 * 0.5 - 10000;
	bCanHitOwner = False;
	TrailModifier = 0.7;

	if( Instigator.HeadRegion.Zone.bWaterZone )
	{
		bHitWater = True;
		bBubbling = True;
		bVelDecreaser = True;
		Velocity = 0.8 * Velocity;
		if( Velocity.Z > 100 )
			Velocity.Z *= 0.5;
		SetPhysics( PHYS_Projectile );
		RotationRate.Pitch = 0;
//		BB = Spawn( class'BubbleBurst', Instigator,,, Instigator.Rotation );			
//		BB.RemoteRole = ROLE_None;
		Spawn( class'BubbleBurst',,,, Instigator.Rotation );			

	}	
	else
	{
		SetPhysics( PHYS_Falling );
		bSmoking = True;
	}	
}

simulated function BeginPlay()
{
	if( Level.bHighDetailMode )
		SmokeRate = 0.03;
	else 
		SmokeRate = 0.15;
}


simulated function ZoneChange( Zoneinfo NewZone )
{
	local waterring r;
	
	if( !NewZone.bWaterZone || bHitWater )
	{
		if( bBubbling )
		{
			SetPhysics( PHYS_Falling );
			bBubbling = False;
			Velocity *= 1.5;
			r = Spawn( class'WaterRing',,,,rot( 16384, 0, 0 ));
			r.DrawScale = 0.15;
			r.RemoteRole = ROLE_None;
		}
		return;
	}
	bSmoking = False;
	bHitWater = True;
	bBubbling = True;
//	bVelDecreaser = True;
	RotationRate.Pitch = 0;
	RotationRate.Roll = 90000 * 2 * 0.5 - 10000;
	Velocity=0.8*Velocity;
}

function Timer()
{
	Explosion( Location+Vect( 0, 0, 1 ) * 16 );
}


simulated function Tick(float DeltaTime)
{
	local SpriteSmokePuff b;
	local BubbleTrail bt;

	if( Velocity.Z < -550 )
	{
		// Temporarily disabled Falling Grenade sound; needs a whistling sound
		// AmbientSound = sound'FallingGrenade';
		SoundVolume = 255;
		if ( SoundPitch >= 48 )
			SoundPitch -= 1;
	}
	else
	{
		AmbientSound = none;
		SoundVolume = 0;
	}
		
	Count += DeltaTime;
	if( ( Count>Frand() * SmokeRate+SmokeRate + NumExtraGrenades * 0.03 ) && ( Level.NetMode != NM_DedicatedServer ) && bSmoking ) 
	{
		b = Spawn( class'SpriteSmokePuff' );
		b.RemoteRole = ROLE_None;
		b.DrawScale -= 0.2 + FRand();
		b.ScaleGlow = 0.5;
		Count=0;
	}
	else if( bBubbling )
	{
		if( Velocity.Z <= 200 )
			Velocity.Z -= 100 * DeltaTime;

		if( FRand() < 0.25 && FRand() < 0.25 && FRand() < 0.25  && bVelDecreaser )
			Velocity *= 0.65;

		if( VSize( Velocity ) <= 45 )
		{
			if( VSize(Velocity) < 10 )
				bBubbling = False;
			else
			{
				SetPhysics( PHYS_Falling );
				bSmoking = False;
				bVelDecreaser = False;
			}
		}
			
		if( VSize( Velocity ) > 300 )
			TrailModifier = 0.95;
		else if( VSize( Velocity ) > 200 )
			TrailModifier = 0.5;
		else if(VSize(Velocity) > 80)
			TrailModifier = 0.3;
		else
			TrailModifier = 0.1;
	
		if( FRand() < TrailModifier )
		{
			bt = Spawn( class'BubbleTrail' );
			bt.RemoteRole = ROLE_None;
			bt.ScaleGlow = 0.5;
		}

		Count = 0;
	}
}


simulated function Landed( vector HitNormal )
{
	bSmoking = False;
	HitWall( HitNormal, None );
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
	if( ( Other != Instigator ) || bCanHitOwner )
		Explosion( HitLocation );
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	local SmallSpark2 Spark;
	
	bSmoking = False;
	bCanHitOwner = True;

	if( VSize( Velocity ) > 600 )
	{
		Spark = Spawn( class'SmallSpark2',,,,Rotation+RotRand() );
		Spark.RemoteRole = ROLE_None;
	}
	
	Velocity = 0.65 * (( Velocity dot HitNormal ) * HitNormal * ( -2.0 ) + Velocity );  
	RandSpin( 100000 );
	speed = VSize( Velocity );

	if( Level.NetMode != NM_DedicatedServer )
		PlaySound( ImpactSound, SLOT_Misc, FMax( 0.5, speed/800 ) );

	if( Velocity.Z > 400 )
		Velocity.Z = 0.65 * ( 400 + Velocity.Z );	
	else if( speed < 20 ) 
	{
		bBounce = False;
		SetPhysics( PHYS_None );
	}
}

function Explosion(vector HitLocation)
{
	Destroy();
}


defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=20
	speed=700
	ExplodeTime=3
	MaxSpeed=1200
	MomentumTransfer=7500
	ImpactSound=Sound'GrenadeHit'
	bNetTemporary=False
	Physics=2
	RemoteRole=2
	AnimSequence='WingIn'
	Skin=Texture'Jsg_grenade1'
	Mesh=LodMesh'sg_Grenade'
	DrawScale=1.3
	AmbientGlow=64
	SoundRadius=64
	SoundPitch=128
	CollisionRadius=3.5
	CollisionHeight=3.5
	bBounce=True
	bFixedRotationDir=True
	Mass=25
	DesiredRotation=(Pitch=6000)
}
