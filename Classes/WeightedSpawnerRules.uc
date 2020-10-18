//*******************************************
// Rules for Weighted Item Spawner - By Higor
//*******************************************

class WeightedSpawnerRules expands Object
	config
	perobjectconfig;

var() config bool bHasConfig;
var() config int InitialWaitSecs;
var() config int BaseRespawnSecs;
var() config int InitialWeightCap;
var() config int WeightIncPerSpawn;
var() config bool bRealSeconds;
var() config float WeightToExtraTimeScale;
var() config float OvertimeTimeScale;
var() config float SpecialItemChance;

var() config string InventoryList[32];
var() config string SpecialInventoryList[32];
var string sPkg;

function FullParse( WeightedItemSpawner Other)
{
	local int i, j;
	local string aCmd, aStr;

	sPkg = string(class);
	sPkg = Left( sPkg, InStr(sPkg,".")+1 );

	Other.InitialSeconds = InitialWaitSecs;
	Other.BaseSeconds = BaseRespawnSecs;
	Other.bRealTimer = bRealSeconds;
	Other.WeightCap = InitialWeightCap;
	Other.WeightInc = WeightIncPerSpawn;
	Other.WeightToExtraTimeScale = WeightToExtraTimeScale;
	Other.OvertimeTimeScale = OvertimeTimeScale;
	Other.SpecialItemChance = SpecialItemChance;
	For ( i=0 ; i<ArrayCount(InventoryList) ; i++ )
	{
		if ( InventoryList[i] == "" )
			continue;
		aCmd = InventoryList[i];
		aStr = class'SiegeStatics'.static.NextParameter( aCmd, "?");
		Other.ItemList[j] = LoadInventory( aStr);
		if ( Other.ItemList[j] == none )
			continue;
		while ( aCmd != "" )
		{
			aStr = class'SiegeStatics'.static.NextParameter( aCmd, "?");
			if ( Left(aStr,5) ~= "minw=" )
				Other.ItemMinWeight[j] = int(Mid(aStr,5));
			else if ( Left(aStr,5) ~= "maxw=" )
				Other.ItemMaxWeight[j] = int(Mid(aStr,5));
			else if ( Left(aStr, 11) ~= "Properties(" )
				Other.ItemProps[j] = Mid(aStr, 11, Len(aStr)-12 );
			else if ( Left(aStr, 8) ~= "Overtime" )
				Other.OvertimeOnly[j] = 1;
			else
				Log("Extraneous parameter at line "$i$": "$aStr);
		}
		j++;
	}
	j = 0;
	For ( i=0 ; i<ArrayCount(SpecialInventoryList) ; i++ )
	{
		if ( InventoryList[i] == "" )
			continue;
		aCmd = InventoryList[i];
		aStr = class'SiegeStatics'.static.NextParameter( aCmd, "?");
		Other.SpecialItemList[j] = LoadInventory( aStr);
		if ( Other.SpecialItemList[j] == none )
			continue;
		while ( aCmd != "" )
		{
			aStr = class'SiegeStatics'.static.NextParameter( aCmd, "?");
			if ( Left(aStr,5) ~= "minw=" )
				Other.SpecialItemMinWeight[j] = int(Mid(aStr,5));
			else if ( Left(aStr,5) ~= "maxw=" )
				Other.SpecialItemMaxWeight[j] = int(Mid(aStr,5));
			else if ( Left(aStr, 11) ~= "Properties(" )
				Other.SpecialItemProps[j] = Mid(aStr, 11, Len(aStr)-12 );
			else if ( Left(aStr, 8) ~= "Overtime" )
				Other.SpecialOvertimeOnly[j] = 1;
			else
				Log("Extraneous parameter at line "$i$": "$aStr);
		}
		j++;
	}
	Other.iItems = j;

	if ( !bHasConfig )
	{
		bHasConfig = true;
		SaveConfig();
	}
}

function class<Inventory> LoadInventory( string aStr)
{
	if ( InStr( aStr, ".") < 0 )
		aStr = sPkg$aStr;
	return class<Inventory> ( DynamicLoadObject(aStr,class'class') );
}

defaultproperties
{
	InitialWaitSecs=600
	BaseRespawnSecs=60
	WeightToExtraTimeScale=1
	OvertimeTimeScale=1
}