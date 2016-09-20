//=============================================================================
// sgItemDampener.
//=============================================================================
class sgItemDampener expands sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	local float Added;
	Super.ModifyProduct( I, Idx);
	Added = (Grade ** 1.6) * 10;
	I.Charge = I.Charge * 1.5 + Added;
}


defaultproperties
{
     bNoUpgrade=False
     bTakeProductVisual=True
	 bDeactivatable=True
     InventoryClass=Class'Unreali.Dampener'
     BuildingName="Dampener"
     BuildCost=100
     UpgradeCost=5
     SpriteScale=0.200000
     Model=LodMesh'Unreali.DampenerM'
     SkinRedTeam=Texture'ContainerSkinTeam0'
     SkinBlueTeam=Texture'ContainerSkinTeam1'
     SkinGreenTeam=Texture'ContainerSkinTeam2'
     SkinYellowTeam=Texture'ContainerSkinTeam3'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
     DSofMFX=1.500000
}
