///////////////////////////////////////
// Category information actor V2


class sgCategoryInfo expands ReplicationInfo;

var byte Team;
var byte sgNetDirty; //Native replication tag

var private class<sgBuilding> NetBuild[128];
var private byte NetCategory[128];
var private sgBaseBuildRule NetRules[128];
var private int NetCost[128]; //0 = default
var private string NetCategories[17], CatLocalized[17]; //Optional localized vars
var private Texture NetCatIcons[17]; //Optional icons for categories
var private string NetProperties[128];
var private byte bCatS[17], bCatE[17]; //Cached end/start indices

var byte iCat, iBuilds, iRecBuilds;

var float PriorityTimer; //Scan if > 0
var byte PossiblePriorities[128]; //AI functions
var byte CurPriItem; //Scan this item currently

var string NewBuild;
var string NewCategory;

//Linked list
var sgBaseBuildRule RuleList;
var SiegeCategoryRules CatObject;

replication
{
	reliable if ( Role == ROLE_Authority )
		NetBuild, NetCategory, NetCost, NetCategories, NetCatIcons, iBuilds, Team, iCat;
}

simulated event PostNetBeginPlay()
{
	local sgBaseBuildRule sgB;

	ForEach AllActors (class'sgBaseBuildRule', sgB, class'sgBaseBuildRule'.default.TagList[Team] )
	{
		sgB.nextRule = RuleList;
		RuleList = sgB;
		sgB.Master = self;
		sgB.MasterSet();
	}
	Timer();
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	SetTimer( 2, true);
	if ( Level.NetMode != NM_Client )
		GotoState( 'ServerOp');
}


//Setup on server
state ServerOp
{
	function LoadRules()
	{
		local sgCategoryInfo sgC;

		if ( SiegeGI(Level.Game).ProfileObject == none )
		{
			SiegeGI(Level.Game).ProfileObject = new(Level.Game,SiegeGI(Level.Game).GameProfile) class'Object'; //This will be the profile's INI name
			SiegeGI(Level.Game).CategoryRules = new(SiegeGI(Level.Game).ProfileObject,'CategoryRules') class'SiegeCategoryRules';
			SiegeGI(Level.Game).CoreRules = new(SiegeGI(Level.Game).ProfileObject,'CoreModifier') class'CoreModifierRules';
			SiegeGI(Level.Game).CoreRules.ApplyRules( SiegeGI(Level.Game) );
		}

		CatObject = SiegeGI(Level.Game).CategoryRules;
		if ( !CatObject.bHasConfig )
		{
			CatObject.bHasConfig = true;
			CatObject.SaveConfig();
		}
		CatObject.FullParse(self);
		sgNetDirty++;
	}
Begin:
	Sleep(0.2 * Level.TimeDilation);
	LoadRules();
	GotoState('');
}

function AttachRule( sgBaseBuildRule Other)
{
	Other.nextRule = RuleList;
	RuleList = Other;
	Other.Team = Team;
}

function AttachBuild( class<sgBuilding> newB, int newC, optional sgBaseBuildRule aRule, optional float newCost, optional string NewProps)
{
	NetBuild[iBuilds] = newB;
	NetCategory[iBuilds] = newC;
	NetCost[iBuilds] = newCost;
	if ( aRule != none )
	{
		NetRules[iBuilds] = aRule;
		aRule.AppliedOn[iBuilds/32] = (aRule.AppliedOn[iBuilds/32] | (1<<(iBuilds%32)));
	}
	NetProperties[iBuilds] = NewProps;
	iBuilds++;
}

function AttachCategory( string NewCategory)
{
	NetCategories[iCat++] = NewCategory;
/*

	local int i;
	For ( i=0 ; i<17 ; i++ )
		if ( NetCategories[i] == "" )
		{
			NetCategories[i] = NewCategory;
			return;
		}*/
}

function string GetProps( byte idx)
{
	if ( idx > 127 )
		return "";
	return NetProperties[idx];
}

function string ParseProp(byte idx, string Prop)
{
	local int i;
	local string Result;

	i = InStr( Caps(NetProperties[idx]), Caps(Prop));
	if ( i >= 0 )
	{
		Result = Mid( NetProperties[idx], i + Len(Prop) + 1);
		i = InStr(Result,",");
		if ( i >= 0 )
			Result = Left( Result, i);
		return Result;
	}
}
/*
event Tick( float DeltaTime)
{
	if ( CurPriItem < 128 )
		ScanPriority(CurPriItem++);
	else if ( PriorityTimer >= 0 )
	{
		PriorityTimer -= DeltaTime / Level.TimeDilation;
		if ( PriorityTimer < 0 )
		{
			PriorityTimer = 5+FRand()*5;
			CurPriItem = 0;
		}
	}
}
*/

//Cache starting/end indices to run faster iterations
simulated event Timer()
{
	local int i, k;
	if ( iBuilds != iRecBuilds )
	{
		iRecBuilds = iBuilds;
		For ( k=0 ; k<iCat ; k++ )
		{
			bCatS[k] = ArrayCount(NetBuild);
			bCatE[k] = 0;
		}
		For ( k=0 ; k<iBuilds ; k++ )
		{
			i = NetCategory[k];
			if ( NetBuild[k] != None && i < iCat )
			{
				bCatS[i] = Min( bCatS[i], k);
				bCatE[i] = Max( bCatE[i], k);
			}
		}
	}
}

event PostBeginPlay()
{
	local string pkg;

	pkg = String( class);
	pkg = Left( class, InStr(pkg, ".")+1 );

	SetTimer(0.2, false);
}


//Trigger adds extra builds, map hook
event Trigger( actor Other, Pawn EventInstigator)
{
	local int i;
	local class<sgBuilding> NewClass;
	local string aStr;

	if ( (NewBuild == "") || (NewCategory == "") )
		return;

	aStr = string(class);
	aStr = Left(aStr, inStr(aStr,"."));

	if ( InStr(NewBuild,".") < 0 )
		NewBuild = aStr $ "." $ NewBuild;
	else if ( InStr(NewBuild,".") == 0 )
		NewBuild = aStr $ NewBuild;
	NewClass = class<sgBuilding> ( DynamicLoadObject(NewBuild,class'class',true) );
	if ( NewClass == none )
		return;

	For ( i=0 ; i<iBuilds ; i++ )
	{
		if ( NetBuild[i] == NewClass )
			return;
	}

	sgNetDirty++;
	For ( i=0 ; i<ArrayCount(NetCategories) ; i++ )
	{
		if ( NetCategories[i] == "" )
		{
			NetCategories[i] = NewCategory;
			iCat++;
			NetCategory[iBuilds] = i;
			NetBuild[iBuilds] = NewClass;
			iBuilds++;
			return;
		}
		if ( NetCategories[i] ~= NewCategory )
		{
			NetCategory[iBuilds] = i;
			NetBuild[iBuilds] = NewClass;
			iBuilds++;

			return;
		}
	}
}

simulated final function int NumBuilds()
{
	return iBuilds;
}

simulated final function int FindBuild( class<sgBuilding> sgB)
{
	local int i;

	For ( i=0 ; i<iBuilds ; i++ )
	{
		if ( NetBuild[i] == sgB )
			return i;
	}
	return -1;
}

simulated final function int BuildIndex( int iBuild)
{
	local int i, j;
	
	//Count other builds in this category
	iBuild = NetCategory[iBuild];
	For ( i=bCatS[iBuild] ; i<=bCatE[iBuild] ; i++ )
	{
		if ( NetCategory[i] == NetCategory[iBuild] )
			j++;
	}
	return j;
}

simulated final function class<sgBuilding> GetBuild( int i)
{
	return NetBuild[i];
}

simulated final function int GetSetMode( int Category, int Index)
{
	local int i, j;

	For ( i=bCatS[Category] ; i<=bCatE[Category] ; i++ )
		if ( (NetCategory[i] == Category) && (j++ == Index) )
			return i;
	return -1;
}

simulated final function class<sgBuilding> NextBuild( class<sgBuilding> From, out int iIndex)
{
	local int i, j;

	if ( iIndex <= 0 )
		j = FindBuild( From);
	else
		j = iIndex;

	iIndex = -1;
	if ( j >= 0 )
	{
		i = j+1;
		j = NetCategory[j];
		while ( i<=bCatE[j] )
		{
			if ( j == NetCategory[i] )
			{
				iIndex = i;
				return NetBuild[i];
			}
			i++;
		}
	}
	return None;
}

simulated final function int NextCategory( int From)
{
	local int i, j;

	j = 28;
	For ( i=0 ; i<iBuilds ; i++ )
		if ( (NetCategory[i] < j) && (NetCategory[i] > From) )
		{
			j = NetCategory[i];
			if ( j == From+1 )
				return j;
		}
	if ( j > 27 )
		return -4; //Goes back to zero
	return j;
}

simulated final function int PrevCategory( int From)
{
	local int i, j;

	if ( --From < 0 )
		return -2; //Go to orb or Remove (remove for now)
	For ( i=0 ; i<iBuilds ; i++ )
	{
		if ( NetCategory[i] == From )
			return From;
		if ( NetCategory[i] < From && NetCategory[i] > j )
			j = NetCategory[i];
	}
	return j;
}

simulated final function int CountCategoryBuilds( int Category)
{
	local int i, j;
	For ( i=bCatS[Category] ; i<=bCatE[Category] ; i++ )
		if ( NetCategory[i] == Category )
			j++;
	return j;
}


//=====================================
// Type locator
simulated final function int NextTypedBuild( class<sgBuilding> Type, optional int i)
{
	while ( i<iBuilds )
	{
		if ( NetBuild[i] != none && ClassIsChildOf(NetBuild[i], Type) )
			return i;
		i++;
	}
	return -1;
}
simulated final function int CountTypedBuilds( class<sgBuilding> Type, optional int i)
{
	local int j;
	for ( j=0 ; i<iBuilds ; i++ )
		if ( NetBuild[i] != none && ClassIsChildOf(NetBuild[i], Type) )
			j++;
	return j;
}

simulated final function int FirstCatBuild( int Category)
{
	local int i;
	
	For ( i=bCatS[Category] ; i<=bCatE[Category] ; i++ )
		if ( NetCategory[i] == Category )
			return i;
	return -1; //OH SHIT
}

simulated final function string CatName( int i)
{
	if ( CatLocalized[i] != "" )
		return CatLocalized[i];
	return NetCategories[i];
}

simulated final function int NumCats()
{
	return iCat;
}

simulated final function int CatIndex( int iIndex)
{
	return NetCategory[iIndex];
}

//Do a graceful destruction
simulated event Destroyed()
{
	local sgConstructor aCons;

	if ( SiegeGI(Level.Game) != none )
		SiegeGI(Level.Game).CategoryInfo[Team] = none;

	ForEach AllActors ( class'sgConstructor', aCons)
		if ( aCons.CatActor == self )
			aCons.CatActor = none;
}

simulated final function string GetRuleString( byte i, out byte bDenyBuild)
{
	if ( NetRules[i] == none )
	{
		bDenyBuild = 0;
		return "";
	}
	bDenyBuild = byte(!NetRules[i].IsEnabled());
	return NetRules[i].GetRuleString();
}

simulated final function bool RulesAllow( byte i)
{
	return (NetRules[i] == none) || NetRules[i].IsEnabled();
}

simulated final function SetRule( int idx, sgBaseBuildRule Other)
{
	NetRules[idx] = Other;
}

simulated final function bool HasCustomCost( byte idx)
{
	return (idx < 128) && (NetCost[idx] > 0);
}

simulated final function int CustomCost( byte idx)
{
	return NetCost[idx];
}

simulated final function int BuildCost( byte idx)
{
	if ( NetCost[idx] > 0 )
		return NetCost[idx];
	return NetBuild[idx].default.BuildCost;
}

function ScanPriority();

defaultproperties
{
	bAlwaysRelevant=True
    Team=255
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=0.5
	PriorityTimer=-0.5
	CurPriItem=128
}