//=============================================================================
// MegaHealth.
//=============================================================================
class MegaHealth expands WildcardsHealth;

defaultproperties
{
     HealingAmount=400
     bSuperHeal=True
     ItemName="Mega Health (400 HP)"
     PickupMessage="You found the Mega Health! +"
     RespawnTime=0.000000
     PickupViewMesh=LodMesh'Botpack.hbox'
     PickupSound=Sound'PickUpMegaHealth'
     Mesh=LodMesh'Botpack.hbox'
     MultiSkins(1)=Texture'MegaHealthSkin'
     MultiSkins(2)=FireTexture'HealthEnergyTexture'
}
