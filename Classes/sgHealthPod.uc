//=============================================================================
// sgHealthPod.
// * Revised by 7DS'Lust
//=============================================================================
class sgHealthPod extends sgEquipmentSupplier;

function Supply(Pawn target)
{
	local Inventory inv;

    inv = target.FindInventoryType(class'sgArmor');
    if ( inv == None )
		SpawnArmor(target);
    else if ( FRand() < 0.1 + (Grade/15) && inv.Charge < 25 + Grade*25 )
        inv.Charge = FMin(inv.Charge + 1, 25 + grade * 25 );
	
	if ( FRand() < 0.3 + (Grade/40) && Target.Health < 60 + (grade*15) )
        Target.Health++;
	
	if ( FRand() < 0.2 )
        Target.PlaySound(sound'sgMedia.sgStockUp', SLOT_Misc, Target.SoundDampening*2.5);
}

defaultproperties
{
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
