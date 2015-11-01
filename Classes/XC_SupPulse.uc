//=============================================================================
// XC_SupApe
// Instant fill supplier, Pulse rifle
// Made by Higor
//=============================================================================
class XC_SupPulse expands XC_SupplierBase;


static function ResetWDefaults()
{
	default.WeapList[0] = class'AsmdPulseRifle';
}

defaultproperties
{
	CollisionHeight=42
	CollisionRadius=26
	MaxWeapons=1
	RetouchTimer=70
	DeathDeduction=10
	Model=Mesh'XCSup4'
	BuildTime=35
	BuildCost=3500
	UpgradeCost=300
	MaxEnergy=4000
	bOnlyOwnerRemove=True
	BuildingName="Pulse Supplier"
	curPct=40
	basePct=40
	fullPct=70
	WeapList(0)=class'AsmdPulseRifle'
}