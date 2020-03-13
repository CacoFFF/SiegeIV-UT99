//=============================================================================
// XC_NukerDeco
//=============================================================================
class XC_NukerDecoLS extends XC_NukerDeco;

event BeginPlay()
{
	Super(Decoration).BeginPlay();
}

function AntiTweak()
{
	if ( Level.NetMode == NM_Client )
		DestroyLocal("Code injection" );
}

defaultproperties
{
   	 RemoteRole=ROLE_None
   	 bProcessHere=True
}
