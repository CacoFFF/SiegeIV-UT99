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
	
	//Reduce amount of traces per second on servers
	if ( Level.NetMode != NM_Standalone )
	{
		ConsoleCommand("Set Barrel NetUpdateFrequency 15");
		ConsoleCommand("Set SludgeBarrel NetUpdateFrequency 15");
		ConsoleCommand("Set SteelBarrel NetUpdateFrequency 15");
		ConsoleCommand("Set SteelBox NetUpdateFrequency 15");
		ConsoleCommand("Set StudMetal NetUpdateFrequency 5");
		ConsoleCommand("Set Tree NetUpdateFrequency 5");
		ConsoleCommand("Set Plant1 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant2 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant3 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant4 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant5 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant6 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant7 NetUpdateFrequency 5");
		ConsoleCommand("Set Boulder NetUpdateFrequency 5");
		ConsoleCommand("Set Urn NetUpdateFrequency 10");
		ConsoleCommand("Set Vase NetUpdateFrequency 10");
		ConsoleCommand("Set WoodenBox NetUpdateFrequency 15");
	}

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