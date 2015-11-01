//=============================================================================
// sgItemSpawner.
//=============================================================================
class sgItemSpawner extends sgBuilding;

var() class<Actor>  ItemClass;
var() int           ItemCount,      // Total number of items to spawn
                    SpawnRate,      // Amount of items to spawn each time
                    RateVariance;   // Amount to vary SpawnRate by
var() float         SpawnChance,    // Probability of spawning each Timer call
                    Speed,          // Amount to normalize final velocity by
                                    //   Use -1 for no normalization
                    SpeedVariance;  // Amount to vary speed by
                                    //   (FinalSpeed = Speed +/- SpeedVariance)
var() vector        StartVel;       // Start velocity relative to spawn
                                    //   direction
var() float         VerticalVel,    // Initial, absolute vertical velocity
                    Spread,         // Spread velocity
                    SpawnRadius;    // Distance from center to spawn
                                    //   objects (useful to avoid
                                    //   collisions between newly
                                    //   spawned objects

simulated event Timer()
{
    local Actor     newActor;
    local int       i,
                    num;
    local vector    randVector,
                    spawnVelocity;

    Super.Timer();

    if ( SCount > 0 || Role != ROLE_Authority )
        return;

    if ( FRand() > SpawnChance )
        return;

	if ( Pawn(Owner) == none )
	{
		DestructionAnnounce = ANN_None;
		Destruct();
		return;
	}
	
	if ( SpawnRate > 0 )
		num = SpawnRate + int((FRand()*2-1) * RateVariance);
	else
		num = ItemCount;

	for ( i = 0; i < num; i++ )
	{
		randVector = VRand();

		spawnVelocity = (StartVel>>Rotation) + Spread*randVector;
		spawnVelocity.Z += VerticalVel;
		if ( Speed > 0 && VSize(spawnVelocity) != 0 )
			spawnVelocity *= (Speed + SpeedVariance * (FRand()*2-1)) / VSize(spawnVelocity);

		newActor = Spawn(ItemClass, Owner,, Location + Normal(spawnVelocity) * SpawnRadius, rotator(spawnVelocity));

		if ( newActor != None )
		{
			if ( Owner == none || Owner.bDeleteMe )
				newActor.Instigator = self;
			else
				newActor.Instigator = Pawn(Owner);
			newActor.Velocity = spawnVelocity;
			SpawnedItem(newActor);
		}

		ItemCount--;
		if ( ItemCount <= 0 )
		{
			DestructionAnnounce = ANN_None;
			Destruct();
			return;
        }
	}
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();
	bNoRemove = true;
}


event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType )
{
	if ( instigatedBy != Owner || Owner == None )
		Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
}

function Upgraded();

function SpawnedItem(Actor newActor);

defaultproperties
{
     ItemCount=1
     SpawnChance=1.000000
     UpgradeCost=0
     BuildTime=10.000000
     MaxEnergy=200.000000
     SpriteScale=0.400000
     SkinRedTeam=None
     SkinBlueTeam=None
     MultiSkins(0)=Texture'ProtectorSpriteTeam0'
     MultiSkins(1)=Texture'ProtectorSpriteTeam1'
     MultiSkins(2)=Texture'ProtectorSpriteTeam2'
     MultiSkins(3)=Texture'ProtectorSpriteTeam3'
}
