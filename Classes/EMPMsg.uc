//=============================================================================
// EMPMsg.
//=============================================================================
class EMPMsg extends CriticalEventPlus;

var() color rc;

static function color GetColor(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2)
{
	return Default.rc;
}

static function string GetString(
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
	return "!ELECTROMAGNETIC ACTIVITY DETECTED!";
}

static simulated function ClientReceive( 
  PlayerPawn P,
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1, 
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	P.PlaySound(sound'sgMedia.sgWarning',, 4.0);
}

defaultproperties
{
     rc=(R=16,G=127,B=255)
     bBeep=False
}
