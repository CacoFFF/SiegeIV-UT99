class SpawnProtEffect expands Effects;

var float AnimAlpha;
var PlayerPawn LocalPlayer;
var sgPlayerData PlayerData;


function AnimationControl( float DeltaTime);

event PostBeginPlay()
{
	local PlayerPawn P;
	local int Team;

	if ( Owner == None )
		return;
	
	ForEach AllActors( class'PlayerPawn', P)
		if ( ViewPort(P.Player) != None )
		{
			LocalPlayer = P;
			break;
		}

	Mesh = Owner.Mesh;

	if ( (Pawn(Owner) != None) && (Pawn(Owner).PlayerReplicationInfo != None) )
		Team = Pawn(Owner).PlayerReplicationInfo.Team + 1;

	switch (Team)
	{
		case 1:		Skin = IceTexture'DashPad_T0';		break;
		case 2:		Skin = IceTexture'DashPad_T1';		break;
		case 4:		Skin = IceTexture'DashPad_T3';		break;
		default:	Skin = IceTexture'DashPad_T2';		break;
	}
	for ( Team=0 ; Team<8 ; Team++ )
		MultiSkins[Team] = Skin;
}

//========== Tick (global) - begin ==========//
//
event Tick( float DeltaTime)
{
	local Rotator R;
	if ( Owner == None || Owner.bDeleteMe || PlayerData == None || PlayerData.bDeleteMe )
	{
		Destroy();
		return;
	}
	SetRotation(Owner.Rotation);
	SetLocation(Owner.Location + AdjustDrawOffset());
	DrawScale = Owner.DrawScale;
	AnimationControl( DeltaTime);
}
//========== Tick (global) - end ==========//



//========== Destroyed (global) - begin ==========//
//
event Destroyed()
{
	if ( PlayerData != None )
	{
		if ( PlayerData.SPEffect == Self )
			PlayerData.SPEffect = None;
		PlayerData = None;
	}
}
//========== Destroyed (global) - end ==========//



//========== AdjustDrawOffset - begin ==========//
//
// Adds a small offset to the effect's location so that
// the renderer doesn't draw it behind the player owner
//
function vector AdjustDrawOffset()
{
	local vector Offset;
	if ( LocalPlayer != None )
	{
		if ( LocalPlayer.ViewTarget == None )
			Offset = Normal( LocalPlayer.Location - Location) * 0.1;
		else if ( LocalPlayer.ViewTarget != Owner )
			Offset = Normal( LocalPlayer.ViewTarget.Location - Location) * 0.1;
		Offset -= Vector(LocalPlayer.ViewRotation) * 0.2;
	}
	return Offset;
}
//========== AdjustDrawOffset - begin ==========//




state Expiring
{
	event BeginState()
	{
		Style = STY_Translucent;
		ScaleGlow = 1;
		AmbientGlow = 254;
	}
	
	function AnimationControl( float DeltaTime)
	{
		ScaleGlow -= DeltaTime * 2.5;
		AmbientGlow = int( 254.f * ScaleGlow);
		if ( ScaleGlow <= 0 )
			Destroy();
	}
}






defaultproperties
{
    bAnimByOwner=True
	bOwnerNoSee=True
	AmbientGlow=254
	DrawType=DT_Mesh
    DrawScale=1.0
    Texture=Texture'sgUMedia.ForceFieldFlash.ForceFieldFlash020'
	Style=STY_Modulated
	Physics=PHYS_None
	RemoteRole=ROLE_None
}
