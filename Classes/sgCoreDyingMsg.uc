//=============================================================================
// sgCoreDyingMsg
// Written by nOs*Badger
//=============================================================================
class sgCoreDyingMsg extends CriticalEventPlus;

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
    return "THE BASECORE WILL SOON BE DESTROYED!";
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
    P.PlaySound(sound'sgMedia.sgcorewarn',, 4.0);
}

defaultproperties
{
     col=(R=253,G=32)
     bBeep=False
}
