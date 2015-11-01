class JetPackMessagePlus expands LocalMessagePlus;

var() localized string FlyMessage, HoverMessage;

static function float GetOffset(int Switch, float YL, float ClipY )
{
	return 0.7 * ClipY + YL * Switch;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
  switch (Switch)
  {
    case 0:	return Default.FlyMessage;
    	break;
    case 1:	return Default.HoverMessage;
    	break;
  }
  return "";
}

defaultproperties
{
     DrawColor=(R=0,G=255,B=150)
     FlyMessage="Hold [Walk] key while in air to fly"
     HoverMessage="Hold [Duck] key while in air to hover"
     bIsConsoleMessage=False
     LifeTime=5
     bIsSpecial=True
}