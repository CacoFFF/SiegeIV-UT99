//=============================================================================
// sgTrail.
// * Revised by 7DS'Lust
//=============================================================================
class sgTrail extends Effects;

function Tick(float deltaTime)
{
	if ( (Pawn(Owner) == None) || (Pawn(Owner).Health <= 0) || (sgNukeLauncher(Pawn(Owner).Weapon) == none) )
        Destroy();
}

defaultproperties
{
     bOwnerNoSee=True
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgFlash'
     DrawScale=1.500000
     AmbientGlow=64
     SpriteProjForward=64.000000
}
