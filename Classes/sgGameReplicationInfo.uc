class sgGameReplicationInfo extends TournamentGameReplicationInfo; 

var int sgTotalBuilt[40];
var sgBaseCore Cores[4];
var int RoundGame;
var int TeamRounds[4];

replication
{
	reliable if (Role==ROLE_Authority)
		Cores, RoundGame, TeamRounds;
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

defaultproperties
{
     HumanString="*Siege Player*"
}
