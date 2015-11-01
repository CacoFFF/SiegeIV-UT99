//////////////////////////////////////////////
// Client effect sound for nuke siren
class NukeClientSound expands Effects;

var PlayerPawn POwner;
var NukeSiren OriginSiren;

event PostBeginPlay()
{
	POwner = PlayerPawn(Owner);
}

event Tick( float DeltaTime)
{
	local vector aVec;
	local float RealVolume;

	RealVolume = 255.0 * class'sgClient'.Default.SirenVol;
	SoundVolume = Clamp(RealVolume,0,255);

	if ( (OriginSiren == none) || OriginSiren.bDeleteMe )
	{
		OriginSiren = none;
		POwner = none;
		Destroy();
		return;
	}

	if ( POwner.ViewTarget != none )
		aVec = POwner.ViewTarget.Location;
	else
		aVec = POwner.Location + vect(0,0,1) * POwner.EyeHeight;
	aVec = aVec + (OriginSiren.Location - aVec) * 0.1;
	SetLocation( aVec);
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None
	AmbientSound=sound'AirRaid'
	SoundRadius=255
	SoundVolume=255
	bCollideActors=False
}