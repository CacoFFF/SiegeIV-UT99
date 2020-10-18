class sgGameReplicationInfo extends TournamentGameReplicationInfo; 

var sgBaseCore Cores[4];
var float MaxRUs[4];

//Game Engine version
var int EngineVersion;

//Global stat counter
var localized string      StatTop_Desc[9];
var string                StatTop_Name[9];
var byte                  StatTop_Team[9];
var PlayerReplicationInfo StatTop_PRI[9];
var float                 StatTop_Value[9];

//Format: "name;count;name;count;...;"
var string Nukers_Red;
var string Nukers_Blue;
var string Nukers_Green;
var string Nukers_Yellow;

//Global game settings
var bool bTeamDrag;


replication
{
	reliable if ( Role==ROLE_Authority )
		Cores;
	reliable if ( !bNetInitial && Role==ROLE_Authority )
		MaxRUs,
		StatTop_Name, StatTop_Team, StatTop_Value,
		bTeamDrag;
		
	// Reverendously ugly but secure.
	reliable if ( !bNetInitial && Role==ROLE_Authority && class'XC_ReplicationNotify'.static.ReplicateVar(0) )
		Nukers_Red;
	reliable if ( !bNetInitial && Role==ROLE_Authority && class'XC_ReplicationNotify'.static.ReplicateVar(1) )
		Nukers_Blue;
	reliable if ( !bNetInitial && Role==ROLE_Authority && class'XC_ReplicationNotify'.static.ReplicateVar(2) )
		Nukers_Green;
	reliable if ( !bNetInitial && Role==ROLE_Authority && class'XC_ReplicationNotify'.static.ReplicateVar(3) )
		Nukers_Yellow;
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
	EngineVersion = int(Level.EngineVersion);
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
		UpdateNukerStats();
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


/*---------------------------------------------------------------*/
/*---------------------------------------------------------------*/


function StatTop_Reset( int i)
{
	StatTop_Name[i] = "";
	StatTop_Team[i] = 255;
	StatTop_PRI[i] = None;
	StatTop_Value[i] = 0;
}

function UpdateNukerStats()
{
	local SiegeStatPlayer Stat;
	local string NewEntry;
	local byte Team;

	Nukers_Red = "";
	Nukers_Blue = "";
	Nukers_Green = "";
	Nukers_Yellow = "";

	if ( SiegeGI(Level.Game).StatPool != None )
	{
		For ( Stat=SiegeGI(Level.Game).StatPool.Active ; Stat!=None ; Stat=Stat.NextStat )
			if ( (Stat.CarryingWarheads > 0) && (Stat.Player != None) && (Stat.Player.PlayerReplicationInfo != None) )
			{
				NewEntry = StripDotComma( Stat.Player.PlayerReplicationInfo.PlayerName) $ ";" $ Stat.CarryingWarheads $ ";";

				//The maximum packet size is 512, so we'll limit the string to a reasonable size
				Team = Stat.Player.PlayerReplicationInfo.Team;
				if      ( (Team == 0) && (Len(Nukers_Red) < 400) )
					Nukers_Red = Nukers_Red $ NewEntry;
				else if ( (Team == 1) && (Len(Nukers_Blue) < 400) )
					Nukers_Blue = Nukers_Blue $ NewEntry;
				else if ( (Team == 2) && (Len(Nukers_Green) < 400) )
					Nukers_Green = Nukers_Green $ NewEntry;
				else if ( (Team == 3) && (Len(Nukers_Yellow) < 400) )
					Nukers_Yellow = Nukers_Yellow $ NewEntry;
			}
	}
}

static final function string StripDotComma( string Src)
{
	local int i;
	local string Processed;
	
	AGAIN:
	i = InStr( Src, ";");
	if ( i == -1 )
		return Processed $ Src;
	Processed = Processed $ Left( Src, i);
	Src = Mid( Src, i+1);
	Goto AGAIN;
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
	StatTop_Desc(8)="Top Warhead failure"
	StatTop_Team(0)=255
	StatTop_Team(1)=255
	StatTop_Team(2)=255
	StatTop_Team(3)=255
	StatTop_Team(4)=255
	StatTop_Team(5)=255
	StatTop_Team(6)=255
	StatTop_Team(7)=255
}
