//=============================================================================
// sgSWave.
// * Revised by 7DS'Lust
// * Explosion ticks rewritten by Higor to uniformly do the following:
// ** 19 ticks every 0.1 engine seconds
// ** Max radius is 2900
//=============================================================================
class sgSWave extends Effects;

const MaxShockTime = 1.9;
const ShockTick = 0.1;

var float ShockTimer;
var rotator HitNorm;
var float TeamDamage[4];
var byte Team;
var bool bAmplified;

event PostBeginPlay()
{
    local PlayerPawn P;

	ForEach RadiusActors (class'PlayerPawn', P, 3000)
		P.ShakeView(0.5, 800000.0/VSize(P.Location - Location), 10);

	if ( Instigator != None )
	{
		if ( Instigator.PlayerReplicationInfo != None )
			Team = Instigator.PlayerReplicationInfo.Team;
		else if ( sgBuilding(Instigator) != None )
			Team = sgBuilding(Instigator).Team;
		
		bAmplified = Instigator.DamageScaling >= 2;
	}
		
    HitNorm = Rotation;
    RotationRate = RotRand()-RotRand()*1.5;

    if ( Instigator != None )
        MakeNoise(10.0);
}

event Destroyed()
{
	local SiegeGI Game;
	local float HighestDamage, FriendlyFireScale;
	local int i;
	
	Game = SiegeGI(Level.Game);
	if ( Game == None )
		return;
		
	if ( Team < 4 )
	{
		FriendlyFireScale = 1;
		if ( TeamGamePlus(Level.Game) != None )
			FriendlyFireScale = TeamGamePlus(Level.Game).FriendlyFireScale;
		else if ( TeamGame(Level.Game) != None )
			FriendlyFireScale = TeamGame(Level.Game).FriendlyFireScale;
			
	
		TeamDamage[Team] *= FriendlyFireScale;
		if ( Game.NetworthStat[Team] != None )
			Game.NetworthStat[Team].AddEvent( 6 + int(bAmplified) );
	}
		
	For ( i=0 ; i<4 ; i++ )
		HighestDamage = Max( HighestDamage, TeamDamage[i]);
		
	For ( i=0 ; i<4 ; i++ )
		if ( (TeamDamage[i] > HighestDamage * 0.2) && (Game.NetworthStat[i] != None) )
			Game.NetworthStat[i].AddEvent(0); //Nuke blast
			
}

simulated event Tick( float DeltaTime )
{
	local float OldShockTimer;
	local float Alpha;
	
	OldShockTimer = ShockTimer;
	ShockTimer += FMin( DeltaTime, ShockTick);
	if ( int(OldShockTimer/ShockTick) != int(ShockTimer/ShockTick) )
		DamageTick( int(ShockTimer/ShockTick) );
	if ( ShockTimer >= MaxShockTime )
		Destroy();
	
	if ( Level.NetMode != NM_DedicatedServer )
	{
		Alpha = FMin( ShockTimer / MaxShockTime, 1.0);
		ScaleGlow = 1 - Alpha;
		AmbientGlow = ScaleGlow * 128;
		DrawScale = FMax(0.1, 100 * Alpha);
	}
}

simulated function DamageTick( int TickNumber)
{
    local rotator   randRot;
    local Actor     Victim;
	local float     Damage, DamageRadius;
    local vector    Dir, Offset;
    local int       i;
	local byte      VictimTeam;
	local float     OldDamageRadius;

	OldDamageRadius = 2900.0 * float(TickNumber-1) * ShockTick / MaxShockTime;
	DamageRadius    = 2900.0 * float(TickNumber)   * ShockTick / MaxShockTime;

	// Spawn effects
	if ( Level.NetMode != NM_DedicatedServer )
	{
		i = 2
		  + int(!Level.bDropDetail)
		  + int(!class'sgClient'.default.bHighPerformance)
		  + Rand(3);
		while ( i-->0 )
		{
			randRot = HitNorm;
			randRot.Pitch += Rand(32750)-16375;
			randRot.Roll += Rand(32750)-16375;
			randRot.Yaw += Rand(32750)-16375;
			Spawn(class'sgNukeFlame',,, Location + vector(randRot) * DamageRadius / 2);
		}
	}
	
	
	if ( Role == ROLE_Authority )
	{
//		ForEach VisibleCollidingActors( class 'Actor', Victim, DamageRadius, Location )
		ForEach RadiusActors( class 'Actor', Victim, DamageRadius, Location )
			if ( Victim.bCollideActors && (Pawn(Victim) != None || Mover(Victim) != None || Projectile(Victim) != None) )
			{
				Dir = Victim.Location - Location;
				Offset = Normal(Dir);
				// Try multiple points
				if	(	FastTrace( Location,              Victim.Location)
					||	FastTrace( Location + Offset * 2, Victim.Location + VRand() - Offset * 2)
					||	FastTrace( Location + Offset * 8, Victim.Location + VRand() - Offset * 4) )
				{
					Damage = 220.0 * (1.0 - FMax(VSize(Dir),20) / DamageRadius);
					if ( Damage >= 1 )
					{
						if ( Pawn(Victim) != None )
						{
							if ( Pawn(Victim).PlayerReplicationInfo != None )
								VictimTeam = Pawn(Victim).PlayerReplicationInfo.Team;
							else if ( sgBuilding(Victim) != None )
							{
								VictimTeam = sgBuilding(Victim).Team;
								if (	Mine(Victim) != None 
									&&	VictimTeam == Team
									&&	VSize(Dir) >= OldDamageRadius
									&&	VSize(Dir) < DamageRadius )
									Mine(Victim).Damage(true);
							}
							else
								VictimTeam = 254; //Ensure non players can harm each other
								
							if ( VictimTeam < 4 )
								TeamDamage[VictimTeam] += Damage;
						}
						Victim.TakeDamage
						(
							Damage,
							Instigator,
							Victim.Location - (0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * Normal(Dir)),
							vect(0,0,0),
							'exploded'
						);
					}
				}
		}
	}
}

defaultproperties
{
     LifeSpan=0
     Team=255
     bAlwaysRelevant=True
     Physics=PHYS_Rotating
     RemoteRole=ROLE_SimulatedProxy
     DrawType=DT_Mesh
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.ShockWavem'
     bUnlit=True
     MultiSkins(1)=Texture'sgMedia.GFX.sgSWave'
     bFixedRotationDir=True
}
