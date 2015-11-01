class CoreModifierRules expands Object
	config
	perobjectconfig;

var() config bool bHasConfig;
var() config float LeechMultiplier;
var() config float RuMultiplier;
var() config float BaseUpgradeCost;
var() config float SuddenDeathScale;

function ApplyRules( SiegeGI Game)
{
	local int i;

	For ( i=0 ; i<4 ; i++ )
	{
		if ( Game.Cores[i] != none )
		{
			Game.Cores[i].RURewardScale = LeechMultiplier;
			Game.Cores[i].UpgradeCost = BaseUpgradeCost;
			Game.Cores[i].RuMultiplier = RuMultiplier;
			Game.Cores[i].SuddenDeathScale = SuddenDeathScale;
		}
	}
	if ( !bHasConfig )
	{
		bHasConfig = true;
		SaveConfig();
	}
}

defaultproperties
{
    LeechMultiplier=1
    RuMultiplier=1
    BaseUpgradeCost=80
	SuddenDeathScale=1
}
