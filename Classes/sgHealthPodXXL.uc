//=============================================================================
// sgSuperHealthPod.
//=============================================================================
class sgHealthPodXXL extends sgEquipmentSupplier;


event PostBeginPlay()
{
	local Pawn p;
	local sgHealthPodXXL sgH;
	local string sLocation;
	
	if ( Pawn(Owner) != none )
	{
		if ( Pawn(owner).PlayerReplicationInfo.PlayerLocation != None )
			sLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
		else if ( Pawn(owner).PlayerReplicationInfo.PlayerZone != None )
			sLocation = Pawn(owner).PlayerReplicationInfo.PlayerZone.ZoneName;
		if ( sLocation != "" && sLocation != " ")
		    sLocation = "at"@sLocation;
	}

	Super.PostBeginPlay();

	if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).SupplierProtection)
	{
		bProtected = True;
		ForEach AllActors( class'sgHealthPodXXL', sgH)
			if ( sgH.bProtected && (sgH.Team == Team) && (sgH != self) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity)
		AnnounceTeam("Your team has built a Super Health Pod"@sLocation, Team);
}

function Pawn FindTarget()
{
	local Pawn p;

	foreach RadiusActors(class'Pawn', p, 72)
		if ( p.bIsPlayer && (p.Health > 0) && (p.PlayerReplicationInfo != None) && (p.PlayerReplicationInfo.Team == Team) )
			Supply(P);

    return None;
}

function Supply(Pawn target)
{
	local Inventory inv;
	local float Decision;
	
	inv = target.FindInventoryType(class'sgArmor');
	if ( inv == None )
	{
		inv = Spawn(class'sgArmor', target);
		if ( inv != None )
			inv.GiveTo(target);
	}
	if ( inv != None && inv.Charge < 50 + Grade*20 )
	{
		inv.Charge = FMin(inv.Charge + 1, 50 + grade * 20 );
		if ( FRand() < (Grade/7.5) )
			inv.Charge = FMin(inv.Charge + 1, 50 + grade * 20 );
	}

	if ( Target.Health < 75 + (grade*15) )
		Target.Health = Min(Target.Health + 2, 150);
	
	if ( FRand() < 0.5 )
		Target.PlaySound(sound'sgMedia.sgStockUp', SLOT_Misc, Target.SoundDampening*2.5);
}


defaultproperties
{
     SuppProtectTimeSecs=6000000
     BuildingName="Super Health Pod"
     BuildCost=1500
     UpgradeCost=40
     BuildTime=60.000000
	 AnnounceImmunity=True
     MaxEnergy=30000.000000
     SpriteScale=0.480000
     Model=LodMesh'Botpack.BigSprocket'
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SpriteRedTeam=Texture'HealthPodSkinT0'
     SpriteBlueTeam=Texture'HealthPodSkinT1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     SpriteGreenTeam=Texture'HealthPodSkinT2'
     SpriteYellowTeam=Texture'HealthPodSkinT3'
     DSofMFX=1.250000
     MFXrotX=(Pitch=30000,Yaw=30000,Roll=30000)
     MultiSkins(0)=Texture'HealthPodSkinT0'
     MultiSkins(1)=Texture'HealthPodSkinT1'
     MultiSkins(2)=Texture'HealthPodSkinT2'
     MultiSkins(3)=Texture'HealthPodSkinT3'
     GUI_Icon=Texture'GUI_SHealthPod'
}
