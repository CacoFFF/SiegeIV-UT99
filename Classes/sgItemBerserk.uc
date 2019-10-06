//=============================================================================
// sgItemBerserk
//=============================================================================
class sgItemBerserk extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	if ( Berserk(I) != none )
		I.Charge = 30 + Square(Grade);
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}


defaultproperties
{
     InventoryClass=Class'Berserk'
     bTakeProductVisual=True
     BuildingName="Berserk"
     BuildCost=800
	 UpgradeCost=60
     SpriteScale=0.350000
     Model=LodMesh'BerserkM'
     SkinRedTeam=Texture'SuperBoosterSkinT0'
     SkinBlueTeam=Texture'SuperBoosterSkinT1'
     SpriteRedTeam=Texture'PlatformSpriteT0'
     SpriteBlueTeam=Texture'PlatformSpriteT1'
     SkinGreenTeam=Texture'SuperBoosterSkinT2'
     SkinYellowTeam=Texture'SuperBoosterSkinT3'
     SpriteGreenTeam=Texture'PlatformSpriteT2'
     SpriteYellowTeam=Texture'PlatformSpriteT3'
     MFXrotX=(Yaw=90000)
     GUI_Icon=Texture'GUI_UDamage'
}
