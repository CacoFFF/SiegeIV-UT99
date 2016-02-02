//=============================================================================
// sgBuildingVolume
// Generic building volume, written by Higor.
//
// Forwards notifications to sgBuilding
// Not replicated, this is handled via pure simulation
//
// Base class, use collision Cylinder
//=============================================================================
class sgBuildingVolume expands Triggers;

var sgBuilding MyBuild;
var sgBuildingVolume NextVolume;
var Actor ActorList[16];
var int iActor;

event PostBeginPlay()
{
	Disable('Tick'); //Reduce script overhead, child classes may override this
}

// Sent by sgBuilding's timer
function VolumeUpdate()
{
	CleanupDestroyed();
	if ( NextVolume != none )
		NextVolume.VolumeUpdate();
}

final function bool ActorInVolume( Actor Other)
{
	local int i;
	for ( i=0 ; i<iActor ; i++ )
		if ( ActorList[i] == Other )
			return true;
}

final function bool RemoveActor( Actor Other)
{
	local int i;
	for ( i=0 ; i<iActor ; i++ )
		if ( ActorList[i] == Other )
		{
			ActorList[i] = ActorList[--iActor];
			ActorList[iActor] = none;
			return true;
		}
}

final function CleanupDestroyed()
{
	local int i;
	while ( i<iActor )
	{
		if ( ActorList[i] == none || ActorList[i].bDeleteMe )
		{
			ActorList[i] = ActorList[--iActor];
			ActorList[iActor] = none;
			continue;
		}
		i++;
	}
}

final function CleanupAll( optional bool bNotifyExit)
{
	local int i;
	if ( bNotifyExit && MyBuild != none )
		for ( i=0 ; i<iActor ; i++ )
			MyBuild.VolumeExit( ActorList[i] );
	for ( i=0 ; i<iActor ; i++ )
		ActorList[i] = none;
	iActor = 0;
}

function bool ValidTouch( Actor Other)
{
	return true;
}

event Touch( Actor Other)
{
	if ( ValidTouch(Other) && !ActorInVolume(Other) && (MyBuild != none) && MyBuild.VolumeEnter(Other) )
	{
		if ( iActor < 16 )
			ActorList[iActor++] = Other;
	}
}

//May need to be forced
event UnTouch( Actor Other)
{
	if ( MyBuild != none && RemoveActor(Other) )
		MyBuild.VolumeExit( Other);
	
}

static final function float HSize( vector aVec)
{
	aVec.Z = 0;
	return VSize( aVec);
}

defaultproperties
{
     RemoteRole=ROLE_None
     CollisionRadius=1.000000
     CollisionHeight=1.000000
     bCollideActors=True
     bBlockActors=False
     bBlockPlayers=False
     bProjTarget=False
     bNoDelete=False
	 bStatic=False
	 bGameRelevant=True
	 bHidden=True
}