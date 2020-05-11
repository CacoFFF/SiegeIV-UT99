//Shared utilitary functions
//By Higor


class SiegeStatics expands Object;

var bool bTrue;
var bool bRelease;
var bool bXCGE;
var bool bXCGE_Octree;

var int XCGE_Version;
var int EngineVersion;
var Color BlackColor;

var name TeamBuildingTags[5];


native(3571) static final function float XCGE_HSize( vector A);

native(3560) static final function bool ReplaceFunction( class<Object> ReplaceClass, class<Object> WithClass, name ReplaceFunction, name WithFunction, optional name InState);


//*********************
// Detect XC_GameEngine
//*********************

static function bool DetectXCGE( Actor Other)
{
	default.bXCGE = InStr( Other.XLevel.GetPropertyText("Engine"), "XC_GameEngine") >= 0;
	default.XCGE_Version = int(Other.Level.ConsoleCommand("get ini:Engine.Engine.GameEngine XC_Version"));
	default.bXCGE_Octree = Other.Level.ConsoleCommand("get ini:Engine.Engine.GameEngine bCollisionHashHook") ~= string(default.bTrue);
	if ( (default.XCGE_Version >= 19) && (Other.Level.NetMode != NM_Client) )
	{
		ReplaceFunction( class'SiegeStatics', class'SiegeStatics', 'HSize', 'XCGE_HSize');
		ReplaceFunction( class'sgProtector', class'sgProtector', 'FindTeamTarget', 'XCGE_FindTeamTarget');
		ReplaceFunction( class'sgProtector', class'SiegeStatics', 'SuitProtects', 'SuitProtects');
		ReplaceFunction( class'sgBaseCore', class'sgBaseCore', 'AddRuToPlayers', 'AddRuToPlayers_XC');
		ReplaceFunction( class'sgEquipmentSupplier', class'sgEquipmentSupplier', 'FindTargets', 'FindTargets_XC');
	}
	assert( MatchesFilter("CTF-Niven","CTF-Niven") );
	assert( MatchesFilter("CTF-Niven","*Niven") );
	assert( MatchesFilter("CTF-Niven","*Niven*") );
	assert( MatchesFilter("CTF-Niven","*Nive*") );
	assert( MatchesFilter("CTF-Niven","*N*n*") );
	
	return default.bXCGE;
}

//**********************************
//Invalid floating point number test
//**********************************
static final function bool BadFloat( float F)
{
	local string S;
	
	S = Caps(string(F));
	return InStr(S,"#") != -1 || InStr(S,"NAN") != -1 || InStr(S,"IND") != -1 || InStr(S,"INF") != -1;
}


//*****************
//Swap two integers
//*****************
static final function ffSwap( out private int U, out private int H)
{
	local private int L;
	
	L = U;
	U = H;
	H = L;
}

//*********************************
//Byte reversal in a simple integer
//*********************************
static final function int ffRevertByte( private int nani2)
{
	local private int nani, i;
	For ( i=0 ; i<32 ; i++ )
		nani = nani | ( ((nani2 >>> i) & 1) << (31-i));
	return nani;
}


//********************************
//Turn a rotator into a single INT
//********************************
static final function int CompressRotator( rotator R)
{
	return (R.Pitch << 16) | (R.Yaw & 65535);
}

//*************************
//Turn a INT into a rotator
//*************************
static final function rotator DecompressRotator( int A)
{
	local rotator aRot;
	aRot.Yaw = A & 65535;
	aRot.Pitch = (A >>> 16);
	return aRot;
}

//******************************************************************
//This actor is always the end of a shot, regardless of other checks
//******************************************************************
static final function bool TraceStopper( actor Other)
{
	if ( Other == Other.Level || Other.IsA('Mover') )
		return true;
	return false;
}


//*******************************************************************
//Parse a parameter from this command string using a custom delimiter
//*******************************************************************
static final function string NextParameter( out string Commands, string Delimiter)
{
	local string Result;
	local int i;
	
	if ( Delimiter == "" )
	{
		Result = Commands;
		Commands = "";
		return Result;
	}

	AGAIN:
	i = InStr(Commands, Delimiter);
	if ( i < 0 )
	{
		Result = Commands;
		Commands = "";
		return Result;
	}
	if ( i == 0 ) //Idiot parse
	{
		Commands = Mid( Commands, Len(Delimiter));
		goto AGAIN;
	}
	Result = Left( Commands, i);
	Commands = Mid( Commands, i + Len(Delimiter) );
	return Result;
}

//**************************************************************************************************
//Parses a parameter from this command using a delimiter, can seek and doesn't modify initial string
//**************************************************************************************************
static function string ByDelimiter( string Str, string Delimiter, optional int Skip)
{
	local int i;

	AGAIN:
	i = InStr( Str, Delimiter);
	if ( i < 0 )
	{
		if ( Skip == 0 )
			return Str;
		return "";
	}
	else
	{
		if ( Skip == 0 )
			return Left( Str, i);
		Str = Mid( Str, i + Len(Delimiter) );
		Skip--;
		Goto AGAIN;
	}
}

//***********************************
//Remove initial spaces from a string
//***********************************
static final function string ClearSpaces( string Text)
{
	local int i;

	i = InStr(Text, " ");
	while( i == 0 )
	{
		Text = Right(Text, Len(Text) - 1);
		i = InStr(Text, " ");
	}
	return Text;
}

//*************
//Replaces text
//*************
static final function ReplaceText(out string Text, string Replace, string With)
{
	local int i;
	local string Input;
		
	Input = Text;
	Text = "";
	i = InStr(Input, Replace);
	while(i != -1)
	{	
		Text = Text $ Left(Input, i) $ With;
		Input = Mid(Input, i + Len(Replace));	
		i = InStr(Input, Replace);
	}
	Text = Text $ Input;
}

//********************************
//Filter matching
// * wildcard can be used anywhere
//********************************
static final function bool MatchesFilter( string Sample, string Filter)
{
	local int i;
	local bool bStartChop, bEndChop;
	local string Section;
		
	Sample = Caps(Sample);
	Filter = Caps(ClearSpaces(Filter));

	// Cleanup double asterisks
	ReplaceText( Filter, "**", "*");
	
	// Special case, all allowed.
	if ( Filter == "*" )
		return true;
	
	// Special case at start
	bStartChop = (Left (Filter,1) == "*");
	bEndChop   = (Right(Filter,1) == "*");

	SECTION_AGAIN:
	if	(	(Filter == "*")                  //END, any text allowed.
		||	(Filter == "" && Sample == "") ) //END, fully validated.
		return true;
	Section = NextParameter( Filter, "*");
	if ( (Filter == "") && bEndChop )
		Filter = "*";
	if ( Section != "" )
	{
		i = InStr( Sample, Section);
		if ( i==0 || (bStartChop && i>0) )
		{
			Sample = Mid( Sample, i+Len(Section));
			bStartChop = true;
			goto SECTION_AGAIN;
		}
		// Fail if section not found in sample.
	}
	// Fail if no more sections to find in sample.
	return false;
}


//*******************************
//Placement and comparison utils
//*******************************
static final function float HSize( vector aVec)
{
	return VSize(aVec * vect(1,1,0));
}

static final function bool InCylinder( vector aVec, float R, float H)
{
	return (Abs(aVec.Z) <= H) && (HSize(aVec) <= R);
}

static final function bool ActorsTouching( Actor A, Actor B)
{
	return InCylinder
		( A.Location - B.Location
		, A.CollisionRadius + B.CollisionRadius
		, A.CollisionHeight + B.CollisionHeight);
}

static final function bool ActorsTouchingExt( Actor A, Actor B, float ExtraR, float ExtraH)
{
	return InCylinder
		( A.Location - B.Location
		, A.CollisionRadius + B.CollisionRadius + ExtraR
		, A.CollisionHeight + B.CollisionHeight + ExtraH);
}

//********************************
//ReachSpec handling in path nodes
//********************************

//False means there was an alteration, let a general handler fix this later
static final function bool AddPath( NavigationPoint NE, int Spec)
{
	local int i;
	while ( i<16 && NE.Paths[i] >= 0 )
		i++;
	if ( i < 16 )
	{
		NE.Paths[i] = Spec;
		return true;
	}
}
static final function bool AddUsPath( NavigationPoint NE, int Spec)
{
	local int i;
	while ( i<16 && NE.upstreamPaths[i] >= 0 )
		i++;
	if ( i < 16 )
	{
		NE.upstreamPaths[i] = Spec;
		return true;
	}
}
static final function RemovePath( NavigationPoint NE, int Spec, optional int i)
{
	while ( i<16 && NE.Paths[i] != Spec ) //Find slot
		i++;
	if ( i == 16 )
		return;
	NE.Paths[i++] = -1; //Null slot
	if ( i<16 && NE.Paths[i] >= 0 ) //There's more stuff
	{
		while ( i<15 && NE.Paths[i] >= 0 ) //Move valid slots one below
			NE.Paths[i-1] = NE.Paths[i++];
		NE.Paths[i-1] = -1; //Null last valid
	}
}
static final function RemoveUsPath( NavigationPoint NE, int Spec)
{
	local int i;
	while ( i<16 && NE.upstreamPaths[i] != Spec ) //Find slot
		i++;
	if ( i == 16 )
		return;
	NE.upstreamPaths[i++] = -1; //Null slot
	if ( i<16 && NE.upstreamPaths[i] >= 0 ) //There's more stuff
	{
		while ( i<15 && NE.upstreamPaths[i] >= 0 ) //Move valid slots one below
			NE.upstreamPaths[i-1] = NE.upstreamPaths[i++];
		NE.upstreamPaths[i-1] = -1; //Null last valid
	}
}

//*********************************************
//Find a first saved move beyond time stamp
//*********************************************
static final function SavedMove FindMoveBeyond( PlayerPawn Other, float TimeStamp)
{
	local SavedMove Result;
	Result = Other.SavedMoves;
	while ( Result != none )
	{
		if ( Result.TimeStamp > TimeStamp )
			return Result;
		Result = Result.NextMove;
	}
}

//****************************************************
//See if the NexGen actor is available for this player
//****************************************************
static final function Info FindNexgenClient( PlayerPawn Player)
{
	local Info aInfo;
	if ( Player == none )
		return none;
	ForEach Player.ChildActors (class'Info', aInfo)
		if ( aInfo.IsA('NexgenClient') )
			return aInfo;
}

//***************************************
//Find specific Siege Actors
//***************************************
static final function sgPlayerData GetPlayerData( Pawn Other)
{
	local sgPlayerData Result;
	if ( Other != None )
	{
		if ( sgPRI(Other.PlayerReplicationInfo) != None )
			Result = sgPRI(Other.PlayerReplicationInfo).PlayerData;
		if ( Result == None ) //Ugh
			ForEach Other.ChildActors ( class'sgPlayerData', Result)
				break;
	}
	return Result;
}
static final function SiegeStatPlayer GetPlayerStat( Pawn Other)
{
	if ( Other != None )
	{
		if ( sgPRI(Other.PlayerReplicationInfo) != None )
			return sgPRI(Other.PlayerReplicationInfo).Stat;
		//TODO: Add more ways
	}
	return None;
}
static final function GameReplicationInfo GetGRI( Pawn Other)
{
	local GameReplicationInfo GRI;
	if ( Other != None )
	{
		if ( (Other.Level.Game != None) && (Other.Level.Game.GameReplicationInfo != None) )
			GRI = Other.Level.Game.GameReplicationInfo;
		else if ( (PlayerPawn(Other) != None) && (PlayerPawn(Other).GameReplicationInfo != None) ) 
			GRI = PlayerPawn(Other).GameReplicationInfo;
		else
			ForEach Other.AllActors( class'GameReplicationInfo', GRI)
				break;
	}
	return GRI;
}



//**********************************************
//Announce to all player and pseudo-player pawns
//**********************************************
static final function AnnounceAll( Actor Broadcaster, string Msg)
{
	local PlayerReplicationInfo PRI;
	local Pawn P;
	
	if ( Broadcaster == none )
		return;
	ForEach Broadcaster.AllActors (class'PlayerReplicationInfo', PRI)
	{
		P = Pawn(PRI.Owner);
		if ( P != none && (P.bIsPlayer || P.IsA('MessagingSpectator')) )
			P.ClientMessage( Msg);
	}
}

//************************************
//Get detail value, 3 is max, 0 is min
//************************************
static final function int GetDetailMode( LevelInfo Level)
{
	return 2 + int(Level.bHighDetailMode)
			- (int(Level.bDropDetail) + int(Level.bAggressiveLOD) + int(class'sgClient'.default.bHighPerformance));
}


//*****************************************
//Find the local player********************
//Cannot be overriden by XCGE (client func)
//*****************************************
static final function PlayerPawn FindLocalPlayer( Actor Other)
{
	local PlayerPawn P;
	ForEach Other.AllActors ( class'PlayerPawn', P)
		if ( ViewPort(P.Player) != None )
			return P;
}


static final function Actor FindActorCN( Actor Other, class<Actor> ActorClass, name ActorName)
{
	local Actor A;
	if ( ActorClass == None )
		ActorClass = class'Actor';
	ForEach Other.AllActors( ActorClass, A)
		if ( ActorName == '' || ActorName == A.Name )
			return A;
}


//*******************************************************
//** XC_ENGINE - Function storage for other classes *****
//** Stored here to reduce field count in said classes **
//*******************************************************

//Nasty hack, changes type of parameter to gain access to 'InventoryActors' native
function bool SuitProtects( sgBuilding Other)
{
	local sgSuit sgS;
	ForEach Other.InventoryActors( class'sgSuit', sgS, true)
		return sgS.bNoProtectors;
}


//*************************************
//Get this team's tag******************
//Used to boost building iterator speed
//*************************************

static final function Name TeamTag( int Team)
{
	if ( Team >= 0 && Team <= 3 )
		return default.TeamBuildingTags[Team];
	return default.TeamBuildingTags[4];
}


//*************************************
//Get this Pawn's team*****************
//*************************************
static final function byte GetTeam( Pawn Other, optional byte DefaultNone)
{
	if ( Other != None )
	{
		if ( Other.PlayerReplicationInfo != None )
			return Other.PlayerReplicationInfo.Team;
		if ( sgBuilding(Other) != None )
			return sgBuilding(Other).Team;
	}
	if ( DefaultNone != 0 )
		return DefaultNone;
	return 255;
}

//****************************************************
//Get this Pawn's ammo amount of a specific ammo type*
//****************************************************
static final function int GetAmmoAmount( Pawn Other, class<Inventory> InvClass)
{
	local Inventory Inv;
	
	if ( Other != None )
	{
		Inv = Other.FindInventoryType(InvClass);
		if ( Ammo(Inv) != None )
			return Ammo(Inv).AmmoAmount;
		if ( (Weapon(Inv) != None) && (Weapon(Inv).AmmoType != None) )
			return Weapon(Inv).AmmoType.AmmoAmount;
	}
	return 0;
}




defaultproperties
{
	bRelease=True
	bTrue=True
	XCGE_Version=-1
	BlackColor=(R=0,G=0,B=0)
	TeamBuildingTags(0)=RedBuilding
	TeamBuildingTags(1)=BlueBuilding
	TeamBuildingTags(2)=GreenBuilding
	TeamBuildingTags(3)=YellowBuilding
	TeamBuildingTags(4)=OtherBuilding
}