//
// Self-protected class
class sgMeshFX_MineModu expands sgMeshFX;

function PostBeginPlay()
{
}

function Tick(float deltaTime)
{
	Texture = Texture'BuildShader';
	Skin = Texture'BuildShader';
	Style = STY_Modulated;
	bUnlit = True;
	ScaleGlow = 1;
	if ( sgBuilding(Owner) == None )
        Destroy();
}


defaultproperties
{
     Texture=Texture'BuildShader'
     Skin=Texture'BuildShader'
     Style=STY_Modulated
	 ScaleGlow=1
	 bUnlit=True
}