///////////////////////////////////////////
// NapalmFragment
// by Higor
// Pretty fire stuff, puts everything on fire

class NapalmFragment expands Projectile;

#exec AUDIO IMPORT FILE="GLauncher\FireExpl_1.WAV" NAME="FireExpl_1" GROUP="GrenadeLauncher"
#exec AUDIO IMPORT FILE="GLauncher\FireExpl_2.WAV" NAME="FireExpl_2" GROUP="GrenadeLauncher"

//To correct LifeSpan on clients
var float PassedTime;

//Extra Z threshold velocity
var float AddedZVel;

//Fire effect timer
var float SpriteTimer;

//Build touch count
var int TouchCount;

var sound HitSounds[2];

replication
{
	reliable if ( Role==ROLE_Authority )
		PassedTime, AddedZVel, TouchCount;
}

simulated event PostNetBeginPlay()
{
	LifeSpan = Default.LifeSpan - PassedTime;
	if ( LifeSpan <= 0 )
		Destroy();
}

simulated event Tick( float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		PassedTime += DeltaTime;
	}


	if ( Physics == PHYS_Falling )
	{
		//Cap vertical velocity in air
		if ( Velocity.Z < (-400 - AddedZVel) )
		{
			Velocity.Z = -400 - AddedZVel;
			AddedZVel += DeltaTime * 15;
		}
		if ( Level.NetMode != NM_DedicatedServer )
		{
			if ( (SpriteTimer -= DeltaTime) < 0 )
			{
				SpriteTimer += 0.08;
				SpriteTimer = (SpriteTimer + 0.08) / 2;
				if ( !Level.bHighDetailMode )
					SpriteTimer += 0.05;
				if ( Level.bDropDetail )
					SpriteTimer += 0.06;
				if ( class'sgClient'.default.bHighPerformance )
					SpriteTimer += 0.07;
				Spawn(class'BurnSprite',,,Location + Normal(Velocity) * 2);
			}
		}
	}
	else if ( Physics == PHYS_None ) //Water or ground
	{
		if ( Region.Zone.bWaterZone && Region.Zone.DamageType != 'Burned' )
		{
			PassedTime += DeltaTime * 2;
			if ( (LifeSpan -= (DeltaTime*2)) <= 0 )
				Destroy();
		}
	}

	ScaleGlow = fClamp( LifeSpan, 0f, 3f);
	DrawScale = Default.DrawScale * fClamp(0.5 + LifeSpan * 0.3, 0.5, 1.2);
	if ( Texture != Default.Texture )
		DrawScale *= 0.7;
}

simulated event ZoneChange( ZoneInfo NewZone )
{
	if ( NewZone.bWaterZone )
	{
//		SetLocation( Location + Normal(OldLocation - Location) * 4 );
		SetPhysics( PHYS_None);
		Texture = WetTexture'KoalasFire';
	}
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	local FlameExplosion F;

	F = Spawn( class'FlameExplosion');
	F.RemoteRole = ROLE_None;
	BurnNear();

	PlaySound( HitSounds[Rand(2)], SLOT_Misc, 1.4 );

	if ( TouchCount++ > 1 )
		Destroy();
}

function BurnNear()
{
	local sgBuilding building;
	local int MyTeam;

	if ( Instigator == none || Instigator.PlayerReplicationInfo == none )
		MyTeam = 255;
	else
		MyTeam = Instigator.PlayerReplicationInfo.Team;

	BurnRadius(damage, 120, 'Burned', MomentumTransfer, Location, MyTeam);	
}

simulated event Landed( vector Hitnormal)
{
	Texture = WetTexture'KoalasFire';
}

simulated function HitWall (vector HitNormal, actor Wall)
{
	if ( Role == ROLE_Authority )
	{
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), '');
		BurnNear();
		MakeNoise(1.0);
	}
	Velocity = 0.65*(( Velocity dot HitNormal ) * HitNormal * (-2.0) + Velocity);   // 
	speed = VSize(Velocity);
//	if ( TouchCount++ > 2 )
//		Destroy();
//	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
//		Spawn(ExplosionDecal,self,,Location, rotator(HitNormal));
}

function BurnRadius( float DamageAmount, float DamageRadius, name DamageName, float Momentum, vector HitLocation, byte MyTeam )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	
	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		if( Victims != self )
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist; 
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			if ( Victims.IsA('sgBuilding') )
			{
				damageScale *= 0.15;
				if ( sgBuilding(Victims).Team != MyTeam && !sgBuilding(Victims).bIsOnFire)
				{
					sgBuilding(Victims).Incinerate( Instigator, Location, Normal(Location - Victims.Location) );
				}
			}
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator, 
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageName
			);
		} 
	}
	bHurtEntry = false;
}


defaultproperties
{
	damage=30
	MomentumTransfer=10000
	CollisionHeight=2
	CollisionRadius=12
	bBounce=False
	DrawType=DT_Sprite
	Style=STY_Translucent
	Physics=PHYS_Falling
	speed=500
	MaxSpeed=900
	Texture=Texture'MetalSuitBulletHit001'
	LifeSpan=9
	SpriteTimer=0.15
	bNetTemporary=True
	HitSounds(0)=Sound'FireExpl_1'
	HitSounds(1)=Sound'FireExpl_2'
	RemoteRole=ROLE_SimulatedProxy
}