//=============================================================================
// sgINukeBuildMsg.
// * Revised by 7DS'Lust
//=============================================================================
class sgINukeBuildMsg extends sgNukeBuildMsg;

static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
    local string team;
    switch ( Switch )
    {
    case 1:
        team = "Blue";
        break;

    case 2:
        team = "Green";
        break;

    case 3:
        team = "Yellow";
        break;

    default:
        team = "Red";
    }

    return "An Invincible Nuke is about to be created by"@team$"!";
}

defaultproperties
{
}
