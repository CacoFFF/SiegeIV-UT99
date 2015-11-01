///////////////////
// Supplier component actor
//
// Holds individual info on the supplier's toucher
// Made by Higor
///////////////////
class XC_SupComp expands Info;

var XC_SupplierBase RelatedSup;
var float CountDown;
var float SimCountDown;
var XC_SupComp nextComp;
var bool bDied;

replication
{
	reliable if ( ROLE==ROLE_Authority )
		CountDown;
	reliable if ( bNetInitial && ROLE==ROLE_Authority )
		RelatedSup;
}

simulated event PostNetBeginPlay()
{
	if ( RelatedSup != none )
		RelatedSup.localComp = self;
}

simulated event Tick( float DeltaTime)
{
	if ( Pawn(Owner) == none || Owner.bDeleteMe )
	{
		Destroy();
		return;
	}

	if ( Level.NetMode == NM_Client )
	{
		SimCountDown -= DeltaTime / Level.TimeDilation;
	}
	else
	{
		if ( !bDied && (Pawn(Owner).Health <= 0) )
		{
			CountDown -= RelatedSup.DeathDeduction;
			bDied = true;
		}
		CountDown -= DeltaTime / Level.TimeDilation;
		SimCountDown = CountDown;
		if ( CountDown <= 0 )
			Destroy();
	}
}

simulated event Destroyed()
{
	local XC_SupComp aS;

	if ( (RelatedSup != none) && (RelatedSup.localComp == self) )
		RelatedSup.localComp = none;

	if ( Level.NetMode == NM_Client )
		return;

	if ( (RelatedSup != none) && !RelatedSup.bDeleteMe )
	{
		if ( RelatedSup.compList == self )
			RelatedSup.compList = nextComp;
		else
		{
			For ( aS=RelatedSup.compList ; aS!=none ; aS=aS.nextComp )
				if ( aS.nextComp == self )
				{
					aS.nextComp = nextComp;
					break;
				}
		}
		if ( (Owner != none) && ActorsTouching( Owner, RelatedSup) )
			RelatedSup.Touch( Owner);
	}
	RelatedSup = none;
}

static final function bool ActorsTouching( actor A, actor B)
{
	local vector aVec;

	aVec = A.Location - B.Location;
	if ( abs(aVec.Z) > (A.CollisionHeight + B.CollisionHeight) )
		return false;
	return class'XC_SupplierBase'.static.HSize(aVec) < (A.CollisionRadius + B.CollisionRadius);
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
}