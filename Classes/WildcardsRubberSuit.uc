//=============================================================================
// Introducing... Wildcards Rubber Suit
// Counters: Combo Whores
//
// Because I really hate people who abuse the asmd shock rifle combo!
// It annoys the piss out of me when you cant even leave your base without being combo whored.
// People who only use the combo whore as offense really annoy the piss out of me!
//
// Well time to change weapons! if you try to combo whore anyone whearing this handy Rubber Suit
// it won't do any damage at all! XD The most you will do is move them. This suit also makes you
// invulnerable to bio also so you don't acidentally kill your own dumbass when attacking the
// enemy base.
//
// Also this can be combined with the metal suit for ultimate protection!
// Any problems or questions? email: wildcardisnotanoob@email.com
//
// Higor: restructured as subclass of sgSuit
//=============================================================================
class WildcardsRubberSuit expands sgSuit;

defaultproperties
{
    PickupMessage="You found the Rubber Suit"
    ItemName="Rubber Suit"
    RespawnTime=80.00
    PickupViewMesh=LodMesh'UnrealI.AsbSuit'
    ProtectionType1=jolted
    ProtectionType2=Corroded
    Charge=75
    ArmorAbsorption=65
    bIsAnArmor=True
    AbsorptionPriority=5
    MaxDesireability=1.15
    PickupSound=Sound'UnrealShare.Pickups.suitsnd'
    RespawnSound=Sound'PickUpRespawn'
    EnviroSkin=Texture'RubberSuitSkin'
    Texture=Texture'RubberSuitSkin'
    Mesh=LodMesh'UnrealI.AsbSuit'
    bUnlit=True
    bMeshEnviroMap=True
    bNoProtectors=True
    HUD_Icon=Texture'HUD_sgRubber'
}
