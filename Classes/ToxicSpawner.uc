//Intermediate class that spawns toxin clientside
class ToxicSpawner expands SiegeActor;


const MULTIPLIER = 0x015a4e35;
const INCREMENT = 1;
var int RandomSeed, BaseSeed;

var PoisonPlayer Poisoned[16];
var int iPoisoned;

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
	local PoisonFragment Frag;
	Spawn(class'GreenCloudEffect');
	PlaySound(sound'PoisonGasHiss',,4.0);
	While ( ++i <= 12 )
	{
		Frag = Spawn( class'PoisonFragment', Owner,,Location, rotator(VRand_Seed()));
		Frag.Instigator = Instigator;
		Frag.InitSpeed( 900, 70 + fRandom_Seed(20), 0.4 + fRandom_Seed(0.2) );
		Frag.Master = self;
		Spawn(class'GreenCloudEffect');
	}
	//Center point, to avoid center non-damage
	Frag = Spawn( class'PoisonFragment', Owner,,Location);
	Frag.Instigator = Instigator;
	Frag.Master = self;
	Spawn(class'GreenCloudEffect');
}

simulated event Tick( float Delta)
{
	local float EffectTimer;

	if ( bHidden )
		return;
	
	EffectTimer = fMax(0, LifeSpan - (Default.LifeSpan-1f) );
	if ( EffectTimer < 0 ) //No longer relevant
	{
		bHidden = true;
		bAlwaysRelevant = false;
		Disable('Tick');
		return;
	}
	DrawScale = Default.DrawScale * (2 - EffectTimer);
	ScaleGlow = EffectTimer;
}

simulated function Vector VRand_Seed()
{
	return vect(1,0,0) * fRandom_Seed(1) + vect(0,1,0) * fRandom_Seed(1) + vect(0,0,0.7) * fRandom_Seed(1);
}

//Ranges from -1 to 1
simulated function float fRandom_Seed( optional float Scale)
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

function bool AlreadyPoisoned( Pawn Other)
{
	local int i;

	While ( i < iPoisoned )
	{
		if ( (Poisoned[i] == none) || Poisoned[i].bDeleteMe )
		{
			iPoisoned--;
			if ( i != iPoisoned )
				Poisoned[i] = Poisoned[iPoisoned];
			else
				Poisoned[i] = none;
			continue;
		}
		if ( Poisoned[i].PoisonedPlayer == Other )
			return true;
		i++;
	}
	return false;
}

defaultproperties
{
	bHidden=False
	bAlwaysRelevant=True
	bNetTemporary=True
	RemoteRole=ROLE_SimulatedProxy
	LifeSpan=5.5
	Texture=Texture'sgWarSpriteT2'
	Style=STY_Translucent
	DrawScale=1
	bUnlit=True
}