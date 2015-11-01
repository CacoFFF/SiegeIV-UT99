//=============================================================================
// XC_SupMega
// Instant fill supplier, 1 weapon
// Made by Higor
//=============================================================================
class XC_SupMega expands XC_SupplierBase;


defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	bNoUpgrade=True
	MaxWeapons=1
	RetouchTimer=30
	DeathDeduction=20
	Model=Mesh'XCSup1'
	BuildTime=25
	BuildCost=2000
	UpgradeCost=0
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="Mega Supplier"
	curPct=200
	basePct=200
	fullPct=200
}