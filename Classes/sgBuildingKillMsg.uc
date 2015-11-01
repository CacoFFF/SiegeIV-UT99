//=============================================================================
// sgBuildingKillMsg.
//=============================================================================
class sgBuildingKillMsg extends CriticalEventPlus;

static function string GetArticle(string noun)
{
    local string letter;

    if ( noun == "" )
        return "";

    letter = Caps(Left(noun, 1));
    if ( letter == "A" || letter == "E" || letter == "I" || letter == "O" ||
      letter == "U" )
        return "A";
    return "An";
}

static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
	local string msg, sgName;
	local bool bLocalOwned;

    if ( class<sgBuilding>(OptionalObject) == None )
        return "";

	sgName = class<sgBuilding>(OptionalObject).Default.BuildingName;
	bLocalOwned = (RelatedPRI_1 != none) && (PlayerPawn(RelatedPRI_1.Owner) != none) && (ViewPort(PlayerPawn(RelatedPRI_1.Owner).Player) != none);

	if ( bLocalOwned )
		msg = "Your";
	else if ( RelatedPRI_1 != None )
		msg = RelatedPRI_1.PlayerName$"'s";
	else
		msg = GetArticle( sgName);

	log(OptionalObject@sgName);
	msg = msg@sgName@ "was destroyed";

	if ( RelatedPRI_2 != None )
		msg = msg@"by"@RelatedPRI_2.PlayerName;

	return msg;
}

defaultproperties
{
}
