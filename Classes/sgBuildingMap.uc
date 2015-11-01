//Map buildings in these per-team objects
//Researched and built by Higor

class sgBuildingMap expands Object
	config(SiegeTest)
	perobjectconfig;

/*
These points must be loaded in InitGame, so they're compatible with CoreSwap
These points must subclass KeyPoint

sg_BOT_SupplyPoint      => Main supply
sg_BOT_SSupplyPoint       => Main super supply
sg_BOT_OptSupply        => Other supplies

sg_BOT_Container       => Required containerss
sg_BOT_SShieldPoint       => This point requires small shielding (container > minishield > containerX)
sg_BOT_BShieldPoint        => This point requires big shielding (containerX > supercontainer > forcefield)
sg_BOT_ContSpot        => Optional good locations for containers

sg_BOT_OffensiveTele        => This is a recommended offensive tele location
sg_BOT_StartTele        => This is a recommended starting tele location
sg_BOT_RequiredTele        => This is a required teleporter target (utilitary usage)

sg_BOT_BuildingBase        => Generic building class location (use the building class instead here)
*/

var() config bool bHasConfig;
var() config string Buildings[48];
var string sPkg;
var byte Team;

//How to parse:(" "?" "?" "?" ")
// sg_BOT_SupplyPoint   > code name
// L=(X,Y,Z)    > L= location (look at here)
// S=(X,Y,Z)     > S= access location (build from) (defaults to location)
// R=    > radius to consider belonging (defaults to 50)
// O=     > order to build (critical components, 1 to 32, non-supplier related, 0 is no order(final random layer) )
// P=     > build priority
// Stra=n     > n being a number, signals the alternate unique strategy in use

//SiegeGI will call this during InitGame, use it to spawn actors
function FullParse( SiegeGI Game)
{
	local class<sg_BOT_BuildingBase> MarkerClass;
	local string aStr, sClass;
	local int i;
	local vector L, S;
	local float R;
	local int O, Stra;
	local byte P;
	local sg_BOT_BuildingBase newMarker;

	if ( !bHasConfig )
	{
		bHasConfig = true;
//		SaveConfig(); Avoid saving
	}

	sPkg = string(class);
	sPkg = Left( sPkg, InStr(sPkg,".")+1 );

	For ( i=0 ; i<48 ; i++ )
	{
		if ( Buildings[i] == "" )
			continue;
		
		aStr = Buildings[i];
		//First param is always class
		sClass = Class'SiegeStatics'.static.NextParameter( aStr, "?" );
		MarkerClass = GetClasses( sClass);
		if ( MarkerClass == none )
			continue;
		S = vect(0,0,0);
		L = vect(0,0,0);
		R = 0;
		O = 0;
		Stra = 0;
		while ( aStr != "" )
		{
			sClass = Class'SiegeStatics'.static.NextParameter( aStr, "?" );
			if ( Left(sClass,2) ~= "S=" )
				S = ToVector( Mid(sClass,2));
			else if ( Left(sClass,2) ~= "L=" )
				L = ToVector( Mid(sClass,2));
			else if ( Left(sClass,2) ~= "R=" )
				R = float( Mid(sClass,2));
			else if ( Left(sClass,2) ~= "O=" )
				O = int( Mid(sClass,2));
			else if ( Left(sClass,2) ~= "P=" )
				P = int( Mid(sClass,2));
			else if ( Left(sClass,5) ~= "Stra=" )
				Stra = int( Mid(sClass,5));
		}
		//Post-Parse
		if ( L == vect(0,0,0) )
			L = S;
		newMarker = Game.Spawn( MarkerClass,,,S);
		newMarker.Team = Team;
		newMarker.FinalPos = L;
		newMarker.Order = O;
		if ( R > 0 )
			newMarker.OwnRadius = R;
		newMarker.Strategy = Stra;
		newMarker.Priority = P;
		newMarker.nextBuild = Game.BuildMarkers[Team];
		Game.BuildMarkers[Team] = newMarker;
	}
}

function FullUnParse( SiegeGI Game)
{
	local int i;
	local sg_BOT_BuildingBase aB;
	
	For ( aB=Game.BuildMarkers[Team] ; aB!=none ; aB=aB.nextBuild )
	{
		Buildings[i] = FromClass( aB.Class );
		if ( aB.FinalPos == vect(0,0,0) )
			aB.FinalPos = aB.Location + vector(aB.Rotation) * 30;
		Buildings[i] = Buildings[i] $ "?S=" $ FromVector(aB.Location) $ "?L=" $ FromVector(aB.FinalPos);
		if ( aB.Order > 0 )
			Buildings[i] = Buildings[i] $ "?O=" $ string(aB.Order);
		if ( aB.OwnRadius != aB.default.OwnRadius )
			Buildings[i] = Buildings[i] $ "?R=" $ string(int(aB.OwnRadius));
		if ( aB.Strategy > 0 )
			Buildings[i] = Buildings[i] $ "?Stra=" $ string(aB.Strategy);
		if ( aB.Priority > 0 )
			Buildings[i] = Buildings[i] $ "?P=" $ string(aB.Priority);
		i++;
	}
	While ( i<ArrayCount(Buildings) )
		Buildings[i++] = "";
	SaveConfig();
}

static function vector ToVector( string aStr)
{
	local vector Result;
	
	aStr = Mid( aStr, 1, Len(aStr)-2 );
	Result.X = float( Left(aStr, InStr(aStr,",") ) );
	aStr = Mid( aStr, InStr(aStr,",")+1 );
	Result.Y = float( Left(aStr, InStr(aStr,",") ) );
	aStr = Mid( aStr, InStr(aStr,",")+1 );
	Result.Z = float( aStr );
	return Result;
}

static function string FromVector( vector aVec)
{
	local int X,Y,Z;
	X=aVec.X; Y=aVec.Y; Z=aVec.Z;
	return "(" $ string(X) $ "," $ string(Y) $ "," $ string(Z) $ ")";
}

function class<sg_BOT_BuildingBase> GetClasses( string sInput)
{
	if ( sInput ~= "sg_BOT_BuildingBase" )
		return none; //U kidding?
	return class<sg_BOT_BuildingBase>(DynamicLoadObject(sPkg$sInput,class'class') );
}

static function string FromClass( class Other)
{
	local string aStr;
	aStr = string( Other);
	aStr = Mid( aStr, InStr(aStr,".") + 1 );
	if ( InStr(aStr,"'") > 0 )
		aStr = Left(aStr, Len(aStr)-1);
	return aStr;
}
