//=============================================================================
// Import
// Import directives, remade by Higor
//=============================================================================
class Import extends Object;

var string nullprotected_;
var int bogus1, bogus2, bogus3, bogus4, bogus5;

//Kept for historic reference
//#exec OBJ LOAD FILE="Graphics\JetpackTex.utx" PACKAGE=SiegeIV_0028.Jetpack

#exec OBJ LOAD FILE="Graphics\XC_Orb.utx" PACKAGE=SiegeIV_0028
#exec OBJ LOAD FILE="Graphics\BuildingGraphics.utx" PACKAGE=SiegeIV_0028.BuildingGraphics
#exec TEXTURE IMPORT NAME=Shade FILE=Graphics\Shade.PCX GROUP=ScoreBoard
#exec TEXTURE IMPORT NAME=Shade2 FILE=Graphics\Shade2.PCX GROUP=ScoreBoard
#exec OBJ LOAD FILE="SiegeUtil_A.u" PACKAGE=SiegeIV_0028

// Stuff that helps making Siege smaller
#exec OBJ LOAD File=sgMedia.u
#exec OBJ LOAD File=sgMedia2.u
#exec OBJ LOAD FILE=sgUMedia.u
