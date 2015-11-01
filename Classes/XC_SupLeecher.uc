//=============================================================================
// XC_SupLeecher
// Instant fill supplier, 1 weapon
// Made by Higor
//=============================================================================
class XC_SupLeecher expands XC_SupplierBase;


static function ResetWDefaults()
{
	default.WeapList[0] = class'HyperLeecher';
}

defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	bNoUpgrade=True
	MaxWeapons=1
	RetouchTimer=60
	DeathDeduction=10
	Model=Mesh'XCSup1'
	BuildTime=25
	BuildCost=2200
	UpgradeCost=0
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="Leecher Supplier"
	curPct=100
	basePct=100
	fullPct=100
	WeapList(0)=class'HyperLeecher'
}