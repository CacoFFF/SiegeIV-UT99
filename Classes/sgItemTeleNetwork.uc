//=============================================================================
// sgItemTeleNetwork 
// nOs*Badger
//=============================================================================

class sgItemTeleNetwork extends sgItem;

simulated function FinishBuilding()
{
	SpriteScale=0.5;
 	Super.FinishBuilding();
}

defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     InventoryClass=Class'sgTeleNetwork'
     BuildingName="TeleNetwork"
     BuildCost=100
     MaxEnergy=1500.000000
     Model=LodMesh'Botpack.Tele2'
     SkinRedTeam=Texture'PlatformSkinT0'
     SkinBlueTeam=Texture'PlatformSkinT1'
     SpriteRedTeam=Texture'BoosterSpriteTeam0'
     SpriteBlueTeam=Texture'BoosterSpriteTeam1'
     SkinGreenTeam=Texture'PlatformSkinT2'
     SkinYellowTeam=Texture'PlatformSkinT3'
     SpriteGreenTeam=Texture'BoosterSpriteTeam2'
     SpriteYellowTeam=Texture'BoosterSpriteTeam3'
     DSofMFX=0.500000
     MFXrotX=(Yaw=80000)
     GUI_Icon=Texture'GUI_Telenetwork'
}
