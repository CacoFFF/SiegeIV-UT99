//=============================================================================
// sgBuildingCH.
// Generic building collision hull, written by Higor.
// Forwards notifications to sgBuilding
// Must be relevant to allow proper client collision
// The server controls this collision hull's location
//=============================================================================
class sgBuildingCH expands Mover;

var bool bLocalHull;
var bool bTransmitDamage;
var float TransmitScale;
var sgBuilding MyBuild; //On clients, the build itself is responsible for setting this if replicated late

//No rotation support yet
var float RelX, RelY, RelZ;
var private vector RelativePosition;
var private bool bHasStand;

replication
{
	reliable if ( bNetInitial && (Role == ROLE_Authority) )
		RelX, RelY, RelZ, MyBuild;
}

// When mover enters gameplay.
simulated function BeginPlay()
{
	local rotator R;
	Super.BeginPlay();
	SetRotation( R);
}

event PostBeginPlay()
{
	if ( Level.NetMode != NM_Client )
		bLocalHull = True;
}

simulated event PostNetBeginPlay()
{
	RelativePosition.X = RelX;
	RelativePosition.Y = RelY;
	RelativePosition.Z = RelZ;
}


//This is a mandatory method to setup the hull
//If called after spawn, it will happen before the fist tick, which is required
function Setup( sgBuilding Other, float CRadius, float CHeight, optional vector RelativePos)
{
	MyBuild = Other;
	SetCollisionSize( CRadius, CHeight);
	if ( RelativePos != vect(0,0,0) )
	{
		RelativePosition = RelativePos;
		RelX = RelativePosition.X;
		RelY = RelativePosition.Y;
		RelZ = RelativePosition.Z;
		SetLocation( Other.Location + RelativePos);
	}
}

simulated event Attach( actor Other)
{
	if ( Other.bIsPawn )
	{
		if ( PlayerPawn(Other) != none )
			bHasStand = True;
		if ( MyBuild != none )
			MyBuild.CollisionStand( Pawn(Other));
	}
	else if ( MyBuild != none )
		MyBuild.CollisionLand( Other);

}

simulated event Detach( actor Other)
{
	if ( Pawn(Other) != None )
	{
		if ( MyBuild != none )
			MyBuild.CollisionJump( Pawn(Other));
	}
	else if ( MyBuild != none )
		MyBuild.CollisionDetach( Other);
}

//Tick occurs after the main actor's tick
event Tick( float DeltaTime)
{
	local PlayerPawn aPawn;

	if ( MyBuild == none || MyBuild.bDeleteMe )
	{
		Destroy();
		return;
	}

	if ( VSize( (MyBuild.Location+RelativePosition) - Location) > 2)
	{	
		//Move will also move attached objects, SetLocation will make sure this remains in a correct position
		Move( (MyBuild.Location + RelativePosition) - Location );
		NetUpdateFrequency = 100;

		if ( VSize( (MyBuild.Location+RelativePosition) - Location) > 2)
			SetLocation( MyBuild.Location + RelativePosition);

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
	else
		NetUpdateFrequency = 3;
}

//Forward damage to main actor
event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
{
	local name aN;
	if ( bTransmitDamage && bLocalHull )
	{
		aN = MyBuild.Tag;
		MyBuild.Tag = 'ForceDamage';
		MyBuild.TakeDamage( Damage * TransmitScale, EventInstigator, HitLocation, Momentum, DamageType);
		MyBuild.Tag = aN;
	}
}


static final function float HSize( vector aVec)
{
	return VSize( aVec * vect(1,1,0) );
}

defaultproperties
{
     RemoteRole=ROLE_DumbProxy
     CollisionRadius=1.000000
     CollisionHeight=1.000000
     bCollideActors=True
     bBlockActors=True
     bBlockPlayers=True
     bProjTarget=True
     bAlwaysRelevant=True
     NetUpdateFrequency=3
     MoverEncroachType=ME_IgnoreWhenEncroach
     NumKeys=1
     bNoDelete=False
     InitialState=TriggerControl
     DrawType=DT_None
}