//=============================================================================
// sgDefeatedMsg.
//=============================================================================
class sgDefeatedMsg extends CriticalEventPlus;

var() color col;

/*static function color GetColor(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2)
{
    return Default.col;
}*/

static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
    switch ( Switch )
    {
    case 0:
        return "Red team has been defeated!";

    case 1:
        return "Blue team has been defeated!";

    case 2:
        return "Green team has been defeated!";

    case 3:
        return "Yellow team has been defeated!";
    }
}

static simulated function ClientReceive( 
  PlayerPawn P,
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
    Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    //P.PlaySound(sound'sgmedia.sgcorewarn',slot_none,float(switch)/10);
}

defaultproperties
{
     col=(R=255)
}
