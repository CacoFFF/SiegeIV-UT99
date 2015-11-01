//*************************************************
// Siege IV's base mutator
//*************************************************

class SiegeMutator expands Mutator;

var SiegeGI SiegeGI;
var string Pkg;


function PostBeginPlay()
{
	SiegeGI = SiegeGI(Level.Game);
	Pkg = Left( string(class), inStr(string(class),"."));
	
	Super.PostBeginPlay();
}

function bool AlwaysKeep(Actor Other)
{
	if ( Other.bIsPawn )
	{
		if ( sgBuilding(Other) != none )
			return true;
		if ( TournamentPlayer(Other) != none )
			TournamentPlayer(Other).PlayerReplicationInfoClass = class'sgPRI';
	}
	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
	return false;
}

//DMMutator's relevancy checks are retarded
function bool IsRelevant(Actor Other, out byte bSuperRelevant)
{
	if ( NextMutator != None )
		return NextMutator.IsRelevant(Other, bSuperRelevant);
	return true;
}

function Mutate( string MutateString, PlayerPawn Sender)
{
	if ( (MutateString ~= "EditMode") && (Sender.bAdmin || (Level.NetMode == NM_Standalone)) )
	{
		Sender.ConsoleCommand("switchlevel "$Left( string(self), inStr(string(self),".")) $ "?game=" $ Pkg $ ".EditSiegeGI");
		return;
	}
	if ( NextMutator != none )
		NextMutator.Mutate( MutateString, Sender);
}