//=============================================================================
// sgPRI_alerts.
// Internal support for AdminAlert messages when removing other's buildings
//=============================================================================
class sgPRI_alerts expands sgPRI;

var Mutator AdminAlert;

function FindAA()
{
	local mutator M;

	For ( M=Level.Game.MessageMutator ; M!=none ; M=M.NextMessageMutator)
	{
		if ( Caps(GetItemName( string(M.class))) == "ADMINALERT" )
		{
			AdminAlert = M;
			return;
		}
	}
}

simulated function ReceiveMessage( string sMsg, byte aTeam, bool bAnnounce)
{
	local mutator M;
	local string S;

	if ( Level.NetMode == NM_Client )
		return;
	if ( AdminAlert == none )
		FindAA();
	if ( AdminAlert == none )
		return;

	if ( bAnnounce )
	{
		bIsSpectator = False;
		S = AdminAlert.GetPropertyText("Keyword");
		if ( S == "" )
			S = "!admin";
		M = AdminAlert.NextMessageMutator;
		AdminAlert.NextMessageMutator = none;
		AdminAlert.MutatorTeamMessage( Owner, Pawn(Owner), self, S@sMsg, 'say', false );
		AdminAlert.NextMessageMutator = M;
		bIsSpectator = True;
	}
}

function Tick(float deltaTime)
{
	PlayerName = "RemoveGuardian";
	bAdmin = True;
	bIsSpectator = True;
	PlayerID = 0;
	Team = 255;
	bWaitingPlayer = True;
	RU = 0;
}