//=============================================================================
// WRU50.
//=============================================================================
class WRU50 expands WildcardsResources;

var KoalasGemSprite aSprite;

simulated event BeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		aSprite = Spawn(Class'KoalasGemSprite');
		aSprite.SetBase(self);
	}
	if ( Level.NetMode == NM_ListenServer )
		aSprite.RemoteRole = ROLE_None; //Don't replicate
	Super.BeginPlay(); //Only called on servers
}

simulated event Destroyed()
{
	if ( aSprite != none )
	{
		aSprite.Destroy();
		aSprite = none;
	}
	Super.Destroyed(); //Only called on servers
}

defaultproperties
{
     RU=50
     PickupMessage="You picked up 50 resource units."
     Texture=WetTexture'SKgreenRU'
	 PickupViewScale=1.5
	 LightHue=120
	 LightSaturation=224
     LightRadius=4
	 GlowHue=120
}
