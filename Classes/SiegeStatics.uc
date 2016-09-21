//Shared utilitary functions
//By Higor


class SiegeStatics expands Object;

var bool bTrue;
var bool bRelease;
var bool bXCGE;
var bool bXCGE_Octree;

var int XCGE_Version;
var Color BlackColor;



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
	}
	return default.bXCGE;
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
	local private int nani, HackMe;
	For ( HackMe=0 ; HackMe<32 ; HackMe++ )
		nani = nani | ( ((nani2 >>> HackMe) & 1) << (31-HackMe));
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
	local string result;
	local int i;
	
	if ( Delimiter == "" )
	{	result = Commands;
		Commands = "";
		return result;
	}

	i = InStr(Commands, Delimiter);
	if ( i < 0 )
	{
		result = Commands;
		Commands = "";
		return result;
	}
	if ( i == 0 ) //Idiot parse
	{
		Commands = Mid( Commands, Len(Delimiter));
		return NextParameter( Commands, Delimiter);
	}
	result = Left( Commands, i);
	Commands = Mid( Commands, i + Len(Delimiter) );
	return result;
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

//*******************************
//Placement and comparison utils
//*******************************
static final function float HSize( vector aVec)
{
	return VSize(aVec * vect(1,1,0));
}

static final function bool ActorsTouching( Actor A, Actor B)
{
	if ( abs(A.Location.Z - B.Location.Z) > (A.CollisionHeight + B.CollisionHeight) )
		return false;
	return HSize( A.Location - B.Location) <= (A.CollisionRadius + B.CollisionRadius);
}

static final function bool ActorsTouchingExt( Actor A, Actor B, float ExtraR, float ExtraH)
{
	if ( abs(A.Location.Z - B.Location.Z) > (A.CollisionHeight + B.CollisionHeight + ExtraH) )
		return false;
	return HSize( A.Location - B.Location) <= (A.CollisionRadius + B.CollisionRadius + ExtraR);
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
static function Info FindNexgenClient( PlayerPawn Player)
{
	local Info aInfo;
	if ( Player == none )
		return none;
	ForEach Player.ChildActors (class'Info', aInfo)
		if ( aInfo.IsA('NexgenClient') )
			return aInfo;
}

//***************************************
//Find the sgPlayerData element of a pawn
//***************************************
static function sgPlayerData GetPlayerData( Pawn Other, optional bool bCreate)
{
	local sgPlayerData Result;
	if ( Other == None )
		return None;
	if ( sgPRI(Other.PlayerReplicationInfo) != None )
		Result = sgPRI(Other.PlayerReplicationInfo).PlayerData;
	if ( Result == None )
		ForEach Other.ChildActors ( class'sgPlayerData', Result)
			break;
	if ( bCreate && Result == None )
		Result = Other.Spawn( class'sgPlayerData', Other);
	return Result;
}


//**********************************************
//Announce to all player and pseudo-player pawns
//**********************************************
static function AnnounceAll( Actor Broadcaster, string Msg)
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
static function int GetDetailMode( LevelInfo Level)
{
	return 2 + int(Level.bHighDetailMode)
			- (int(Level.bDropDetail) + int(Level.bAggressiveLOD) + int(class'sgClient'.default.bHighPerformance));
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




defaultproperties
{
	bRelease=True
	bTrue=True
	XCGE_Version=-1
	BlackColor=(R=0,G=0,B=0)
}