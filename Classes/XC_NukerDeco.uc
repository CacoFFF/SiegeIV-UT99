//=============================================================================
// XC_NukerDeco
// THIS IS BROKEN RIGHT NOW!!
//=============================================================================
class XC_NukerDeco extends Decoration;

var bool bProcessHere;
var sgNukeLauncher CachedNuke;
var XC_NukerDecoLS LSVersion;
var bool bLocalOwned;
var private float LastKill;
var int EyeHeight;

replication
{
	reliable if ( Role==ROLE_Authority )
		EyeHeight;
}

simulated event PostBeginPlay()
{
	AmbientGlow = 0;
	if ( Level.NetMode == NM_Client || Level.NetMode == NM_Standalone )
		bProcessHere = True;
	else
	{ //Spawn offline copy for server effects, this is a network optimization
		LSVersion = Spawn(class'XC_NukerDecoLS', Owner);
		SetLocation( vect(0,20000,20000) );
	}
}

function SetNuke( sgNukeLauncher aNuke)
{
	CachedNuke = aNuke;
	if ( LSVersion != none )
		LSVersion.CachedNuke = aNuke;
}

simulated function Tick(float DeltaTime)
{
	local vector X,Y,Z;
	local rotator aRot;
	local pawn P;

	if ( Role == ROLE_Authority )
	{
		if ( CachedNuke.Owner != Owner )
			SetOwner( CachedNuke.Owner);
		if ( Pawn(Owner) != none)
			EyeHeight = Pawn(Owner).BaseEyeHeight;
	}

	if ( bProcessHere )
	{
		P = Pawn(Owner);
		if ( P != none )
		{
			if ( !bLocalOwned && (PlayerPawn(P) != none) && (ViewPort(PlayerPawn(P).Player) != none) ) //Local owner
				bLocalOwned = True;

			bOwnerNoSee = bLocalOwned && !P.bBehindView && (PlayerPawn(P).ViewTarget == none);
			bHidden = (sgNukeLauncher(P.Weapon) != none) || (P.PlayerReplicationInfo == none) || P.PlayerReplicationInfo.bFeigningDeath;

			if ( !bHidden )
			{
				GetAxes( Owner.Rotation, X, Y, Z);
				SetLocation( Owner.Location + X * -15 + Z * (EyeHeight * 0.7 - 6) - Y * 1.2);
				aRot = Owner.Rotation;
				aRot.Pitch -= 17000;
				aRot.Yaw += 1000;
				aRot.Roll = 32768;
				SetRotation(aRot);
				Texture = Owner.Texture;
				Style = Owner.Style;
				bMeshEnviroMap = Owner.bMeshEnviroMap;
				AntiTweak();
			}
			if ( P.Health <= 0 ) //Client controlled destruction, in case of extreme packet loss
				Destroy();
		}
	}
}

simulated function AntiTweak()
{
	if ( Level.TimeSeconds - LastKill < 1 )
		return;
	if ( Default.DrawType != DT_Mesh )
	{
		DestroyLocal("Altered deco DrawType: "$Default.DrawType );
		return;
	}
	if ( Default.AmbientGlow > 0 )
	{
		DestroyLocal("Altered deco glow: "$Default.AmbientGlow );
		return;
	}
	if ( Default.DrawScale > 0.7 )
	{
		DestroyLocal("Altered deco scale: "$Default.DrawScale );
		return;
	}
	if ( LightType != LT_None )
	{
		DestroyLocal("Nuker glow hack" );
		return;
	}
}

simulated function DestroyLocal( coerce string Reason)
{
	local PlayerPawn P;
	ForEach AllActors (class'PlayerPawn', P)
	{
		if ( ViewPort(P.Player) != none )
		{
			if ( P.Health <= 0 )
				return;
			P.Say("ANTITWEAK SUICIDE > "$Reason);
			Log("TWEAK DETECTED, DESTROYING PLAYER:"@Reason);
			P.Suicide();
			LastKill = Level.TimeSeconds;
			return;
		}
	}
}

simulated event Destroyed()
{
	if ( LSVersion != none )
		LSVersion.Destroy();
	if ( CachedNuke != none )
		CachedNuke.NukeDeco = none;
	CachedNuke = none;
}

defaultproperties
{
   	 RemoteRole=ROLE_SimulatedProxy
   	 bAlwaysRelevant=True
   	 AmbientGlow=0
     bStatic=False
//     bOwnerNoSee=True
     Physics=PHYS_None
     DrawType=DT_Mesh
     Mesh=Mesh'WHPick'
     LightType=LT_None
     DrawScale=0.55
}
