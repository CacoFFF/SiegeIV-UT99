class sgSupplierQueuer expands SiegeActor;

var float SupplierRadius;
var Pawn POwner;
var sgEquipmentSupplier Master;
var sgSupplierQueuer nextQueuer;

var float AccumulatedHealth;
var float AccumulatedArmor;
var float AccumulatedAmmo; //0 to 1 | can go above 1
var bool bSupplyFull;

//Default sgSupplier radius is 60
function Setup( sgEquipmentSupplier aS, Pawn NewP)
{
	local sgSupplierQueuer aQ;

	Master = aS;
	POwner = NewP;
	SupplierRadius = Master.SupplyRadius + POwner.CollisionRadius;

	nextQueuer = Master.QueuerList; //Attach to chain
	Master.QueuerList = self;
}

event Tick( float DeltaTime)
{
	if ( (POwner == none) || POwner.bDeleteMe || POwner.Health <= 0 )
		Destroy();
	else if ( VSize(POwner.Location - Master.Location) > SupplierRadius )
	{
		//Notify the trigger box the player left
		Destroy();
	}
}

//Destroys unneeded accumulators and returns amount in chain
function int AccumulatorCount()
{
	local int Count;
	local sgSupplierQueuer Acc, NextAcc;
	
	for ( Acc=self ; Acc!=None ; Acc=NextAcc )
	{
		NextAcc = Acc.nextQueuer;
		Acc.bSupplyFull = false;
		Acc.Tick(0);
		Count += int( !Acc.bDeleteMe );
	}
	return Count;
}

function bool AddHealth( float HealthAmount, int HealthLimit)
{
	if ( (HealthLimit > 0) && (POwner.Health < HealthLimit) )
	{
		AccumulatedHealth += HealthAmount;
		if ( AccumulatedHealth >= 1 )
		{
			POwner.Health = Min( POwner.Health + int(AccumulatedHealth), HealthLimit);
			AccumulatedHealth -= int(AccumulatedHealth);
		}
		return true;
	}
}

function bool AddArmor( float ArmorAmount, int ArmorLimit)
{
	local Inventory Armor;

	if ( ArmorLimit > 0 )
	{
		Armor = POwner.FindInventoryType( class'sgArmor');
		if ( Armor == None )
			Armor = Master.SpawnArmor( POwner);
		if ( Armor.Charge < ArmorLimit )
		{
			AccumulatedArmor += ArmorAmount;
			if ( (AccumulatedArmor >= 1) && (Armor != None) )
			{
				Armor.Charge = Min( Armor.Charge + int(AccumulatedArmor), ArmorLimit);
				AccumulatedArmor -= int(AccumulatedArmor);
			}
			return true;
		}
	}
}


event Destroyed()
{
	local sgSupplierQueuer aQ;
	if ( Master == none || Master.bDeleteMe )
		return;

	if ( Master.QueuerList == self )
		Master.QueuerList = nextQueuer;
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