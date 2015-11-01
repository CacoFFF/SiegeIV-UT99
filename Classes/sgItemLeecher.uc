//=============================================================================
// sgItemLeecher
// by SK
//=============================================================================
class sgItemLeecher extends sgItem;

event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType )
{
	damage /= 4; //Reduce in 75%
	Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
}


defaultproperties
{
     bNoUpgrade=True
     bFullAmmoRestock=True
     bTakeProductVisual=True
     InventoryClass=Class'HyperLeecher'
     SwitchToWeapon=True
     BuildingName="Hyper Leecher"
     BuildCost=275
     UpgradeCost=0
     BuildTime=1.00000
     SpriteScale=0.400000
     Model=LodMesh'Botpack.BRifle2Pick'
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SpriteRedTeam=Texture'CoreSpriteTeam0'
     SpriteBlueTeam=Texture'CoreSpriteTeam1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteGreenTeam=Texture'CoreSpriteTeam2'
     SpriteYellowTeam=Texture'CoreSpriteTeam3'
     DSofMFX=1.000000
}
