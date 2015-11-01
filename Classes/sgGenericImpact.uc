//*****************************************************************************
// Global handle that corrects a translocator target's impact before first land
// By Higor
//*****************************************************
class sgGenericImpact expands SiegeActor;

var actor Impacted;
var float NewVelX, NewVelY, NewVelZ; //Passed using full 32 bit precision
var float NewLocX, NewLocY, NewLocZ;
var EPhysics NewPhysics;

replication
{
	reliable if ( Role==ROLE_Authority )
		Impacted, NewVelX, NewVelY, NewVelZ, NewLocX, NewLocY, NewLocZ, NewPhysics;
}

function Setup( actor NewI)
{
	Impacted = NewI;
	SetTimer(0.001, false); //Wait a frame before replicating, we need to ensure proper velocity application first
}

event Timer()
{
	if ( Impacted == none )
		return;
	NewVelX = Impacted.Velocity.X;
	NewVelY = Impacted.Velocity.Y;
	NewVelZ = Impacted.Velocity.Z;
	NewLocX = Impacted.Location.X;
	NewLocY = Impacted.Location.Y;
	NewLocZ = Impacted.Location.Z;
	NewPhysics = Impacted.Physics;
	RemoteRole = ROLE_DumbProxy; //Become relevant now
}

simulated event PostNetBeginPlay()
{
	local vector aVec;
	if ( Impacted != none )
	{
		aVec.X = NewLocX;
		aVec.Y = NewLocY;
		aVec.Z = NewLocZ;
		Impacted.SetLocation( aVec );
		aVec.X = NewVelX;
		aVec.Y = NewVelY;
		aVec.Z = NewVelZ;
		Impacted.Velocity = aVec;
		Impacted.SetPhysics( NewPhysics);
	}
}


defaultproperties
{
    bHidden=false
    RemoteRole=ROLE_None
    DrawType=DT_None
    bNetTemporary=True
    LifeSpan=0.5
}
