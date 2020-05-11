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
var bool bDemo;

replication
{
	reliable if ( bNetOwner && Role==ROLE_Authority && NotifyReplication() )
		RepDummy;
}

// Make server always consider this for replication
event PostBeginPlay()
{
	RepDummy=0;
}

// Make client always accept incoming variables.
simulated event PostNetBeginPlay()
{
	default.Team = 255;
}

simulated function bool NotifyReplication()
{
	if ( Owner == None )
		LifeSpan = 0.001;
	else
	{
		Team = PlayerReplicationInfo(Owner).Team;
		default.Team = Team;
		default.bDemo = bDemoRecording;
	}
	return false;
}

static final function bool ReplicateVar( byte OwnerTeam)
{
	return default.Team == OwnerTeam || default.Team == 255 || default.bDemo;
}



defaultproperties
{
	bGameRelevant=True
	NetPriority=500
	NetUpdateFrequency=200
	Team=100
	RepDummy=1
	RemoteRole=ROLE_SimulatedProxy;
}
