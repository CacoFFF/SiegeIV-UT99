//=============================================================================
// XC_Sup4
// Instant fill supplier, 4 weapons
// Made by Higor
//=============================================================================
class XC_Sup4 expands XC_SupplierBase;


defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=4
	RetouchTimer=30
	DeathDeduction=20
	Model=Mesh'XCSup4'
	BuildTime=25
	BuildCost=700
	UpgradeCost=50
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="Advanced Supplier"
	basePct=16
	fullPct=40
}