//=============================================================================
// EffectsPool.
// Since XC_Engine is severely limited on the clients, we want this
// Especially since we can't fix the excessive name allocations on ACE servers
//=============================================================================
class EffectsPool expands SiegeActor;

var sgParticle Particles;

function sgParticle RequestBuildParticle( sgBuilding Requester)
{
	local sgParticle Result;
	
	Assert( Requester != None); //Remove on release
	
	if ( Particles == None )
	{
		Result = Requester.Spawn( class'sgParticle');
		Result.Pool = self;
	}
	else
	{
		Result = Particles;
		Particles = Particles.Next;
		Result.Next = None;
	}
	Result.Setup( Requester);
	return Result;
}

function sgParticle RequestGenericParticle( Actor Requester, int MaxDist)
{
	local sgParticle Result;
	
	Assert( Requester != None); //Remove on release
	
	if ( Particles == None )
	{
		Result = Requester.Spawn( class'sgParticle');
		Result.Pool = self;
	}
	else
	{
		Result = Particles;
		Particles = Particles.Next;
		Result.Next = None;
	}
	Result.SetupGen( Requester, MaxDist);
	return Result;
}


defaultproperties
{
     bGameRelevant=True
     RemoteRole=ROLE_None
}
