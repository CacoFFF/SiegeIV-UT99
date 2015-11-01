//=============================================================================
// sgItemDampener.
//=============================================================================
class sgItemDampener expands sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	I.Charge *= 2.2;
}


defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     InventoryClass=Class'Unreali.Dampener'
     BuildingName="Dampener"
     BuildCost=125
     UpgradeCost=0
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
