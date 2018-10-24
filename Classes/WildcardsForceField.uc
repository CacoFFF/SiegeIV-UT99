//=============================================================================
// WildcardsForceField.
//
// Enlarge method revised by Higor
// Class entirely rewritten.
//=============================================================================
class WildcardsForceField expands sgBuilding;

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
		myFX.DrawScale = DSofMFX;
	}
}

function Upgraded()
{	
	local float Percent;

	bDragable = false;
	
	//Adjust the forcefield properties
	SetCollisionSize( 40+20*Grade, 40+20*Grade);
	SpriteScale = 0.5 + 0.25*Grade;
	DrawScale = SpriteScale;
	DSofMFX = 1 + 0.5 * Grade;
	AmbientGlow=255/(6-Grade);

	//Keep energy proportion
	Percent = Energy/MaxEnergy;
	MaxEnergy = default.MaxEnergy * (Grade+1);
	Energy = Percent * MaxEnergy;
}

/*
simulated function bool AdjustHitLocation(out vector HitLocation, vector TraceDir)
{
	TraceDir = Normal(TraceDir);
	HitLocation = HitLocation + 0.4 * CollisionRadius * TraceDir;
	return true;
}
*/
event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType )
{

	Super.TakeDamage( damage, instigatedBy, hitLocation, momentum, damageType);

	if ( !bDeleteMe && !bIsOnFire)
	{
		Spawn(class'ForceFieldFlash',,,hitlocation);
		Self.PlaySound(Sound'UnrealShare.General.Expla02',,7.0);
	}
}

defaultproperties
{
     bDragable=true
     RuRewardScale=0.4
     MFXFatness=125
     BuildingName="Forcefield"
     BuildCost=1200
     UpgradeCost=30
     BuildTime=15.000000
     MaxEnergy=4000.000000
     SpriteScale=0.500000
     Model=LodMesh'Botpack.earth1'
     SkinRedTeam=WetTexture'ForceFieldT0'
     SkinBlueTeam=WetTexture'ForceFieldT1'
     SpriteRedTeam=Texture'ForceFieldAuraT0'
     SpriteBlueTeam=Texture'ForceFieldAuraT1'
     SkinGreenTeam=WetTexture'ForceFieldT2'
     SkinYellowTeam=WetTexture'ForceFieldT3'
     SpriteGreenTeam=Texture'ForceFieldAuraT2'
     SpriteYellowTeam=Texture'ForceFieldAuraT3'
     MFXrotX=(Pitch=10000,Yaw=10000,Roll=10000)
     MultiSkins(0)=Texture'ForceFieldAuraT0'
     MultiSkins(1)=Texture'ForceFieldAuraT1'
     MultiSkins(2)=Texture'ForceFieldAuraT2'
     MultiSkins(3)=Texture'ForceFieldAuraT3'
     CollisionRadius=40.000000
     CollisionHeight=40.000000
     BuildDistance=70
     GUI_Icon=Texture'GUI_Forcefield'
}
