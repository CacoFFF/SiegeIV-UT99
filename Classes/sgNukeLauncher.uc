//=============================================================================
// sgNukeLauncher.
// * Revised by 7DS'Lust
//=============================================================================
class sgNukeLauncher extends TournamentWeapon;

var sgGuidedWarShell GuidedShell;
var int Scroll;
var PlayerPawn GuidingPawn;
var bool	bGuiding, bCanFire, bShowStatic;
var rotator StartRotation;
var() sgtrail trail;
var XC_NukerDeco NukeDeco;

replication
{
	// Things the server should send to the client.
	reliable if( bNetOwner && (Role==ROLE_Authority) )
		bGuiding, bShowStatic;
	reliable if ( Role < ROLE_Authority )
		GetNuke;
}

exec function GetNuke()
{
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).GetWeapon(class);
}

function AddDeco()
{
	if ( (SiegeGI(Level.Game) != none) && !SiegeGI(Level.Game).bUseNukeDeco )
		return;

	if ( NukeDeco != none )
		NukeDeco.SetOwner( Owner);
	else
	{
		NukeDeco = Spawn(class'XC_NukerDeco', Owner);
		NukeDeco.SetNuke(self);
	}
}

function SetWeaponStay()
{
	bWeaponStay = false; // redeemer never stays
}

event Destroyed()
{
	if ( NukeDeco != none )
	{
		NukeDeco.Destroy();
		NukeDeco = none;
	}
	Super.Destroyed();
}

simulated function PostRender( canvas Canvas )
{
	local int i, numReadouts, OldClipX, OldClipY;
	local float XScale;

	bOwnsCrossHair = ( bGuiding || bShowStatic );

	if ( !bGuiding )
	{
		if ( !bShowStatic )
			return;

		Canvas.SetPos( 0, 0);
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawIcon(Texture'botpack.Static_a00', FMax(Canvas.ClipX, Canvas.ClipY)/256.0);
		if ( Owner.IsA('PlayerPawn') )
			PlayerPawn(Owner).ViewTarget = None;
		return;
	}
	if(trail==none)		trail=spawn(class'sgtrail',owner,,owner.location);
	GuidedShell.PostRender(Canvas);
	OldClipX = Canvas.ClipX;
	OldClipY = Canvas.ClipY;
	XScale = FMax(0.5, int(Canvas.ClipX/640.0));
	Canvas.SetPos( 0.5 * OldClipX - 128, 0.5 * OldClipY - 128);
	Canvas.Style = ERenderStyle.STY_Translucent;
	Canvas.DrawIcon(Texture'WH_A00', 1.0);

	numReadouts = OldClipY/128 + 2;
	for ( i = 0; i < numReadouts; i++ )
	{ 
		Canvas.SetPos(1,Scroll + i * 128);
		Scroll--;
		if ( Scroll < -128 )
			Scroll = 0;
		Canvas.DrawIcon(Texture'Readout', 1.0);
	}
}

function float RateSelf( out int bUseAltMode )
{
	local Pawn P, E;
	local Bot O;

	O = Bot(Owner);
	if ( (O == None) || (AmmoType.AmmoAmount <=0) || (O.Enemy == None) )
		return -2;

	bUseAltMode = 0;
	E = O.Enemy;

	for ( P=Level.PawnList; P!=None; P=P.NextPawn )
		if ( P.bIsPlayer && (P != O) && (P != E)
			&& (!Level.Game.bTeamGame || (O.PlayerReplicationInfo.Team != P.PlayerReplicationInfo.Team))
			&& (VSize(E.Location - P.Location) < 650) 
			&& (!Level.Game.IsA('TeamGamePlus') || TeamGamePlus(Level.Game).PriorityObjective(O) < 2)
			&& FastTrace(P.Location, E.Location) )
		{
			if ( VSize(E.Location - O.Location) > 500 )
				return 2.0;
			else
				return 1.0;
		}

	return 0.35;
}

// return delta to combat style
function float SuggestAttackStyle()
{
	return -1.0;
}

simulated function PlayFiring()
{
	local TournamentPlayer TP;
	local PlayerReplicationInfo PRI;
	
	PlayAnim( 'Fire', 0.3 );		
	PlayOwnedSound(FireSound, SLOT_None,4.0*Pawn(Owner).SoundDampening);

	if ( Pawn(Owner) == none )
		return;

	PRI = Pawn(Owner).PlayerReplicationInfo;
	if ( sgPRI(PRI) != none )
		sgPRI(PRI).sgInfoSpreeCount = Max( 5, sgPRI(PRI).sgInfoSpreeCount-2);
		
	ForEach AllActors (class'TournamentPlayer', TP)
		if ( (TP.PlayerReplicationInfo != none) && (TP.PlayerReplicationInfo.Team != PRI.Team) )
			TP.ReceiveLocalizedMessage(Class'sgNukeLaunchMsg');
}

function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		bHideWeapon = true;
		return;
	}
	else
		bHideWeapon = false;

	PlayerViewOffset.Y = Default.PlayerViewOffset.Y;
	PlayerViewOffset.X = Default.PlayerViewOffset.X;
	PlayerViewOffset.Z = Default.PlayerViewOffset.Z;
	
	PlayerViewOffset *= 100; //scale since network passes vector components as ints
}

//Add decoration if nuke was added by via on us
function GiveTo( pawn Other )
{
	Super.GiveTo(Other);
	if ( PickupAmmoCount > 0 )
		AddDeco();
}

//Add decoration if picked a nuke
function bool HandlePickupQuery( Inventory Item )
{
	local bool bResult;
	
	if ( (Item.Class == Class) && (AmmoType.AmmoAmount >= AmmoType.MaxAmmo) )
		return true;

	bResult = Super.HandlePickupQuery( Item);
	if ( (Item.Class == Class) && (AmmoType.AmmoAmount > 0) )
		AddDeco();
	return bResult;
}

//Destroy decoration if dropped nuke
function DropFrom(vector StartLocation)
{
	if ( NukeDeco != none )
		NukeDeco.Destroy();
	Super.DropFrom(StartLocation);
}

//If nukes were fired, destroy decoration
function Fire( float Value )
{
	Super.Fire(Value);
	if ( (AmmoType.AmmoAmount <= 0) && (NukeDeco != none) )
		NukeDeco.Destroy();
}

function AltFire( float Value )
{
	local pawn p;

	if ( !Owner.IsA('PlayerPawn') )
	{
		Fire(Value);
		return;
	}

	if ( AmmoType.UseAmmo(1) )
	{
		for ( p = Level.PawnList; p != None; p = p.nextPawn )
			if ( p.IsA('TournamentPlayer' ) && p.PlayerReplicationInfo.Team !=
              Pawn(Owner).PlayerReplicationInfo.Team)
				TournamentPlayer(P).ReceiveLocalizedMessage(Class'sgNukeBuildMsg', 1);

		if ( (AmmoType.AmmoAmount <= 0) && (NukeDeco != none) )
			NukeDeco.Destroy();

		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		bPointing=True;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		PlayFiring();
		GuidedShell = sgGuidedWarShell(ProjectileFire(AltProjectileClass,
          ProjectileSpeed, bWarnTarget));
		GuidedShell.SetOwner(Owner);
		PlayerPawn(Owner).ViewTarget = GuidedShell;
		GuidedShell.Guider = PlayerPawn(Owner);
		ClientAltFire(0);
		GotoState('Guiding');
	}
}

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local float SavedOffset;
	local Projectile Result;
	
	Result = Super.ProjectileFire( ProjClass, ProjSpeed, bWarn);
	if ( Result == None )
	{
		SavedOffset = FireOffset.X;
		FireOffset.X = 0;
		Result = Super.ProjectileFire( ProjClass, ProjSpeed, bWarn);
		FireOffset.X = SavedOffset;
	}

	return Result;	
}


simulated function bool ClientAltFire( float Value )
{
	if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		if ( Affector != None )
			Affector.FireEffect();
		PlayOwnedSound(FireSound, SLOT_None,4.0*Pawn(Owner).SoundDampening);
		return true;
	}
	return false;
}

State Guiding
{
	function Fire ( float Value )
	{
		if ( !bCanFire )
			return;
		if ( GuidedShell != None )
			GuidedShell.Explode(GuidedShell.Location,Vect(0,0,1));
		bCanClientFire = true;

		GotoState('Finishing');
	}

	function AltFire ( float Value )
	{
		Fire(Value);
	}

	function BeginState()
	{
		Scroll = 0;
		bGuiding = true;
		bCanFire = false;
		if ( Owner.IsA('PlayerPawn') )
		{
			GuidingPawn = PlayerPawn(Owner);
			StartRotation = PlayerPawn(Owner).ViewRotation;
			PlayerPawn(Owner).ClientAdjustGlow(-0.2,vect(200,0,0));
		}
	}

	function EndState()
	{
		bGuiding = false;
		if ( GuidingPawn != None )
		{
			GuidingPawn.ClientAdjustGlow(0.2,vect(-200,0,0));
			GuidingPawn.ClientSetRotation(StartRotation);
			GuidingPawn = None;
		}
	}


Begin:
	Sleep(1.0);
	bCanFire = true;
}

State Finishing
{
	ignores Fire, AltFire;

	function BeginState()
	{
		bShowStatic = true;
	}

Begin:
	Sleep(0.3);
	bShowStatic = false;
	Sleep(1.0);
	GotoState('Idle');
}

state Idle
{
	function EndState()
	{	
		Super.EndState();
		ambientsound=none;
	}

	Begin:
	ambientsound=sound'sgmedia.sggetnuke';
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	if ( Pawn(Owner).bAltFire!=0 ) AltFire(0.0);	

	Disable('AnimEnd');
	super.PlayIdleAnim();
}

defaultproperties
{
     WeaponDescription="Classification: Thermonuclear Device"
     InstFlash=-0.400000
     InstFog=(X=950.000000,Y=650.000000,Z=290.000000)
     AmmoName=Class'Botpack.WarHeadAmmo'
     ReloadCount=1
     PickupAmmoCount=1
     bWarnTarget=True
     bAltWarnTarget=True
     bSplashDamage=True
     bSpecialIcon=True
     FiringSpeed=1.000000
     FireOffset=(X=10.000000,Z=-8.000000)
     ProjectileClass=Class'sgWarShell'
     AltProjectileClass=Class'sgGuidedWarshell'
     shakemag=350.000000
     shaketime=0.200000
     shakevert=7.500000
     AIRating=1.000000
     RefireRate=0.250000
     AltRefireRate=0.250000
     FireSound=Sound'Botpack.Redeemer.WarheadShot'
     SelectSound=Sound'Botpack.Redeemer.WarheadPickup'
     DeathMessage="%o was vaporized by %k's %w!!"
     NameColor=(G=128,B=128)
     AutoSwitchPriority=10
     InventoryGroup=10
     PickupMessage="You got the NukeLauncher."
     ItemName="NukeLauncher"
     RespawnTime=60.000000
     PlayerViewOffset=(X=1.800000,Y=1.000000,Z=-1.890000)
     PlayerViewMesh=LodMesh'Botpack.WarHead'
     BobDamping=0.975000
     PickupViewMesh=LodMesh'Botpack.WHPick'
     ThirdPersonMesh=LodMesh'Botpack.WHHand'
     StatusIcon=Texture'Botpack.Icons.UseWarH'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UseWarH'
     Mesh=LodMesh'Botpack.WHPick'
     bNoSmooth=False
     SoundRadius=64
     SoundVolume=255
     SoundPitch=16
     CollisionRadius=45.000000
     CollisionHeight=23.000000
}
