//=============================================================================
// sgItemTranslocator.
//=============================================================================
class sgItemTranslocator expands sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	I.PickupSound = Sound'Unrealshare.Pickups.GenPickSnd';
	I.Charge = Grade;
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}


defaultproperties
{
     bTakeProductVisual=True
     bNoFractionUpgrade=True
     InventoryClass=Class'sgTranslocator'
     SwitchToWeapon=True
     BuildingName="Translocator"
     BuildCost=850
     UpgradeCost=20
     SpriteScale=0.250000
     Model=LodMesh'Botpack.Trans3loc'
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
