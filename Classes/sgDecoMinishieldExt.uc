////////////////////////////////////////////
// Done by Higor
// First actor in the next generation models
////////////////////////////////////////////
class sgDecoMinishieldExt expands SiegeActor;

#exec MESH IMPORT MESH=sgSphereMesh ANIVFILE=MODELS\sgSphereMesh_a.3d DATAFILE=MODELS\sgSphereMesh_d.3d X=0 Y=0 Z=0
#exec MESH ORIGIN MESH=sgSphereMesh X=0 Y=0 Z=0

#exec MESH SEQUENCE MESH=sgSphereMesh SEQ=All STARTFRAME=0 NUMFRAMES=1

#exec MESHMAP NEW MESHMAP=sgSphereMesh MESH=sgSphereMesh
#exec MESHMAP SCALE MESHMAP=sgSphereMesh X=0.05 Y=0.05 Z=0.1
/*
#exec TEXTURE IMPORT NAME=Jtex1 FILE=texture1.pcx GROUP=Skins FLAGS=2
#exec TEXTURE IMPORT NAME=Jtex1 FILE=texture1.pcx GROUP=Skins PALETTE=Jtex1
#exec MESHMAP SETTEXTURE MESHMAP=sgSphereMesh NUM=1 TEXTURE=Jtex1

#exec TEXTURE IMPORT NAME=Jtex2 FILE=texture2.pcx GROUP=Skins FLAGS=2
#exec TEXTURE IMPORT NAME=Jtex2 FILE=texture2.pcx GROUP=Skins PALETTE=Jtex2
#exec MESHMAP SETTEXTURE MESHMAP=sgSphereMesh NUM=2 TEXTURE=Jtex2
*/
defaultproperties
{
    DrawType=DT_Mesh
    Mesh=LodMesh'sgSphereMesh'
    bHidden=False
    RemoteRole=ROLE_None
    Style=STY_Modulated
    LodBias=3
}
