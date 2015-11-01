//=============================================================================
// sgMeshFX.
// * Revised by 7DS'Lust
//=============================================================================
class sgMeshFX extends Effects;

var sgMeshFX NextFX;


function PostBeginPlay()
{
	if ( sgBuilding(Owner) != None )
        switch ( sgBuilding(Owner).Team )
        {
        case 1:
            Texture = texture'sgMedia.sgEnvSkinT1';
            break;

        case 2:
            Texture = texture'sgMedia2.sgEnvSkinT2';
            break;

        case 3:
            Texture = texture'sgMedia2.sgEnvSkinT3';
            break;

        default:
		    Texture = texture'sgMedia.sgEnvSkinT0';
        }
}

function Tick(float deltaTime)
{
	if ( Owner == None )
        Destroy();
}

function Destroyed()
{
    Super.Destroyed();
    if ( NextFX != None )
    {
        NextFX.Destroy();
        NextFX = None;
    }
}

function SetSize(float size)
{
    DrawScale = size;
    if ( NextFX != None )
        NextFX.SetSize(size);
}

defaultproperties
{
     Physics=PHYS_Rotating
     RemoteRole=ROLE_None
     LODBias=0.500000
     DrawType=DT_Mesh
     Style=STY_Translucent
     AmbientGlow=255
     bUnlit=True
     bMeshEnviroMap=True
     bFixedRotationDir=True
}
