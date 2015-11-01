//=============================================================================
// sgItemScuba
//=============================================================================
class sgItemScuba extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	if ( Pickup(I) != none )
		Pickup(I).bAutoActivate = Region.Zone.bWaterZone;
}

defaultproperties
{
     bTakeProductVisual=True
     bNoUpgrade=True
     InventoryClass=Class'UnrealShare.SCUBAGear'
     BuildingName="Scuba Gear"
     BuildCost=250
     MaxEnergy=1000.000000
     Model=LodMesh'UnrealShare.Scuba'
     SkinRedTeam=Texture'PoisonGuardianSkinT0'
     SkinBlueTeam=Texture'PoisonGuardianSkinT1'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SkinGreenTeam=Texture'PoisonGuardianSkinT2'
     SkinYellowTeam=Texture'PoisonGuardianSkinT3'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
}
