class sgGameReplicationInfo extends TournamentGameReplicationInfo; 

var int sgTotalBuilt[40];
var sgBaseCore Cores[4];
var float MaxRUs[4];
var int RoundGame;
var int TeamRounds[4];

replication
{
	reliable if (Role==ROLE_Authority)
		Cores, MaxRUs, RoundGame, TeamRounds;
}
//REMOVED SGTOTALBUILT FORM REPLICATION


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (SiegeGI(Level.Game) != None)
	{
		Cores[0] = SiegeGI(Level.Game).Cores[0];
		Cores[1] = SiegeGI(Level.Game).Cores[1];
		Cores[2] = SiegeGI(Level.Game).Cores[2];
		Cores[3] = SiegeGI(Level.Game).Cores[3];
	}
}

simulated event Timer()
{
	local SiegeGI Game;
	Super.Timer();

	Game = SiegeGI(Level.Game);
	if ( Game != none )
	{
		MaxRUs[0] = Game.MaxRUs[0];
		MaxRUs[1] = Game.MaxRUs[1];
		MaxRUs[2] = Game.MaxRUs[2];
		MaxRUs[3] = Game.MaxRUs[3];
	}
}


defaultproperties
{
     HumanString="*Siege Player*"
}
