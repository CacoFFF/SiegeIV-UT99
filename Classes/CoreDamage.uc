//=============================================================================
// CoreDamage.
//=============================================================================
class CoreDamage expands Mutator config(SiegeIV_0031);

var config float DamageMultiplyer;
var config float PlayerDamageMultiplyer;

var int PlayersActive;

function PostBeginPlay()
{
	if ( SiegeGI(Level.Game) != none )
	{
		SiegeGI(Level.Game).MonsterMadness = true;
		Level.Game.RegisterDamageMutator( Self );
	}
}

event Tick( float DeltaTime )
{
	local PlayerPawn Player;
	
	PlayersActive = 0;

	foreach AllActors(class'PlayerPawn', Player)
	{
		if ( Player.bIsPlayer == true && Spectator(Player) == None )
		{
			if ( Player.PlayerReplicationInfo.Team != 0 )
			{
				level.game.ChangeTeam(Player, 0);
				level.game.RestartPlayer(Player);
			}
			PlayersActive++;
		}
	}
}

function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, 
						out Vector Momentum, name DamageType)
{
	local sgBaseCore Core;
	local float FinalDamage;
	

	if ( (ScriptedPawn(instigatedBy) != None) && (Victim.PlayerReplicationInfo != none) )
	{
		Core = SiegeGI(Level.Game).Cores[Victim.PlayerReplicationInfo.Team];
		if ( Core != none )
		{
			if ( PlayerDamageMultiplyer != 0 )
				FinalDamage = ActualDamage * DamageMultiplyer / max(1, PlayersActive*PlayerDamageMultiplyer);
			else
				FinalDamage = ActualDamage * DamageMultiplyer;
			Core.MonsterDamage(FinalDamage, instigatedBy);
		}
	}


	if ( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );
}
