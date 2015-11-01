//=============================================================================
// FlameProjectile
// by SK
//=============================================================================
class FlameProjectile extends Projectile;

#exec OBJ LOAD File=Extro.uax

var float SmokeRate;
var	redeemertrail trail;
var() float health;
var name MyDamageType;

replication
{
	// Things the server should send to the client.
	reliable if ( Role == ROLE_Authority )
		health;
}

simulated function Timer()
{
	Spawn(class'FlameParticle');
	SmokeRate = 152/Speed; 
	SetTimer(SmokeRate, false);
}

simulated function Destroyed()
{
	if ( Trail != None )
		Trail.Destroy();
	Super.Destroyed();
}

simulated function PostBeginPlay()
{
	SmokeRate = 0.1;
	SetTimer(0.0001,false); 
}

auto state Flying
{
	function ProcessTouch (Actor Other, Vector HitLocation)
	{	
		if ( Other != instigator ) 
			Explode(HitLocation,Normal(HitLocation-Other.Location));
	}
	
	function Explode(vector HitLocation, vector HitNormal)
	{
	
		local sgBuilding building;
		local PlayerPawn victim;
	
		if ( Role < ROLE_Authority )
			return;
			
		Spawn(Class'Botpack.FlameExplosion');

		foreach RadiusActors(class'sgBuilding', building, 64)
		
		if (building.Team != instigator.PlayerReplicationInfo.Team)
		building.Incinerate(instigator,HitLocation,HitNormal);
		
		foreach RadiusActors(class'PlayerPawn', victim, 64)
		
		if (victim.PlayerReplicationInfo.Team != instigator.PlayerReplicationInfo.Team)
		victim.TakeDamage(40, instigator, location, location, MyDamageType);
		
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
     Health=4000.000000
     speed=2048.000000
     Damage=0
     MomentumTransfer=0
     MyDamageType=Burned
	 ExplosionDecal=Class'Botpack.BlastMark'
     bNetTemporary=False
     RemoteRole=ROLE_SimulatedProxy
     AmbientSound=Sound'flamesound'
     Mesh=None
     AmbientGlow=78
     bUnlit=True
     SoundRadius=128
     SoundVolume=255
	 SoundPitch=48
     CollisionRadius=22.000000
     CollisionHeight=14.000000
     bProjTarget=True
}