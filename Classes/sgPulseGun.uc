//=============================================================================
// sgPulseGun.
//=============================================================================
class sgPulseGun expands PulseGun;

var sgPBolt sgPlasmaBeam;

//Shoot beam through walls fix
function AltFire( float Value )
{
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	
	if (AmmoType.UseAmmo(1))
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		bPointing=True;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		ClientAltFire(value);
		if (sgPlasmaBeam == None )
		{
			sgPlasmaBeam = sgPBolt(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
			if ( FireOffset.Y == 0 )
				sgPlasmaBeam.bCenter = true;
			else if ( Mesh == mesh'PulseGunR' )
				sgPlasmaBeam.bRight = false;
		}
	}
}

simulated function Destroyed()
{
	if ( sgPlasmaBeam != None )
		sgPlasmaBeam.Destroy();

	Super.Destroyed();
}

function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		FireOffset.Y = 0;
		bHideWeapon = true;
		if ( sgPlasmaBeam != None )
			sgPlasmaBeam.bCenter = true;
		return;
	}
	else
		bHideWeapon = false;
	PlayerViewOffset = Default.PlayerViewOffset * 100;
	if ( Hand == 1 )
	{
		if ( sgPlasmaBeam != None )
		{
			sgPlasmaBeam.bCenter = false;
			sgPlasmaBeam.bRight = false;
		}
		FireOffset.Y = Default.FireOffset.Y;
		Mesh = mesh(DynamicLoadObject("Botpack.PulseGunL", class'Mesh'));
	}
	else
	{
		if ( sgPlasmaBeam != None )
		{
			sgPlasmaBeam.bCenter = false;
			sgPlasmaBeam.bRight = true;
		}
		FireOffset.Y = -1 * Default.FireOffset.Y;
		Mesh = mesh'PulseGunR';
	}
}

//Avoid creating a sgPulseGun entry, use PulseGun instead
function SetSwitchPriority(pawn Other)
{
	local int i;
	local name temp, carried;

	if ( PlayerPawn(Other) != None )
	{
		for ( i=0; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++)
			if ( PlayerPawn(Other).WeaponPriority[i] == 'PulseGun' )
			{
				AutoSwitchPriority = i;
				return;
			}
		// else, register this weapon
		carried = 'PulseGun';
		for ( i=AutoSwitchPriority; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++ )
		{
			if ( PlayerPawn(Other).WeaponPriority[i] == '' )
			{
				PlayerPawn(Other).WeaponPriority[i] = carried;
				return;
			}
			else if ( i<ArrayCount(PlayerPawn(Other).WeaponPriority)-1 )
			{
				temp = PlayerPawn(Other).WeaponPriority[i];
				PlayerPawn(Other).WeaponPriority[i] = carried;
				carried = temp;
			}
		}
	}		
}


//Multigunning fix
state AltFiring
{
	ignores AnimEnd;

	function Tick(float DeltaTime)
	{
		local Pawn P;

		P = Pawn(Owner);
		if ( P == None )
		{
			GotoState('Pickup');
			return;
		}

		if ( Pawn(owner).PlayerReplicationInfo.bFeigningDeath == true && SiegeGI(Level.Game).AllowMultiGunning == false )
			{
				log("MultiGunning is Forbidden!");
				//Finish();
				Pawn(owner).bAltFire = 0;
				Finish();
				return;
				//GotoState('Idle');
			}

		if ( (P.bAltFire == 0) || (P.IsA('Bot')
					&& ((P.Enemy == None) || (Level.TimeSeconds - Bot(P).LastSeenTime > 5))) )
		{
			P.bAltFire = 0;
			Finish();
			return;
		}

		Count += Deltatime;
		if ( Count > 0.24 )
		{
			if ( Owner.IsA('PlayerPawn') )
				PlayerPawn(Owner).ClientInstantFlash( InstFlash,InstFog);
			if ( Affector != None )
				Affector.FireEffect();
			Count -= 0.24;
			if ( !AmmoType.UseAmmo(1) )
				Finish();
		}
	}
	
	function EndState()
	{
		AmbientGlow = 0;
		AmbientSound = None;
		if ( sgPlasmaBeam != None )
		{
			sgPlasmaBeam.Destroy();
			sgPlasmaBeam = None;
		}
		Super.EndState();
	}

Begin:
	AmbientGlow = 200;
	FinishAnim();	
	LoopAnim('boltloop');
}

defaultproperties
{
	AltProjectileClass=Class'sgStarterBolt'
}
