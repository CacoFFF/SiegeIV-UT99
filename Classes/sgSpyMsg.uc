//=============================================================================
// sgSpyMsg.
//=============================================================================
class sgSpyMsg extends CriticalEventPlus;


static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
	local bool bLocalOwned;
	local byte LocalTeam;
	local PlayerPawn aP;

//RelatedPRI_1 = spy
//RelatedPRI_2 = somebody on target team

	LocalTeam = 255;

	bLocalOwned = (RelatedPRI_1 != none) && (PlayerPawn(RelatedPRI_1.Owner) != none) && (ViewPort(PlayerPawn(RelatedPRI_1.Owner).Player) != none);
	if ( RelatedPRI_1 != none )
	{
		ForEach RelatedPRI_1.AllActors (class'PlayerPawn', aP) //First playerpawn is always the local player!
			break;
		if ( ViewPort(aP.Player) != none )
			LocalTeam = aP.PlayerReplicationInfo.Team;
	}
	else
		return "";
	
	if ( LocalTeam == 255 )
		return "";

	if ( RelatedPRI_2 == none ) //No info on infiltrated team
	{
		if ( bLocalOwned )
			return "You have infiltrated the enemy team";
		else if ( RelatedPRI_1.Team == LocalTeam )
			return RelatedPRI_1.PlayerName @ "has infiltrated the enemy team";
		return "A team has been infiltrated";
	}

	if ( bLocalOwned )
		return "Your have infiltrated the" @ TeamString(RelatedPRI_2.Team) @ "team";
	else if ( RelatedPRI_2.Team == LocalTeam )
		return "Your team has been infiltrated";
	else if ( RelatedPRI_1.Team == LocalTeam )
		return RelatedPRI_1.PlayerName @ "has infiltrated" @ TeamString(RelatedPRI_2.Team) @ "team";
	return "An enemy team has been infiltrated";
}

static function string TeamString( byte aTeam)
{
	if ( aTeam == 0 )
		return "red";
	else if ( aTeam == 1 )
		return "blue";
	else if ( aTeam == 2 )
		return "green";
	else if ( aTeam == 3 )
		return "yellow";
	return "_null_";
}

defaultproperties
{
}
