//=============================================================================
// sgMiniAmmo.
//
// Revision history:
//  * SiegeXXLh: deadbeefhash
//=============================================================================

class sgMiniAmmo extends TournamentAmmo;

defaultproperties
{
     AmmoAmount=50
     MaxAmmo=199
     UsedInWeaponSlot(0)=1
     UsedInWeaponSlot(2)=1
     PickupMessage="You picked up 50 bullets."
     ItemName="Large Bullets"
     PickupViewMesh=LodMesh'Botpack.MiniAmmom'
     Mesh=LodMesh'Botpack.MiniAmmom'
     CollisionRadius=22.000000
     CollisionHeight=11.000000
     bCollideActors=True
}
