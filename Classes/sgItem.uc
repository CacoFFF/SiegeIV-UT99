//=============================================================================
// sgItem.
// Optimized and reviewed by Higor
//=============================================================================
class sgItem extends sgBuilding
    abstract;

var() sound         FinishSound;
var() class<Inventory>     InventoryClass;
var() bool          SwitchToWeapon, PlayPickupSound;
var() bool bFullAmmoRestock;
var() bool bTakeProductVisual;
var() bool bTouchMechanics; //Make product use simple pickup methods
var() bool bOwnerlessCheck; //sgItem is particularly expensive when ownerless, check every 2 ticks instead
var() int ProductCount;

var Inventory MyProduct; //Safety checks, Inventory chain isn't replicated
var float LastOwnerCheck;



replication
{
    reliable if ( bNetInitial && (Role == ROLE_Authority) )
		bTakeProductVisual;
    reliable if ( Role == ROLE_Authority )
    	MyProduct;
}

simulated function CompleteBuilding()
{
    local Pawn P;
    local Inventory Inv;

	if ( bTakeProductVisual && ((myFX == None)||myFX.bDeleteMe) && (Level.NetMode != NM_DedicatedServer) )
		SetupProductFX();

	if ( bDisabledByEMP || (Role != ROLE_Authority) )
		return;
		
	P = Pawn(Owner);
	if ( (P != none) && !P.bDeleteMe )
	{
		if ( Spectator(P) != none )
		{
			if ( Level.TimeSeconds - LastOwnerCheck > 300 )
				Goto ALLOW_PICKUP;
			return;
		}
		LastOwnerCheck = Level.TimeSeconds;
		if ( P.bCollideActors && P.bIsPlayer && (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team == Team) )
		{
			if ( (VSize(P.Location - Location) < 44 + P.CollisionRadius) && GiveItems(P) )
				Destroy();
		}
	}
	else if ( Level.TimeSeconds - LastOwnerCheck > 15 )
	{
		ALLOW_PICKUP:
		//Once every 2 timers
		bOwnerlessCheck = !bOwnerlessCheck;
		if ( bOwnerlessCheck )
			return;
		foreach RadiusActors(class'Pawn', P, 48)
			if ( P.bIsPlayer && P.Health > 0 && P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.Team == Team && GiveItems(P) )
	        {
				Destroy();
				return;
			}
	}
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();
	if ( FinishSound != none )
		PlayFinishSound();


	if ( bTakeProductVisual && (Role == ROLE_Authority) )
	{
		Inventory.bHidden = false;
		Inventory.bReplicateInstigator = true;
		Inventory.Instigator = self;
		MyProduct = Inventory;
	}
}

function PlayFinishSound()
{
	PlaySound(FinishSound, SLOT_None, 5);
}

//Spawn the products
function PostBuild()
{
	if ( !SpawnProducts() )
	{
		Destroy();
		return;
	}
	if ( bTakeProductVisual )
	{
		Model = none;
		bReplicateMFX = true;
	}
	Super.PostBuild();
}

function bool SpawnProducts()
{
	local Inventory Product, I, lastInv;
	local vector aVec;
	local int Idx;
	local rotator eRot; //Empty rotator

	AGAIN:
	aVec = VRand() * 30000;
	ForEach RadiusActors (class'Inventory', I, 50, aVec)
	{
		aVec = vect(0,0,0);
		break;
	}
	if ( aVec == vect(0,0,0) )
		Goto AGAIN;

	NEWPRODUCT:
	Product = Spawn( ProductClass(Idx), none,, aVec, eRot);
	Product.LifeSpan = 0;
	if ( (Product == none) || Product.bDeleteMe ) //SpawnNotify or Mutator killed our product, find possible replacement(s)
	{
		ForEach RadiusActors( class'Inventory', I, 50, aVec)
			if ( !I.bDeleteMe )
			{
				if ( lastInv == none )	Inventory = I;
				else					lastInv.Inventory = I;
				ModifyProduct( I, Idx);
				lastInv = I;
			}
	}
	else
	{
		if ( lastInv == none )	Inventory = Product;
		else					lastInv.Inventory = Product;
		ModifyProduct( Product, Idx);
		lastInv = Product;
	}
	if ( ++Idx < ProductCount )
		Goto NEWPRODUCT;

	For ( I=Inventory ; I!=none ; I=I.Inventory )
	{
		I.bHidden = true;
		I.GotoState('Idle2');
		I.SetCollision( false, false, false );
		I.SetTimer(0.0,False);
		I.RotationRate.Pitch = MFXrotX.Pitch * 0.5;
		I.RotationRate.Roll = MFXrotX.Roll * 0.5;
		I.RotationRate.Yaw = MFXrotX.Yaw * 0.5;
		I.SetPhysics(PHYS_Rotating);
		I.Style = STY_Translucent;
		I.RespawnTime = 0;
		I.SetLocation( Location + (I.Location - aVec) );
		I.LifeSpan = 0;
	}

	return Inventory != none;
}

function class<Inventory> ProductClass( int Idx)
{
	if ( Idx == 0 )
		return InventoryClass;
}
function ModifyProduct( Inventory I, int Idx)
{
	if ( (Weapon(I) != none) && bFullAmmoRestock )
		Weapon(I).PickupAmmoCount = Weapon(I).AmmoName.default.MaxAmmo;
	if ( !PlayPickupSound )
		I.PickupSound = none;
}

//Make sure ALL items can be given
function bool GiveItems( Pawn Other)
{
	local Inventory Discarded, I, inv;
	local bool bReject;

	For ( I=Inventory ; I!=none ; I=I.Inventory )
	{
		inv = Other.FindInventoryType( I.class);
		if ( inv == none )
			continue;
		I.Tag = 'ThisHasDupe';
		if ( !CustomDenyPickup( Other, I) )
		{
			if ( CustomAllowPickup( Other, I) )
				continue;
			if ( Weapon(Inv) != none )
			{
				if ( (Weapon(inv).AmmoType != none) && (Weapon(inv).AmmoType.AmmoAmount < Weapon(inv).AmmoType.MaxAmmo) )
					continue;
			}
		}
		I.Tag = '';
		bReject = true;
	}

	if ( bReject )
		return false;

	While ( MyProduct != none )
	{
		MyProduct.SetOwner(none);
		Inventory = Inventory.Inventory;
		MyProduct.Inventory = none;
		MyProduct.Style = MyProduct.default.Style;

		if ( MyProduct.Tag != 'ThisHasDupe' )
		{
			MyProduct.GiveTo( Other);
			if ( Pickup(MyProduct) != none )
			{
				if ( MyProduct.bActivatable )
				{
					if ( Other.SelectedItem == None)
	 					Other.SelectedItem = MyProduct;
					if ( Pickup(MyProduct).bAutoActivate && Other.bAutoActivate )
						MyProduct.Activate();
				}
				if ( MyProduct.PickupMessageClass == None )
					Other.ClientMessage(MyProduct.PickupMessage, 'Pickup');
				else
					Other.ReceiveLocalizedMessage(MyProduct.PickupMessageClass, 0, None, None, MyProduct.Class);
				Pickup(MyProduct).PickupFunction(Other);
			}
			else if ( Weapon(MyProduct) != none )
			{
				MyProduct.bHeldItem = true;
				Weapon(MyProduct).GiveAmmo(Other);
				if ( PlayerPawn(Other) != none )
					PlayerPawn(Other).GetWeapon( class<Weapon> (MyProduct.class) );
			}
		}
		else
		{
			if ( !CustomGiveDuplicate( Other, MyProduct) )
			{
				if ( Weapon(MyProduct) != none )
				{
					Inv = Weapon(Other.FindInventoryType( MyProduct.Class)).AmmoType;
					if ( Inv != none )
						Ammo(Inv).AmmoAmount = Min(Ammo(Inv).AmmoAmount + Weapon(MyProduct).PickupAmmoCount, Ammo(Inv).MaxAmmo);
				}
			}
			MyProduct.Destroy();
		}
		if ( MyProduct.PickupSound != none )
			Other.PlaySound( MyProduct.PickupSound, SLOT_None, Other.SoundDampening*3);
		MyProduct = Inventory;
	}
	if ( OwnerPRI != none )
		OwnerPRI.sgInfoSpreeCount++;
	return true;
}

//Allow an item to bypass the default rules
function bool CustomAllowPickup( Pawn Other, inventory Inv);
//Override giving item when duplicate exists, deletes the new item
function bool CustomGiveDuplicate( Pawn Other, inventory Inv);
//Never add the item if a duplicate is found under the following conditions
function bool CustomDenyPickup( Pawn Other, inventory Inv);


simulated function bool ClientFindProduct()
{
	local inventory I;
	
	ForEach RadiusActors (class'Inventory', I, 50)
		if ( I.Instigator == self )
		{
			MyProduct = I;
			Inventory = I;
			return true;
		}
}

simulated function SetupProductFX()
{
	if ( (MyProduct != none) || ClientFindProduct() )
	{
		MyProduct.SetOwner(none);
		myFX = Spawn(class'sgItemMeshFX', Self,,, MyProduct.Rotation );
		myFX.Mesh = MyProduct.Mesh;
		myFX.DrawScale = MyProduct.DrawScale;
		myFX.Fatness = MyProduct.Fatness;
		myFX.SetOwner( MyProduct);
		myFX.SetPhysics( PHYS_Trailer);
	}
}

defaultproperties
{
     bOnlyOwnerRemove=True
     MaxEnergy=200
     FinishSound=Sound'UnrealShare.Pickups.HEALTH1'
     PlayPickupSound=True
     UpgradeCost=0
     BuildTime=2.500000
     SpriteScale=0.400000
     SkinRedTeam=None
     SkinBlueTeam=None
     MFXrotX=(Yaw=20000)
     bCanTakeOrb=False
     ProductCount=1
     CollisionHeight=26
}
