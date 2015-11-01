//=============================================================================
// sgItemGrenadeLauncher
// Dummy grenade launcher, to be used by subclasses
// by Higor
//=============================================================================
class sgItemGrenadeLauncher extends sgItem;

var int GrenadeCounts[4];

function ModifyProduct( Inventory I, int Idx)
{
	local sgGrenadeLauncher GL;
	local int j;

	Super.ModifyProduct( I, Idx);
	GL = sgGrenadeLauncher(I);
	if ( GL != none )
	{
		GL.PickupAmmoCount = 1;
		For ( j=0 ; j<4 ; j++ )
			GL.AmmoCounts[j+1] = GrenadeCounts[j];
	}
}

function bool CustomDenyPickup( Pawn Other, inventory Inv)
{
	local sgGrenadeLauncher GL;
	local sg_GLAmmo GLAmmo;
	local int i;
	
	GL = sgGrenadeLauncher(Other.FindInventoryType( class'sgGrenadeLauncher'));
	GLAmmo = sg_GLAmmo(GL.AmmoType);
	if ( GL != none && GLAmmo != none )
	{
		For ( i=0 ; i<4 ; i++ )
		{
			if ( GrenadeCounts[i] <= 0 )
				continue;
			if ( GLAmmo.AmmoCounts[i+1] < GLAmmo.MaxAmmos[i+1] )
				return false;
		}
	}
	return true;
}

function bool CustomAllowPickup( Pawn Other, inventory Inv)
{
	return true;
}


function bool CustomGiveDuplicate( Pawn Other, inventory Inv)
{
	local sgGrenadeLauncher GL;
	local sg_GLAmmo GLAmmo;
	local int i;
	
	GL = sgGrenadeLauncher(Other.FindInventoryType( class'sgGrenadeLauncher'));
	GLAmmo = sg_GLAmmo(GL.AmmoType);
	if ( GL != none && GLAmmo != none )
	{
		For ( i=0 ; i<4 ; i++ )
			GLAmmo.AmmoCounts[i+1] = Min( GLAmmo.AmmoCounts[i+1] + GrenadeCounts[i], GLAmmo.MaxAmmos[i+1]);
	}
	return true;
}

//Other.PlaySound(Sound'UnrealShare.Pickups.WeaponPickup', SLOT_None, Other.SoundDampening*3);


defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     GrenadeCounts(0)=15
     GrenadeCounts(1)=15
     GrenadeCounts(2)=20
     GrenadeCounts(3)=30
     bFullAmmoRestock=True
     InventoryClass=Class'sgGrenadeLauncher'
     SwitchToWeapon=True
     BuildingName="Grenade Launcher"
     BuildCost=2100
     UpgradeCost=0
     BuildTime=9.000000
     SpriteScale=0.400000
     Model=LodMesh'sg_GLPickup'
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SpriteRedTeam=Texture'CoreSpriteTeam0'
     SpriteBlueTeam=Texture'CoreSpriteTeam1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteGreenTeam=Texture'CoreSpriteTeam2'
     SpriteYellowTeam=Texture'CoreSpriteTeam3'
     DSofMFX=1.000000
     MaxEnergy=250
}
