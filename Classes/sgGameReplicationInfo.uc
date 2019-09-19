class sgGameReplicationInfo extends TournamentGameReplicationInfo; 

var sgBaseCore Cores[4];
var float MaxRUs[4];

var string TopCoreKiller;
var string TopCoreRepair;
var string TopBuildingHurt;
var string TopUpgradeRepair;
var byte TopCoreKillerTeam;
var byte TopCoreRepairTeam;
var byte TopBuildingHurtTeam;
var byte TopUpgradeRepairTeam;
var PlayerReplicationInfo TopCoreKillerPRI;
var PlayerReplicationInfo TopCoreRepairPRI;
var PlayerReplicationInfo TopBuildingHurtPRI;
var PlayerReplicationInfo TopUpgradeRepairPRI;
var float TopCoreKillerValue;
var float TopCoreRepairValue;
var float TopBuildingHurtValue;
var float TopUpgradeRepairValue;


replication
{
	reliable if ( Role==ROLE_Authority )
		Cores;
	reliable if ( !bNetInitial && Role==ROLE_Authority )
		MaxRUs,
		TopCoreKiller, TopCoreKillerTeam,
		TopCoreRepair, TopCoreRepairTeam,
		TopBuildingHurt, TopBuildingHurtTeam,
		TopUpgradeRepair, TopUpgradeRepairTeam;
}



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
	
	if ( Role == ROLE_Authority )
	{
		if ((TopCoreKillerPRI != None) && !TopCoreKillerPRI.bDeleteMe )
		{
			TopCoreKiller = TopCoreKillerPRI.PlayerName;
			TopCoreKillerTeam = TopCoreKillerPRI.Team;
		}
		if ( (TopCoreRepairPRI != None) && !TopCoreRepairPRI.bDeleteMe )
		{
			TopCoreRepair = TopCoreRepairPRI.PlayerName;
			TopCoreRepairTeam = TopCoreRepairPRI.Team;
		}
		if ( (TopBuildingHurtPRI != None) && !TopBuildingHurtPRI.bDeleteMe )
		{
			TopBuildingHurt = TopBuildingHurtPRI.PlayerName;
			TopBuildingHurtTeam = TopBuildingHurtPRI.Team;
		}
		if ( (TopUpgradeRepairPRI != None) && !TopUpgradeRepairPRI.bDeleteMe )
		{
			TopUpgradeRepair = TopUpgradeRepairPRI.PlayerName;
			TopUpgradeRepairTeam = TopUpgradeRepairPRI.Team;
		}
	}
}


defaultproperties
{
     HumanString="*Siege Player*"
     TopCoreKillerTeam=255
}
