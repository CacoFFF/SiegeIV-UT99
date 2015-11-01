//=============================================================================
// AsmdPulseRifle.
// Written By nOs*Wildcard
//=============================================================================
class AsmdPulseRifle expands WildcardsWeapons;

var float Angle, Count;
var PBolt PlasmaBeam;
var() sound DownSound;
var() int HitDamage;
var float ClientSleepAgain;

auto state Pickup
{
	ignores AnimEnd;

	// Landed on ground.
	simulated function Landed(Vector HitNormal)
	{
		local rotator newRot;

		newRot = Rotation;
		newRot.pitch = 0;
		SetRotation(newRot);
		if ( Role == ROLE_Authority )
		{
			bSimFall = false;
			SetTimer(2.0, false);
		}
	}
}

simulated event RenderOverlays( canvas Canvas )
{
	MultiSkins[1] = none;
	Texture'Ammoled'.NotifyActor = Self;
	Super.RenderOverlays(Canvas);
	Texture'Ammoled'.NotifyActor = None;
	MultiSkins[1] = Default.MultiSkins[1];
}

simulated function Destroyed()
{
	if ( PlasmaBeam != None )
		PlasmaBeam.Destroy();

	Super.Destroyed();
}

simulated function AnimEnd()
{
	if ( (Level.NetMode == NM_Client) && (Mesh != PickupViewMesh) )
	{
		if ( AnimSequence == 'SpinDown' )
			AnimSequence = 'Idle';
		PlayIdleAnim();
	}
}
// set which hand is holding weapon
function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		FireOffset.Y = 0;
		bHideWeapon = true;
		if ( PlasmaBeam != None )
			PlasmaBeam.bCenter = true;
		return;
	}
	else
		bHideWeapon = false;
	PlayerViewOffset = Default.PlayerViewOffset * 100;
	if ( Hand == 1 )
	{
		if ( PlasmaBeam != None )
		{
			PlasmaBeam.bCenter = false;
			PlasmaBeam.bRight = false;
		}
		FireOffset.Y = Default.FireOffset.Y;
		Mesh = mesh(DynamicLoadObject("Botpack.PulseGunL", class'Mesh'));
	}
	else
	{
		if ( PlasmaBeam != None )
		{
			PlasmaBeam.bCenter = false;
			PlasmaBeam.bRight = true;
		}
		FireOffset.Y = -1 * Default.FireOffset.Y;
		Mesh = mesh'PulseGunR';
	}
}

// return delta to combat style
function float SuggestAttackStyle()
{
	local float EnemyDist;

	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	if ( EnemyDist < 1000 )
		return 0.4;
	else
		return 0;
}

function float RateSelf( out int bUseAltMode )
{
	local Pawn P;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	P = Pawn(Owner);
	if ( (P.Enemy == None) || (Owner.IsA('Bot') && Bot(Owner).bQuickFire) )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	if ( P.Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return (AIRating + 0.4);
	}
	else
		bUseAltMode = int( 700 > VSize(P.Enemy.Location - Owner.Location) );

	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

simulated function PlayFiring()
{
	FlashCount++;
	AmbientSound = FireSound;
	SoundVolume = Pawn(Owner).SoundDampening*255;
	LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	bWarnTarget = (FRand() < 0.2);
}

simulated function PlayAltFiring()
{
	
	FlashCount++;
	AmbientSound = AltFireSound;
	SoundVolume = Pawn(Owner).SoundDampening*255;
	LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	bWarnTarget = (FRand() < 0.2);
}

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
		ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
	}
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color C;
	local string Temp;

	if ( AmmoType == none )
		return;
	
	Temp = String(AmmoType.AmmoAmount);
	while(Len(Temp) < 3) Temp = "0"$Temp;

	Tex.DrawTile( 30, 100, (Min(AmmoType.AmmoAmount,AmmoType.Default.AmmoAmount)*196)/AmmoType.Default.AmmoAmount, 10, 0, 0, 1, 1, Texture'AmmoCountBar', False );

	if(AmmoType.AmmoAmount < 10)
	{
		C.R = 255;
		C.G = 0;
		C.B = 0;	
	}
	else
	{
		C.R = 0;
		C.G = 0;
		C.B = 255;
	}

	Tex.DrawColoredText( 56, 14, Temp, Font'LEDFont', C );	
}


///////////////////////////////////////////////////////
state NormalFire
{
	ignores AnimEnd;

	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Vector Start, X,Y,Z;

		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
		Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
		Angle += 1.8;
		return Spawn(ProjClass,,, Start,AdjustedAim);	
	}

	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			GotoState('Pickup');
	}

	function BeginState()
	{
		Super.BeginState();
		Angle = 0;
		AmbientGlow = 200;
	}

	function EndState()
	{
		PlaySpinDown();
		AmbientSound = None;
		AmbientGlow = 0;	
		OldFlashCount = FlashCount;	
		Super.EndState();
	}

Begin:
	Sleep(0.18);
	Finish();
}

simulated function PlaySpinDown()
{
	if ( (Mesh != PickupViewMesh) && (Owner != None) )
	{
		PlayAnim('Spindown', 1.0, 0.0);
		Owner.PlayOwnedSound(DownSound, SLOT_None,1.0*Pawn(Owner).SoundDampening);
	}
}	

simulated state ClientFiring
{
	simulated function Tick( float DeltaTime )
	{
		if ( (Pawn(Owner) != None) && (Pawn(Owner).bFire != 0) )
			AmbientSound = FireSound;
		else
			AmbientSound = None;
		if ((ClientSleepAgain -= DeltaTime) <= 0 ) //ACE IS BUGGED, SO I HAVE TO HANDLE THIS HERE
			AnimEnd();
	}

	simulated function AnimEnd()
	{
		if ( (AmmoType != None) && (AmmoType.AmmoAmount <= 0) )
		{
			PlaySpinDown();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlaySpinDown();
			GotoState('');
		}
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlaySpinDown();
			GotoState('');
		}
	}
Begin:
	ClientSleepAgain = 0.18;
//	Sleep(0.18);
}

///////////////////////////////////////////////////////////////
simulated state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( AmmoType.AmmoAmount <= 0 )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( Pawn(Owner).bAltFire != 0 )
			LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
Begin:
	Sleep(0.18);
	AnimEnd();
}

state AltFiring
{
	ignores AnimEnd;

	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Vector Start, X,Y,Z;

		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
		Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
		Angle += 1.8;
		return Spawn(ProjClass,,, Start,AdjustedAim);	
	}

	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			GotoState('Pickup');
	}

	function BeginState()
	{
		Super.BeginState();
		Angle = 0;
		AmbientGlow = 200;
	}

	function EndState()
	{
		PlaySpinDown();
		AmbientSound = None;
		AmbientGlow = 0;	
		OldFlashCount = FlashCount;	
		Super.EndState();
	}

Begin:
	Sleep(0.18);
	Finish();
}

state Idle
{
Begin:
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	if ( Pawn(Owner).bAltFire!=0 ) AltFire(0.0);	

	Disable('AnimEnd');
	PlayIdleAnim();
}

///////////////////////////////////////////////////////////
simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;

	if ( (AnimSequence == 'BoltLoop') || (AnimSequence == 'BoltStart') )
		PlayAnim('BoltEnd');		
	else if ( AnimSequence != 'SpinDown' )
		TweenAnim('Idle', 0.1);
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
		TweenAnim('Down', 0.26);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local int i;
	local PlayerPawn PlayerOwner;

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	PlayerOwner = PlayerPawn(Owner);
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);

	if ( ShockProj(Other)!=None )
	{ 
		AmmoType.UseAmmo(2);
		ShockProj(Other).SuperExplosion();
	}
	else
		Spawn(class'ut_RingExplosion5',,, HitLocation+HitNormal*8,rotator(HitNormal));

	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
		Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 60000.0*X, MyDamageType);
}

simulated function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local ShockBeam Smoke,shock;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	Smoke = Spawn(class'ShockBeam',,,SmokeLocation,SmokeRotation);
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;	
}

defaultproperties
{
     DownSound=Sound'Botpack.PulseGun.PulseDown'
     hitdamage=50
     AmmoName=Class'BlueGunAmmo'
     PickupAmmoCount=199
     bInstantHit=True
     bRapidFire=True
     FireOffset=(X=16.000000,Y=-14.000000,Z=-8.000000)
	 MultiSkins(1)=Texture'AsmdPulseRifleSkin'
	 MultiSkins(2)=Texture'AsmdPulseRifleSkin'
     ProjectileClass=Class'Botpack.PlasmaSphere'
     AltProjectileClass=Class'Botpack.ShockProj'
     MyDamageType=jolted
     AltDamageType=jolted
     shakemag=135.000000
     shakevert=8.000000
     AIRating=0.700000
     RefireRate=0.950000
     AltRefireRate=0.990000
     FireSound=Sound'AsmdPulseRiflePrimaryFire'
     AltFireSound=Sound'AsmdPulseRiflePrimaryFire'
     SelectSound=Sound'Botpack.PulseGun.PulsePickup'
     DeathMessage="%o was torn to pieces by %k's %w."
     NameColor=(R=128,G=0,B=128)
     FlashLength=0.020000
     AutoSwitchPriority=5
     InventoryGroup=5
     PickupMessage="You got the ASMD Pulse Rifle"
     ItemName="Pulse Gun"
     PlayerViewOffset=(X=1.500000,Z=-2.000000)
     PlayerViewMesh=LodMesh'Botpack.PulseGunR'
     PickupViewMesh=LodMesh'Botpack.PulsePickup'
     ThirdPersonMesh=LodMesh'Botpack.PulseGun3rd'
     ThirdPersonScale=0.400000
     StatusIcon=Texture'Botpack.Icons.UsePulse'
     bMuzzleFlashParticles=True
     MuzzleFlashStyle=STY_Translucent
     MuzzleFlashMesh=LodMesh'Botpack.muzzPF3'
     MuzzleFlashScale=0.400000
     MuzzleFlashTexture=Texture'Botpack.Skins.MuzzyPulse'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UsePulse'
     Mesh=LodMesh'Botpack.PulsePickup'
     bNoSmooth=False
}
