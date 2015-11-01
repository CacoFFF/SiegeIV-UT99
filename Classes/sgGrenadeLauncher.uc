//=============================================================================
// sg_GLpickup.
//=============================================================================
class sgGrenadeLauncher extends TournamentWeapon;

//Pickup mesh
#exec MESH IMPORT MESH=sg_GLpickup ANIVFILE=GLauncher\sg_GLpickup_a.3d DATAFILE=GLauncher\sg_GLpickup_d.3d
#exec MESH LODPARAMS MESH=sg_GLpickup HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=sg_GLpickup X=-50.00 Y=-200.00 Z=10.00 YAW=0.00 ROLL=0.00 PITCH=0.00

#exec MESH SEQUENCE MESH=sg_GLpickup SEQ=All       STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=sg_GLpickup SEQ=sg_GLpickup  STARTFRAME=0 NUMFRAMES=1

#exec TEXTURE IMPORT NAME=JGLauncherSkin FILE=GLauncher\JGLauncherSkin.PCX GROUP=Skins LODSET=2
#exec MESHMAP SETTEXTURE MESHMAP=sg_GLpickup NUM=2 TEXTURE=JGLauncherSkin
#exec MESHMAP SETTEXTURE MESHMAP=sg_GLpickup NUM=1 TEXTURE=JGLauncherSkin
#exec MESHMAP SCALE MESHMAP=sg_GLpickup X=0.10 Y=0.10 Z=0.20


//First person mesh
#exec MESH IMPORT MESH=sg_GL1st ANIVFILE=GLauncher\sg_GL1st_a.3d DATAFILE=GLauncher\sg_GL1st_d.3d
#exec MESH LODPARAMS MESH=sg_GL1st HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=sg_GL1st X=-140.00 Y=-75.00 Z=20.00 YAW=0.00 ROLL=0.00 PITCH=0.00

#exec MESH SEQUENCE MESH=sg_GL1st SEQ=All       STARTFRAME=0 NUMFRAMES=86
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=DISPENSE  STARTFRAME=0 NUMFRAMES=24
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Down      STARTFRAME=24 NUMFRAMES=11
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Fire      STARTFRAME=35 NUMFRAMES=10
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Reload    STARTFRAME=45 NUMFRAMES=25
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Select    STARTFRAME=70 NUMFRAMES=11
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Still     STARTFRAME=81 NUMFRAMES=1
#exec MESH SEQUENCE MESH=sg_GL1st SEQ=Sway      STARTFRAME=82 NUMFRAMES=4

#exec TEXTURE IMPORT NAME=Jsg_GL1st1 FILE=GLauncher\sg_JGL1st1.PCX GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=Jsg_GL1st2 FILE=GLauncher\sg_JGL1st2.PCX GROUP=Skins LODSET=2
// #exec TEXTURE IMPORT NAME=Jsg_GL1st3 FILE=GLauncher\sg_JGL1st3.PCX GROUP=Skins
#exec TEXTURE IMPORT NAME=Jsg_GL1st4 FILE=GLauncher\sg_JGL1st4.PCX GROUP=Skins LODSET=2

#exec MESHMAP SETTEXTURE MESHMAP=sg_GL1st NUM=1 TEXTURE=Jsg_GL1st1
#exec MESHMAP SETTEXTURE MESHMAP=sg_GL1st NUM=2 TEXTURE=Jsg_GL1st2
// #exec MESHMAP SETTEXTURE MESHMAP=sg_GL1st NUM=3 TEXTURE=Jsg_GL1st3
#exec MESHMAP SETTEXTURE MESHMAP=sg_GL1st NUM=4 TEXTURE=Jsg_GL1st4
#exec MESHMAP SCALE MESHMAP=sg_GL1st X=0.01 Y=0.01 Z=0.02


//Third person mesh
#exec MESH IMPORT MESH=sg_GL3rd ANIVFILE=GLauncher\sg_GL3rd_a.3d DATAFILE=GLauncher\sg_GL3rd_d.3d
#exec MESH LODPARAMS MESH=sg_GL3rd HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=sg_GL3rd X=-90.00 Y=-20.00 Z=-20.00 YAW=0.00 ROLL=0.00 PITCH=0.00

#exec MESH SEQUENCE MESH=sg_GL3rd SEQ=All       STARTFRAME=0 NUMFRAMES=11
#exec MESH SEQUENCE MESH=sg_GL3rd SEQ=Fire      STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=sg_GL3rd SEQ=Still     STARTFRAME=10 NUMFRAMES=1

#exec MESHMAP SETTEXTURE MESHMAP=sg_GL3rd NUM=1 TEXTURE=JGLauncherSkin
//#exec MESHMAP SETTEXTURE MESHMAP=sg_GL3rd NUM=2 TEXTURE=JGLauncherSkin
#exec MESHMAP SCALE MESHMAP=sg_GL3rd X=0.06 Y=0.06 Z=0.13

//Audio
// #exec AUDIO IMPORT FILE="GLauncher\Bounce1.WAV" NAME="Bounce1" GROUP="GrenadeLauncher"
#exec AUDIO IMPORT FILE="GLauncher\GrenadeHit.WAV" NAME="GrenadeHit" GROUP="GrenadeLauncher"

#exec AUDIO IMPORT FILE="GLauncher\GrenadeSelect1.WAV" NAME="GrenadeSelect1" GROUP="GrenadeLauncher"
#exec AUDIO IMPORT FILE="GLauncher\GrenadeLoad3.WAV" NAME="GrenadeLoad3" GROUP="GrenadeLauncher"
#exec AUDIO IMPORT FILE="GLauncher\GrenadeShot2.WAV" NAME="GrenadeShot2" GROUP="GrenadeLauncher"
#exec AUDIO IMPORT FILE="GLauncher\GrenadeSet3.WAV" NAME="GrenadeSet3" GROUP="GrenadeLauncher"

const TypeCount = 0x00000005;

var FontInfo MyFonts;

var byte AmmoTypes; //THIS IS A BITFIELD
var byte AmmoMode;
//0 - Rockets
//1 - EMP
//2 - Flame
//3 - Toxic
//4 - Frag

var class<Projectile> ProjectileTypes[5];
var RocketPack SharedPack;

//Initial values here too, because weapon is dropped when killed instead of ammo
var travel int AmmoCounts[5];
//  RocketAmmo,
//	EMPAmmo,
//	FlameAmmo,
//	ToxicAmmo,
//	FragAmmo;
var Color AmmoColors[5];

var float ammoTimer;

replication
{
	reliable if ( Role == ROLE_Authority ) //This data takes less bandwidth
		AmmoTypes, AmmoMode;
}

simulated function PostRender( canvas Canvas)
{
	local float XL, YL, Scale, X, YOffset;
	local string aStr, aStr2;
	local int i, j;
	local sg_GLAmmo GLAmmo;

	if ( MyFonts == none )
	{
		GetFonts();
		return;
	}

	GLAmmo = sg_GLAmmo(AmmoType);
	if ( GLAmmo == none )
		return;

	Scale = Canvas.ClipY / 960.0f;
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.TextSize("999", XL, YL);

	if ( bHideWeapon )		YOffset = Canvas.ClipY - YL*3;
	else					YOffset = Canvas.ClipY - 70*Scale - YL*3; 

	For ( i=0 ; i<TypeCount ; i++ )
	{
		if ( GLAmmo.AmmoCounts[i] > 0 )
		{
			Canvas.SetPos( Canvas.ClipX - 48 * Scale, YOffSet - j * 36 * Scale);
			Canvas.DrawColor = AmmoColors[i];
			Canvas.Style = ERenderStyle.STY_Translucent;
			if ( AmmoMode == i )
				Canvas.Style = ERenderStyle.STY_Normal;
			else
			{
				Canvas.DrawColor.R -= 20;
				Canvas.DrawColor.G -= 20;
				Canvas.DrawColor.B -= 20;
			}
			Canvas.DrawIcon( Texture'sg_GLAmmoI', Scale);
			Canvas.SetPos( Canvas.ClipX - (48 * Scale + XL), YOffSet - j * 36 * Scale);
			if ( AmmoMode == i )
			{
				Canvas.DrawColor.R = 255;
				Canvas.DrawColor.G = 255;
				Canvas.DrawColor.B = 255;
			}
			Canvas.DrawText( GLAmmo.AmmoCounts[i] );
			j++;
		}
	}

}

function BringUp()
{
	Super.BringUp();
	NetUpdateFrequency = 15;
	Enable('Tick');
}

//Customized to allow respawning with custom ammo types
function inventory SpawnCopy( pawn Other )
{
	local sgGrenadeLauncher Copy;

	if( Level.Game.ShouldRespawn(self) )
	{
		Copy = spawn(class'sgGrenadeLauncher',Other,,,rot(0,0,0));
		Copy.Tag           = Tag;
		Copy.Event         = Event;
		Copy.PickupAmmoCount = PickupAmmoCount;
		if ( !bWeaponStay )
			GotoState('Sleeping');
	}
	else
		Copy = self;

	Copy.RespawnTime = 0.0;
	Copy.bHeldItem = true;
	Copy.bTossedOut = false;
	Copy.GiveTo( Other );
	Copy.Instigator = Other;
	Copy.GiveAmmo(Other);
	Copy.SetSwitchPriority(Other);
	if ( !Other.bNeverSwitchOnPickup )
		Copy.WeaponSet(Other);
	Copy.AmbientGlow = 0;
	return Copy;
}

function GiveAmmo( Pawn Other )
{
	local sg_GLAmmo GAmmo;

	if ( AmmoName == None )
		return;
	AmmoType = Ammo(Other.FindInventoryType(AmmoName));
	GAmmo = sg_GLAmmo(AmmoType);

	if ( GAmmo != none )
	{
//		Log("Use existing AMMO");
		GAmmo.TakeAmmoFrom(self);
	}
	else if ( AmmoType != None )
		AmmoType.AddAmmo(PickUpAmmoCount);
	else
	{
		AmmoType = Spawn(AmmoName);	// Create ammo type required		
		Other.AddInventory(AmmoType);		// and add to player's inventory
		AmmoType.BecomeItem();
		GAmmo = sg_GLAmmo(AmmoType);
		if ( GAmmo != none )
		{
			GAmmo.TakeAmmoFrom( self);
			SetRocketPack();
			UpdateAmmoCount();
		}
		else
			AmmoType.AmmoAmount = PickUpAmmoCount; 
		AmmoType.GotoState('Idle2');
	}
}

function DropFrom( vector StartLocation)
{
	local sg_GLAmmo GAmmo;

	if ( !SetLocation(StartLocation) )
		return; 
	AIRating = Default.AIRating;
	bMuzzleFlash = 0;
	AmbientSound = None;

	GAmmo = sg_GLAmmo( AmmoType);
	if ( GAmmo != none )
	{
		GAmmo.CopyAmmoValues( self);
		GAmmo.AmmoCounts[0] = 0;
		SharedPack = none;
//		UpdateAmmoCount();
		PickupAmmoCount = 1;
		GAmmo.ClearAllAmmo();
	}
	else if ( AmmoType != None )
	{
		PickupAmmoCount = 21 + Rand(10); //Monster drop, randomize ammo?
		AmmoType.AmmoAmount = 0;
	}
	AmmoType = none;
	Super(Inventory).DropFrom(StartLocation);
}

function UpdateAmmoCount()
{
	local sg_GLAmmo GAmmo;
	local int i, NewCode;

	if ( AmmoType == none )
		return;
	GAmmo = sg_GLAmmo( AmmoType);
	GAmmo.CurAmmoMode = AmmoMode;

	if ( AmmoMode == 0 )
	{
		if ( SharedPack != none )
			GAmmo.AmmoCounts[0] = SharedPack.AmmoAmount;
		else
			GAmmo.AmmoCounts[0] = 0;
	}
	else
		GAmmo.AmmoAmount = GAmmo.AmmoCounts[AmmoMode];
	AmmoType.AmmoAmount = GAmmo.AmmoCounts[AmmoMode];
	AmmoType.MaxAmmo = GAmmo.MaxAmmos[AmmoMode];
	For ( i=0 ; i<ArrayCount(AmmoCounts) ; i++ )
	{
		AmmoCounts[i] = GAmmo.AmmoCounts[i];
		if ( AmmoCounts[i] > 0 )
			NewCode = NewCode | (1 << i);
	}
	AmmoTypes = NewCode;
}

simulated function PlayFiring()
{
	PlayAnim( 'Fire', 0.6, 0.05);	
	PlayOwnedSound(FireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);	
}

simulated function PlayAltFiring()
{
	DoSelectNext();
	PlayOwnedSound(AltFireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);
	PlayAnim('DISPENSE', 1.3, 0.05);
}


state ClientFiring
{
	simulated function AnimEnd()
	{
		if ( AnimSequence == 'Fire' )
		{
			if ( AmmoType != none && (AmmoType.AmmoAmount <= 0) && CanSelectNext() )
			{
				PlayAltFiring();
				return;
			}
			PlaySound( sound'GrenadeLoad3', SLOT_None, 3.0 * Pawn( Owner ).SoundDampening );	
			PlayAnim( 'Reload', 1.85, 0.05 );
			return;
		}

		if ( (Pawn(Owner) == None)
			|| ((AmmoType != None) && (AmmoType.AmmoAmount <= 0)) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
}

state NormalFire
{
	function AnimEnd()
	{
		if ( AnimSequence == 'Fire' )
		{
			if ( AmmoType != none && (AmmoType.AmmoAmount <= 0) && CanSelectNext() )
			{
				if ( CanSelectNext() )
					Global.AltFire(1);
				else
					PutDown();
				return;
			}
			PlayOwnedSound( sound'GrenadeLoad3', SLOT_None, 3.0 * Pawn( Owner ).SoundDampening );	
			PlayAnim( 'Reload', 1.85, 0.05 );
			return;
		}
		Finish();
	}

Begin:
	Sleep(0.0);
}


simulated function bool ClientAltFire( float Value )
{
	if ( bCanClientFire && CanSelectNext() && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0) ) )
	{
		PlayAltFiring();
		if ( Role < ROLE_Authority )
			GotoState('ClientAltFiring');
		return true;
	}
	return false;
}

function AltFire( float Value )
{
	if ( (AmmoType == None) && (AmmoName != None) )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}

	bPointing=True;
	bCanClientFire = true;
	if ( ClientAltFire(Value) )
		GotoState('AltFiring');
}

function bool HandlePickupQuery( inventory Item )
{
	local int OldAmmo;
	local Pawn P;
	local sg_GLAmmo GAmmo;

	if (Item.Class == Class)
	{
		if ( Weapon(item).bWeaponStay && (!Weapon(item).bHeldItem || Weapon(item).bTossedOut) )
			return true;
		P = Pawn(Owner);
		GAmmo = sg_GLAmmo(AmmoType);
		if ( GAmmo != none )
			GAmmo.TakeAmmoFrom( sgGrenadeLauncher(item) );
		else if ( AmmoType != None )
		{
			OldAmmo = AmmoType.AmmoAmount;
			if ( AmmoType.AddAmmo(Weapon(Item).PickupAmmoCount) && (OldAmmo == 0) 
				&& (P.Weapon.class != item.class) && !P.bNeverSwitchOnPickup )
					WeaponSet(P);
		}
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		if (Item.PickupMessageClass == None)
			P.ClientMessage(Item.PickupMessage, 'Pickup');
		else
			P.ReceiveLocalizedMessage( Item.PickupMessageClass, 0, None, None, item.Class );
		Item.PlaySound(Item.PickupSound);
		Item.SetRespawn();   
		return true;
	}
	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}


//////////////////////////////////////////////////////
/// LOGIC STUFF

event Tick( float DeltaTime)
{
	if ( Instigator != none )
	{
		if ( (ammoTimer -= DeltaTime) < 0 )
		{
			SetRocketPack();
			UpdateAmmoCount();
			ammoTimer = 1 + FRand();
		}
	}
}

function bool SetRocketPack()
{
	local inventory Inv;

	if ( (Instigator == none) || (Instigator.PlayerReplicationInfo == none) )
	{
		SharedPack = none;
		return false;
	}

	if ( SharedPack != none && (SharedPack.Owner == Owner || SharedPack.Instigator == Instigator) )
	{
		if ( sg_GLAmmo(AmmoType) != none )
		{
			sg_GLAmmo(AmmoType).AmmoCounts[0] = SharedPack.AmmoAmount;
			if ( AmmoMode == 0 )
				AmmoType.AmmoAmount = SharedPack.AmmoAmount;
		}
		return true;
	}
	SharedPack = none;
	For ( Inv=Instigator.Inventory ; Inv!=none ; Inv=Inv.Inventory )
	{
		if ( Inv.IsA('RocketPack') )
		{
			SharedPack = RocketPack(Inv);
			return true;
		}
	}
}

simulated function bool CanSelectNext()
{
	local int iTypes, iMode;
	
	iTypes = AmmoTypes;
	iMode = AmmoMode;
	iMode++;
	While ( iMode < TypeCount )
	{
		if ( (iTypes & (1 << iMode)) > 0 )
			return true;
		iMode++;
	}
	iMode = 0;
	While ( iMode < AmmoMode )
	{
		if ( (iTypes & (1 << iMode)) > 0 )
			return true;
		iMode++;
	}
	return false;
}


simulated function DoSelectNext()
{
	local int iTypes, iMode;
	
	iTypes = AmmoTypes;
	iMode = AmmoMode;
	iMode++;
	While ( iMode < TypeCount )
	{
		if ( (iTypes & (1 << iMode)) > 0 )
		{
			AmmoMode = iMode; //MISSING: ADJUST PROJECTILE TYPE!!!
			ProjectileClass = ProjectileTypes[iMode];
			UpdateAmmoCount();
			return;
		}
		iMode++;
	}
	iMode = 0;
	While ( iMode < AmmoMode )
	{
		if ( (iTypes & (1 << iMode)) > 0 )
		{
			AmmoMode = iMode;
			ProjectileClass = ProjectileTypes[iMode];
			UpdateAmmoCount();
			return;
		}
		iMode++;
	}

//	PUT DOWN WEAPON!

}

function bool WeaponSet(Pawn Other)
{
	if ( AmmoType != none && AmmoType.AmmoAmount <= 0 )
		DoSelectNext();
	return Super.WeaponSet(Other);
}

simulated function GetFonts()
{
	local fontInfo aF;

	ForEach AllActors ( class'FontInfo', aF)
	{
		MyFonts = aF;
		return;
	}
}

defaultproperties
{
    FireSound=Sound'GrenadeShot2'
    AltFireSound=Sound'GrenadeSelect1'
    SelectSound=Sound'GrenadeSelect1'

	MultiSkins(3)=texture'ZappyBlank'
	LodBias=3
    
    ProjectileClass=class'sgMK2Grenade'
    ProjectileTypes(0)=class'sgMK2Grenade'
    ProjectileTypes(1)=class'EMPGrenade'
    ProjectileTypes(2)=class'NapalmGrenade'
    ProjectileTypes(3)=class'ToxicGrenade'
    ProjectileTypes(4)=class'FragGrenade'
    AmmoColors(0)=(R=160,G=230,B=230)
    AmmoColors(1)=(R=50,G=50,B=255)
    AmmoColors(2)=(R=255,G=30,B=30)
    AmmoColors(3)=(R=30,G=255,B=30)
    AmmoColors(4)=(R=255,G=255,B=100)
    PickupAmmoCount=20
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    bWarnTarget=True
    bAltWarnTarget=True
    bSplashDamage=True
	AmmoName=Class'sg_GLAmmo'
    shakemag=350.00
    shaketime=0.20
    shakevert=7.50
    AIRating=0.70
    RefireRate=0.20
    AltRefireRate=0.20

    AutoSwitchPriority=5
    InventoryGroup=4
    PickupMessage="You got the Grenade Launcher."
    ItemName="GrenadeLauncher"
    PlayerViewOffset=(X=3.50,Y=-1.80,Z=-2.00),
    PlayerViewMesh=LodMesh'sg_GL1st'
    BobDamping=0.987
    PickupViewMesh=LodMesh'sg_GLpickup'
    Mesh=LodMesh'sg_GLpickup'
    ThirdPersonMesh=LodMesh'sg_GL3rd'
    Mesh=LodMesh'GLpickup'
    AmbientGlow=15
    bNoSmooth=False
    CollisionRadius=21.00
    CollisionHeight=16.00
}
