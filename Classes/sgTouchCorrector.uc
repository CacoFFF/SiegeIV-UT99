//*********************************
// Correct a player's location here
//*********************************

// Higor: since the collision hulls are movers now...
// do we even need this to correct a player's position in a platform?
class sgTouchCorrector expands SiegeActor;


enum ECorrectMode
{
	CM_None,
	CM_StandAbove,
	CM_PushAway,
	CM_Unused1,
	CM_Unused2,
	CM_Unused3
};

enum ECorrectType
{
	CT_None,
	CT_Player,
	CT_Pawn,
	CT_Actor,
	CT_Class,
	CT_Unused1,
	CT_Unused2
};

var ECorrectMode CorrectMode;
var ECorrectType CorrectType;
var class<Actor> CorrectClass;
var actor StandBase;

simulated event Touch( actor Other)
{
	if ( IsRelevant(Other) )
	{
		if ( CorrectMode == CM_StandAbove )
			StandAbove( Other);
	}
}


simulated function bool IsRelevant( actor Other)
{
	if ( CorrectType == CT_Player )
		return Other.bIsPawn && Pawn(Other).bIsPlayer;
	else if ( CorrectType == CT_Pawn )
		return Other.bIsPawn;
	else if ( CorrectType == CT_Actor )
		return true;
	else if ( CorrectType == CT_Class )
		return ClassIsChildOf( Other.Class, CorrectClass);
}

simulated function StandAbove( actor Other)
{
	local vector aVec;

	aVec = Other.Location;
	if ( aVec.Z > Location.Z )
	{
		aVec.Z = StandBase.Location.Z + StandBase.CollisionHeight + Other.CollisionHeight + 2.33;
		Other.SetLocation( aVec);
		Other.SetBase( StandBase);
		Other.SetPhysics( PHYS_Walking);
	}
}


defaultproperties
{
    RemoteRole=ROLE_None
    bCollideActors=True
    bCollideWorld=False
    bBlockActors=False
    bBlockPlayers=False
}