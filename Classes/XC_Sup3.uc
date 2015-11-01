//=============================================================================
// XC_Sup3
// Instant fill supplier, 3 weapons
// Made by Higor
//=============================================================================
class XC_Sup3 expands XC_SupplierBase;


defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=3
	RetouchTimer=30
	DeathDeduction=20
	Model=Mesh'XCSup3'
	BuildTime=20
	BuildCost=410
	UpgradeCost=35
	MaxEnergy=3500
	bOnlyOwnerRemove=True
	BuildingName="Extended Supplier"
	basePct=14
	fullPct=32
}