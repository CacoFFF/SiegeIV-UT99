//=============================================================================
// sgGenericCH.
// Generic collision hull, written by Higor.
// Remove all collision properties from main actor so it doesn't take damage
// Nukes and neutrons will still harm the main actor, while not harming this one
// So everything is fine anyways.
//
// There's lots of effort in keeping relative positions an bases here in both
// ends of the network.
//=============================================================================
class sgGenericCH expands Actor;

var bool bLocalHull;
var bool bTransmitDamage;
var private actor MyActor;
var private vector RelativePosition;

var private bool bHasStand;

event PostBeginPlay()
{
	if ( Level.NetMode != NM_Client )
		bLocalHull = True;
}

//This is a mandatory method to setup the hull
//If called after spawn, it will happen before the fist tick, which is required
function Setup( actor Other, float CRadius, float CHeight, optional vector RelativePos)
{
	MyActor = Other;
	SetCollisionSize( CRadius, CHeight);
	if ( RelativePos != vect(0,0,0) )
	{
		RelativePosition = RelativePos;
		SetLocation( Other.Location + RelativePos);
	}
}

event Attach( actor Other)
{
	if ( PlayerPawn(Other) != none )
		bHasStand = True;
}

//Tick occurs after the main actor's tick
event Tick( float DeltaTime)
{
	local PlayerPawn aPawn;

	if ( MyActor == none || MyActor.bDeleteMe )
	{
		Destroy();
		return;
	}

	if ( VSize( (MyActor.Location+RelativePosition) - Location) > 2)
	{	
		//Move will also move attached objects, SetLocation will make sure this remains in a correct position
		Move( (MyActor.Location + RelativePosition) - Location );

		if ( VSize( (MyActor.Location+RelativePosition) - Location) > 2)
			SetLocation( MyActor.Location + RelativePosition);

		if ( bHasStand )
		{
			bHasStand = False;
			//Eject players if not standing on this structure anymore (crouch bug)
			ForEach BasedActors (class'PlayerPawn', aPawn )
			{
				if ( HSize( aPawn.Location - Location) >= CollisionRadius + aPawn.CollisionRadius )
					aPawn.AddVelocity( vect(0,0,1) );
				else
					bHasStand = True;
			}
		}
	}
}

//Forward damage to main actor
event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
{
	local name aN;
	if ( bTransmitDamage && bLocalHull )
	{
		aN = MyActor.Tag;
		MyActor.Tag = 'ForceDamage';
		MyActor.TakeDamage( Damage, EventInstigator, HitLocation, Momentum, DamageType);
		MyActor.Tag = aN;
	}
}


static final function float HSize( vector aVec)
{
	return VSize( aVec * vect(1,1,0) );
}

defaultproperties
{
     bHidden=True
     RemoteRole=ROLE_None
     CollisionRadius=1.000000
     CollisionHeight=1.000000
     bCollideActors=True
     bBlockActors=True
     bBlockPlayers=True
     bProjTarget=True
}