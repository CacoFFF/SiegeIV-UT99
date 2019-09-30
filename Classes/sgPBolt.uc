//=============================================================================
// sgPBolt.
//=============================================================================
class sgPBolt extends Projectile;

var() texture SpriteAnim[5];
var int SpriteFrame;
var sgPBolt PlasmaBeam;
var PlasmaCap WallEffect;
var int Position;
var vector FireOffset;
var float BeamSize;
var bool bRight, bCenter;
var float AccumulatedDamage, LastHitTime;
var Actor DamagedActor;

replication
{
	// Things the server should send to the client.
	unreliable if( Role==ROLE_Authority )
		bRight, bCenter;
}

simulated function Destroyed()
{
	Super.Destroyed();
	if ( PlasmaBeam != None )
		PlasmaBeam.Destroy();
	if ( WallEffect != None )
		WallEffect.Destroy();
}

simulated function CheckBeam(vector X, float DeltaTime)
{
	local actor HitActor;
	local vector HitLocation, HitNormal;
	local float InstigBeamSize;

	// check to see if hits something, else spawn or orient child
	HitActor = Trace(HitLocation, HitNormal, Location + BeamSize * X, Location, true);
	
	//Actual fix for shooting through wall
	if (HitActor == Instigator && Instigator != None)
	{
		InstigBeamSize = BeamSize - VSize(HitLocation - Location);
		HitActor = Instigator.Trace(HitLocation, HitNormal, HitLocation + InstigBeamSize * X, Location, true);
	}
		
	if ( (HitActor != None) && (HitActor != Instigator)
		&& (HitActor.bProjTarget || (HitActor == Level) || (HitActor.bBlockActors && HitActor.bBlockPlayers)) 
		&& ((Pawn(HitActor) == None) || Pawn(HitActor).AdjustHitLocation(HitLocation, Velocity)) )
	{
		if ( Level.Netmode != NM_Client )
		{
			if ( DamagedActor == None )
			{
				AccumulatedDamage = FMin(0.5 * (Level.TimeSeconds - LastHitTime), 0.1);
				HitActor.TakeDamage(damage * AccumulatedDamage, instigator,HitLocation,
					(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				AccumulatedDamage = 0;
			}			  
			else if ( DamagedActor != HitActor )
			{
				DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator,HitLocation,
					(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				AccumulatedDamage = 0;
			}			  
			LastHitTime = Level.TimeSeconds;
			DamagedActor = HitActor;
			AccumulatedDamage += DeltaTime;
			if ( AccumulatedDamage > 0.22 )
			{
				if ( DamagedActor.IsA('Carcass') && (FRand() < 0.09) )
					AccumulatedDamage = 35/damage;
				DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator,HitLocation,
					(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				AccumulatedDamage = 0;
			}
		}
		if ( HitActor.bIsPawn && Pawn(HitActor).bIsPlayer )
		{
			if ( WallEffect != None )
				WallEffect.Destroy();
		}
		else if ( (WallEffect == None) || WallEffect.bDeleteMe )
			WallEffect = Spawn(class'PlasmaHit',,, HitLocation - 5 * X);
		else if ( !WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();   
			WallEffect = Spawn(class'PlasmaHit',,, HitLocation - 5 * X);
		}
		else
			WallEffect.SetLocation(HitLocation - 5 * X);

		if ( (WallEffect != None) && (Level.NetMode != NM_DedicatedServer) )
			Spawn(ExplosionDecal,,,HitLocation,rotator(HitNormal));

		if ( PlasmaBeam != None )
		{
			AccumulatedDamage += PlasmaBeam.AccumulatedDamage;
			PlasmaBeam.Destroy();
			PlasmaBeam = None;
		}

		return;
	}
	else if ( (Level.Netmode != NM_Client) && (DamagedActor != None) )
	{
		DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator, DamagedActor.Location - X * 1.2 * DamagedActor.CollisionRadius,
			(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
		AccumulatedDamage = 0;
		DamagedActor = None;
	}		  


	if ( Position >= 9 )
	{   
		if ( (WallEffect == None) || WallEffect.bDeleteMe )
			WallEffect = Spawn(class'PlasmaCap',,, Location + (BeamSize - 4) * X);
		else if ( WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();   
			WallEffect = Spawn(class'PlasmaCap',,, Location + (BeamSize - 4) * X);
		}
		else
			WallEffect.SetLocation(Location + (BeamSize - 4) * X);
	}
	else
	{
		if ( WallEffect != None )
		{
			WallEffect.Destroy();
			WallEffect = None;
		}
		if ( PlasmaBeam == None )
		{
			PlasmaBeam = Spawn(class'sgPBolt',,, Location + BeamSize * X); 
			PlasmaBeam.Position = Position + 1;
		}
		else
			PlasmaBeam.UpdateBeam(self, X, DeltaTime);
	}
}

simulated function UpdateBeam(sgPBolt ParentBolt, vector Dir, float DeltaTime)
{
	SpriteFrame = ParentBolt.SpriteFrame;
	Skin = SpriteAnim[SpriteFrame];
	SetLocation(ParentBolt.Location + BeamSize * Dir);
	SetRotation(ParentBolt.Rotation);
	CheckBeam(Dir, DeltaTime);
}

defaultproperties
{
	SpriteAnim(0)=Texture'Botpack.Skins.PBolt0'
	SpriteAnim(1)=Texture'Botpack.Skins.PBolt1'
	SpriteAnim(2)=Texture'Botpack.Skins.PBolt2'
	SpriteAnim(3)=Texture'Botpack.Skins.PBolt3'
	SpriteAnim(4)=Texture'Botpack.Skins.PBolt4'
	FireOffset=(X=16.000000,Y=-14.000000,Z=-8.000000)
	BeamSize=81.000000
	bRight=True
	MaxSpeed=0.000000
	Damage=72.000000
	MomentumTransfer=8500
	MyDamageType=zapped
	ExplosionDecal=Class'Botpack.BoltScorch'
	bNetTemporary=False
	Physics=PHYS_None
	RemoteRole=ROLE_None
	LifeSpan=60.000000
	AmbientSound=Sound'Botpack.PulseGun.PulseBolt'
	Style=STY_Translucent
	Texture=Texture'Botpack.Skins.PBolt0'
	Skin=Texture'Botpack.Skins.PBolt0'
	Mesh=LodMesh'Botpack.PBolt'
	bUnlit=True
	SoundRadius=12
	SoundVolume=255
	bCollideActors=False
	bCollideWorld=False
}
