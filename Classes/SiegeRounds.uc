//=============================================================================
// SiegeRounds.
//=============================================================================
class SiegeRounds expands Mutator;

function AddMutator( mutator M)
{
	if ( M.Class == Class )
	{
		M.Destroy();
		return;
	}
	Super.AddMutator(M);
}

event PostBeginPlay()
{
	local SiegeGI aGame;

	aGame = SiegeGI(Level.Game);

	if ( aGame != none )
	{
		aGame.bRoundMode = true;
		aGame.RoundGames = aGame.MaxTeams;
		sgGameReplicationInfo(aGame.GameReplicationInfo).RoundGame = 1;
	}
}

//SelfDestruct, mutator isn't needed anymore
event Tick( float DeltaTime)
{
	local mutator M;

	if ( Level.Game.BaseMutator == self )
		Level.Game.BaseMutator = NextMutator;
	else
	{
		For ( M=Level.Game.BaseMutator ; M!=none ; M=M.NextMutator )
			if ( M.NextMutator == self )
			{
				M.NextMutator = NextMutator;
				break;
			}
	}
	Destroy();
}