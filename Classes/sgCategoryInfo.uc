///////////////////////////////////////
// Category information actor V2


class sgCategoryInfo expands ReplicationInfo;

var byte Team;

var PlayerPawn PList[32]; //Relevancy Playerpawn list
var int iSize, pPosition;
var float SwitchTimer;

var class<sgBuilding> NetBuild[128];
var byte NetCategory[128];
var sgBaseBuildRule NetRules[128];
var int NetCost[128]; //0 = default
var string NetCategories[17], Netlocalized[17]; //Optional localized vars
var int iCat;
var string NetProperties[128];
var byte iBuilds;

var float PriorityTimer; //Scan if > 0
var byte CurPriItem; //Scan this item currently
var byte PossiblePriorities[128]; //AI functions

var string NewBuild;
var string NewCategory;

//Linked list
var sgBaseBuildRule RuleList;
var SiegeCategoryRules CatObject;

replication
{
	reliable if ( Role == ROLE_Authority )
		NetBuild, NetCategory, NetCost, NetCategories, iBuilds, Team, iCat;
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

event Tick( float DeltaTime)
{
	if ( (SwitchTimer -= (DeltaTime / Level.TimeDilation)) <= 0 )
		RotateReplication();

/*	if ( CurPriItem < 128 )
		ScanPriority(CurPriItem++);
	else if ( PriorityTimer >= 0 )
	{
		PriorityTimer -= DeltaTime / Level.TimeDilation;
		if ( PriorityTimer < 0 )
		{
			PriorityTimer = 5+FRand()*5;
			CurPriItem = 0;
		}
	}*/
}

//Process custom replication hack here
//Replicate this actor to the owner team's player pawns
function RotateReplication()
{
	local sgBaseBuildRule aR;

	SwitchTimer = 1 / NetUpdateFrequency;
	if ( (pPosition < iSize) && (PList[pPosition] != none || PList[iSize - (pPosition+1)] != none) )
	{
		iSize--;
		SetOwner(PList[pPosition]);
		Instigator = PList[iSize-pPosition];
			
		For ( aR=RuleList ; aR!=none ;aR=aR.nextRule )
		{
			aR.SetOwner(PList[pPosition]);
			aR.Instigator = PList[iSize-pPosition];
		}
		iSize++;
	}
	pPosition++;
	if ( pPosition > 10 && pPosition >= iSize )
		RefillList();
}

function RefillList()
{
	local PlayerPawn P;
	local int i, k;

	ForEach AllActors (class'PlayerPawn', P)
		if ( (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team == Team) )
			PList[i++] = P;
	k = i;
	while ( i<iSize )
		PList[i++] = none;
	iSize = k;
	pPosition = 0;
}

event Timer()
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
	For ( i=0 ; i<iBuild ; i++ )
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

simulated final function class<sgBuilding> NextBuild( class<sgBuilding> From, out int iIndex)
{
	local int i, j;

	if ( iIndex == 0 )
		j = FindBuild( From);
	else
		j = iIndex;
	For ( i=j+1 ; i<iBuilds ; i++ )
	{
		if ( NetCategory[j] == NetCategory[i] )
		{
			iIndex = i;
			return NetBuild[i];
		}
	}
	iIndex = -1;
	return none;
}

simulated final function class<sgBuilding> PrevBuild( class<sgBuilding> From, out int iIndex)
{
	local int i, j;

	if ( iIndex == 0 )
		j = FindBuild( From);
	else
		j = iIndex;
	For ( i=j-1 ; i>=0 ; i-- )
	{
		if ( NetCategory[j] == NetCategory[i] )
		{
			iIndex = i;
			return NetBuild[i];
		}
	}
	iIndex = -1;
	return none;
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

simulated final function int FirstCatBuild( int Category)
{
	local int i;
	
	For ( i=0 ; i<iBuilds ; i++ )
	{
		if ( NetCategory[i] == Category )
			return i;
	}
	return -1; //OH SHIT
}

simulated final function string CatName( int i)
{
	if ( NetLocalized[i] != "" )
		return NetLocalized[i];
	return NetCategories[i];
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
	bDenyBuild = byte(NetRules[i].IsEnabled());
	return NetRules[i].GetRuleString();
}

simulated final function bool RulesAllow( byte i)
{
	if ( NetRules[i] == none )
		return true;
	return NetRules[i].IsEnabled();
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
	bAlwaysRelevant=False
    Team=255
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=10
	PriorityTimer=-0.5
	CurPriItem=128
}