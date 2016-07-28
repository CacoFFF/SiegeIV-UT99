// To be implemented
// A chain of affectors to be applied over a player's default speed

class XC_MovementAffector expands SiegeActor;

var sgPlayerData PlayerData;
var XC_MovementAffector NextAffector;
var int AffectorPriority; //Higher = earlier

replication
{
	reliable if ( bNetInitial && (Role == ROLE_Authority) )
		AffectorPriority;
}


simulated event PostNetBeginPlay()
{
	if ( Owner != none )
		ForEach Owner.ChildActors( class'sgPlayerData', PlayerData )
		{
			PlayerData.AddMAffector( self);
			break;
		}
}

simulated event Destroyed()
{
	local XC_MovementAffector M;

	if ( PlayerData == none )
		return;

	if ( PlayerData.MA_List == self )
		PlayerData.MA_List = NextAffector;
	else
	{
		For ( M=PlayerData.MA_List ; M!=none ; M=M.NextAffector )
			if ( M.NextAffector == self )
			{
				M.NextAffector = NextAffector;
				break;
			}
	}
}

//Safe to self destruct here
simulated function AffectMovement( float DeltaTime);

simulated function XC_MovementAffector InsertSorted( XC_MovementAffector Other)
{
	if ( Other == self )
		return self;
	if ( Other.AffectorPriority >= AffectorPriority )
	{
		Other.NextAffector = self;
		return Other;
	}
	if ( NextAffector == none )
		NextAffector = Other;
	else
		NextAffector = NextAffector.InsertSorted( Other);
	return self;
}



defaultproperties
{
	 bHidden=True
	 bAlwaysRelevant=False
	 RemoteRole=ROLE_SimulatedProxy
	 NetUpdateFrequency=2
	 NetPriority=1.3
}