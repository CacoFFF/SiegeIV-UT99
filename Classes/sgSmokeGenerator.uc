//=============================================================================
// sgSmokeGenerator
// Endless generation
//=============================================================================
class sgSmokeGenerator extends SmokeGenerator;

var bool bEnabled; //We use this as marker

Auto State Active
{
	function Timer()
	{
	}
	
	function SpawnSmoke()
	{
		local Effects d;
		
		d = Spawn(GenerationType);
		d.DrawScale = BasePuffSize+FRand()*SizeVariance;	
		d.RemoteRole = ROLE_None;
		if (SpriteSmokePuff(d)!=None)
			SpriteSmokePuff(d).RisingRate = RisingVelocity;	
	}


	function Trigger( actor Other, pawn EventInstigator )
	{
	}


	function UnTrigger( actor Other, pawn EventInstigator )
	{
	}

Begin:
	if ( (Owner == none) || Owner.bDeleteMe )
		Destroy();
	Sleep(SmokeDelay+FRand()*SmokeDelay);
	if ( class'sgClient'.default.bHighPerformance )
		Sleep( SmokeDelay * 2);
	if ( bEnabled )
		SpawnSmoke();
	DrawType = DT_None;
	Goto('Begin');
}

defaultproperties
{
RemoteRole=ROLE_None
CollisionHeight=4
CollisionRadius=4
BasePuffSize=8.000000
bRepeating=True
GenerationType=Class'UnrealShare.SpriteSmokePuff'
RisingVelocity=128
SizeVariance=1.000000
SmokeDelay=0.25
TotalNumPuffs=1316134911
}