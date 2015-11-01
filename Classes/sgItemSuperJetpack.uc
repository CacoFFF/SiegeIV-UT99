//=============================================================================
// sgItemSuperJetpack.uc.
// Class created by nOs*Badger
//=============================================================================
class sgItemSuperJetpack extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	local Jetpack pack;
	Super.ModifyProduct( I, Idx);
	pack = Jetpack(I);
	if ( pack != None )
	{
		pack.MaxFuel = 999999999;
		pack.Fuel = pack.MaxFuel;
		pack.ItemName="Super Jetpack";
	}
}

//Allow an item to bypass the default rules
function bool CustomAllowPickup( Pawn Other, inventory Inv)
{
	local Jetpack pack;
	pack = Jetpack(Other.FindInventoryType(class'Jetpack'));
	if ( (pack != None) && (pack.MaxFuel != 999999999) )
	{
		pack.MaxFuel = 999999999;
		pack.Fuel = pack.MaxFuel;
		pack.ItemName="Super Jetpack";
		return true;
	}
}

//Override giving item when duplicate exists, deletes the new item
function bool CustomGiveDuplicate( Pawn Other, inventory Inv);
//Never add the item if a duplicate is found under the following conditions
function bool CustomDenyPickup( Pawn Other, inventory Inv);


defaultproperties
{
    bNoUpgrade=True
    bTakeProductVisual=True
    InventoryClass=Class'JetPack'
    BuildingName="Super Jetpack"
    BuildCost=1500
    UpgradeCost=0
    MaxEnergy=10000.00
    Model=LodMesh'UnrealI.AsbSuit'
    SkinRedTeam=Texture'SuperContainerSkinT0'
    SkinBlueTeam=Texture'SuperContainerSkinT1'
    SpriteRedTeam=Texture'ProtectorSpriteTeam0'
    SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
    SkinGreenTeam=Texture'SuperContainerSkinT2'
    SkinYellowTeam=Texture'SuperContainerSkinT3'
    SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
    SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
}
