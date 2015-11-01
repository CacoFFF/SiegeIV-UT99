class XC_AntigravityToucher expands SiegeActor;

var XC_AntigravityPlatform CurPlat;

event PostBeginPlay()
{
}

event UnTouch( Actor Other)
{
	local byte i;
	//These conditions appear to be too vague
	if ( (CurPlat != none) && (CurPlat.LocalPush == Other) )
	{
		if ( PlayerPawn(Other).bUpdating )
		{
			PendingTouch = Other;
			Other.PendingTouch = self;
		}
		class'sg_TouchUtil'.static.SetTouch( Other, self);
		class'sg_TouchUtil'.static.SetTouch( self, Other);
	}
}

event PostTouch( Actor Other)
{
	if ( (CurPlat == none) || (Other == CurPlat.LocalPush ) || (Other.Role != ROLE_AutonomousProxy) || (Other.Physics != PHYS_Falling) )
		CurPlat.PlayerUpdatePush();
}

defaultproperties
{
	RemoteRole=ROLE_None
	bCollideWorld=False
}