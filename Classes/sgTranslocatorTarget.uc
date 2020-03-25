//=============================================================================
// sgTranslocatorTarget.
//
// Revised by Higor
// - Fixes several collision issues and enhances client simulation by providing
// impact information.
//=============================================================================
class sgTranslocatorTarget expands TranslocatorTarget;
/*
Ideas:
> Alt fire to shoot a trans so that it falls and sticks at where you aim at...
Auto trans on impact (optional?, maybe if ALTFIRE is held after firing it) for the alt fire mode.
Fail ALT shoot if no possible trajectory to aim point (no curve, or too far) (optional).
> Make the trans stick to a teammate instead of falling.
> Teammates can repair a disrupted trans.
> Being affected by Boosters and Super Boosters.
*/

function Throw(Pawn Thrower, float force, vector StartPosition)
{
	local vector dir;

	dir = vector(Thrower.ViewRotation);
	if ( Thrower.IsA('Bot') )
		Velocity = force * dir + vect(0,0,200);
	else
	{
		dir.Z = dir.Z + 0.35 * (1 - Abs(dir.Z));
		Velocity = force * Normal(dir);
//		Velocity = FMin(force,  Master.MaxTossForce + (Master.Charge *150)) * Normal(dir);
	}
	bBounce = true;
	DropFrom(StartPosition);
}


////////////////////////////////////////////////////////
auto state Pickup
{
	simulated singular function Touch( Actor Other )
	{
		local bool bMasterTouch;
		local vector NewPos;

		if ( Instigator == none || Instigator.bDeleteMe )
		{
			Destroy();
			return;
		}
		
		if ( !Other.bIsPawn )
		{
			if ( (Physics == PHYS_Falling) && !Other.IsA('Inventory') && !Other.IsA('Triggers') && !Other.IsA('NavigationPoint') )
				BounceActor( Other);
			return;
		}
		if ( sgBuilding(Other) != none )
		{
			if ( Other.bBlockActors || sgBuilding(Other).bStandable || (sgBuilding(Other).Team != Instigator.PlayerReplicationInfo.Team) )
				BounceActor( Other);
			return;
		}
		bMasterTouch = (Other == Instigator) || ((Master != None) && (Other == Master.Owner));
		
		if ( Physics == PHYS_None )
		{
			if ( bMasterTouch )
			{
				PlaySound(Sound'Botpack.Pickups.AmmoPick',,2.0);
				if ( Master != None )
				{
					Master.TTarget = None;
					Master.bTTargetOut = false;
				}
				if ( Other.IsA('PlayerPawn') )
					PlayerPawn(Other).ClientWeaponEvent('TouchTarget');
				destroy();
			}
			return;
		}
		if ( bMasterTouch ) 
			return;
		NewPos = Other.Location;
		NewPos.Z = Location.Z;
		SetLocation(NewPos);
		Velocity = vect(0,0,0);
		if ( Level.Game.bTeamGame && (Pawn(Other).PlayerReplicationInfo != none) && (Instigator.PlayerReplicationInfo.Team == Pawn(Other).PlayerReplicationInfo.Team) )
			return;

		if ( Instigator.IsA('Bot') )
			Master.Translocate();
	}

	//Make an ultra precise bounce on both server and clients
	simulated function BounceActor( actor Other)
	{
		local bool bOldHit, bBounceOff;
		local int i;
		local vector aVec, oVec;

		//No brushes
		if ( (Mover(Other) != none) || (LevelInfo(Other) != none) || (Other == none) )
			return;

		//Evaluate location and exact hitnormal/hitlocation, use 10 step precision for it at first (no gravity pull, sorry)
		//First point avoided, didn't touch during last tick anyways
		While (++i <= 10)
		{
			aVec = OldLocation + (Location - OldLocation) * 0.1 * float(i);
			if ( abs(aVec.Z - Other.Location.Z) <= (CollisionHeight + Other.CollisionHeight) )
				if ( VSize( (Other.Location - aVec) * vect(1,1,0)) <= (CollisionRadius + Other.CollisionRadius) )
				{
					oVec = OldLocation + (Location - OldLocation) * 0.1 * float(i-1);
					break;
				}
		}

		//No collision detected here, do not bounce
		if ( oVec == vect(0,0,0) )
			return;

		SetLocation( oVec);

		//Compare Z component of hull normal and location diff normal, so we know if we hit side or ceil/floor
		oVec = Normal(vect(0,0,1) * (Other.CollisionHeight + CollisionHeight) + vect(1,0,0) * (Other.CollisionRadius + CollisionRadius));
		aVec = Normal( Location - Other.Location);
		bOldHit = bAlreadyHit; //Save this and restore later
		if ( aVec.Z > oVec.Z )
		{
			bBounceOff = Other.bIsPawn;
			if ( bBounceOff && sgBuilding(Other) != none && sgBuilding(Other).bStandable )
				bBounceOff = false;
			aVec = Location;
			aVec.Z = Other.Location.Z + CollisionHeight + Other.CollisionHeight;
			SetLocation( aVec);
			//Bounce
			if ( !bAlreadyHit || bBounceOff )
			{
				HitWall( vect(0,0,1), Other);
				if ( bBounceOff )
				{
					bAlreadyHit = False;
					Velocity += (Location - Other.Location);
				}
			}
			else
			{	//Land
				SetPhysics( PHYS_None);
				Velocity = vect(0,0,0);
				Landed( vect(0,0,1) );
			}
		}
		else if ( aVec.Z < -oVec.Z )
		{
			aVec = Location;
			aVec.Z = Other.Location.Z - (CollisionHeight + Other.CollisionHeight);
			SetLocation( aVec);
			bAlreadyHit = false;
			HitWall( vect(0,0,-1), Other);
			bAlreadyHit = bAlreadyHit || bOldHit;
		}
		else
		{
			aVec = Other.Location + Normal( (Location - Other.Location)*vect(1,1,0)) * (CollisionRadius + Other.CollisionRadius);
			aVec.Z = Location.Z;
			SetLocation( aVec);
			bAlreadyHit = false;
			HitWall( Normal((Location - Other.Location)*vect(1,1,0)) , Other);
			bAlreadyHit = bAlreadyHit || bOldHit;
		}

	}
	event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
	{
		Super.TakeDamage( Damage, EventInstigator, HitLocation, Momentum, DamageType);

		if ( RemoteRole == ROLE_SimulatedProxy && Momentum != vect(0,0,0) )
			Spawn( class'sgGenericImpact').Setup(self);
	}
}
