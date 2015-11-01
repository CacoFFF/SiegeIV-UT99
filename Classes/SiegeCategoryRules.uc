//****************************************
//**** Rule class for named INI files ****
//****************************************
class SiegeCategoryRules expands Object
	config perobjectconfig;


/*
FACTS:
?			is the delimiter

RULE(name?class=?min=?finished?level=?timer=?cooldown?onceonly)

NOT( name?rule)
reverses result

COMBO( name?rule?rule?rule?req=) (up to 8) (REQ is optional number of rules required)
*/



/*
CATEGORIES[17]
as always
*/

/*
B=class?C=category?RULE?cost=othercost?properties(a=b,c=d,e=f)
CATEGORY=
*/



var() config bool bHasConfig;
var() config string Rule[256];
var int iNum; //Internal, faster processing
var string sPkg;

struct ParseParms
{
	var class<sgBuilding> BuildClass;
	var bool bOnceOnly, bRequiresFinish, bPersistantTimer, bOverTime;
	var int BCount;
	var float LReq, BTimer;
	var string sName, oNames[8];
	var byte MinRules;
};

function FullParse( sgCategoryInfo Other)
{
	local string aStr, sParm;
	local int i, j;
	local ParseParms P, E;
	local sgBuildRuleCount BuildRule;
	local sgBaseBuildRule aRule[8];
	local sgBuildRuleNot NotRule;
	local sgBuildRuleCombo ComboRule;
	local class<sgBuilding> tmpClass;
	local float aCost;
	local string sProps;

	if ( Other == none )
		return;

	sPkg = string(class);
	sPkg = Left( sPkg, InStr(sPkg,".")+1 );
	iRuleCtr();
	E.BCount = 1; //Defaults to minimum 1 build in RULES
	E.MinRules = 255; //This will auto adapt to max rule count in combos

	For ( i=0 ; i<iNum ; i++ )
	{
		if ( Rule[i] == "" )
			continue;

		if ( Left(Rule[i], 2) ~= "B=" )
		{
			aStr = Mid( Rule[i], 2);
			if ( InStr(aStr, " ") >= 0 )
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
			sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
			tmpClass = LoadClass(sParm);
			if ( tmpClass == none )
				continue;
			aRule[0] = none;
			j = 0;
			aCost = 0;
			sProps = "";
			while ( aStr != "" )
			{
				sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( Left(sParm, 2) ~= "C=" )
					j = int(Mid(sParm,2));
				else if ( Left(sParm,5) ~= "Cost=" )
					aCost = float( Mid(sParm,5) );
				else if ( Left(sParm, 11) ~= "Properties(" )
					sProps = Mid(sParm, 11, Len(sParm)-12 );
				else //Apply rule
				{
					aRule[0] = Other.RuleList.GetByName( sParm);
					if ( aRule[0] == none )
						Log("SIEGE RULES: No rule "$sParm$" found for "$tmpClass);
				}
			}
			Other.AttachBuild( tmpClass, j, aRule[0], aCost, sProps);
		}
		else if ( Left(Rule[i], 9) ~= "CATEGORY=" )
		{
			Other.AttachCategory( Mid(Rule[i], 9));
		}
		else if ( Left(Rule[i], 5) ~= "RULE(" )
		{
			P = E;
			aStr = Mid(Rule[i], 5, Len(Rule[i])-6 );
			if ( InStr(aStr, " ") >= 0 )
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
			P.sName = class'SiegeStatics'.static.NextParameter( aStr, "?");
			if ( P.sName == "" )
				continue;
			while ( aStr != "" )
			{
				sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( sParm ~= "onceonly" )
					P.bOnceOnly=true;
				else if ( sParm ~= "finished" )
					P.bRequiresFinish=true;
				else if ( sParm ~= "cooldown" )
					P.bPersistantTimer=true;
				else if ( sParm ~= "overtime" )
					P.bOverTime = true;
				else if ( Left(sParm, 6) ~= "class=" )
					P.BuildClass = LoadClass( Mid(sParm,6));
				else if ( Left(sParm, 4) ~= "min=" )
					P.BCount = int( Mid(sParm,4) );
				else if ( Left(sParm, 6) ~= "level=" )
					P.LReq = fClamp(float( Mid(sParm,6) ),0,5);
				else if ( Left(sParm, 6) ~= "timer=" )
					P.BTimer = float( Mid(sParm,6));
				else
					Log("SIEGE RULES: Extraneous parameter found for rule "$i$": "$sParm);
			}
			if ( P.BCount <= 0 )
			{
				Log("SIEGE RULES: Invalid Build count parameter for rule "$i$": "$P.BCount);
				continue;
			}
			if ( P.BuildClass == none )
			{
				Log("SIEGE RULES: No build class loaded for rule "$i);
				continue;
			}
			BuildRule = Other.Spawn(class'sgBuildRuleCount',none,,vect(0,0,0) );
			BuildRule.RuleName = P.sName;
			BuildRule.RuleString = Rule[i];
			BuildRule.BuildClass = P.BuildClass;
			BuildRule.bOnceOnly = P.bOnceOnly;
			BuildRule.TargetTimer = P.BTimer;
			BuildRule.TargetCount = P.BCount;
			BuildRule.bOverTime = P.bOverTime;
			BuildRule.bPersistantTimer = P.bPersistantTimer;
			if ( P.LReq > 0 || P.bRequiresFinish )
				BuildRule.AddRequiresLevel( P.LReq );
			Other.AttachRule( BuildRule);
		}
		else if ( Left(Rule[i],4) ~= "NOT(" )
		{
			P = E;
			aStr = Mid(Rule[i], 4, Len(Rule[i])-5 );
			if ( InStr(aStr, " ") >= 0 )
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
			P.sName = class'SiegeStatics'.static.NextParameter( aStr, "?");
			if ( P.sName == "" )
				continue;
			//aStr is the negated RULE, if accessed none, then on rules were set!
			aRule[0] = Other.RuleList.GetByName( aStr);
			if ( aRule[0] == none )
			{
				Log("SIEGE RULES: No target rule "$aStr$" defined before "$P.sName);
				continue;
			}
			NotRule = Other.Spawn(class'sgBuildRuleNot',none,,vect(0,0,0) );
			NotRule.RuleName = P.sName;
			NotRule.RuleString = Rule[i];
			NotRule.ChildName = aStr;
			NotRule.ChildRule = aRule[0];
			Other.AttachRule( NotRule);
		}
		else if ( Left(Rule[i],6) ~= "COMBO(" )
		{
			P = E;
			aStr = Mid(Rule[i], 6, Len(Rule[i])-7 );
			if ( InStr(aStr, " ") >= 0 )
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
			P.sName = class'SiegeStatics'.static.NextParameter( aStr, "?");
			if ( P.sName == "" )
				continue;
			j=0;
			while ( aStr != "" )
			{
				sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( Left(sParm,4) ~= "req=" )
					P.MinRules = int( Mid(sParm,4) );
				else
				{
					aRule[j] = Other.RuleList.GetByName( sParm);
					if ( aRule[j++] == none )
					{
						Log("SIEGE RULES: No target rule "$sParm$" defined before "$P.sName);
						continue;
					}
				}
			}
			ComboRule = Other.Spawn(class'sgBuildRuleCombo',none,,vect(0,0,0) );
			ComboRule.RuleName = P.sName;
			ComboRule.RuleString = Rule[i];
			ComboRule.MinRules = Clamp(P.MinRules,1,j);
			ComboRule.iChild = j;
			while ( --j >= 0 )
			{
				ComboRule.ChildRules[j] = aRule[j];
				ComboRule.ChildNames[j] = aRule[j].RuleName;
			}
			Other.AttachRule( ComboRule);
		}
		else
			Warn( Rule[i]);
	}
}


function class<sgBuilding> LoadClass( string aStr)
{
	return class<sgBuilding> ( DynamicLoadObject(sPkg$aStr,class'class')  );
}

//Internal - count rules for faster proc
function iRuleCtr()
{
	local int i;

	i = 255;
	while ( (Rule[i] == "") && (i>=0) )
		i--;
	iNum = ++i;
}

