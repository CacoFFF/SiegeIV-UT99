//=============================================================================
// sgMeshFX.
// * Revised by 7DS'Lust
//=============================================================================
class sgMeshFX_DashPadPanel extends sgMeshFX;

var Texture SolidSkins[4];

function PostBeginPlay()
{
	if ( DashPad(Owner) != None && DashPad(Owner).Team < 4 )
	{
		MultiSkins[0] = SolidSkins[DashPad(Owner).Team];
		MultiSkins[1] = MultiSkins[DashPad(Owner).Team + 4];
	}
}

defaultproperties
{
     Physics=PHYS_None
     Style=STY_Normal
     AmbientGlow=255
     bUnlit=True
	 bMeshEnviroMap=False
	 Mesh=Mesh'DashPadPanel'
	 Skin=IceTexture'DashPad_T0'
	 MultiSkins(4)=IceTexture'DashPad_T0'
	 MultiSkins(5)=IceTexture'DashPad_T1'
	 MultiSkins(6)=IceTexture'DashPad_T2'
	 MultiSkins(7)=IceTexture'DashPad_T3'
	 SolidSkins(0)=Texture'Botpack.AmmoCountJunk'
	 SolidSkins(1)=Texture'sgUMedia.BlueSquare'
	 SolidSkins(2)=Texture'Botpack.AmmoCountBar'
	 SolidSkins(3)=Texture'sgMedia.sgSWave'
}
