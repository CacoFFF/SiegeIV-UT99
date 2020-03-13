//=============================================================================
// MiniShield
//=============================================================================
class MiniShield extends SphericShield;

simulated function FinishBuilding()
{
	if ( Role == ROLE_Authority )
		SetCollisionSize(50,50);
	Super.FinishBuilding();
}


defaultproperties
{
     BuildingName="Mini Shield"
     BuildCost=800
     MaxEnergy=14000.000000
     SpriteRedTeam=Texture'ContainerSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerSpriteTeam1'
     SpriteGreenTeam=Texture'ContainerSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerSpriteTeam3'
     SpriteScale=0.8
     DSofMFX=1.700000
     CollisionRadius=20.000000
     CollisionHeight=20.000000
     GUI_Icon=Texture'GUI_MiniShield'
}
