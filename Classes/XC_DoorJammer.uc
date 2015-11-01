// Door Jammer
// By Higor
class XC_DoorJammer expands sgBuilding;

var Trigger TrackedTrigger;
var Mover TrackedMover;
var rotator PreRot;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		PreRot;
}

event PostBeginPlay()
{
	local vector HitLocation, HitNormal, Dir;
	local actor A, Nearest;
	local Mover M;
	local float Dist, NearestDist;
	
	Dir = vector(Rotation);
	A = Trace( HitLocation, HitNormal, Location + vect(0,0,10) + Dir * 50, Location + vect(0,0,10), true, vect(1,1,1) );
	
	if ( A != Level )
	{
		Destroy();
		return;
	}

	//Find a trigger
	NearestDist = 800;
	ForEach AllActors (class'Mover', M)
	{
		if ( M.bTriggerOnceOnly )
			continue;
		if ( M.IsInState('StandOpenTimed') )//Lifts
		{
			Dist = VSize( M.Location - Location);
			if ( Dist < 120 )
			{
				if ( Dist < NearestDist )
				{
					NearestDist = Dist;
					Nearest = M;
				}
			}
			else if ( Dist < 600 )
			{
				Dist = TraceToMover( M);
				if ( (Dist < 600) && (Dist < NearestDist) )
				{
					NearestDist = Dist;
					Nearest = M;
					TrackedMover = M;
				}
			}
		}
		else if ( M.IsInState('TriggerControl') || M.IsInState('TriggerOpenTimed') )
		{
			if ( (M.TriggerActor != none) && (M.TriggerActor.class == class'Trigger') )
			{
				Dist = VSize( M.TriggerActor.Location - Location);
				if ( (Dist < 100 + M.TriggerActor.CollisionRadius * 1.27) && (Dist < NearestDist) )
				{
					NearestDist = Dist;
					Nearest = M.TriggerActor;
					TrackedMover = M;
					TrackedTrigger = Trigger(M.TriggerActor);
				}
			}
			if ( (M.TriggerActor2 != none) && (M.TriggerActor2.class == class'Trigger') )
			{
				Dist = VSize( M.TriggerActor2.Location - Location);
				if ( (Dist < 100 + M.TriggerActor2.CollisionRadius * 1.27) && (Dist < NearestDist) )
				{
					NearestDist = Dist;
					Nearest = M.TriggerActor2;
					TrackedMover = M;
					TrackedTrigger = Trigger(M.TriggerActor2);
				}
			}
		}
	}


	if ( TrackedMover != none )
	{
		bCollideWorld=False;
		bCollideWhenPlacing=False;
		SetLocation( HitLocation);
		if ( HitNormal.Z == 0 )
			HitNormal.Z = 0.08;
		SetRotation( rotator(-HitNormal) );
		PreRot = Rotation;
		SetCollisionSize( 10, 10);
	}
	else
		Destroy();

	Super.PostBeginPlay();
}

function CompleteBuilding()
{
	local Actor A;

	if ( TrackedMover == none || bDisabledByEMP || TrackedMover.bDelaying || TrackedMover.bOpening )
		return;
		
	if ( TrackedMover.KeyNum == 0 )
	{
		if ( TrackedMover.IsInState('StandOpenTimed') )
		{
			bIsPlayer = true;
			TrackedMover.Attach( self);
			bIsPlayer = false;
		}
		else
		{
			ForEach AllActors (class'Actor', A, TrackedMover.Tag)
				A.Trigger( self, self);
		}
	}
}

event Destroyed()
{
	if ( TrackedMover != none )
		UnJam();
	Super.Destroyed();
}

function Electrify()
{
	if ( !bDisabledByEMP )
		UnJam();
	Super.Electrify();
}

function UnJam()
{
	local Actor A;
	if ( TrackedMover.IsInState('TriggerControl') )
	{
		ForEach AllActors (class'Actor', A, TrackedMover.Tag)
			A.UnTrigger( self, self);
	}
}

event TakeDamage( int Damage, Pawn instigatedBy, vector HitLocation, Vector momentum, name DamageType)
{
	if ( DamageType == 'sgSpecial' )
		Damage = (Damage * 2) / 3;
	Super.TakeDamage(Damage, instigatedBy, HitLocation, momentum, DamageType);
}

simulated function FinishBuilding()
{
	local vector X, Y, Z;
	local Rotator Rots;
	Super.FinishBuilding();
	if ( myFX != none )
	{
		GetAxes( PreRot, X, Y, Z);
		Rots = rotator(Z);
		if ( X.Z > 0 )
			Rots.Roll = 32768;
		myFX.SetRotation( Rots );
	}
}

function float TraceToMover( Mover M)
{
	local vector HitLocation, HitNormal;
	local Actor A;

	ForEach TraceActors (class'Actor', A, HitLocation, HitNormal, M.Location)
		if ( A == M )
			return VSize(HitLocation - Location);
	return 9999;
}

defaultproperties
{
     Model=LodMesh'UnrealShare.AmplifierM'
     DSofMFX=0.530000
     SpriteScale=0.150000
     bCanTakeOrb=False
     bNoUpgrade=True
     BurnPerSecond=300
     BuildCost=175
     MaxEnergy=1000
     BuildTime=4
     BuildDistance=15
     CollisionRadius=8
     CollisionHeight=8
     ScaleGlow=0.4
     BuildingName="Door Jammer"
     SpriteRedTeam=Texture'ContainerXSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerXSpriteTeam1'
     SpriteGreenTeam=Texture'ContainerXSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerXSpriteTeam3'
     bCollideWhenPlacing=False
     SpriteProjForward=4
}
