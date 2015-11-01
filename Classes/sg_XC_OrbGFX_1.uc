// ORB GFX ACTOR 1, MADE BY HIGOR

class sg_XC_OrbGFX_1 extends Effects;

var vector Swerve, RealOff;
var float SwerveTimer;
var vector BaseLocation;
var sg_XC_OrbGFX_2 Slave;
var sg_XC_Orb MyOrb;
var PlayerPawn LocalPlayer;

event Tick( float DeltaTime)
{
	if ( (MyOrb == none) || MyOrb.bDeleteMe )
	{
		Slave.Destroy();
		Destroy();
		return;
	}
	
	if ( MyOrb.Holder == none )
		SmoothToPoint( MyOrb.Location, DeltaTime);
	else if ( sgBuilding(MyOrb.Holder) != none )
		UpgradeBuildPosition( deltaTime);
	else
		SmoothToPoint( PlayerSmooth(MyOrb.Holder) , DeltaTime);
}

event Spawned()
{
	local PlayerPawn P;
	
	ForEach AllActors (class'PlayerPawn', P)
	{
		if ( ViewPort(P.Player) != none )
		{
			LocalPlayer = P;
			break;
		}
	}
	if ( LocalPlayer == none )
		Destroy();
}

function SetTeamTexture( byte Team)
{
	Switch ( Team )
	{
		case 0:
			MultiSkins[1] = FireTexture'OrbRed';
			break;
		case 1:
			MultiSkins[1] = FireTexture'OrbBlue';
			LightHue = 160;
			break;
		case 2:
			MultiSkins[1] = FireTexture'OrbGreen';
			LightHue = 80;
			break;
		case 3:
			MultiSkins[1] = FireTexture'OrbYellow';
			LightHue = 40;
			break;
		default:
			MultiSkins[1] = FireTexture'OrbWhite';
			LightSaturation = 255;
			break;
	}

}

function SmoothToPoint( vector SmoothDest, float DeltaTime)
{
	local vector smooth;
	local float j;
	
	j=5;
	smooth = Location * (1 - j * DeltaTime) + SmoothDest * j * DeltaTime;
	SetLocation( Smooth);
	Slave.SetLocation( Smooth - CalcViewOff() );
}

function UpgradeBuildPosition (float delta)
{
	local float aF;
	local vector aV;

	SwerveTimer -= Delta;
	if ( SwerveTimer < 0 )
		NewSwerve();

	RealOff = RealOff + Swerve*Delta;	
	aF = VSize(RealOff);
	RealOff = RealOff*(64/aF);
	SetLocation( MyOrb.Holder.Location + RealOff);
	Slave.SetLocation( Location - CalcViewOff() );
}

//Swerve is a 10 sized vector that determines the orbitation around building
//It should take 0.5 second to run a swerve
function NewSwerve()
{
	local vector X, Y;
	local float aF;

	X = RealOff;
	Y = Normal(X + Swerve + VRand() ) * 64;
	While (VSize(X-Y) < 9 )
	{
		Y += Normal(Y-X);
		aF = VSize(Y);
		Y = Y*(64/aF);
	}
	Y += VRand() * 2;
	aF = VSize(Y);
	Y = Y*(64/aF);
	Swerve = Y;
	SwerveTimer = 0.5;
}

function vector PlayerSmooth( actor Other)
{
	local vector aV, eV;

	eV = Other.Location + vect(0,0,10);
	aV = Normal( (eV - Location) * vect(1,1,0) ) * 30;
	return eV - aV;

	aV = Normal( (Other.Location + vect(0,0,10)) - Location) * Other.CollisionRadius * 1.2;
	return Other.Location - aV;
}

function vector CalcViewOff()
{
	local vector CameraLocation;

	if ( LocalPlayer.ViewTarget != None )
	{
		CameraLocation = LocalPlayer.ViewTarget.Location;
		if ( !LocalPlayer.bBehindView && Pawn(LocalPlayer.ViewTarget) != None )
			CameraLocation.Z += LocalPlayer.EyeHeight;
		else if ( LocalPlayer.bBehindView )
			CameraLocation -= (vect(1,0,0) >> LocalPlayer.ViewRotation) * 150;
		return Normal(Location - CameraLocation) * 2;
	}

	CameraLocation = LocalPlayer.Location;

	if( LocalPlayer.bBehindView ) //up and behind
		CameraLocation -= (vect(1,0,0) >> LocalPlayer.ViewRotation) * 120;
	else
	{
		// First-person view.
		CameraLocation.Z += LocalPlayer.EyeHeight;
		CameraLocation += LocalPlayer.WalkBob;
	}
	
	return Normal(Location - CameraLocation) * 1;
}

defaultproperties
{
     RemoteRole=ROLE_None
     DrawType=DT_Mesh
     Mesh=LodMesh'Botpack.ShockRWM'
     DrawScale=0.350000
     AmbientGlow=254
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightBrightness=100
     LightRadius=6
}
