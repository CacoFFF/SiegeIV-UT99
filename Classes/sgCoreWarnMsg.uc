//=============================================================================
// sgCoreWarnMsg.
// * Revised by 7DS'Lust
//=============================================================================
class sgCoreWarnMsg extends CriticalEventPlus;

var() color col;

static function color GetColor(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2)
{
    return Default.col;
}

static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
    return "THE BASECORE IS UNDER ATTACK!";
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
     col=(R=253,G=32)
     bBeep=False
}
