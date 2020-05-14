//=============================================================================
// sgMeshFX_MiniShieldHQ.
// * High quality version of MiniShield
//=============================================================================
class sgMeshFX_MiniShieldHQ extends sgMeshFX;

#exec MESH IMPORT MESH=sgSphereMesh ANIVFILE=MODELS\sgSphereMesh_a.3d DATAFILE=MODELS\sgSphereMesh_d.3d X=0 Y=0 Z=0 MLOD=0
#exec MESH ORIGIN MESH=sgSphereMesh X=0 Y=0 Z=0

#exec MESH SEQUENCE MESH=sgSphereMesh SEQ=All STARTFRAME=0 NUMFRAMES=1

#exec MESHMAP NEW MESHMAP=sgSphereMesh MESH=sgSphereMesh
#exec MESHMAP SCALE MESHMAP=sgSphereMesh X=0.05 Y=0.05 Z=0.1

function PostBeginPlay()
{
	if ( sgBuilding(Owner) != None )
    {
		switch ( sgBuilding(Owner).Team )
        {
        case 1:
            Texture = texture'sgUMedia.ForceFieldT1';
            break;

        case 2:
            Texture = texture'sgUMedia.ForceFieldT2';
            break;

        case 3:
            Texture = texture'sgUMedia.ForceFieldT3';
            break;

        default:
		    Texture = texture'sgUMedia.ForceFieldT0';
        }
	}
	SetTimer( 0.01, false); //Wait one frame
}

event Timer()
{
	bHidden = Class'sgClient'.default.bHighPerformance;
	if ( Owner != none )
		DrawScale = Owner.CollisionRadius / 50;
	if ( NextFX != none )
		NextFX.bHidden = !bHidden;
	SetTimer( 0.01 + FRand() * 2 * Level.TimeDilation, false);
}

defaultproperties
{
     LODBias=5.00000
     Style=STY_Modulated
     bUnlit=True
     bMeshEnviroMap=False
     Mesh=Mesh'sgSphereMesh'
	 MultiSkins(2)=IceTexture'SBG_IceEff_01'
}
