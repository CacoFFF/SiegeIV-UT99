//*****************************************************************************
// Global handle that corrects a translocator target's impact before first land
// By Higor
//*****************************************************
class sgGenericImpact expands SiegeActor;

var Actor Impacted;
var float NewVelX, NewVelY, NewVelZ; //Passed using full 32 bit precision
var EPhysics NewPhysics;

replication
{
	reliable if ( Role==ROLE_Authority )
		Impacted, NewVelX, NewVelY, NewVelZ, NewPhysics;
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
	SetLocation( Impacted.Location);
	NewPhysics = Impacted.Physics;
	RemoteRole = ROLE_DumbProxy; //Become relevant now
}

simulated event PostNetBeginPlay()
{
	local vector aVec;
	if ( Impacted != none )
	{
		Impacted.SetLocation( Location );
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
