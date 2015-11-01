//=============================================================================
// sg_GLAmmo.
//=============================================================================
class sg_GLAmmo expands TournamentAmmo;

#exec MESH IMPORT MESH=sg_GLAmmo ANIVFILE=GLAUNCHER\sg_GLAmmo_a.3d DATAFILE=GLAUNCHER\sg_GLAmmo_d.3d X=0 Y=0 Z=0

#exec MESH ORIGIN MESH=sg_GLAmmo X=0 Y=0 Z=50 ROLL=0.59

#exec MESH SEQUENCE MESH=sg_GLAmmo SEQ=All    STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=sg_GLAmmo SEQ=sg_GLAmmo STARTFRAME=0 NUMFRAMES=1

//MISSING THIS TEXTURE!!!!
#exec TEXTURE IMPORT NAME=JGLauncherSkin FILE=GLauncher\JGLauncherSkin.PCX GROUP=Skins LODSET=2

#exec MESHMAP NEW   MESHMAP=sg_GLAmmo MESH=sg_GLAmmo
#exec MESHMAP SCALE MESHMAP=sg_GLAmmo X=0.05 Y=0.05 Z=0.1

#exec MESHMAP SETTEXTURE MESHMAP=sg_GLAmmo NUM=0 TEXTURE=JGLauncherSkin

//ALSO MISSING!!!!!
#exec TEXTURE IMPORT NAME=sg_GLAmmoI FILE=GLAUNCHER\sg_GLAmmoI.PCX GROUP=Skins MIPS=OFF

var byte CurAmmoMode;
var travel int AmmoCounts[5];
//  RocketAmmo,
//	EMPAmmo, max=15
//	FlameAmmo, max=15
//	ToxicAmmo, max=15
//	FragAmmo; max=30
var int MaxAmmos[5];

replication
{
	reliable if ( bNetOwner && Role == ROLE_Authority )
		AmmoCounts;
}
	
function bool UseAmmo(int AmountNeeded)
{
	local sgGrenadeLauncher GL;

	if ( Instigator == none || !Instigator.bIsPlayer )
		return false;
	
	GL = sgGrenadeLauncher(Instigator.FindInventoryType(class'sgGrenadeLauncher'));
	if ( GL != none )
	{
		if ( (CurAmmoMode == 0 && GL.SharedPack != none && !GL.SharedPack.UseAmmo(AmountNeeded) ) || (AmmoCounts[CurAmmoMode] < AmountNeeded) )
		{
			GL.SetRocketPack();
			GL.SelectNext();
			return false;
		}
		AmmoCounts[CurAmmoMode] -= AmountNeeded;
		GL.SetRocketPack();
		GL.UpdateAmmoCount();
		return true;
	}

	if (AmmoAmount < AmountNeeded)
		return False;
	AmmoAmount -= AmountNeeded;
	return True;
}

function TakeAmmoFrom( sgGrenadeLauncher GL)
{
	local int i, j, k;
	if ( GL.PickupAmmoCount == 20 ) //This is a default drop, set max to all ammos
	{
		For ( i=1 ; i<5 ; i++ )
			AmmoCounts[i] = MaxAmmos[i];
	}
	else if ( GL.PickupAmmoCount == 21 ) //This is a mid random drop
	{
		j = Rand(4) + 1;
		i = Rand(3) + 1;
		if ( i == j )
			i++;
		For ( k=1 ; k<5 ; k++ )
		{
			if ( k==i )			continue; //No ammo here
			else if ( k==j )	AmmoCounts[k] = MaxAmmos[k]; //Full ammo here
			else				AmmoCounts[k] = Clamp(AmmoCounts[k] + Rand(MaxAmmos[k]), 0, MaxAmmos[k]); //Random ammo
		}
	}
	else if ( GL.PickupAmmoCount == 22 ) //Nerfed random drop
	{
		j = Rand(3) + 1;
		i = Rand(3) + 1;
		if ( i == 2 ) //No napalm
			i=4;
		if ( j == 2 )
			j=4;
		AmmoCounts[j] += Clamp(Rand(MaxAmmos[j]/2), Rand(MaxAmmos[j])/2, MaxAmmos[j]); //Random ammo
		AmmoCounts[i] += Clamp(Rand(MaxAmmos[i]/2), Rand(MaxAmmos[i])/2, MaxAmmos[i]); //Random ammo
	}
	else if ( GL.PickupAmmoCount == 23 ) //Nerfed EMP drop
		AmmoCounts[1] = MaxAmmos[1];
	else if ( GL.PickupAmmoCount == 24 ) //Napalm drop
		AmmoCounts[2] = MaxAmmos[2];
	else if ( GL.PickupAmmoCount == 25 ) //Toxic drop
		AmmoCounts[3] = MaxAmmos[3];
	else if ( GL.PickupAmmoCount == 26 ) //Fragmentation drop
		AmmoCounts[4] = MaxAmmos[4];
	else //This weapon was dropped by a pawn
	{
		For ( i=1 ; i<5 ; i++ )
			AmmoCounts[i] = Clamp( AmmoCounts[i] + GL.AmmoCounts[i], 0, MaxAmmos[i] );
	}
	CheckGLState( GL);
}

function InsertAmmoFrom( sg_GLAmmo GL)
{
	AmmoCounts[1] = Min( Max(MaxAmmos[1], AmmoCounts[1]), AmmoCounts[1] + GL.AmmoCounts[1]);
	AmmoCounts[2] = Min( Max(MaxAmmos[2], AmmoCounts[2]), AmmoCounts[2] + GL.AmmoCounts[2]);
	AmmoCounts[3] = Min( Max(MaxAmmos[3], AmmoCounts[3]), AmmoCounts[3] + GL.AmmoCounts[3]);
	AmmoCounts[4] = Min( Max(MaxAmmos[4], AmmoCounts[4]), AmmoCounts[4] + GL.AmmoCounts[4]);
}

function ClearAllAmmo()
{
	AmmoAmount = 0;
	AmmoCounts[0] = 0;
	AmmoCounts[1] = 0;
	AmmoCounts[2] = 0;
	AmmoCounts[3] = 0;
	AmmoCounts[4] = 0;
}

function CopyAmmoValues( sgGrenadeLauncher GL)
{
	GL.AmmoCounts[1] = AmmoCounts[1];
	GL.AmmoCounts[2] = AmmoCounts[2];
	GL.AmmoCounts[3] = AmmoCounts[3];
	GL.AmmoCounts[4] = AmmoCounts[4];
}

function CheckGLState( sgGrenadeLauncher GL)
{
	GL.UpdateAmmoCount();
	if ( AmmoCounts[GL.AmmoMode] == 0 )
		GL.DoSelectNext();
	else
	{
		AmmoAmount = AmmoCounts[GL.AmmoMode];
		MaxAmmo = MaxAmmos[GL.AmmoMode];
	}
}

function bool HandlePickupQuery( inventory Item )
{
	if ( class == item.class ) 
	{
//		if (AmmoAmount==MaxAmmo) return true;
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		if (Item.PickupMessageClass == None)
			Pawn(Owner).ClientMessage( Item.PickupMessage, 'Pickup' );
		else
			Pawn(Owner).ReceiveLocalizedMessage( Item.PickupMessageClass, 0, None, None, item.Class );
		item.PlaySound( item.PickupSound );
		InsertAmmoFrom(sg_GLAmmo(item));
		item.SetRespawn();
		return true;				
	}
	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

function inventory SpawnCopy( Pawn Other )
{
	local sg_GLAmmo Copy;

	Copy = sg_GLAmmo(Super.SpawnCopy(Other));
	Copy.AmmoAmount = AmmoAmount;
	Copy.AmmoCounts[1] = AmmoCounts[1];
	Copy.AmmoCounts[2] = AmmoCounts[2];
	Copy.AmmoCounts[3] = AmmoCounts[3];
	Copy.AmmoCounts[4] = AmmoCounts[4];
	return Copy;
}

defaultproperties
{
	MaxAmmos(0)=48
	MaxAmmos(1)=15
	MaxAmmos(2)=15
	MaxAmmos(3)=20
	MaxAmmos(4)=30

}
