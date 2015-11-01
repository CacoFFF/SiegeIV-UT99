//***********************************************************
// This is a category rule, it will enable techtree functions
// Combination of rules
//***********************************************************

class sgBuildRuleCombo expands sgBaseBuildRule;

var sgBaseBuildRule childRules[8];
var string childNames[8];
var int iChild, MinRules;

replication
{
	reliable if ( Role==ROLE_Authority )
		childNames, MinRules;
}

simulated function string GetRuleString( optional bool bNegative)
{
	local string Result, BadResult;
	local int i, k;
	
	For ( i=0 ; i<iChild ; i++ )
	{
		if ( childRules[i] == none )
			continue;
		Result = childRules[i].GetRuleString( bNegative);
		if ( !childRules[i].IsEnabled() )
			BadResult = Result;
		else
			k++;
	}
	if ( k < MinRules )
		return BadResult;
	return Result;
}

simulated function bool IsEnabled()
{
	local int i, k;

	For ( i=0 ; i<iChild ; i++ )
	{
		if ( childRules[i] != none && childRules[i].IsEnabled() )
			if ( ++k >= MinRules )
				return true;
	}
}


simulated function bool IsChildRule( sgBaseBuildRule Other)
{
	local int i;

	For ( i=0 ; i<ArrayCount(childNames) ; i++ )
		if ( Other.RuleName ~= childNames[i] )
			return true;
}

simulated function AddChild( sgBaseBuildRule Other)
{
	childRules[iChild++] = Other;
}

