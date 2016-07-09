//=============================================================================
// sgSupplierXXL
// Optimized by Higor
//=============================================================================
class sgSupplierXXL extends sgEquipmentSupplier;

var() config string Weapons[9];
var() config bool bUseSubclasses;
var() bool            ClassesLoaded;
var() class<Weapon> WeaponClasses[9];
var() float         EquipRate;
var int iWeaponClasses;

function Upgraded()
{
	local sgSupplier sgS;

	Super.Upgraded();
	if ( Grade >= 5 )
	{
		ForEach RadiusActors( class'sgSupplier', sgS, 150)
			if ( sgS.Team == Team )
				sgS.bOnlyOwnerRemove = false;
	}
}

event PostBuild()
{
	local Pawn p;
	local sgSupplierXXL sgS;
	local int nSuppliers;
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
		ForEach AllActors( class'sgSupplierXXL', sgS)
			if ( sgS.bProtected && (sgS.Team == Team) && (sgS != self) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity)
		AnnounceTeam("Your team has built a Super Supplier"@sLocation, Team);
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

simulated function CompleteBuilding()
{
	local sgSupplier MySupplier;

	Super.CompleteBuilding();
	if (  Role != ROLE_Authority )
        return;

	if ( FRand() < 0.3 ) //HIGOR: Timer happens 10 times per second, we really don't need to hog that much resources
		ForEach AllActors(Class'sgSupplier', MySupplier)
			if ( MySupplier.bProtected && (MySupplier.Team == Team) )
				MySupplier.bProtected=False;
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
	aStr = string(Class'sgSupplierXXL'.default.Class);
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

function Supply(Pawn Other)
{
    local int numWeapons, i, j;
    local Inventory inv;
	local sgArmor theArmor;

    if ( !default.ClassesLoaded )
        LoadWeaponClasses();
        
	Super.Supply(Other);

	numWeapons = min(GetWeaponCount(), default.iWeaponClasses);
	for ( inv=Other.Inventory ; inv!=none ; inv=inv.Inventory )
	{
		if ( (Weapon(Inv) == none) || (Weapon(Inv).AmmoType == none) )
		{
			if ( sgArmor(Inv) != none )
			{
				theArmor = sgArmor(Inv);
				if ( FRand() < 0.2 + (Grade/7.5) && theArmor.Charge < 25 + Grade*25 )
					++theArmor.Charge;
			}
			continue;
		}

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

	//Armor inventory not found? Maybe rearranged to last in chain?
	if ( theArmor == none )
	{
		while ( inv != none )
		{
			if ( sgArmor(Inv) != none )
			{
				theArmor = sgArmor(Inv);
				if ( FRand() < 0.2 + (Grade/7.5) && theArmor.Charge < 25 + Grade*25 )
					++theArmor.Charge;
				Goto PLAY_SOUND;
			}
			inv = inv.Inventory;
		}
		SpawnArmor( Other);
	}

	PLAY_SOUND:
	if ( FRand() < 0.35 )
		Other.PlaySound(sound'sgMedia.sgStockUp', SLOT_Misc, Other.SoundDampening*2.5);
}

function Pawn FindTarget()
{
	local Pawn p;

	foreach RadiusActors(class'Pawn', p, 72)
		if ( p.bIsPlayer && (p.Health > 0) && (p.PlayerReplicationInfo != None) && (p.PlayerReplicationInfo.Team == Team) )
			Supply(P);

    return None;
}


/*
REMINDER:
ORB EQUALS APE, HYPER LEECHER AND PULSE RIFLE RECHARGE
*/

defaultproperties
{
     ProtectionExpired="Your team Super Supplier immunity has expired."
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
     EquipRate=4.000000
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
     bUseSubclasses=True
}