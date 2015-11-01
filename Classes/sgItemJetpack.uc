//=============================================================================
// sgItemJetpack.
//=============================================================================
class sgItemJetpack extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	local Jetpack pack;
	Super.ModifyProduct( I, Idx);
	pack = Jetpack(I);
	if ( pack != None )
	{
		pack.MaxFuel = pack.default.MaxFuel * (Grade/4 + 1);
		pack.Fuel = pack.MaxFuel;
	}
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}



defaultproperties
{
     bTakeProductVisual=True
     InventoryClass=Class'JetPack'
     BuildingName="Jetpack"
     BuildCost=650
     UpgradeCost=20
     MaxEnergy=1500.000000
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
