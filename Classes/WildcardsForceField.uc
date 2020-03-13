//=============================================================================
// WildcardsForceField.
//
// Enlarge method revised by Higor
// Class entirely rewritten as subclass of SphericShield
//=============================================================================
class WildcardsForceField expands SphericShield;

var float ClientGrade;

simulated event Timer()
{
	Super.Timer();

	if ( Level.NetMode == NM_DedicatedServer )
		return;

	//Correct various things on client version
	if ( (myFX != none) && (ClientGrade != Grade) )
	{
		ClientGrade = Grade;
		SetCollisionSize( 40+20*Grade, 40+20*Grade);
		SpriteScale = 0.5 + 0.25*Grade;
		DSofMFX = 1 + 0.5 * Grade;
		myFX.SetSize(DSofMFX);
		myFX.Timer();
	}
}

function Upgraded()
{	
	bDragable = false;
	
	//Adjust the forcefield properties
	SetCollisionSize( 40+20*Grade, 40+20*Grade);
	SpriteScale = 0.5 + 0.25*Grade;
	DrawScale = SpriteScale;
	DSofMFX = 1 + 0.5 * Grade;
	AmbientGlow=255/(6-Grade);

	//Keep energy proportion
	SetMaxEnergy( BaseEnergy * (Grade * 0.5 + 1) );
}


defaultproperties
{
     RuRewardScale=0.4
     bNoUpgrade=False
     MFXFatness=125
     BuildingName="Forcefield"
     BuildCost=1200
     UpgradeCost=30
     MaxEnergy=8000.000000
     SpriteScale=0.500000
     DSofMFX=1
     Model=LodMesh'Botpack.earth1'
     SpriteRedTeam=Texture'ForceFieldAuraT0'
     SpriteBlueTeam=Texture'ForceFieldAuraT1'
     SpriteGreenTeam=Texture'ForceFieldAuraT2'
     SpriteYellowTeam=Texture'ForceFieldAuraT3'
     MFXrotX=(Pitch=8000,Yaw=8000,Roll=8000)
     MultiSkins(0)=Texture'ForceFieldAuraT0'
     MultiSkins(1)=Texture'ForceFieldAuraT1'
     MultiSkins(2)=Texture'ForceFieldAuraT2'
     MultiSkins(3)=Texture'ForceFieldAuraT3'
     CollisionRadius=40.000000
     CollisionHeight=40.000000
     BuildDistance=70
     GUI_Icon=Texture'GUI_Forcefield'
}
