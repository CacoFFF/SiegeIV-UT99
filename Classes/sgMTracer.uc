class sgMTracer expands MTracer;

simulated function PostBeginPlay()
{
	if ( (Owner != None) && (Owner.Role == 3) )
		Destroy();
	else
		Super.PostBeginPlay();
}

defaultproperties
{
	bOwnerNoSee=True
}
