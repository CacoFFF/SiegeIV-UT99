// Class B suit (class A is unreal suits)
// Player can only wear 1 suit of each class

class sgSuit expands TournamentPickup
	abstract;

var texture EnviroSkin;
var float aTimer;
var bool bNoMines;
var bool bNoProtectors;
var Weapon AffectedWeapon;
var Texture HUD_Icon; //For new sgHUD icon methodology

function sgSuit OtherSuit( Pawn P)
{
	local inventory I;

	For ( I=P.Inventory ; I!=none ; I=I.inventory )
	{
		if ( I.IsA('sgSuit') )
			return sgSuit(I);
	}
	return none;
}

function ChangedWeapon()
{
	if( Inventory != None )
		Inventory.ChangedWeapon();
		
	if ( AffectedWeapon != none )
	{
		AffectedWeapon.SetDefaultDisplayProperties();
		AffectedWeapon = Pawn(Owner).Weapon;
		if ( !AffectedWeapon.bMeshEnviroMap )
			AffectedWeapon.SetDisplayProperties(ERenderStyle.STY_Normal,EnviroSkin,true,true);
	}
}

function SetOwnerDisplay()
{
	ApplySkin();

	if( Inventory != None )
		Inventory.SetOwnerDisplay();
}

//Can be subdefined
function ApplySkin()
{
	local Pawn P;

	P = GetOwner();
	if ( (EnviroSkin == none) || (P == none) )
		return;

	if ( P.bMeshEnviroMap ) //Already has skin, don't override
		return;

	P.SetDisplayProperties(ERenderStyle.STY_Normal,EnviroSkin,true,true);
	AffectedWeapon = P.Weapon;
	if ( (AffectedWeapon != none) && !AffectedWeapon.bMeshEnviroMap )
		AffectedWeapon.SetDisplayProperties(ERenderStyle.STY_Normal,EnviroSkin,true,true);
}


function RemoveSkin()
{
	local pawn P;

	P = GetOwner();
	if ( (EnviroSkin == none) || (P == none) )
		return;

	Instigator = none; //Make sure we don't repeat this call
	P.SetDefaultDisplayProperties();
}

event Destroyed()
{
	Super.Destroyed();
	RemoveSkin();
	aTimer = -99;
	if ( AffectedWeapon != none )
	{
		AffectedWeapon.SetDefaultDisplayProperties();
		AffectedWeapon = none;
	}
}

function PickupFunction(Pawn Other)
{
	local Inventory I;

	if ( Owner == none )
		SetOwner( Other);

	For ( I=Other.Inventory ; I!=none ; I=I.inventory )
	{
		if ( (sgSuit(I) != none) && (I!=self) )
		{
			I.Destroy(); //Returns skin back to normal?
			break;
		}
	}

	Super.PickupFunction( Other);
	ApplySkin();
	aTimer = 0;
}


function bool HandlePickupQuery( inventory Item )
{
	local inventory S;

	if (item.class == class) //Restock up to 200%
	{
			Charge = Default.Charge + Charge/2;

			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
			if ( Item.PickupMessageClass == None )
				Pawn(Owner).ClientMessage(item.PickupMessage, 'Pickup');
			else
				Pawn(Owner).ReceiveLocalizedMessage( item.PickupMessageClass, 0, None, None, item.Class );
			Item.PlaySound (item.PickupSound,,2.0);
			Item.SetReSpawn();
			return true;
	}

	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

final function Pawn GetOwner()
{
	if ( Pawn(Owner) != none )
		return Pawn(Owner);
	return Instigator;
}

defaultproperties
{
    PickupMessage="You found a Class B suit"
    RespawnTime=80.00
    PickupViewMesh=LodMesh'UnrealI.AsbSuit'
    MaxDesireability=1.15
    PickupSound=Sound'UnrealShare.Pickups.suitsnd'
    RespawnSound=Sound'PickUpRespawn'
    Mesh=LodMesh'UnrealI.AsbSuit'
    bUnlit=True
}