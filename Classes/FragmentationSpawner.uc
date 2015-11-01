//Intermediate class that spawns fragments clientside
class FragmentationSpawner expands SiegeActor;


const MULTIPLIER = 0x015a4e35;
const INCREMENT = 1;
var int RandomSeed, BaseSeed;

replication
{
	reliable if ( Role == ROLE_Authority )
		BaseSeed;
}

event PreBeginPlay()
{
	RandomSeed = Rand(0x7FFF);
	BaseSeed = RandomSeed;
	Super.PreBeginPlay();
}

event PostBeginPlay()
{
	FragmentateNow();
}

simulated event PostNetBeginPlay()
{
	RandomSeed = BaseSeed;
	FragmentateNow();
}

simulated function FragmentateNow()
{
	local int i;
	local APE_Chunk4_norand Chunk;
	local FlameExplosion F;

	PlaySound( Sound'Unreali.CannonExplode', SLOT_Misc, 1.7,, 1450 );
	F = Spawn( class'FlameExplosion');
	if ( F != none )
	{
		F.DrawScale = 2.2;
		F.RemoteRole = ROLE_None;
	}

	While ( ++i <= 40 )
	{
		Chunk = Spawn( class'APE_Chunk4_norand',,,Location, rotator(VRand_Seed()));
		Chunk.DrawScale *= 0.8;
		Chunk.RemoteRole = ROLE_None;
	}
	SetTimer(1,false);
}

simulated event Timer()
{
	Destroy();
}

simulated function Vector VRand_Seed()
{
	return vect(1,0,0) * fRandom_Seed(1) + vect(0,1,0) * fRandom_Seed(1) + vect(0,0,0.5) * fRandom_Seed(1);
}

//Ranges from -1 to 1
simulated function float fRandom_Seed(float Scale)
{
	local int aRs;
	local float Result;

	if ( Scale == 0 )
		Scale = 1;

	RandomSeed = MULTIPLIER * RandomSeed + INCREMENT;
	aRs = ((RandomSeed >>> 16) & 65535) - 32768; //Sign is kept, precision increased
//	Log("Seed is now: "$RandomSeed@" aRs is: "$aRs);
	Result = Scale * aRs / 32768f;
	return Result;
}


defaultproperties
{
	bAlwaysRelevant=True
	bNetTemporary=True
	RemoteRole=ROLE_SimulatedProxy
}