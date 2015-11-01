//=============================================================================
// XC_SupApe
// Instant fill supplier, Pulse rifle
// Made by Higor
//=============================================================================
class XC_SupIG expands XC_SupplierBase;


static function ResetWDefaults()
{
	default.WeapList[0] = class'SiegeInstagibRifle';
}

defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=1
	RetouchTimer=80
	DeathDeduction=10
	Model=Mesh'XCSup1'
	BuildTime=35
	BuildCost=5000
	UpgradeCost=500
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="InstaGib Supplier"
	curPct=2
	basePct=2
	fullPct=12
	WeapList(0)=class'SiegeInstagibRifle'
}