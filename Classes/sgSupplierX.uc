//=============================================================================
// sgSupplierX.
// Rebuilt by Higor (didn't have original code)
//=============================================================================
class sgSupplierX extends sgSupplier;

//Supply all weapons instead of 2-5, 9
var bool bSupplyAll;

event PostBuild()
{
	local Pawn p;
	local sgSupplierX sgS;
	local string sLocation;

	Super(sgBuilding).PostBuild();

	if ( Pawn(Owner) != none )
	{
		if ( Pawn(owner).PlayerReplicationInfo.PlayerLocation != None )
			sLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
		else if ( Pawn(owner).PlayerReplicationInfo.PlayerZone != None )
			sLocation = Pawn(owner).PlayerReplicationInfo.PlayerZone.ZoneName;
		if ( sLocation != "" && sLocation != " ")
		    sLocation = "at"@sLocation;
	}

	if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).SupplierProtection)
	{
		bProtected = True;
		ForEach AllActors( class'sgSupplierX', sgS)
			if ( sgS.bProtected && (sgS.Team == Team) && (sgS != self) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity)
		AnnounceTeam("Your team has built a SupplierX"@sLocation, Team);
}

function int GetWeaponCount()
{
	if ( bSupplyAll )
		return Super.GetWeaponCount();
	if ( Grade < 2 )
		return 1;
	else if ( Grade < 3 )
		return 2;
	else if ( Grade < 4 )
		return 3;
	else if ( Grade < 5 )
		return 4;
	return 9;
}

function Supply(Pawn target)
{
	local int numWeapons, i, j;
	local Inventory inv;
	local sgArmor theArmor;

    if ( !default.ClassesLoaded )
        LoadWeaponClasses();

	Super(sgEquipmentSupplier).Supply(target);

    numWeapons = min(GetWeaponCount(), default.iWeaponClasses);
	for ( inv=target.Inventory ; inv!=none ; inv=inv.Inventory )
	{
		if ( (Weapon(Inv) == none) || (Weapon(Inv).AmmoType == none) )
		{
			if ( sgArmor(Inv) != none )
				theArmor = sgArmor(Inv);
			continue;
		}

		i=0;
		While ( i<numWeapons )
		{
			if ( (!bUseSubclasses && Inv.class == default.WeaponClasses[i]) || (bUseSubclasses && ClassIsChildOf(Inv.class, default.WeaponClasses[i]) ) )
			{
				j++;
				if ( Weapon(inv).AmmoType.AmmoAmount < Weapon(inv).Default.PickupAmmoCount / 2 )
	                Weapon(inv).AmmoType.AmmoAmount = Weapon(inv).Default.PickupAmmoCount / 2;
	            else if ( FRand() < float(Weapon(inv).AmmoType.MaxAmmo) / 400 )
					Weapon(inv).AmmoType.AmmoAmount = FMin(
						Weapon(inv).AmmoType.AmmoAmount + 1 +
						int(FRand()*Grade/2*EquipRate),
						Weapon(inv).AmmoType.MaxAmmo);
				if ( j >= min(numWeapons,5+int(bSupplyAll)*20) )
					Goto WEAPONS_READY;
				break;
			}
			if ( i < 3 )
				i++;
			else if ( i < 7 )
			{
				if ( bSupplyAll )
					i++;
				else
					i = 7;
			}
			else
				break;
		}
	}

	WEAPONS_READY:
	if ( theArmor != none )
		Goto UPGRADE_ARMOR;
	
	while ( inv != none )
	{
		if ( sgArmor(Inv) != none )
		{
			theArmor = sgArmor(Inv);
			Goto UPGRADE_ARMOR;
		}
		inv = inv.Inventory;
	}

	theArmor = SpawnArmor( Target);
	Goto PLAY_SOUND;

	UPGRADE_ARMOR:
	if ( FRand() < 0.1 + (Grade/15) && theArmor.Charge < 25 + Grade*25 )
		++theArmor.Charge;

	PLAY_SOUND:
    if ( FRand() < 0.2 )
        target.PlaySound(sound'sgMedia.sgStockUp', SLOT_Misc,
          target.SoundDampening*2.5);
}

defaultproperties
{
     ProtectionExpired="Your team SupplierX immunity has expired."
     EquipRate=2.700000
     BuildingName="SupplierX"
     BuildCost=800
     BuildTime=60.000000
     MaxEnergy=20000.000000
}
