class sgGameReplicationInfo extends TournamentGameReplicationInfo; 

var sgBaseCore Cores[4];
var float MaxRUs[4];

//Global stat counter
var localized string      StatTop_Desc[8];
var string                StatTop_Name[8];
var byte                  StatTop_Team[8];
var PlayerReplicationInfo StatTop_PRI[8];
var float                 StatTop_Value[8];


replication
{
	reliable if ( Role==ROLE_Authority )
		Cores;
	reliable if ( !bNetInitial && Role==ROLE_Authority )
		MaxRUs,
		StatTop_Name, StatTop_Team, StatTop_Value;
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
	local int i;
	
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
		For ( i=0 ; i<ArrayCount(StatTop_Desc) ; i++ )
			if ( StatTop_PRI[i] != None && !StatTop_PRI[i].bDeleteMe )
			{
				StatTop_Name[i] = StatTop_PRI[i].PlayerName;
				StatTop_Team[i] = StatTop_PRI[i].Team;
			}
	}
}

function StatTop_Reset( int i)
{
	StatTop_Name[i] = "";
	StatTop_Team[i] = 255;
	StatTop_PRI[i] = None;
	StatTop_Value[i] = 0;
}


defaultproperties
{
     HumanString="*Siege Player*"
	 
	StatTop_Desc(0)="Top BaseCore attacker"
	StatTop_Desc(1)="Top BaseCore repairer"
	StatTop_Desc(2)="Top attacker"
	StatTop_Desc(3)="Top player killer"
	StatTop_Desc(4)="Top builder"
	StatTop_Desc(5)="Top Warhead maker"
	StatTop_Desc(6)="Top Warhead defender"
	StatTop_Desc(7)="Top repairer/upgrader"
	StatTop_Team(0)=255
	StatTop_Team(1)=255
	StatTop_Team(2)=255
	StatTop_Team(3)=255
	StatTop_Team(4)=255
	StatTop_Team(5)=255
	StatTop_Team(6)=255
	StatTop_Team(7)=255
}
