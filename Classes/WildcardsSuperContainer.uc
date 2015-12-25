//=============================================================================
// WildcardsSuperContainer.
// When a Container is not good enough...
// Besides ContainerX's are generally Useless!
//
// Higor: now radius and storage fully scalable
// Now subclass of sgContainer
//=============================================================================
class WildcardsSuperContainer expands sgContainer;

var float HealRadius;

simulated function FinishBuilding()
{
	SetCollisionSize( 80, 80);
	Super.FinishBuilding();
}

function float ScanRadius()
{
	return 240 + HealRadius * Grade * 0.25;
}


defaultproperties
{
     StorageAmount=1600
     HealRadius=240
     HealAmount=6.0
     BuildingName="Super Container"
     BuildCost=1600
     UpgradeCost=60
     BuildTime=45.000000
     MaxEnergy=7000.000000
     SpriteScale=1.350000
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SpriteRedTeam=Texture'SuperContainerSpriteT0'
     SpriteBlueTeam=Texture'SuperContainerSpriteT1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteGreenTeam=Texture'SuperContainerSpriteT2'
     SpriteYellowTeam=Texture'SuperContainerSpriteT3'
     DSofMFX=5.000000
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     MultiSkins(0)=Texture'SuperContainerSpriteT0'
     MultiSkins(1)=Texture'SuperContainerSpriteT1'
     MultiSkins(2)=Texture'SuperContainerSpriteT2'
     MultiSkins(3)=Texture'SuperContainerSpriteT3'
     CollisionRadius=40.000000
     CollisionHeight=40.000000
     BuildDistance=55
     GUI_Icon=Texture'GUI_SContainer'
}
