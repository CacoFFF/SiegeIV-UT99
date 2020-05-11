//****************************************
//**** Rule class for named INI files ****
//****************************************
class SiegeCategoryRules expands Object
	config
	perobjectconfig;

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
B=class?C=category?RULE?cost=othercost?properties(a=b,c=d,e=f)?weight=weight
CATEGORY=name?maxweight=weight
*/

/*
Maps can override a line, N being the line number, OVERRIDE being the line text
'mapname' can be a single map or multiple maps (in,braces)

MAP=mapname*?N?OVERRIDE
*/

/*
Categories without MaxWeight have no weight limit
Buildings have a default weight of 1
*/

const SGS = class'SiegeStatics';

var() config bool bHasConfig;
var() config string Rule[320];
var string ParsingRule[320];
var int iNum; //Internal, faster processing
var string sPkg;

struct ParseParms
{
	var class<sgBuilding> BuildClass;
	var bool bOnceOnly, bRequiresFinish, bPersistantTimer, bOverTime;
	var int BCount;
	var float LReq, BTimer;
	var string Name, oNames[8];
	var int MinRules;
};

struct ParseParmsBuild
{
	var class<sgBuilding> BuildClass;
	var string Name;
	var int Cost;
	var int Weight;
	var int Category;
	var string Properties;
	var sgBaseBuildRule Rule;
};

struct ParseParmsCategory
{
	var string Name;
	var int MaxWeight;
};


function FullParse( sgCategoryInfo Other)
{
	local string aStr, sParm;
	local int i, j;
	local ParseParms         P       , PDef;
	local ParseParmsBuild    Build   , BuildDef;
	local ParseParmsCategory Category, CategoryDef;
	local sgBuildRuleCount BuildRule;
	local sgBaseBuildRule aRule[8];
	local sgBuildRuleNot NotRule;
	local sgBuildRuleCombo ComboRule;
	
	local int SkippedRules;
	local int ParsedRules;

	if ( Other == none )
		return;

	// Defaults
	PDef.BCount = 1; //Defaults to minimum 1 build in RULES
	PDef.MinRules = 255; //This will auto adapt to max rule count in combos
	BuildDef.Weight = 1;
		
	sPkg = string(class);
	sPkg = Left( sPkg, InStr(sPkg,".")+1 );

	// Whole list considered
	iNum = ArrayCount(Rule);
	
	// TODO (469): USE DYNAMIC ARRAY FOR RULE SYSTEM
	
	// Copy rules to temporary storage
	For ( i=0; i<ArrayCount(Rule); i++)
		ParsingRule[i] = Rule[i];
	
	// Parse MAP= modifiers
	For ( i=0; i<iNum; i++)
		if ( ParseHeader(ParsingRule[i],"MAP=",aStr) )
		{
			sParm = SGS.static.NextParameter( aStr, "?");
			if ( LevelInList( string(Other.Outer.Name), sParm) )
			{
				sParm = SGS.static.NextParameter( aStr, "?");
				if ( GetNumber(sParm,j) && j<ArrayCount(ParsingRule) )
				{
					sParm = SGS.static.NextParameter( aStr, "?");
					ParsingRule[j] = sParm;
					Log("PARSE: Setting line"@j@"to"@sParm);
				}
			}
			ParsingRule[j] = "";
		}

	// Parse categories
	j = 0;
	For ( i=0; i<iNum; i++)
		if ( ParseHeader(ParsingRule[i],"CATEGORY=",aStr) )
		{
			Category = CategoryDef;
			Category.Name      = class'SiegeStatics'.static.NextParameter( aStr, "?");
			Category.MaxWeight = int(class'SiegeStatics'.static.NextParameter( aStr, "?"));
			if ( Category.Name != "" )
				Other.AttachCategory( Category.Name, Category.MaxWeight);
			ParsingRule[i] = "";
		}

	// Parse base rules
	For ( i=0; i<iNum; i++)
		if ( ParseHeader(ParsingRule[i],"RULE(",aStr) )
		{
			P = PDef;
			SGS.static.ReplaceText( aStr, " ", "");
			P.Name = SGS.static.NextParameter( aStr, "?");
			while ( aStr != "" )
			{
				sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( sParm ~= "onceonly" )              P.bOnceOnly=true;
				else if ( sParm ~= "finished" )         P.bRequiresFinish=true;
				else if ( sParm ~= "cooldown" )         P.bPersistantTimer=true;
				else if ( sParm ~= "overtime" )         P.bOverTime = true;
				else if ( !ParseBuild( sParm, "class=", P.BuildClass)
				       && !ParseInt  ( sParm, "min="  , P.BCount)
				       && !ParseFloat( sParm, "level=", P.LReq)
				       && !ParseFloat( sParm, "timer=", P.BTimer) )
				{
					Log("SIEGE RULES: Extraneous parameter found for rule "$i$": "$sParm);
				}
			}
			if ( P.Name == "" )
				Log("SIEGE RULES: No rule name for rule "$i);
			else if ( P.BCount <= 0 )
				Log("SIEGE RULES: Invalid Build count parameter for rule "$i$": "$P.BCount);
			else if ( P.BuildClass == none )
				Log("SIEGE RULES: No build class loaded for rule "$i);
			else
			{
				BuildRule = Other.Spawn(class'sgBuildRuleCount',none,,vect(0,0,0) );
				BuildRule.RuleName = P.Name;
				BuildRule.RuleString = ParsingRule[i];
				BuildRule.BuildClass = P.BuildClass;
				BuildRule.bOnceOnly = P.bOnceOnly;
				BuildRule.TargetTimer = P.BTimer;
				BuildRule.TargetCount = P.BCount;
				BuildRule.bOverTime = P.bOverTime;
				BuildRule.bPersistantTimer = P.bPersistantTimer;
				if ( P.LReq > 0 || P.bRequiresFinish )
					BuildRule.AddRequiresLevel( fClamp( P.LReq, 0, 5) );
				Other.AttachRule( BuildRule);
			}
			ParsingRule[i] = "";
		}
		
		
	SkippedRules = -1;
	ParsedRules = -1;
	while ( (SkippedRules != 0) && (ParsedRules != 0) )
	{
		SkippedRules = 0;
		ParsedRules = 0;
		
		// Parse negation rules
		For ( i=0; i<iNum; i++)
			if ( ParseHeader(ParsingRule[i],"NOT(",aStr) )
			{
				P = PDef;
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
				P.Name = class'SiegeStatics'.static.NextParameter( aStr, "?");
				aRule[0] = Other.GetNamedRule( aStr);
				//aStr is the negated RULE, if accessed none, then on rules were set!
				if ( P.Name == "" )
				{
					Log("SIEGE RULES: No rule name for rule "$i);
					ParsingRule[i] = "";
				}
				else if ( aRule[0] == none )
				{
					SkippedRules++;
					continue;
				}
				else
				{
					ParsedRules++;
					NotRule = Other.Spawn(class'sgBuildRuleNot',none,,vect(0,0,0) );
					NotRule.RuleName = P.Name;
					NotRule.RuleString = ParsingRule[i];
					NotRule.ChildName = aStr;
					NotRule.ChildRule = aRule[0];
					Other.AttachRule( NotRule);
					ParsingRule[i] = "";
				}
			}
			
		// Parse combo rules
		For ( i=0; i<iNum; i++)
			if ( ParseHeader(ParsingRule[i],"COMBO(",aStr) )
			{
				P = PDef;
				class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
				P.Name = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( P.Name == "" )
				{
					Log("SIEGE RULES: No rule name for rule "$i);
					ParsingRule[i] = "";
					continue;
				}
				j=0;
				while ( aStr != "" )
				{
					sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
					if ( !ParseInt( sParm, "Req=", P.MinRules) )
					{
						aRule[j] = Other.GetNamedRule( sParm);
						if ( aRule[j++] == none )
						{
							j = -1;
							break;
						}
					}
				}
				if ( j < 0 )
				{
					SkippedRules++;
					continue;
				}
				ParsedRules++;
				ComboRule = Other.Spawn(class'sgBuildRuleCombo',none,,vect(0,0,0) );
				ComboRule.RuleName = P.Name;
				ComboRule.RuleString = ParsingRule[i];
				ComboRule.MinRules = Clamp(P.MinRules,1,j);
				ComboRule.iChild = j;
				while ( --j >= 0 )
				{
					ComboRule.ChildRules[j] = aRule[j];
					ComboRule.ChildNames[j] = aRule[j].RuleName;
				}
				Other.AttachRule( ComboRule);
			}

	}
	
	// Log leftover rules
	For ( i=0; i<iNum; i++)
		if ( ParseHeader(ParsingRule[i],"COMBO(",aStr)
			|| ParseHeader(ParsingRule[i],"NOT(",aStr) )
			Log("SIEGE RULES: Rule "$i$" could not locate all referenced rules");
	
	// Parse building rules
	For ( i=0 ; i<iNum ; i++)
		if ( ParseHeader(ParsingRule[i],"B=",aStr) )
		{
			Build = BuildDef;
			ParsingRule[i] = "";
			class'SiegeStatics'.static.ReplaceText( aStr, " ", "");
			sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
			Build.BuildClass = LoadClass(sParm);
			if ( Build.BuildClass == none )
			{
				Log("SIEGE RULES: No class for rule "$i$": "$sParm);
				continue;
			}
			while ( aStr != "" )
			{
				sParm = class'SiegeStatics'.static.NextParameter( aStr, "?");
				if ( !ParseInt   ( sParm, "C="         , Build.Category)
				  && !ParseInt   ( sParm, "Cost="      , Build.Cost)
				  && !ParseInt   ( sParm, "Weight="    , Build.Weight)
				  && !ParseHeader( sParm, "Properties(", Build.Properties)
				  && !ParseHeader( sParm, "Name="      , Build.Name) )
				{
					//Apply rule
					Build.Rule = Other.GetNamedRule( sParm);
					if ( Build.Rule == none )
						Log("SIEGE RULES: No rule "$sParm$" found for "$Build.BuildClass);
				}
			}
//			Other.AttachBuild( Build.BuildClass, Build.Category, Build.Rule, Build.Name, Build.Cost, Build.Weight, Build.Properties);
			Other.AttachBuild( Build);
		}
		
	// Log unparsed rules
	For ( i=0 ; i<iNum ; i++)
		if ( ParsingRule[i] != "" )
			Warn( ParsingRule[i] );
}


function class<sgBuilding> LoadClass( string aStr)
{
	local class<sgBuilding> Result;
	
	Result = class<sgBuilding>(DynamicLoadObject(sPkg$aStr,class'class'));
	if ( Result == None )
		Log("SIEGE RULES: Unable to load building class"@aStr);

	return Result;
}


/*--------------------------------------------------------------------
	Parser Helpers (TODO: Move to global funcs)
--------------------------------------------------------------------*/
function bool ParseHeader( string Rule, string InHeader, out string OutRuleData)
{
	local int i;
	
	i = Len(InHeader);
	if ( Left(Rule,i) ~= InHeader )
	{
		OutRuleData = Mid(Rule,i);
		if ( (Right(InHeader,1) == "(") && (Right(OutRuleData,1) == ")") )
			OutRuleData = Left( OutRuleData, Len(OutRuleData)-1);
		return true;
	}
	return false;
}

function bool ParseInt( string Data, string Parameter, out int OutInt)
{
	local int i;
	
	i = Len(Parameter);
	if ( Left( Data, i) ~= Parameter )
	{
		OutInt = int(Mid( Data, i));
		return true;
	}
	return false;
}

function bool ParseFloat( string Data, string Parameter, out float OutFloat)
{
	local int i;
	
	i = Len(Parameter);
	if ( Left( Data, i) ~= Parameter )
	{
		OutFloat = float(Mid( Data, i));
		return true;
	}
	return false;
}

function bool ParseBuild( string Data, string Parameter, out class<sgBuilding> OutBuild)
{
	local int i;
	
	i = Len(Parameter);
	if ( Left( Data, i) ~= Parameter )
	{
		OutBuild = LoadClass(Mid( Data, i));
		return true;
	}
	return false;
}

function bool LevelInList( string LevelName, string LevelList)
{
	local string CurLevel;
	
	SGS.static.ReplaceText( LevelList, " ", "");
	
	// Multi level
	if ( (Left(LevelList,1) == "(") && (Right(LevelList,1) == ")") )
		LevelList = Mid(LevelList,1,Len(LevelList)-2);

	AGAIN:
	CurLevel = SGS.static.NextParameter( LevelList, ",");
	if ( CurLevel != "" )
	{
		if ( SGS.static.MatchesFilter(LevelName,CurLevel) )
			return true;
		goto AGAIN;
	}
	return false;
}

function bool GetNumber( string Param, out int i)
{
	SGS.static.ReplaceText( Param, " ", "");
	i = int(Param);
	return string(i) == Param;
}


