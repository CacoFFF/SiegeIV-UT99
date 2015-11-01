//=============================================================================
// XC_SupplierBase
// Instant fill supplier
// Made by Higor
//=============================================================================
class XC_SupplierBase expands sgBuilding;

#exec AUDIO IMPORT FILE="Sounds\XC_Supply1.wav" NAME="XC_Supply1" GROUP="XC_"

#exec mesh import mesh=XCSup1 anivfile=Models\XCSup1_a.3d datafile=Models\XCSup1_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=XCSup1 x=0 y=0 z=0
#exec mesh sequence mesh=XCSup1 seq=All startframe=0 numframes=1
#exec meshmap new meshmap=XCSup1 mesh=XCSup1
#exec meshmap scale meshmap=XCSup1 x=0.02930 y=0.02930 z=0.05859

#exec mesh import mesh=XCSup2 anivfile=Models\XCSup2_a.3d datafile=Models\XCSup2_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=XCSup2 x=0 y=0 z=0
#exec mesh sequence mesh=XCSup2 seq=All startframe=0 numframes=1
#exec meshmap new meshmap=XCSup2 mesh=XCSup2
#exec meshmap scale meshmap=XCSup2 x=0.05859 y=0.05859 z=0.11719

#exec mesh import mesh=XCSup3 anivfile=Models\XCSup3_a.3d datafile=Models\XCSup3_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=XCSup3 x=0 y=0 z=0
#exec mesh sequence mesh=XCSup3 seq=All startframe=0 numframes=1
#exec meshmap new meshmap=XCSup3 mesh=XCSup3
#exec meshmap scale meshmap=XCSup3 x=0.05127 y=0.05127 z=0.10254

#exec mesh import mesh=XCSup4 anivfile=Models\XCSup4_a.3d datafile=Models\XCSup4_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=XCSup4 x=0 y=0 z=0
#exec mesh sequence mesh=XCSup4 seq=All startframe=0 numframes=1
#exec meshmap new meshmap=XCSup4 mesh=XCSup4
#exec meshmap scale meshmap=XCSup4 x=0.05859 y=0.05859 z=0.11719

var byte MaxWeapons;
var byte NumWeapons;
var byte DispWeapons;
var XC_SupComp compList, localComp;
var class<Weapon> WeapList[4];
var float basePct, fullPct, curPct;
var float RetouchTimer, DeathDeduction;
var mesh MeshList[4];
var XC_SupFX SupFX[4];

replication
{
	reliable if ( Role==ROLE_Authority )
		WeapList;
}

event PreBeginPlay()
{
	local XC_SupplierBase xOther;

	Super.PreBeginPlay();
	if ( bDeleteMe )
		return;

	MeshList[0] = mesh'XCSup1';
	MeshList[1] = mesh'XCSup2';
	MeshList[2] = mesh'XCSup3';
	MeshList[3] = mesh'XCSup4';

	bCollideWorld = True;

	//Don't stack suppliers
	ForEach RadiusActors (class'XC_SupplierBase', xOther, 80)
	{
		if ( xOther != self )
		{
			if ( (abs(xOther.Location.Z - (Location.Z - 22) ) < 20 ) && (HSize(xOther.Location - Location) > 80) )
			{
				if ( !PutAwayFrom(xOther.Location) )
				{
					Destroy();
					return;
				}
			}
			else
			{
				Destroy();
				return;
			}
		}
	}

	SetCollisionSize( 10, 20);
	SetLocation( Location - vect(0,0,22) );
}

simulated event Touch( actor Other)
{
	local XC_SupComp sC;
	local pawn P;
	local int i;
	local Weapon W;
	local bool bSuccess;
	local float aF;

	if ( (SCount > 0) || bDisabledByEMP )
		return;

	//Simulate supply
	if ( (Level.NetMode == NM_Client) )
	{
		return;
	}

	P = Pawn(Other);
	if ( (P == none) || !P.bIsPlayer || (P.Health <= 0) || (P.PlayerReplicationInfo == none) || (P.PlayerReplicationInfo.Team != Team) )
		return;

	For ( sC=compList ; sC!=none ; sC=sC.nextComp )
	{
		if ( sC.Owner == Other )
			return;
	}


	For ( i=0 ; i<ArrayCount(WeapList) ; i++ )
	{
		if ( WeapList[i] == none )
			break;
		if ( SiegeGI(Level.Game) == none )
			W = Weapon( P.FindInventoryType(WeapList[i]) );
		else
			W = SiegeGI(Level.Game).GivePlayerWeapon( P, WeapList[i]);

		if ( W != none )
		{
			if ( W.AmmoType == none )
				continue;
			aF = W.AmmoType.AmmoAmount; //Keep as float for safety
			aF /= W.AmmoType.MaxAmmo;
			if ( aF * 100 < curPct )
			{
				aF = (W.AmmoType.MaxAmmo * curPct) / 100; //Keep as float for safety
				W.AmmoType.AmmoAmount = aF;
				bSuccess = true;
			} 
		}
	}

	if ( bSuccess )
	{
		PlaySound( sound'XC_Supply1');
		sC = Spawn( class'XC_SupComp', P, '', vect(0,0,0), rot(0,0,0) ); //Create a new counter
		sC.nextComp = compList;
		sC.CountDown = RetouchTimer / Level.TimeDilation;
		sC.RelatedSup = self;
		compList = sC;
		if ( (PlayerPawn(P) != none) && (ViewPort(PlayerPawn(P).Player) != none) )
			localComp = sC;
	}

}

simulated event Timer()
{
	local int i;

	Super.Timer();

	if ( SCount > 0 )
		return;

	if ( Level.NetMode != NM_DedicatedServer )
	{
		For ( i=0 ; i<ArrayCount(WeapList) ; i++ )
			if ( WeapList[i] == none )
			{
				NumWeapons = i;
				break;
			}
		if ( DispWeapons < NumWeapons )
		{
			SupFX[DispWeapons] = class'XC_SupFX'.static.Setup( self, Location + NextWeaponOffset() );
			//Spawn energy wave at same offset?
			DispWeapons++;
		}
	}
}

simulated function vector NextWeaponOffset()
{
	local vector aLoc;

	if ( MaxWeapons == 3 )
	{
		if ( DispWeapons == 0 )
			return vect(0,-25,45);
		else if ( DispWeapons == 1 )
			return vect(23,15,45);
		else if ( DispWeapons == 2 )
			return vect(-23,15,45);
	}
	else if ( MaxWeapons > 1 )
	{
		if ( DispWeapons == 0 )
			return vect(0,25,45);
		else if ( DispWeapons == 1 )
			return vect(0,-25,45);
		else if ( DispWeapons == 2 )
			return vect(25,0,45);
		else if ( DispWeapons == 3 )
			return vect(-25,0,45);
	}
	return vect(0,0,40);
}

static final function float HSize( vector aVec)
{
	return VSize( aVec * vect(1,1,0) );
}

function bool PutAwayFrom( vector aVec)
{
	aVec = aVec - Normal( (aVec - Location) * vect(1,1,0));
	return SetLocation( aVec);
}

event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType )
{
	Super.TakeDamage( damage/3, instigatedBy, hitLocation, momentum, damageType);
}

function Upgraded()
{
	CalculatePerc();
}

simulated function CalculatePerc()
{
	local float aF;

	aF = (fullPct - basePct) / 5;
	curPct = basePct + aF * Grade;
}

event Destroyed()
{
	local XC_SupComp sC;
	Super.Destroyed();
	For ( sC=compList ; sC!=none ; sC=sC.nextComp )
		sC.Destroy();
}

//Reset weapon defaults on hardcoded suppliers
static function ResetWDefaults()
{
}

defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=1
	RetouchTimer=40
	DeathDeduction=25
	Model=Mesh'XCSup1'
	BuildTime=20
	MaxEnergy=3000
	bOnlyOwnerRemove=True
	BuildingName="XC Supplier"
	basePct=10
	fullPct=100
}