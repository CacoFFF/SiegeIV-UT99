//=============================================================================
// WarShell.
// * Revised by 7DS'Lust
//=============================================================================
class sgWarShell extends Projectile;

var float CannonTimer, SmokeRate;
var	redeemertrail trail;
var() float health;
var float SpawnedAt;

replication
{
	// Things the server should send to the client.
	reliable if ( Role == ROLE_Authority )
		health;
}

simulated function Timer()
{
	local ut_SpriteSmokePuff b;

	if ( Trail == None )
		Trail = Spawn(class'RedeemerTrail',self);

	CannonTimer += SmokeRate;
	if ( CannonTimer > 0.6 )
	{
		WarnCannons();
		CannonTimer -= 0.6;
	}

	if ( Region.Zone.bWaterZone || (Level.NetMode == NM_DedicatedServer) )
	{
		SetTimer(SmokeRate, false);
		Return;
	}

	if ( Level.bHighDetailMode )
	{
		if ( Level.bDropDetail )
			Spawn(class'LightSmokeTrail');
		else
			Spawn(class'UTSmokeTrail');
		SmokeRate = 152/Speed; 
	}
	else 
	{
		SmokeRate = 0.15;
		b = Spawn(class'ut_SpriteSmokePuff');
		b.RemoteRole = ROLE_None;
	}
	SetTimer(SmokeRate, false);
}

simulated function Destroyed()
{
	if ( Trail != None )
		Trail.Destroy();
	Super.Destroyed();
}

simulated function PostBeginPlay()
{
	SmokeRate = 0.3;
	SetTimer(0.3,false); 
	if ( Level.NetMode != NM_Client )
		SpawnedAt = Level.TimeSeconds;
}

simulated function WarnCannons()
{
	local Pawn P;

	for ( P=Level.Pawnlist; P!=None; P=P.NextPawn )
		if ( P.IsA('sgWarshell') && P.LineOfSightTo(self) )
		{
			P.target = self;
			P.GotoState('TrackWarhead');
		}
}

singular function TakeDamage( int NDamage, Pawn instigatedBy, vector hitlocation, vector momentum, name damageType )
{
	local SiegeGI Game;
	local byte OwnerTeam, DenierTeam;
	local SiegeStatPlayer Stat, VictimStat;
	
	if ( bDeleteMe )
		return;
	health-=NDamage;

	if ( (health <= 0) && (Role == ROLE_Authority)  )
	{
		OwnerTeam = class'SiegeStatics'.static.GetTeam(Instigator);
		DenierTeam = class'SiegeStatics'.static.GetTeam(instigatedBy);
		VictimStat = class'SiegeStatics'.static.GetPlayerStat(Instigator);

		if ( instigatedBy != Instigator )
		{
			Stat = class'SiegeStatics'.static.GetPlayerStat( instigatedBy );
			if ( Stat != None )
				Stat.WarheadDestroyEvent( 1 );
		}
	
		if ( instigatedBy != None )
		{
			if ( Instigator != None )
				Level.Game.BroadcastMessage( Instigator.GetHumanName()$ "'s nuke was taken down by"@ instigatedBy.GetHumanName()$"!");
			else
				Level.Game.BroadcastMessage("The nuke was taken down by"@ instigatedBy.GetHumanName()$"!");
		}

		if(VictimStat != None) 
			VictimStat.WarheadFailEvent(1);
	
		if ( (OwnerTeam != DenierTeam) && (instigatedBy != None) && (instigatedBy.PlayerReplicationInfo != None) )
		{
			if ( sgPRI(instigatedBy.PlayerReplicationInfo) != None )
				sgPRI(instigatedBy.PlayerReplicationInfo).AddRU( 500 );
			instigatedBy.PlayerReplicationInfo.Score += 10;
		}

		Game = SiegeGI(Level.Game);
		if ( Game != none )
		{
			if ( Game.bUseDenied )
				DeniedSound();
			if ( (OwnerTeam < 4) && (DenierTeam < 4) )
			{
				if ( Game.NetworthStat[OwnerTeam] != None )
					Game.NetworthStat[OwnerTeam].AddEvent( 2 + DenierTeam);
				if ( (OwnerTeam != DenierTeam) && (Game.NetworthStat[DenierTeam] != None) )
					Game.NetworthStat[DenierTeam].AddEvent( 1);
			}
		}
		Spawn(class'UT_SpriteBallExplosion');
		RemoteRole = ROLE_SimulatedProxy;	 		 		
 		Destroy();
	}
}

function DeniedSound()
{
	local PlayerPawn P;
	
	ForEach AllActors( class'PlayerPawn', P)
		P.ClientPlaySound( sound'denied_3');
}

auto state Flying
{
	simulated function ZoneChange( Zoneinfo NewZone )
	{
		local waterring w;
		
		if ( NewZone.bWaterZone != Region.Zone.bWaterZone )
		{
			w = Spawn(class'WaterRing',,,,rot(16384,0,0));
			w.DrawScale = 0.2;
			w.RemoteRole = ROLE_None; 
		}	
	}

	function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if ( Other != Instigator ) 
			Explode(HitLocation,Normal(HitLocation-Other.Location));
	}

	function Explode(vector HitLocation, vector HitNormal)
	{
		local vector SpawnLocation;
		
		if ( Role < ROLE_Authority )
			return;
	 	
		SpawnLocation = Location; //was HitLocation + HitNormal*16
		
		PlaySound(impactsound, SLOT_None, 20,,10000,1+(FRand()*0.3-0.15));
		PlaySound(sound'sgmedia.sgnukering', SLOT_None, 20,,7500);
		PlaySound(miscsound, SLOT_None, 30,,5000,1+(FRand()*0.3-0.15));
		Spawn(class'sgNukeRing',,,SpawnLocation,rotator(hitnormal));
 		Spawn(class'sgNukeFlash',,,SpawnLocation, rotator(hitnormal));
		Spawn(class'sgSWave',,,SpawnLocation, rotator(hitnormal));	
		RemoteRole = ROLE_SimulatedProxy;	 		 		
 		Destroy();
	}

	function BeginState()
	{
		local vector InitialDir;

		initialDir = vector(Rotation);
		if ( Role == ROLE_Authority )	
			Velocity = speed*initialDir;
		Acceleration = initialDir*50;
	}
}

defaultproperties
{
     Health=26.000000
     speed=750.000000
     Damage=1250.000000
     MomentumTransfer=100000
     MyDamageType=RedeemerDeath
     ImpactSound=Sound'kaboom1'
     MiscSound=Sound'sgMedia.SFX.sgNuke2'
     ExplosionDecal=Class'Botpack.NuclearMark'
     bNetTemporary=False
     RemoteRole=ROLE_SimulatedProxy
     AmbientSound=Sound'Botpack.Redeemer.WarFly'
     Mesh=LodMesh'Botpack.missile'
     AmbientGlow=78
     bUnlit=True
     SoundRadius=128
     SoundVolume=255
     CollisionRadius=22.000000
     CollisionHeight=14.000000
     bProjTarget=True
}

