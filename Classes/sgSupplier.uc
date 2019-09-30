//=============================================================================
// sgSupplier.
// * Revised by 7DS'Lust
// * Revised by Higor
//=============================================================================
class sgSupplier extends sgEquipmentSupplier;

var() config string Weapons[9];
var() config bool bUseSubclasses;
var() bool            ClassesLoaded;
var() class<Weapon> WeaponClasses[9];

var int iWeaponClasses;


event PostBuild()
{
	local sgSupplier sgS;
	
	Super.PostBuild();

	if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).SupplierProtection )
	{
		bProtected = True;
		ForEach AllActors( class'sgSupplier', sgS)
			if ( sgS.bProtected && (sgS.Team == Team) && (sgS != self) && (sgS.BuildCost >= BuildCost) )
			{
				bProtected = False;
				break;
			}
	}
	if ( bProtected && AnnounceImmunity )
		AnnounceConstruction();
}

function Upgraded()
{
	local sgSupplier sgS;

	Super.Upgraded();
	if ( Grade >= 5 )
	{
		ForEach RadiusActors( class'sgSupplier', sgS, 200)
			if ( (sgS.Team == Team) && (sgS.BuildCost < BuildCost) ) //Never self
				sgS.bOnlyOwnerRemove = false;
	}
}

//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aCost;

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

function bool Supply(Pawn target, sgSupplierQueuer Accumulator, float SupplyFactor)
{
	local int numWeapons, i, j;
	local Inventory inv;
	local Weapon W;
	local float AccumulatedAmmoBase;
	local int AmmoAccBase, AmmoAccNew;
	local int SuppliedCount;

    if ( !default.ClassesLoaded )
        LoadWeaponClasses();

    numWeapons = min(GetWeaponCount(), default.iWeaponClasses);
	AccumulatedAmmoBase = Accumulator.AccumulatedAmmo;
	Accumulator.AccumulatedAmmo += 0.1 * SupplyFactor / 20.0; //Takes 20 seconds to complete cycle
	for ( inv=target.Inventory ; inv!=none ; inv=inv.Inventory )
	{
		W = Weapon(Inv);
		if ( (W == none) || (W.AmmoType == none) )
			continue;
	
		for ( i=0 ; i<numWeapons ; i++ )
		{
			if ( (!bUseSubclasses && W.class == default.WeaponClasses[i]) || (bUseSubclasses && ClassIsChildOf(W.class, default.WeaponClasses[i]) ) )
			{
				j++;
				if ( W.AmmoType.AmmoAmount < W.Default.PickupAmmoCount / 2 )
	                W.AmmoType.AmmoAmount = W.Default.PickupAmmoCount / 2;
				else if ( W.AmmoType.AmmoAmount < W.AmmoType.MaxAmmo )
				{
					SuppliedCount++;
					AmmoAccBase = AccumulatedAmmoBase * W.AmmoType.MaxAmmo;
					AmmoAccNew = Accumulator.AccumulatedAmmo * W.AmmoType.MaxAmmo;
					if ( AmmoAccNew > AmmoAccBase )
						W.AmmoType.AmmoAmount = Min( W.AmmoType.AmmoAmount + (AmmoAccNew-AmmoAccBase), W.AmmoType.MaxAmmo);
				}
				if ( j >= numWeapons )
					Goto WEAPONS_READY;
				break;
			}
		}
	}

	WEAPONS_READY:
	return Super.Supply(target,Accumulator,SupplyFactor) | (SuppliedCount > 0);
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
     RuRewardScale=0.6
	 SupplySoundFrequency=0.2
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
     GUI_Icon=Texture'GUI_Sup'
     bUseSubclasses=True
}
