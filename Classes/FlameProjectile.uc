//=============================================================================
// FlameProjectile
// by SK
//
// Higor changelog:
// - Got rid of useless variables.
// - Disconnected players cannot incinerate builds
// - Spawns less sprites on low framerates
// - Set bNetTemporary=True
// - Can only incinerate one target
// - TakeDamage applied on all Pawns
// - Victim lookup rules changed
// ** from: Radius=(64+Victim.CollisionRadius)
// ** to: Touching OR (Radius=72+Victim.CollisionRadius AND visible)
// - Base damage changed to 20 (from 40)
// - Another 20 damage instance is dealt to the Actor that touches the projectile
// ** Can now hit triggers, open doors, destroy decorations...
//=============================================================================
class FlameProjectile extends Projectile;

#exec OBJ LOAD File=Extro.uax

simulated function Timer()
{
	//Need to recycle this!!!
	Spawn(class'FlameParticle');
	if ( Level.bDropDetail )
		SetTimer( 250.f/Speed, false);
	else
		SetTimer( 125.f/Speed, false); 
}


simulated function PostBeginPlay()
{
	SetTimer(0.0001,false); 
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{	
		if ( Other != Instigator ) 
		{
			if ( Role == ROLE_Authority && Instigator != none && !Instigator.bDeleteMe )
			{
				Other.TakeDamage( 20, Instigator, Location, vect(0,0,0), 'Burned');
				//Add incineration to players here later...
			}
			if ( !bDeleteMe ) //Touch may happen more than once
				Explode(HitLocation,Normal(HitLocation-Other.Location));
		}
	}
	
	simulated function Explode(vector HitLocation, vector HitNormal)
	{
	
		local sgBuilding sgB, sgBurn;
		local float Dist, BestDist;
		local Pawn P;
		local bool bOverlapping;
		local byte Team;
	
		Spawn(Class'Botpack.FlameExplosion').RemoteRole = ROLE_None;

		//Do nothing if instigator is gone
		if ( Role == ROLE_Authority && Instigator != none && !Instigator.bDeleteMe )
		{
			BestDist = 999999.f;
			Team = 255;
			if ( Instigator.PlayerReplicationInfo != none )
				Team = Instigator.PlayerReplicationInfo.Team;
			ForEach RadiusActors( class'Pawn', P, 72)
			{
				//Visible or overlap
				bOverlapping = class'SiegeStatics'.static.ActorsTouching( self, P);
				if ( bOverlapping || FastTrace(P.Location) )
				{
					sgB = sgBuilding(P);
					if ( (sgB != none) && !sgB.bIsOnFire && sgB.CanIncinerate( Instigator) )
					{
						Dist = VSize( Location - sgB.Location);
						if ( Dist < BestDist )
						{
							BestDist = Dist;
							sgBurn = sgB;
						}
					}
					if ( P.Health > 0 && P.bCollideActors && P.bProjTarget ) //Hittable pawn
						P.TakeDamage( 10, Instigator, Location, vect(0,0,0), 'Burned');
				}
			}
			if ( sgBurn != none )
				sgBurn.Incinerate( Instigator, HitLocation, HitNormal);
		}
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
     speed=2048.000000
     Damage=0
     MomentumTransfer=0
	 ExplosionDecal=Class'Botpack.BlastMark'
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
     AmbientSound=Sound'flamesound'
     Mesh=None
     AmbientGlow=78
     bUnlit=True
     SoundRadius=128
     SoundVolume=255
	 SoundPitch=48
     CollisionRadius=24.000000
     CollisionHeight=14.000000
     bProjTarget=True
	 LifeSpan=2.2
}