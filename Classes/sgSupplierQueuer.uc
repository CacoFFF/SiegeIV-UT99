class sgSupplierQueuer expands Info;

var float SupplierRadius;
var pawn POwner;
var sgEquipmentSupplier Master;
var sgSupplierQueuer nextQueuer;
var float QueueTime;

//Default sgSupplier radius is 60
function Setup( sgEquipmentSupplier aS, pawn NewP)
{
	local sgSupplierQueuer aQ;

	Master = aS;
	POwner = NewP;
	SupplierRadius = Master.SupplyRadius + POwner.CollisionRadius;
	QueueTime = Master.RotationTime;

	//Add to the end of the queuer list, this player just arrived to supplier
	if ( Master.QueuerList == none )
	{
		Master.QueuerList = self;
		Master.QueuerTimer = QueueTime;
	}
	else
	{
		aQ = Master.QueuerList;
		While ( aQ.nextQueuer != none )
			aQ = aQ.nextQueuer;
		aQ.nextQueuer = self;
	}	
}

event Tick( float DeltaTime)
{
	if ( (POwner == none) || POwner.bDeleteMe )
		Destroy();
	else if ( VSize(POwner.Location - Master.Location) > SupplierRadius )
	{
		//Notify the trigger box the player left
		Destroy();
	}
}

//ONLY CALL THIS IF I AM THE MAIN QUEUER!!!!
//IGNORING SANITY CHECKS DUE TO SPEED REASONS
function Push()
{
	local sgSupplierQueuer aQ;
	
	Master.QueuerList = nextQueuer;
	Master.QueuerTimer = QueueTime;
	aQ = nextQueuer;
	While( aQ.nextQueuer != none )
		aQ = aQ.nextQueuer;
	aQ.nextQueuer = self;
	nextQueuer = none;
}

event Destroyed()
{
	local sgSupplierQueuer aQ;
	if ( Master == none || Master.bDeleteMe )
		return;

	if ( Master.QueuerList == self )
	{
		Master.QueuerList = nextQueuer;
		Master.QueuerTimer = QueueTime;
	}
	else
	{
		For ( aQ=Master.QueuerList ; aQ.nextQueuer!=none ; aQ=aQ.nextQueuer )
			if ( aQ.nextQueuer == self )
			{
				aQ.nextQueuer = nextQueuer;
				break;
			}
	}
	Master = none;
}

defaultproperties
{
    RemoteRole=ROLE_None
}