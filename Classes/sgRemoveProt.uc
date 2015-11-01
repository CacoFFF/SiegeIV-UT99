class sgRemoveProt expands Inventory;

var int Count;
var int Frequency;
var Pawn PlayerOwner;

function Activate()
{
	PlayerOwner = Pawn(Owner);
	SetTimer(1, true);
	AddRemove();
}

function AddRemove()
{
	Frequency++;
}

function bool ExcessRemove()
{
	
	if (Frequency>=Charge)
		return true;
	return false;
}

function bool RemoveWarning()
{
	if (Frequency>=(Charge/2))
		return true;
	return false;
}

function Timer()
{	
	if ( Level.Game.bGameEnded || PlayerOwner == None || !PlayerOwner.bIsPlayer )
		Destroy();

	Count++;
	if (Count >= FlashCount)
		Destroy();
}

defaultproperties
{
     Charge=4
     FlashCount=10
}
