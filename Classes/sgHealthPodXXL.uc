//=============================================================================
// sgSuperHealthPod.
// * Rewritten by Higor
//=============================================================================
class sgHealthPodXXL extends sgHealthPod;


function PostBuild()
{
	local sgHealthPod sgH;
	
	Super.PostBuild();

	if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).SupplierProtection)
	{
		bProtected = True;
		ForEach AllActors( class'sgHealthPod', sgH)
			if ( sgH.bProtected && (sgH.Team == Team) && (sgH != self) && (sgH.BuildCost >= BuildCost) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity)
		AnnounceConstruction();
}




//Players heal up to this amount of health
function int HealthLimit()
{
	return 75 + (Grade * 15.0);
}

//Chance a player heals 1 point (values above 1 may yield more points)
function float HealthRate()
{
	return 2.0;
}

//Armor is received up to this amount
function int ArmorLimit()
{
	return 50 + (Grade * 20.0);
} 

//Chance a player gains 1 armor point (values above 1 may yield more points)
function float ArmorRate()
{
	return Grade / 7.5;
}


defaultproperties
{
     bGlobalSupply=True
	 SupplySoundFrequency=0.5
     SuppProtectTimeSecs=6000000
     BuildingName="Super Health Pod"
     BuildCost=1500
     UpgradeCost=40
     BuildTime=60.000000
	 AnnounceImmunity=True
     MaxEnergy=30000.000000
     SpriteScale=0.480000
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     MFXrotX=(Pitch=30000,Yaw=30000,Roll=30000)
     GUI_Icon=Texture'GUI_SHealthPod'
}
