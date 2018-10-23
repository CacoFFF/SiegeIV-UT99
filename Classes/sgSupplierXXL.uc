//=============================================================================
// sgSupplierXXL
// Optimized by Higor
//=============================================================================
class sgSupplierXXL extends sgSupplier;

simulated function CompleteBuilding()
{
	local sgSupplier MySupplier;

	Super.CompleteBuilding();
	if (  Role != ROLE_Authority )
        return;

	if ( FRand() < 0.2 ) //HIGOR: Timer happens 10 times per second, we really don't need to hog that much resources
		ForEach AllActors(Class'sgSupplier', MySupplier)
			if ( (MySupplier.BuildCost < BuildCost) && MySupplier.bProtected && (MySupplier.Team == Team) )
				MySupplier.bProtected=False;
}

/*
function bool Supply( Pawn Other, sgSupplierQueuer Accumulator, float SupplyFactor)
{
    local int numWeapons, i, j;
    local Inventory inv;

    if ( !default.ClassesLoaded )
        LoadWeaponClasses();
        
	Super.Supply(Other,Accumulator,SupplyFactor);

	numWeapons = min(GetWeaponCount(), default.iWeaponClasses);
	for ( inv=Other.Inventory ; inv!=none ; inv=inv.Inventory )
	{
		if ( (Weapon(Inv) == none) || (Weapon(Inv).AmmoType == none) )
			continue;

		for ( i=0 ; i<numWeapons ; i++ )
		{
			if ( (!bUseSubclasses && Inv.class == default.WeaponClasses[i]) || (bUseSubclasses && ClassIsChildOf(Inv.class, default.WeaponClasses[i]) ) )
			{
				j++;
				if ( Weapon(inv).AmmoType.AmmoAmount < Weapon(inv).Default.PickupAmmoCount / 2 )
					Weapon(inv).AmmoType.AmmoAmount = Weapon(inv).Default.PickupAmmoCount / 2;
				else if ( FRand() < float(Weapon(inv).AmmoType.MaxAmmo) / 200.0 )
					Weapon(inv).AmmoType.AmmoAmount = FMin(
						Weapon(inv).AmmoType.AmmoAmount + 1 +
						int(FRand()*Grade/2*EquipRate),
						Weapon(inv).AmmoType.MaxAmmo);
				if ( j >= numWeapons )
					Goto WEAPONS_READY;
				break;
			}
		}
	}

	WEAPONS_READY:
	return true;
}
*/

/*
//Chance a player gains 1 armor point (values above 1 may yield more points)
function float ArmorRate()
{
	return 0.4 + (Grade / 3.75);
}
*/


/*
REMINDER:
ORB EQUALS APE, HYPER LEECHER AND PULSE RIFLE RECHARGE
*/

defaultproperties
{
     SupplyScale=4
	 SupplySoundFrequency=0.35
     ProtectionExpired="Your team Super Supplier immunity has expired."
     bOnlyOwnerRemove=True
     bGlobalSupply=True
     Weapons(0)="Botpack.Enforcer"
     Weapons(1)="Botpack.ut_biorifle"
     Weapons(2)="Botpack.ShockRifle"
     Weapons(3)="Botpack.PulseGun"
     Weapons(4)="Botpack.ripper"
     Weapons(5)="Botpack.minigun2"
     Weapons(6)="Botpack.UT_FlakCannon"
     Weapons(7)="Botpack.UT_Eightball"
     Weapons(8)="Botpack.SniperRifle"
     AnnounceImmunity=True
     SuppProtectTimeSecs=6000000
     BuildingName="Super Supplier"
     BuildCost=1500
     BuildTime=60.000000
     MaxEnergy=30000.000000
     Model=LodMesh'Botpack.ShockWavem'
     SkinRedTeam=Texture'SuperBoosterSpriteT0'
     SkinBlueTeam=Texture'SuperBoosterSpriteT1'
     SpriteRedTeam=Texture'SuperProtectorSpriteT0'
     SpriteBlueTeam=Texture'SuperProtectorSpriteT1'
     SkinGreenTeam=Texture'SuperBoosterSpriteT2'
     SkinYellowTeam=Texture'SuperBoosterSpriteT3'
     SpriteGreenTeam=Texture'SuperProtectorSpriteT2'
     SpriteYellowTeam=Texture'SuperProtectorSpriteT3'
     MFXrotX=(Pitch=25000,Yaw=25000,Roll=25000)
     DSofMFX=2.000000
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     GUI_Icon=Texture'GUI_SupXXL'
     bUseSubclasses=True
}