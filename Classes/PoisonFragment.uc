//=============================================================================
// PoisonCloud.
//=============================================================================
class PoisonFragment expands PoisonCloud;

var float SpeedFallOff;
var vector InitialVel;
var float NormalizedFalloff;
var ToxicSpawner Master;

function InitSpeed( float InitialSpeed, float EndSpeed, float Timer)
{
	InitialVel = vector(Rotation) * InitialSpeed;
	NormalizedFalloff = (InitialSpeed - EndSpeed) / Timer;
	SpeedFalloff = Timer;

	Velocity += InitialVel;
}

event Tick( float DeltaTime)
{
	if ( SpeedFallOff <= 0 )
		return;

	Velocity -= Normal(InitialVel) * NormalizedFalloff * DeltaTime;
	SpeedFallOff -= DeltaTime;
}

function Timer()
{
	if ( (Level.NetMode != NM_Client) && (CurrentFrame % 3 == 0) )
		PoisonRadius( fMin(31 - CurrentFrame, 20) * 0.5, 70 + CurrentFrame * 5 );

	Super.Timer();
}

function PoisonRadius( float DamageAmount, float DamageRadius )
{
	local Pawn Victims;
	local float dist;
	local int aHealth;

	foreach VisibleCollidingActors( class 'Pawn', Victims, DamageRadius )
	{
		aHealth = Victims.Health;
		if ( Victims.IsA('sgBuilding') )
			Victims.TakeDamage ( DamageAmount * 0.8, Instigator, vect(0,0,0), vect(0,0,0), 'Corroded');
		else
		{
			Victims.TakeDamage ( DamageAmount-2, Instigator, vect(0,0,0), vect(0,0,0), 'Corroded');
			Victims.TakeDamage ( 1, Instigator, vect(0,0,0), vect(0,0,0), 'Corroded');
			Victims.TakeDamage ( 1, Instigator, vect(0,0,0), vect(0,0,0), 'Corroded');
		}
		if ( (aHealth != Victims.Health) && !Master.AlreadyPoisoned(Victims) )
		{
			Master.Poisoned[Master.iPoisoned] = Spawn(Class'PoisonPlayer', Owner, , Location);
			Master.Poisoned[Master.iPoisoned].PoisonedPlayer = Victims;
			Master.Poisoned[Master.iPoisoned].Slowness = 1 + DamageAmount / 7; //4 to 1
			Master.Poisoned[Master.iPoisoned++].RecoverRate = 0.700 - DamageAmount / 60; //0.2 to 0.7
		}
	}
}

function HitWall( vector HitNormal, actor Wall )
{
	Velocity -= (Velocity * (-HitNormal)) * 1.2;
	SpeedFallOff = 0;
}

defaultproperties
{
     AnimationLength=5.000000
     RemoteRole=ROLE_None
     Physics=PHYS_Projectile
     bBounce=True
     bMovable=True
     bCollideWorld=True
     DrawScale=2
}
