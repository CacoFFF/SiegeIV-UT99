//=============================================================================
// XC_Sup2
// Instant fill supplier, 2 weapons
// Made by Higor
//=============================================================================
class XC_Sup2 expands XC_SupplierBase;


defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=2
	RetouchTimer=30
	DeathDeduction=20
	Model=Mesh'XCSup2'
	BuildTime=15
	BuildCost=150
	UpgradeCost=20
	MaxEnergy=3000
	bOnlyOwnerRemove=True
	BuildingName="Basic Supplier"
	basePct=10
	fullPct=24
}