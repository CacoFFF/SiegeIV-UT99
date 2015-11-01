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

singular function TakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation, 
						vector momentum, name damageType )
{
	if ( bDeleteMe )
		return;
	health-=NDamage;

	if ( (health <= 0) && (Role ==ROLE_Authority)  )
	{
		if ( instigatedBy != Instigator && instigatedBy.bIsPlayer && instigatedBy.PlayerReplicationInfo != None )
		{
			if ( Instigator != None && Instigator.PlayerReplicationInfo != None )
			{
				Level.Game.BroadcastMessage(Instigator.PlayerReplicationInfo.PlayerName$ "'s nuke was taken down by"@ instigatedBy.PlayerReplicationInfo.PlayerName$"!");
				if ( instigatedBy.PlayerReplicationInfo.Team != Instigator.PlayerReplicationInfo.Team && sgPRI(instigatedBy.PlayerReplicationInfo) != None )
				{
					sgPRI(instigatedBy.PlayerReplicationInfo).AddRU(400.0 + 200*FRand());
					instigatedBy.PlayerReplicationInfo.Score += 10;
				}
                  
			}
			else
				Level.Game.BroadcastMessage("The nuke was taken down by"@ instigatedBy.PlayerReplicationInfo.PlayerName$"!");
			sgPRI(instigatedBy.PlayerReplicationInfo).sgInfoWarheadKiller++;
		}
		if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).bUseDenied )
			DeniedSound();
		Spawn(class'UT_SpriteBallExplosion');
		RemoteRole = ROLE_SimulatedProxy;	 		 		
 		Destroy();
	}
}

function DeniedSound()
{
	local PlayerPawn P;
	
	ForEach AllActors( class'PlayerPawn',P)
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
		if ( Other != instigator ) 
			Explode(HitLocation,Normal(HitLocation-Other.Location));
	}

	function Explode(vector HitLocation, vector HitNormal)
	{
		if ( Role < ROLE_Authority )
			return;
	 	
		PlaySound(impactsound, SLOT_None, 20,,10000,1+(FRand()*0.3-0.15));
		PlaySound(sound'sgmedia.sgnukering', SLOT_None, 20,,7500);
		PlaySound(miscsound, SLOT_None, 30,,5000,1+(FRand()*0.3-0.15));
		spawn(class'sgNukeRing',,,HitLocation+HitNormal*16,rotator(hitnormal));
 		spawn(class'sgNukeFlash',,,HitLocation+ HitNormal*16, rotator(hitnormal));
		spawn(class'sgSWave',,,HitLocation+ HitNormal*16, rotator(hitnormal));	
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
