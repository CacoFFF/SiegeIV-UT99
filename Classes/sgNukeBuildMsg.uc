//=============================================================================
// sgNukeBuildMsg.
// * Revised by 7DS'Lust
//=============================================================================
class sgNukeBuildMsg extends CriticalEventPlus;

var() color MsgColor;

static function color GetColor(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2)
{
    return Default.MsgColor;
}

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

    return "A Nuke is about to be created by"@team$"!";
}

static simulated function ClientReceive( 
  PlayerPawn P,
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
    P.PlaySound(sound'sgMedia.sgWarning',, 2.0);
}

defaultproperties
{
     MsgColor=(R=255,G=183,B=85)
     bBeep=False
}
