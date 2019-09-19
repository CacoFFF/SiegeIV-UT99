//=============================================================================
// XC_ReplicationNotify
//
// This actor attempts to position itself highest in the actor priority list
// in the relevancy loop, in doing so it can be used to identify the player
// the relevancy loop is sending data to.
//
// Then other classes can use this info to block sending data to specific
// clients that are not supposed to receive it.
//=============================================================================
class XC_ReplicationNotify expands Info;

var int RepDummy;
var byte Team;

replication
{
	reliable if ( bNetOwner && Role==ROLE_Authority && NotifyReplication() )
		RepDummy;
}


event PostBeginPlay()
{
	RepDummy=0;
}

function bool NotifyReplication()
{
	if ( Owner == None )
		LifeSpan = 0.001;
	else
	{
		Team = PlayerReplicationInfo(Owner).Team;
		default.Team = Team;
	}
	return false;
}

static final function bool ReplicateVar( byte OwnerTeam)
{
	return default.Team == OwnerTeam || default.Team == 255;
}



defaultproperties
{
	bGameRelevant=True
	NetPriority=500
	NetUpdateFrequency=200
	Team=100
	RepDummy=1
}
