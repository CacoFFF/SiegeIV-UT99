//=============================================================================
// sgContainerX.
// * Revised by 7DS'Lust
// Brought back by Higor, plus collision expansion after build
//=============================================================================
class sgContainerX extends sgContainer;

simulated function FinishBuilding()
{
	SetCollisionSize(45,45);
	Super.FinishBuilding();
}

defaultproperties
{
     StorageAmount=250
     BuildDistance=50
     BuildingName="ContainerX"
     BuildCost=750
     UpgradeCost=35
     MaxEnergy=6000.000000
     DSofMFX=3.325000
     CollisionRadius=36.000000
     CollisionHeight=36.000000
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SpriteRedTeam=Texture'HealthPodSkinT0'
     SpriteBlueTeam=Texture'HealthPodSkinT1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     SpriteGreenTeam=Texture'HealthPodSkinT2'
     SpriteYellowTeam=Texture'HealthPodSkinT3'
     GUI_Icon=Texture'GUI_ContainerX'
}
