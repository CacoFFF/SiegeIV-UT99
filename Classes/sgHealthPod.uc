//=============================================================================
// sgHealthPod.
// * Revised by 7DS'Lust
// * Turned into archetype of generic sgEquipmentSupplier by Higor
//=============================================================================
class sgHealthPod extends sgEquipmentSupplier;


function Upgraded()
{
	local sgHealthPod sgH;

	Super.Upgraded();
	if ( Grade >= 5 )
	{
		ForEach RadiusActors( class'sgHealthPod', sgH, 200)
			if ( (sgH.Team == Team) && (sgH.BuildCost < BuildCost) ) //Never self
				sgH.bOnlyOwnerRemove = false;
	}
}

//Players heal up to this amount of health
function int HealthLimit()
{
	return 60 + (Grade * 15.0);
}

//Chance a player heals 1 point (values above 1 may yield more points)
function float HealthRate()
{
	return 0.3 + Grade / 40.0;
}

//Armor is received up to this amount
function int ArmorLimit()
{
	return 25 + (Grade * 25.0);
} 

//Chance a player gains 1 armor point (values above 1 may yield more points)
function float ArmorRate()
{
	return 0.1 + (Grade / 15.0);
}


defaultproperties
{
	 SupplySoundFrequency=0.2
     BuildingName="Health Pod"
     BuildCost=200
     UpgradeCost=30
     BuildTime=40.000000
     MaxEnergy=2700.000000
     SpriteScale=0.320000
     Model=LodMesh'Botpack.BigSprocket'
     SkinRedTeam=Texture'PoisonGuardianSkinT0'
     SkinBlueTeam=Texture'PoisonGuardianSkinT1'
     SpriteRedTeam=Texture'HealthPodSkinT0'
     SpriteBlueTeam=Texture'HealthPodSkinT1'
     SkinGreenTeam=Texture'PoisonGuardianSkinT2'
     SkinYellowTeam=Texture'PoisonGuardianSkinT3'
     SpriteGreenTeam=Texture'HealthPodSkinT2'
     SpriteYellowTeam=Texture'HealthPodSkinT3'
     DSofMFX=1.250000
     MFXrotX=(Yaw=5000)
     MultiSkins(0)=Texture'HealthPodSkinT0'
     MultiSkins(1)=Texture'HealthPodSkinT1'
     MultiSkins(2)=Texture'HealthPodSkinT2'
     MultiSkins(3)=Texture'HealthPodSkinT3'
     GUI_Icon=Texture'GUI_HealthPod'
}
