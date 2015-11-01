//=============================================================================
// sgItemJumpBoots
//=============================================================================
class sgItemJumpBoots extends sgItem;

function ModifyProduct( Inventory I, int Idx)
{
	Super.ModifyProduct( I, Idx);
	I.Charge = Grade+3;
}

function Upgraded()
{
	ModifyProduct( MyProduct, 1);
}


defaultproperties
{
     bTakeProductVisual=True
     bNoFractionUpgrade=True
     InventoryClass=Class'Botpack.UT_Jumpboots'
     BuildingName="Jump Boots"
     BuildCost=250
     UpgradeCost=15
     Model=LodMesh'Botpack.jboot'
     SkinRedTeam=Texture'HealthPodSkinT0'
     SkinBlueTeam=Texture'HealthPodSkinT1'
     SpriteRedTeam=Texture'MotionAlarmSpriteT0'
     SpriteBlueTeam=Texture'MotionAlarmSpriteT1'
     SkinGreenTeam=Texture'HealthPodSkinT2'
     SkinYellowTeam=Texture'HealthPodSkinT3'
     SpriteGreenTeam=Texture'MotionAlarmSpriteT2'
     SpriteYellowTeam=Texture'MotionAlarmSpriteT3'
}
