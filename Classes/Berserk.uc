//=============================================================================
// Berserk.
//=============================================================================
class Berserk expands TournamentPickup;

//#exec TEXTURE IMPORT NAME=I_Berserk FILE=Graphics\i_berserk.PCX GROUP="Icons" MIPS=OFF

#exec MESH IMPORT MESH=BerserkM ANIVFILE=MODELS\BerserkM_a.3d DATAFILE=MODELS\BerserkM_d.3d
#exec MESH LODPARAMS MESH=BerserkM STRENGTH=0.6
#exec MESH ORIGIN MESH=BerserkM X=0 Y=0 Z=0 ROLL=64
#exec MESH SEQUENCE MESH=BerserkM SEQ=All     STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=BerserkM SEQ=Berserk STARTFRAME=0 NUMFRAMES=1
#exec MESHMAP NEW   MESHMAP=BerserkM MESH=BerserkM
#exec MESHMAP SCALE MESHMAP=BerserkM X=0.0625 Y=0.0625 Z=0.0625

var Weapon BerserkWeapon;
var UDamage UDamageItem;
var int FinalCount;
var bool bDelayActivation;
var bool bFirstActivation;
var bool bAcquireAnimation;

var name WAnim;
var float WRate;

replication
{
	reliable if ( !bNetInitial && ROLE==ROLE_Authority )
		UDamageItem;
}

simulated function FireEffect()
{
	local Weapon W;

	W = BerserkWeapon;
	if ( W == None )
		W = Pawn(Owner).Weapon;

	if ( (UDamageItem != None) && UDamageItem.bActive )
		UDamageItem.FireEffect();
	else if ( W != None )
		W.PlayOwnedSound( Sound'UnrealShare.Generic.RespawnSound', SLOT_Interact, 10,,,1.7);
		
	if ( (W != None) && (Level.NetMode != NM_Client) )
	{
		//Some heuristics to find out which weapons have Animation speed control (used by bots)
		if ( W.IsA('ShockRifle') || W.IsA('SniperRifle') || W.IsA('Ripper') || W.IsA('UT_Biorifle') || W.IsA('Enforcer')
			|| (W.PickupViewMesh==LodMesh'Botpack.ASMD2pick') )
			bAcquireAnimation = true;
	}
}



singular function UsedUp()
{
	RemoveBerserk();
	if ( Owner != None )
	{
		bActive = false;
		if ( Owner.Inventory != None )
		{
			Owner.Inventory.SetOwnerDisplay();
			Owner.Inventory.ChangedWeapon();
		}
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogItemDeactivate(Self, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogItemDeactivate(Self, Pawn(Owner));
	}
	Destroy();
}

function SetOwnerLighting()
{
	local bool bActiveUDamage;

	if ( (Pawn(Owner) != None) && (Pawn(Owner).PlayerReplicationInfo != None) && (Pawn(Owner).PlayerReplicationInfo.HasFlag != None) )
		return;

	bActiveUDamage = (UDamageItem != None) && UDamageItem.bActive;
	if ( !bActive )
	{
		if ( bActiveUDamage )
			UDamageItem.SetOwnerLighting();
		else	
			Owner.LightType = LT_None;
	}
	else
	{
		Owner.AmbientGlow = 254; 
		Owner.LightEffect = LE_NonIncidence;
		Owner.LightBrightness = 255;
		Owner.LightRadius = 10;
		if ( bActiveUDamage )
		{
			Owner.LightHue = 230;
			Owner.LightSaturation=40;
		}
		else
		{
			Owner.LightHue = 20;
			Owner.LightSaturation = 80;
		}
		Owner.LightType = LT_Steady;
	}
}

// Make old weapon normal again.
function RemoveBerserk()
{
	SetOwnerLighting();
	if ( BerserkWeapon != None )
	{
		BerserkWeapon.SetDefaultDisplayProperties();
		if ( TournamentWeapon(BerserkWeapon) != None )
		{
			if ( (UDamageItem != None) && UDamageItem.bActive )
				TournamentWeapon(BerserkWeapon).Affector = UDamageItem;
			else
				TournamentWeapon(BerserkWeapon).Affector = None;
			TournamentWeapon(BerserkWeapon).FireAdjust /= 3;
		}
		BerserkWeapon = None;
	}
}

function SetBerserkWeapon()
{
	local ERenderStyle NewStyle;
	local Texture NewTexture;
	
	CheckUDamage();
	RemoveBerserk();

	if ( !bActive || bDelayActivation )
		return;

	SetOwnerLighting();
	
	// Make new weapon cool.
	BerserkWeapon = Pawn(Owner).Weapon;
	if ( BerserkWeapon != None )
	{
		if ( BerserkWeapon.IsA('TournamentWeapon') )
		{
			TournamentWeapon(BerserkWeapon).Affector = self;
			TournamentWeapon(BerserkWeapon).FireAdjust *= 3;
		}

		if ( Level.bHighDetailMode )
			NewStyle = STY_Translucent;
		else
			NewStyle = STY_Normal;

		if ( (UDamageItem != None) && UDamageItem.bActive )
			NewTexture = FireTexture'BerserkAmp';
		else
			NewTexture = FireTexture'BerserkBase';
			
		BerserkWeapon.SetDisplayProperties( NewStyle, NewTexture, true, true);
	}
}

function CheckUDamage()
{
	local Inventory Inv;
	
	if ( (UDamageItem == None) || UDamageItem.bDeleteMe )
	{
		UDamageItem = None;
		For ( Inv=Owner.Inventory ; Inv!=None ; Inv=Inv.Inventory )
			if ( UDamage(Inv) != None )
			{
				UDamageItem = UDamage(Inv);
				return;
			}
	}
}

simulated event Tick( float DeltaTime)
{
	if ( bActive && (Pawn(Owner) != None) && (Owner.Role >= ROLE_AutonomousProxy) )
		CheckAnimation( Pawn(Owner).Weapon, DeltaTime);
}

simulated function CheckAnimation( Weapon W, float DeltaTime)
{
	if ( W == None )
		return;
	
	if ( W.LatentFloat > DeltaTime )
		W.LatentFloat = W.LatentFloat - DeltaTime * 0.8;
		
	if ( (W.AnimSequence == WAnim) && (W.AnimRate == WRate) )
		return;
		
	if ( bAcquireAnimation )
		bAcquireAnimation = false;
	else
		W.AnimRate *= 2;
	WAnim = W.AnimSequence;
	WRate = W.AnimRate;
}

//
// Player has activated the item
//
state Activated
{
	function Timer()
	{
		Charge--;
		
		if ( Charge < FinalCount )
			Owner.PlaySound( DeActivateSound,, 20);
		if ( Charge <= 0 )
			UsedUp();
	}

	event Tick( float DeltaTime)
	{
		if ( bDelayActivation )
		{
			bDelayActivation = false;
			SetBerserkWeapon();
		}
		Global.Tick( DeltaTime);
	}
	
	function SetOwnerDisplay()
	{
		if( Inventory != None )
			Inventory.SetOwnerDisplay();

		SetBerserkWeapon();
	}

	function ChangedWeapon()
	{
		if( Inventory != None )
			Inventory.ChangedWeapon();

		bDelayActivation = (UDamageItem != None);
		SetBerserkWeapon();
	}

	function EndState()
	{
		bActive = false;
		RemoveBerserk();
	}

	function BeginState()
	{
		local Inventory Inv;
		local Ammo A;

		bActive = true;
		FinalCount = Charge / 6;
		SetTimer( 1.0, true);
		Owner.PlaySound(ActivateSound);	
		CheckUDamage();
		SetBerserkWeapon();	
		
		if ( !bFirstActivation )
			return;
		bFirstActivation = false;
		for ( Inv=Owner.Inventory ; Inv!=None ; Inv=Inv.Inventory )
		{
			A = Ammo(Inv);
			if ( (A != None) && (A != None) && (A.MaxAmmo >= 20) && (A.AmmoAmount < A.MaxAmmo)
				&& !A.IsA('APEAmmo') && !A.IsA('BlueGunAmmo') && !A.IsA('InstagibAmmo') && !A.IsA('HyperLeecherAmmo') )
				A.AmmoAmount = A.MaxAmmo;
		}
	}
}






defaultproperties
{
     bMeshEnviroMap=True
     Mesh=LodMesh'BerserkM'
     Texture=Texture'Botpack.GoldSkin2'
     PickupViewMesh=LodMesh'BerserkM'
     bAutoActivate=True
     bActivatable=True
     bDisplayableInv=True
     bFirstActivation=True
     PickupMessage="You got the Berserk!"
     ItemName="Berserk"
     RespawnTime=120.000000
     Icon=Texture'I_Berserk'
     Charge=30
     MaxDesireability=2.500000
     PickupSound=Sound'HEALTH1'
     DeActivateSound=Sound'AmbModern.OneShot.teleprt3'
     Physics=PHYS_Rotating
}
