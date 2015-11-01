//=============================================================================
// XC_NukerDeco
//=============================================================================
class XC_NukerDecoLS extends XC_NukerDeco;

event PostBeginPlay()
{
	Super(Decoration).PostBeginPlay();
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
