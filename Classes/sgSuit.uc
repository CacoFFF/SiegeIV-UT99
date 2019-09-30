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

//XC_Engine interface
native(3542) final iterator function InventoryActors( class<Inventory> InvClass, out Inventory Inv, optional bool bSubclasses, optional Actor StartFrom); 

function sgSuit OtherSuit( Pawn P)
{
	local inventory I;

	For ( I=P.Inventory ; I!=none ; I=I.inventory )
	{
		if ( I.IsA('sgSuit') && I != self )
			return sgSuit(I);
	}
}

function sgSuit OtherSuit_XC( Pawn P)
{
	local sgSuit sgS;
	ForEach InventoryActors( class'sgSuit', sgS, true, P)
		if ( sgS != self )
			return sgS;
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
	if ( EnviroSkin != None )
	{
		if ( P.bMeshEnviroMap && P.Texture == EnviroSkin ) //Only change to defaults if player has MY enviro skin
			P.SetDefaultDisplayProperties();
		if ( (AffectedWeapon != none) && AffectedWeapon.bMeshEnviroMap && (AffectedWeapon.Texture == EnviroSkin) )
		{
			AffectedWeapon.SetDefaultDisplayProperties();
			AffectedWeapon = none;
		}
	}
}

event Destroyed()
{
	Super.Destroyed();
	RemoveSkin();
	aTimer = -99;
}

function PickupFunction(Pawn Other)
{
	local sgSuit Suit;

	if ( Owner == none )
		SetOwner( Other);

	Suit = OtherSuit( Other);
	if ( Suit != None && Suit != self ) //Skin SHOULD go back to normal
		Suit.Destroy();

	Super.PickupFunction( Other);
	ApplySkin();
	aTimer = 0;
}


function bool HandlePickupQuery( Inventory Item )
{
	if ( Item.class == class ) //Restock up to 200%
	{
		Charge = Min( Charge + Item.Charge, Default.Charge * 2);

		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		if ( Item.PickupMessageClass == None )
			Pawn(Owner).ClientMessage(Item.PickupMessage, 'Pickup');
		else
			Pawn(Owner).ReceiveLocalizedMessage( Item.PickupMessageClass, 0, None, None, item.Class );
		Item.PlaySound( Item.PickupSound,, 2.0);
		Item.SetReSpawn();
		return true;
	}

	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery( Item );
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