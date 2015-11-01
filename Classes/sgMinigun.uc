//==================================================================================
// sgMinigun
// HISTORY?: Well, I'm sure it's here just to use a different ammo class
// than the enforcer.
//
// WHAT NOW: I'm here to edit this to prevent multigunning.
// This will be optional to server admins however if they want to enable it or not.
//==================================================================================
class sgMinigun extends minigun2;


state NormalFire
{
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
		{
			AmbientSound = None;
			return;
		}

		if ( Pawn(owner).PlayerReplicationInfo.bFeigningDeath == true && SiegeGI(Level.Game).AllowMultiGunning == false )
			{
				log("MultiGunning is Forbidden!");
				GotoState('FinishFire');
			}

	}
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
		{
			AmbientSound = None;
			GotoState('Pickup');
			return;
		}			

		if	( bFiredShot && ((pawn(Owner).bAltFire==0) || bOutOfAmmo) ) 
			GoToState('FinishFire');

		if ( Pawn(owner).PlayerReplicationInfo.bFeigningDeath == true && SiegeGI(Level.Game).AllowMultiGunning == false )
		{
			log("MultiGunning is Forbidden!");
			GotoState('FinishFire');
		}
	}
}


defaultproperties
{
     AmmoName=Class'sgMiniammo'
}
