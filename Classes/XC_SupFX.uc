//=============================================================================
// XC_SupFX.
// Supplier weapon FX effect
//=============================================================================
class XC_SupFX extends Effects;

var XC_SupplierBase RelatedSup;

var float MaxDraw;
var float DrawAlpha;
var vector LocOffset;

function PostBeginPlay()
{
}

//Attach or destroy, fixes attachables made by XC_Siege
function Tick(float deltaTime)
{
	if ( (RelatedSup == none) || RelatedSup.bDeleteMe )
		Destroy();
	else
	{
		SetLocation( RelatedSup.Location + LocOffset);
	}
}

function Destroyed()
{
}

//Setup the wave here?
static function XC_SupFX Setup( XC_SupplierBase Master, vector SpawnAt)
{
	local XC_SupFX sample;
	
	sample = Master.Spawn( default.class, Master,'SupEffect', SpawnAt);
	sample.RelatedSup = Master;
	sample.LocOffset = sample.Location - Master.Location;
//Process scaleview later
	sample.ImitateWeapon( Master.WeapList[Master.DispWeapons], 1);
	return sample;
}

function ImitateWeapon(class<Weapon> aWeap, float ScaleView)
{
	local rotator aRot;
	if ( ScaleView <= 0 )
		ScaleView = 1;
	MaxDraw = aWeap.default.PickupViewScale * ScaleView * 0.82;
	Mesh = aWeap.default.PickupViewMesh;
	aRot.Pitch = -16384;
	SetRotation(aRot);
	Skin = aWeap.Default.Skin;
	MultiSkins[0] = aWeap.Default.MultiSkins[0];
	MultiSkins[1] = aWeap.Default.MultiSkins[1];
	MultiSkins[2] = aWeap.Default.MultiSkins[2];
	MultiSkins[3] = aWeap.Default.MultiSkins[3];
	bMeshEnviroMap = aWeap.default.bMeshEnviroMap;
}


auto state Displaying
{
	event BeginState()
	{
		Style=STY_Normal;
		AmbientGlow = 255;
		RotationRate.Yaw = 3000;
	}
	event Tick( float DeltaTime)
	{
		if ( DrawAlpha < 1 )
		{
			DrawAlpha = fMin(DrawAlpha + DeltaTime * 0.3, 1);
			DrawScale = MaxDraw * DrawAlpha;
		}
		Global.Tick( DeltaTime);
		if ( !bDeleteMe )
		{
			if ( (RelatedSup.localComp != none) && !RelatedSup.localComp.bDeleteMe )
				GotoState('Hidden');
		}
	}
}

state Hidden
{
	event BeginState()
	{
		DrawScale = MaxDraw * 0.5;
		Style = STY_Modulated;
		AmbientGlow = 254;
		RotationRate.Yaw = 1000;
	}

	event Tick( float DeltaTime)
	{
		Global.Tick( DeltaTime);
		if ( !bDeleteMe )
		{
			if ( (RelatedSup.localComp == none) || RelatedSup.localComp.bDeleteMe )
			{
				DrawAlpha = 0.5;
				GotoState('Displaying');
			}
		}
	}
}

defaultproperties
{
     Physics=PHYS_Rotating
     bFixedRotationDir=True
     RemoteRole=ROLE_None
     LODBias=1.000000
     DrawType=DT_Mesh
     Style=STY_Normal
     AmbientGlow=255
     bUnlit=False
     bMeshEnviroMap=False
     bCollideWhenPlacing=False
}
