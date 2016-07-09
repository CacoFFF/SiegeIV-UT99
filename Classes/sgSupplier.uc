//=============================================================================
// sgSupplier.
// * Revised by 7DS'Lust
//=============================================================================
class sgSupplier extends sgEquipmentSupplier;

var() config string Weapons[9];
var() config bool bUseSubclasses;
var() bool            ClassesLoaded;
var() class<Weapon> WeaponClasses[9];
var() float         EquipRate;
var int iWeaponClasses;


event PostBuild()
{
	local Pawn p;
	local sgSupplier sgS;
	local string sLocation;
	
	Super.PostBuild();

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
		ForEach AllActors( class'sgSupplier', sgS)
			if ( sgS.bProtected && (sgS.Team == Team) && (sgS != self) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity)
		AnnounceTeam("Your team has built a Supplier"@sLocation, Team);
}

//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aStorage, aCost;

	if ( Super.AI_Rate(CrtTeam, sgC, cSlot) < 0 ) //Forbidden
		return -1;

	aCost = sgC.BuildCost(cSlot);
	if ( (CrtTeam.AIList.TeamRU() * 1.0) < aCost ) //Too damn expensive
	{
		if ( CrtTeam.MainSupplier != none && CrtTeam.MainSupplier.BuildCost >= aCost ) //We already have a main supplier, don't cast as future project
			return -1;
	}
	return 1 + aCost / 200;
}

function int GetWeaponCount()
{
    if ( Grade < 2 )
        return 3;
    else if ( Grade < 3 )
        return 5;
    else if ( Grade < 4 )
        return 6;
	else if ( Grade < 5 )
        return 8;
	else if ( Grade >= 5 )
        return 9;
    return 3;
}

static function LoadWeaponClasses()
{
	local int i;
	local class<Weapon> weaponClass;
	local string aStr;

	default.ClassesLoaded = true;
	aStr = string(Class'sgSupplier'.default.Class);
	aStr = Left( aStr, InStr(aStr,".")+1 );
	for ( i = 0; i < 9; i++ )
		if ( default.Weapons[i] != "" )
		{
			if ( InStr(default.Weapons[i], ".") > 0 )
				default.WeaponClasses[i] = class<Weapon>(DynamicLoadObject(default.Weapons[i], class'Class'));
			else
				default.WeaponClasses[i] = class<Weapon>(DynamicLoadObject( aStr $ default.Weapons[i], class'Class'));
		}

	//Keep array compacted, faster if weapon fails to load
	default.iWeaponClasses = 9;
	for ( i=0 ; i<default.iWeaponClasses ; i++ )
		if ( default.WeaponClasses[i] == none )
		{
			default.WeaponClasses[i] = default.WeaponClasses[--default.iWeaponClasses];
			default.WeaponClasses[default.iWeaponClasses] = none;
			--i; //Loop this element again
		}
}

static function ClearWeaponClasses()
{
	default.WeaponClasses[0] = none;
	default.WeaponClasses[1] = none;
	default.WeaponClasses[2] = none;
	default.WeaponClasses[3] = none;
	default.WeaponClasses[4] = none;
	default.WeaponClasses[5] = none;
	default.WeaponClasses[6] = none;
	default.WeaponClasses[7] = none;
	default.WeaponClasses[8] = none;
	default.ClassesLoaded = false;
}

function Supply(Pawn target)
{

	local int numWeapons, i, j;
	local Inventory inv;
	local sgArmor theArmor;

    if ( !default.ClassesLoaded )
        LoadWeaponClasses();

	Super.Supply(target);

    numWeapons = min(GetWeaponCount(), default.iWeaponClasses);
	for ( inv=target.Inventory ; inv!=none ; inv=inv.Inventory )
	{
		if ( (Weapon(Inv) == none) || (Weapon(Inv).AmmoType == none) )
		{
			if ( sgArmor(Inv) != none )
				theArmor = sgArmor(Inv);
			continue;
		}
	
		for ( i=0 ; i<numWeapons ; i++ )
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
				if ( j >= numWeapons )
					Goto WEAPONS_READY;
				break;
			}
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
     RuRewardScale=0.6
     ProtectionExpired="Your team Supplier immunity has expired."
     bOnlyOwnerRemove=True
     Weapons(0)="Botpack.Enforcer"
     Weapons(1)="Botpack.ut_biorifle"
     Weapons(2)="Botpack.ShockRifle"
     Weapons(3)="Botpack.PulseGun"
     Weapons(4)="Botpack.ripper"
     Weapons(5)="Botpack.minigun2"
     Weapons(6)="Botpack.UT_FlakCannon"
     Weapons(7)="Botpack.UT_Eightball"
     Weapons(8)="Botpack.SniperRifle"
     EquipRate=1.750000
     AnnounceImmunity=True
     SuppProtectTimeSecs=6000000
     BuildingName="Supplier"
     BuildCost=300
     BuildTime=45.000000
     MaxEnergy=2500.000000
     Model=LodMesh'Botpack.ShockWavem'
     SkinRedTeam=Texture'MotionAlarmSpriteT0'
     SkinBlueTeam=Texture'MotionAlarmSpriteT1'
     SpriteRedTeam=Texture'ContainerSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerSpriteTeam1'
     SkinGreenTeam=Texture'MotionAlarmSpriteT2'
     SkinYellowTeam=Texture'MotionAlarmSpriteT3'
     SpriteGreenTeam=Texture'ContainerSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerSpriteTeam3'
     DSofMFX=2.000000
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     bUseSubclasses=True
}
