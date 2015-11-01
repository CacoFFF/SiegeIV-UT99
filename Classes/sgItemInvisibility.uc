//=============================================================================
// sgItemInvisibility.
//=============================================================================
class sgItemInvisibility extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	I.Charge = 60 + 20 * Grade;
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}


defaultproperties
{
     InventoryClass=Class'Botpack.UT_invisibility'
     bTakeProductVisual=True
    BuildingName="Invisibility"
     BuildCost=800
     UpgradeCost=30
     MaxEnergy=1000.000000
     Model=LodMesh'Botpack.invis2M'
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SpriteRedTeam=Texture'PoisonGuardianSpriteT0'
     SpriteBlueTeam=Texture'PoisonGuardianSpriteT1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     SpriteGreenTeam=Texture'PoisonGuardianSpriteT2'
     SpriteYellowTeam=Texture'PoisonGuardianSpriteT3'
}
