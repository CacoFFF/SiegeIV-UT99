//=============================================================================
// sgTeamOnlyStats.
//=============================================================================
class sgTeamOnlyStats expands ReplicationInfo;

var byte Team;
var sgTeamOnlyStats TeamStats[4]; //Dispatch to here in XC_Engine
var sgHUD ClientHUD;

var PlayerReplicationInfo NukerPRI[32];
var int Nuker;



replication
{
	//Variables that we absolutely need in PostNetBeginPlay() should go here
	reliable if ( bNetInitial && ROLE==ROLE_Authority )
		Team;

	//Other variables should go here
//	reliable if ( !bNetInitial && Role==ROLE_Authority )
//		;


}



//For security reasons we'll use XC_Engine to send limited stat counters to players.
//These limited stat counters should only contain data relevant to the designated team.
event PostBeginPlay()
{
	local SiegeGI Game;
	local int i;

	Game = SiegeGI(Level.Game);
	if ( (Game != None) && (Game.GlobalTeamOnlyStat == None) )
	{
		Game.GlobalTeamOnlyStat = self;
		Team = 255;
		//XC_Engine adds this property to actors!
		if ( GetPropertyText("bRelevantToTeam") != "" ) //Master stat may setup team-specific stats on XC_Engine servers
		{
			SetPropertyText("bRelevantToTeam","1");
			For ( i=0 ; i<4 ; i++ )
				if ( Game.Cores[i] != None )
				{
					TeamStats[i] = Spawn( Class);
					TeamStats[i].SetPropertyText("bRelevantToTeam","1");
					TeamStats[i].Team = i;
				}
		}
	}
}

//Select this stat actor's behaviour during it's lifetime
simulated event SetInitialState()
{
	if ( Level.NetMode == NM_Client )
		InitialState = 'NetClient';
	else
		InitialState = 'NetServer';
	Super.SetInitialState();
}


// On clients this may arrive after the HUD has been initialized.
simulated event PostNetBeginPlay()
{
	ForEach AllActors( class'sgHUD', ClientHUD)
		if ( (ClientHUD.Owner != None) && (ClientHUD.Owner.Role == ROLE_AutonomousProxy) )
			break;
			
	if ( ClientHUD != None )
		ClientHUD.RegisterTeamStat( self );
}


//========================================
//======= States
//========================================

state NetServer
{
Begin:
	Sleep(0.0);
	if ( Team == 255 )
	{
		Sleep( 1 + FRand() );
		Goto('Begin');
	}
}


simulated state NetClient
{
Begin:
	Sleep( FRand() );
	if ( (Team != 255) && (ClientHUD != None) )
		ClientHUD.RegisterTeamStat( self );
	Goto('Begin');
}


//========================================
//======= Stat logic
//========================================




defaultproperties
{
	NetPriority=0.5
	NetUpdateFrequency=0.5
	Team=255
	RemoteRole=ROLE_SimulatedProxy
}
