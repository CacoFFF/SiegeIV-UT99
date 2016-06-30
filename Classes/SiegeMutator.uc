//*************************************************
// Siege IV's base mutator
//*************************************************

class SiegeMutator expands Mutator;

var SiegeGI SiegeGI;
var string Pkg;
var bool bDropNetRate; //Important, lowers net rate to preserve framerate

var float AccumulatedFPS; //This is very aggresive!
var byte RegisteredFPS;
var byte TickCounter;
var byte __b1;
var byte __b2;


event Tick( float DeltaTime)
{
	local float Tr;
	
	if ( Level.NetMode == NM_DedicatedServer )
	{
		if ( __b2 > 0 ) //Cooldown timer (to avoid dropping/undropping at constant, equal rates)
			__b2--;
		else
		{
			AccumulatedFPS += DeltaTime / Level.TimeDilation;
			if ( ((++__b1) % 8 == 0) ) //We run the check every 8 ticks
			{
				Tr = float( ConsoleCommand("GetMaxTickRate"));
				bDropNetRate = (AccumulatedFPS > 8.16/Tr); //Allow 2% error to prevent constant dropping on servers with imprecise timers
				AccumulatedFPS = 0;
				if ( bDropNetRate )
					__b2 = 10 + Rand(20); //Wait this + 8 ticks to check again
			}
		}
	}
	else if ( Level.NetMode == NM_ListenServer )
	{
		if ( Level.bDropDetail ) //Listen server is dropping frames
			__b1 = 10;
		bDropNetRate = __b1 > 0;
		if ( bDropNetRate )
			__b1--;
	}

	TickCounter++; //Will overflow and go back to 0
	default.TickCounter = TickCounter;
	default.bDropNetRate = bDropNetRate;
}

function PostBeginPlay()
{
	SiegeGI = SiegeGI(Level.Game);
	Pkg = Left( string(class), inStr(string(class),"."));
	
	TickCounter = 0;
	default.TickCounter = 0;
	__b1 = 0;
	__b2 = 0;
	
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
	if ( MutateString ~= "StressTest" && Sender != none && Sender.bAdmin )
	{
		MutateString = MutateString $ self $ Sender $ SiegeGI $ Level $ XLevel $ Level.NavigationPointList $ Level.PawnList;
		MutateString = MutateString $ MutateString $ MutateString $ MutateString $ MutateString $ MutateString;
		MutateString = MutateString $ MutateString $ MutateString $ MutateString $ MutateString $ MutateString;
		while ( MutateString != "" )
			MutateString = Mid( MutateString, 1);
	}
	if ( NextMutator != none )
		NextMutator.Mutate( MutateString, Sender);
}