//=============================================================================
// FV_ApeCannon.
//=============================================================================
class ApeCannon expands UT_FlakCannon;

var bool bInitSkin;

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	WetTexture'APE_Flak'.Palette = Texture'APE_FlakPal'.Palette;
}

event PostBeginPlay()
{
	super.PostBeginPlay();
	WetTexture'APE_Flak'.Palette = Texture'APE_FlakPal'.Palette;
}



simulated event RenderOverlays( canvas Canvas )
{
	if ( !bInitSkin )
	{
		MultiSkins[1] = WetTexture'APE_Flak2';
		WetTexture'APE_Flak1'.Palette = Texture'APE_FlakPal1'.Palette;
		WetTexture'APE_Flak2'.Palette = Texture'APE_FlakPal2'.Palette;
		bInitSkin = True;
	}
	Super.RenderOverlays(Canvas);
}

// Fire chunks
function Fire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn P;

	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.UseAmmo(1))
	{
		bCanClientFire = true;
		bPointing=True;
		Start = Owner.Location + CalcDrawOffset();
		P = Pawn(Owner);
		P.PlayRecoil(FiringSpeed);
		Owner.MakeNoise(2.0 * P.SoundDampening);
		AdjustedAim = P.AdjustAim(AltProjectileSpeed, Start, AimError, True, bWarnTarget);
		GetAxes(AdjustedAim,X,Y,Z);
		Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));		
		Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;	
		Spawn( class 'APE_Chunk1',, '', Start, AdjustedAim);
		Spawn( class 'APE_Chunk2',, '', Start - Z, AdjustedAim);
		Spawn( class 'APE_Chunk3',, '', Start + 2 * Y + Z, AdjustedAim);
		Spawn( class 'APE_Chunk4',, '', Start - Y, AdjustedAim);
		Spawn( class 'APE_Chunk1',, '', Start + 2 * Y - Z, AdjustedAim);
		Spawn( class 'APE_Chunk2',, '', Start, AdjustedAim);
		Spawn( class 'APE_Chunk1',, '', Start, AdjustedAim);
		Spawn( class 'APE_Chunk2',, '', Start - Z, AdjustedAim);
		Spawn( class 'APE_Chunk3',, '', Start + 2 * Y + Z, AdjustedAim);
		Spawn( class 'APE_Chunk4',, '', Start - Y, AdjustedAim);
		Spawn( class 'APE_Chunk1',, '', Start + 2 * Y - Z, AdjustedAim);
		Spawn( class 'APE_Chunk2',, '', Start, AdjustedAim);
		Spawn( class 'APE_Chunk3',, '', Start + Y - Z, AdjustedAim);
		Spawn( class 'APE_Chunk4',, '', Start + 2 * Y + Z, AdjustedAim);
		Spawn( class 'APE_Chunk3',, '', Start + Y - Z, AdjustedAim);

		ClientFire(Value);
		GoToState('NormalFire');
	}
}

function AltFire( float Value )
{
	local Vector Start, X,Y,Z;

	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.UseAmmo(1))
	{
		Pawn(Owner).PlayRecoil(FiringSpeed);
		bPointing=True;
		bCanClientFire = true;
		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset();
		Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));
		Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;
		AdjustedAim = pawn(owner).AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);
		Spawn(class'APE_FlakSlug',,, Start,AdjustedAim);
		ClientAltFire(Value);
		GoToState('AltFiring');
	}
}

defaultproperties
{
     PickupMessage="You got the Ape Cannon."
     ItemName="APE Cannon"
     MultiSkins(0)=WetTexture'APE_Flak1'
     MultiSkins(1)=WetTexture'APE_Flak'
     DeathMessage="%o got CHIMP'd by %k."
     AmmoName=class'APEAmmo'
     PickupAmmoCount=65
     AltProjectileClass=class'APE_FlakSlug'
}
