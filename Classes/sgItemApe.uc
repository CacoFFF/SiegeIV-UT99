//=============================================================================
// sgItemApe
//=============================================================================
class sgItemApe extends sgItem;

event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType )
{
	damage = (damage * 10) / 15; //Reduce in 33%
	Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
}


defaultproperties
{
     bNoUpgrade=True
     bFullAmmoRestock=True
     bTakeProductVisual=True
     InventoryClass=Class'ApeCannon'
     SwitchToWeapon=True
     BuildingName="Ape Cannon"
     BuildCost=750
     UpgradeCost=0
     BuildTime=10.000000
     SpriteScale=0.400000
     Model=LodMesh'Botpack.Flak2Pick'
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
