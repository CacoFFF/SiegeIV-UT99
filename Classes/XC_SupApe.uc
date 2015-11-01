//=============================================================================
// XC_SupApe
// Instant fill supplier, Ape cannon
// Made by Higor
//=============================================================================
class XC_SupApe expands XC_SupplierBase;


static function ResetWDefaults()
{
	default.WeapList[0] = class'ApeCannon';
}

defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=1
	RetouchTimer=70
	DeathDeduction=10
	Model=Mesh'XCSup3'
	BuildTime=35
	BuildCost=3500
	UpgradeCost=200
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="Ape Supplier"
	curPct=40
	basePct=40
	fullPct=70
	WeapList(0)=class'ApeCannon'
}