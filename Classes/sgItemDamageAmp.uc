//=============================================================================
// sgItemDamageAmp
//=============================================================================
class sgItemDamageAmp extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	if ( UDamage(I) != none )
		I.Charge = 300 + Square(Grade) * 10;
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}

function bool GiveItems( Pawn Other)
{
	if ( Super.GiveItems(Other) )
	{
		Other.DamageScaling = 2 + (Grade/10);
		return true;
	}
}

defaultproperties
{
     InventoryClass=Class'Botpack.UDamage'
     bTakeProductVisual=True
     BuildingName="Damage Amplifier"
     BuildCost=2500
	 UpgradeCost=100
     SpriteScale=0.350000
     Model=LodMesh'Botpack.UDamage'
     SkinRedTeam=Texture'SuperBoosterSkinT0'
     SkinBlueTeam=Texture'SuperBoosterSkinT1'
     SpriteRedTeam=Texture'PlatformSpriteT0'
     SpriteBlueTeam=Texture'PlatformSpriteT1'
     SkinGreenTeam=Texture'SuperBoosterSkinT2'
     SkinYellowTeam=Texture'SuperBoosterSkinT3'
     SpriteGreenTeam=Texture'PlatformSpriteT2'
     SpriteYellowTeam=Texture'PlatformSpriteT3'
     MFXrotX=(Yaw=90000)
}
