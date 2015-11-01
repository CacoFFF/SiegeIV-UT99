//=============================================================================
// HyperLeecher.
//=============================================================================
class HyperLeecher expands WildcardsWeapons;

var float ChargeSize, Count;
var bool bBurst;

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	if ( (Owner != None) && (VSize(Owner.Velocity) > 10) )
		PlayAnim('Walking',0.3,0.3);
	else 
		TweenAnim('Still', 1.0);
	Enable('AnimEnd');
}

function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist;
	local bool bRetreating;
	local vector EnemyDir;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	bUseAltMode = 0;
	if ( Pawn(Owner).Enemy == None )
		return AIRating;

	EnemyDir = Pawn(Owner).Enemy.Location - Owner.Location;
	EnemyDist = VSize(EnemyDir);
	if ( EnemyDist > 1400 )
		return 0;

	bRetreating = ( ((EnemyDir/EnemyDist) Dot Owner.Velocity) < -0.6 );
	if ( (EnemyDist > 600) && (EnemyDir.Z > -0.4 * EnemyDist) )
	{
		// only use if enemy not too far and retreating
		if ( !bRetreating )
			return 0;

		return AIRating;
	}

	bUseAltMode = int( FRand() < 0.3 );

	if ( bRetreating || (EnemyDir.Z < -0.7 * EnemyDist) )
		return (AIRating + 0.18);
	return AIRating;
}

// return delta to combat style
function float SuggestAttackStyle()
{
	return -0.3;
}

function float SuggestDefenseStyle()
{
	return -0.4;
}

function AltFire( float Value )
{
	bPointing=True;
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) ) 
	{
		GoToState('AltFiring');
		bCanClientFire = true;
		ClientAltFire(Value);
	}
}

simulated function bool ClientAltFire( float Value )
{
	local bool bResult;

	InstFlash = 0.0;
	bResult = Super.ClientAltFire(value);
	InstFlash = Default.InstFlash;
	return bResult;
}

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustToss(ProjSpeed, Start, 0, True, (bWarn || (FRand() < 0.4)));	
	return Spawn(ProjClass,,, Start,AdjustedAim);
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(Sound'Botpack.BioRifle.BioAltRep', SLOT_Misc, 1.3*Pawn(Owner).SoundDampening);	 //loading goop	
	PlayAnim('Charging',0.24,0.05);
}

///////////////////////////////////////////////////////
state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		if ( bBurst )
			return;
		if ( !bCanClientFire || (Pawn(Owner) == None) )
			GotoState('');
		else if ( Pawn(Owner).bAltFire == 0 )
		{
			PlayAltBurst();
			bBurst = true;
		}
	}

	simulated function AnimEnd()
	{
		if ( bBurst )
		{
			bBurst = false;
			Super.AnimEnd();
		}
		else
			TweenAnim('Loaded', 0.5);
	}
}

state AltFiring
{
	ignores AnimEnd;

	function Tick( float DeltaTime )
	{
		if ( ChargeSize < 8.1 )
		{
			Count += DeltaTime * 1.25;
			if ( (Count > 0.5) && AmmoType.UseAmmo(1) )
			{
				ChargeSize += Count;
				Count = 0;
				if ( (PlayerPawn(Owner) == None) && (FRand() < 0.2) )
					GoToState('ShootLoad');
			}
		}
		if( (pawn(Owner).bAltFire==0) ) 
			GoToState('ShootLoad');
	}

	function BeginState()
	{
		ChargeSize = 0.0;
		Count = 0.0;
	}

	function EndState()
	{
		ChargeSize = FMin(ChargeSize, 8.1);
	}

Begin:
	FinishAnim();
}

state ShootLoad
{
	function ForceFire()
	{
		bForceFire = true;
	}

	function ForceAltFire()
	{
		bForceAltFire = true;
	}

	function Fire(float F) 
	{
	}

	function AltFire(float F) 
	{
	}

	function Timer()
	{
		local rotator R;
		local vector start, X,Y,Z;

		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		R = Owner.Rotation;
		R.Yaw = R.Yaw + Rand(8000) - 4000;
		R.Pitch = R.Pitch + Rand(1000) - 500;
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		Spawn(AltProjectileClass,,, Start,R);

		R = Owner.Rotation;
		R.Yaw = R.Yaw + Rand(8000) - 4000;
		R.Pitch = R.Pitch + Rand(1000) - 500;
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		Spawn(AltProjectileClass,,, Start,R);
	}

	function AnimEnd()
	{
		Finish();
	}

	function BeginState()
	{
		Local Projectile Gel;

		Gel = ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
		Gel.DrawScale = 1.0 + 0.8 * ChargeSize;
		PlayAltBurst();
	}

Begin:
}


// Finish a firing sequence
function Finish()
{
	local bool bForce, bForceAlt;

	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;

	if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( PlayerPawn(Owner) == None )
	{
		Pawn(Owner).bAltFire = 0;
		Super.Finish();
	}
	else if ( (AmmoType.AmmoAmount<=0) || (Pawn(Owner).Weapon != self) )
		GotoState('Idle');
	else if ( (Pawn(Owner).bFire!=0) || bForce )
		Global.Fire(0);
	else if ( (Pawn(Owner).bAltFire!=0) || bForceAlt )
		Global.AltFire(0);
	else 
		GotoState('Idle');
}

simulated function PlayAltBurst()
{
	if ( Owner.IsA('PlayerPawn') )
		PlayerPawn(Owner).ClientInstantFlash( InstFlash, InstFog);
	PlayOwnedSound(FireSound, SLOT_Misc, 1.7*Pawn(Owner).SoundDampening);	//shoot goop
	PlayAnim('Fire',5, 0.05);
}

simulated function PlayFiring()
{
//	PlayOwnedSound(AltFireSound, SLOT_None, 1.7*Pawn(Owner).SoundDampening);	//fast fire goop
	//LoopAnim('Fire',0.65 + 0.4 * FireAdjust, 0.05);
	//LoopAnim('Fire',0.65 + 0.4 * FireAdjust, 0.05);
    PlayOwnedSound(AltFireSound, SLOT_None, 1.7*Pawn(Owner).SoundDampening);	//fast fire goop
	PlayAnim('Charging', 10, 0.05);
}

defaultproperties
{
     MaxTargetRange=1000.000000
     AmmoName=Class'HyperLeecherAmmo'
     PickupAmmoCount=100
     bAltWarnTarget=True
     bRapidFire=True
     FiringSpeed=4.000000
     FireOffset=(X=12.000000,Y=-11.000000,Z=-6.000000)
     ProjectileClass=Class'Botpack.sgBioGel'
     AltProjectileClass=Class'Botpack.BioGlob'
     AIRating=0.900000
     RefireRate=0.950000
     AltRefireRate=0.900000
     FireSound=Sound'HyperLeecherFire'
     AltFireSound=Sound'HyperLeecherFire'
     CockingSound=Sound'UnrealI.Blob.BlobInjur'
     SelectSound=Sound'HyperLeecherSelect'
     DeathMessage="%o was oversaturated by  %k's bio madness!"
     NameColor=(R=0,B=0)
     AutoSwitchPriority=3
     InventoryGroup=3
     PickupMessage="You Found The Hyper Leecher"
     ItemName="Hyper Leecher"
     PlayerViewOffset=(X=1.700000,Y=-0.850000,Z=-0.950000)
     PlayerViewMesh=LodMesh'Botpack.BRifle2'
     BobDamping=0.972000
     PickupViewMesh=LodMesh'Botpack.BRifle2Pick'
     ThirdPersonMesh=LodMesh'Botpack.BRifle23'
     StatusIcon=Texture'Botpack.Icons.UseBio'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UseBio'
     Texture=WetTexture'WetHyprLeecherEnvMapSkin'
     Mesh=LodMesh'Botpack.BRifle2Pick'
     bNoSmooth=False
     bMeshEnviroMap=True
}
