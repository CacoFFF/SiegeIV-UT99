//=============================================================================
// NeutronExplosion
// by SK
//=============================================================================
class NeutronExplosion extends Projectile;

#exec OBJ LOAD File=DDay.uax

var() float health;

replication
{
	// Things the server should send to the client.
	reliable if ( Role == ROLE_Authority )
		health;
}

function PostBeginPlay()
{
Super.PostBeginPlay();
}

auto state Flying
{

function ProcessTouch (Actor Other, Vector HitLocation)
	{
			Explode(HitLocation,Normal(HitLocation-Other.Location));
	}
	
singular function TakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation, 
						vector momentum, name damageType )
{
	health-=NDamage;

	if ( health <= 0 )
	{
		Explode(location, vector(rotation));
		RemoteRole = ROLE_SimulatedProxy;	 		 		
 		Destroy();
	}
}

function Explode(vector HitLocation, vector HitNormal)
{

if ( Role < ROLE_Authority )
			return;
	 	
		PlaySound(ImpactSound, SLOT_None, 20,,10000,1+(FRand()*0.3-0.15));
		PlaySound(MiscSound, SLOT_None, 20,,7500);
		spawn(class'NeutronRings',,,HitLocation+ HitNormal*16, rotator(hitnormal));
		spawn(class'NeutronBall',,,HitLocation+ HitNormal*16, rotator(hitnormal));
 		spawn(class'NeutronFlash',,,HitLocation+ HitNormal*16, rotator(hitnormal));
		spawn(class'NeutronWave',,,HitLocation+ HitNormal*16, rotator(hitnormal));
		spawn(class'NeutronCloud');
		spawn(class'LongFlash');
		RemoteRole = ROLE_SimulatedProxy;	 		 		
 		Destroy();
}

function BeginState()
	{
		local vector InitialDir;

		initialDir = vector(Rotation);
		if ( Role == ROLE_Authority )	
			Velocity = speed*initialDir;
		Acceleration = initialDir*50;
	}

}

defaultproperties
{
     speed=750.000000
     Damage=1600.000000
     MomentumTransfer=100000
     MyDamageType=RedeemerDeath
     ImpactSound=Sound'kaboom2'
     MiscSound=Sound'kaboom2'
     ExplosionDecal=Class'Botpack.NuclearMark'
     bNetTemporary=False
     RemoteRole=ROLE_SimulatedProxy
     bUnlit=True
	 Mesh=LodMesh'Botpack.shellM'
	 DrawScale=6.0
	 Skin=Texture'Botpack.JTUTOT4'
	 Texture=Texture'Botpack.JTUTOT4'
	 Style=STY_Normal
	 AmbientSound=Sound'DDay.whistle1'
     SoundRadius=255
     SoundVolume=255
     CollisionRadius=8.000000
     CollisionHeight=24.000000
     bProjTarget=True
}