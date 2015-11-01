//=============================================================================
// Introducing... Wildcards Metal Suit
// Counters: 1337 Snipers
// 
// Because I really hate 1337 snipers who hide in your base and or camp somewhere and not even 
// let you leave your own base or kill you at your supplier and keep doing there annoying 
// magical head shot antics! everybodys such a fucking good sniper i doubt they even try!!!
// yet they can nail a headshot and you will not even see them do it. Usually most players
// in unreal get labled a n00b because there not a 1337 Sniper who never misses or
// a Combo Whore with the asmd bitch rifle. 
// 
// Well time to change weapons! if you try to headshot anyone whearing this awesome Metal Suit 
// it won't do any dameage at all! :) yea you heard me! nothing. also makes you to invulnerable 
// to the minigun and enforcer. This suit is not cheap. it means the person whereing it is tired 
// of you and your 1337 headshots! any other weapon can blow this off like normal armor.
// 
// And this can be combined with the rubber suit for aditional protection!
// Any problems or questions? email: wildcardisnotanoob@email.com
//
// Higor: restructured as subclass of sgSuit
//=============================================================================

class WildcardsMetalSuit expands sgSuit;

function int ArmorAbsorbDamage(int Damage, name DamageType, vector HitLocation)
{
	local int ArmorDamage;

	if ( DamageType != 'Drowned' )
		ArmorImpactEffect(HitLocation);

	if( (DamageType!='None') && ((ProtectionType1==DamageType) || (ProtectionType2==DamageType)) )
	{
		Spawn(class'MetalSuitDeflectFx',,,HitLocation);
		Owner.PlaySound(Sound'MetalSuitDeflect', SLOT_None,
		Pawn(Owner).SoundDampening*1.2,,, 1 + (FRand()*0.2 - 0.4));
		return 0;
	}
	
	if (DamageType=='Drowned') Return Damage;
	
	ArmorDamage = (Damage * ArmorAbsorption) / 100;
	if( ArmorDamage >= Charge )
	{
		ArmorDamage = Charge;
		Destroy();
	}
	else 
		Charge -= ArmorDamage;
	return (Damage - ArmorDamage);
}

defaultproperties
{
    PickupMessage="You have found the Metal Suit"
    ItemName="Metal Suit"
    RespawnTime=120.00
    PickupViewMesh=LodMesh'UnrealI.AsbSuit'
    ProtectionType1=shot
    ProtectionType2=Decapitated
    Charge=100
    ArmorAbsorption=80
    bIsAnArmor=True
    AbsorptionPriority=7
    MaxDesireability=2.25
    PickupSound=Sound'UnrealShare.Pickups.ArmorSnd'
    RespawnSound=Sound'PickUpRespawn'
    EnviroSkin=Texture'MetalSuitSkin'
    Texture=Texture'MetalSuitSkin'
    Mesh=LodMesh'UnrealI.AsbSuit'
    bUnlit=True
    bMeshEnviroMap=True
    HUD_Icon=Texture'HUD_sgMetal'
}
