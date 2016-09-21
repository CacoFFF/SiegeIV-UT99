//=============================================================================
// sgParticle.
// * Revised by 7DS'Lust
// * Higor: Added transient flag, new physics and pooling
//=============================================================================
class sgParticle extends Effects
	transient;

var sgParticle Next;
var EffectsPool Pool;
var float Alpha;
var float MaxDistance;
var vector Destination;
var vector VTransform;

function Setup( sgBuilding Other)
{
	local int i;

	//Transform to local space
	Destination = Other.Location;
	MaxDistance = 200 + Other.CollisionRadius * 3;
AGAIN:
	SetLocation( Destination + Normal(VRand()) * MaxDistance );
	bHidden = false;
	if ( !FastTrace(Destination) )
	{
		if ( i++ < 2 )
		{
			MaxDistance *= 0.85;
			Goto AGAIN;
		}
		bHidden = true; //Do not display particle
	}
	VTransform = ((Location + Destination) * 0.5) + VRand() * (MaxDistance * 0.7) - Destination;
	GotoState('Active');
}

function SetupGen( Actor Other, int MaxDist)
{
	//Transform to local space
	Destination = Other.Location;
	MaxDistance = RandRange( MaxDist * 0.2, MaxDist);
	SetLocation( Destination + Normal(VRand()) * MaxDistance );
	bHidden = false;
	VTransform = ((Location + Destination) * 0.5) + VRand() * (MaxDistance * 0.7) - Destination;
	GotoState('Active');
}

state Active
{
	event Tick( float DeltaTime)
	{
		local float CurDist;
		local vector NewLocation;
		
		if ( !bHidden )
		{
			DrawScale = Smerp( Abs(Alpha - 0.5), default.DrawScale, -default.DrawScale);
			ScaleGlow = Lerp( Alpha, 0, 2);
			AmbientGlow = 127 * ScaleGlow;

			CurDist = Lerp( Sqrt(Alpha), MaxDistance, 0);
			NewLocation = (Location - Destination) + VTransform * DeltaTime;
			NewLocation = Normal(NewLocation) * CurDist + Destination;
			SetLocation( NewLocation);
		}
		Alpha += DeltaTime;
		if ( Alpha >= 1 )
			GotoState('');
	}
	event EndState()
	{
		Alpha = 0;
		if ( bDeleteMe ) //EndState is called with Destroy(), so avoid endless call cycle
			return;
		else if ( Pool == None )
			Destroy();
		else
		{
			bHidden = True;
			Next = Pool.Particles;
			Pool.Particles = self;
			Texture = default.Texture;
		}
	}
}

/*
simulated function Tick(float deltaTime)
{
	if ( LifeSpan > default.LifeSpan / 2 )
        DrawScale = default.DrawScale * (default.LifeSpan - LifeSpan) * 2 /
          default.LifeSpan;
	else
        DrawScale = LifeSpan * default.DrawScale * 2 / default.LifeSpan;
	ScaleGlow = 2 - 2 * LifeSpan / default.LifeSpan;
	AmbientGlow = 127 * ScaleGlow;
}
*/
defaultproperties
{
     Physics=PHYS_None
     RemoteRole=ROLE_None
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'SKFlare'
     ScaleGlow=0.000000
     bUnlit=True
	 LifeSpan=0

}
