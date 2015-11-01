//***********************************************************
// This is a category rule, it will enable techtree functions
// Reverse conditional
//***********************************************************

class sgBuildRuleNot expands sgBaseBuildRule;

var sgBaseBuildRule childRule;
var string childName;

replication
{
	reliable if ( Role==ROLE_Authority )
		childName;
}

simulated function string GetRuleString( optional bool bNegative)
{
	if ( childRule != none )
		return childRule.GetRuleString( !bNegative);
}

simulated function bool IsEnabled()
{
	if ( childRule != none )
		return !childRule.IsEnabled();
}


simulated function bool IsChildRule( sgBaseBuildRule Other)
{
	if ( Other.RuleName ~= childName )
		return true;
}

simulated function AddChild( sgBaseBuildRule Other)
{
	childRule = Other;
}

