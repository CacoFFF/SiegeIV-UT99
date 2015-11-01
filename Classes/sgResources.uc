//=============================================================================
// sgResources.
// * Revised by 7DS'Lust
//=============================================================================
class sgResources extends TournamentPickup;

var int RU;

function PickupFunction(Pawn other)
{
    if ( Pawn(Owner) != None &&
      sgPRI(Pawn(Owner).PlayerReplicationInfo) != None )
	    sgPRI(Pawn(Owner).PlayerReplicationInfo).AddRU(RU);
	Super.PickupFunction(other);
	Destroy();
}

defaultproperties
{
     RU=15
     PickupMessage="You picked up some Resources."
     ItemName="RUs"
     PickupSound=Sound'sgMedia.SFX.sgPickRUs'
     DrawType=DT_Sprite
     Style=STY_Translucent
     Texture=Texture'sgMedia.GFX.sgParticle'
     ScaleGlow=2.000000
     bUnlit=True
}
