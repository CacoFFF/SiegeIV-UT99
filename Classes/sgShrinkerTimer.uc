//**************************
// Entirely recoded by Higor
//**************************

class sgShrinkerTimer expands sgSuit;


function ChangedWeapon()
{
	if( Inventory != None )
		Inventory.ChangedWeapon();
		
	if ( AffectedWeapon != none )
	{
		AffectedWeapon.ThirdPersonScale = AffectedWeapon.Default.ThirdPersonScale;
		AffectedWeapon = Pawn(Owner).Weapon;
		if ( AffectedWeapon != none )
			AffectedWeapon.ThirdPersonScale = AffectedWeapon.Default.ThirdPersonScale * 0.5;
	}
}


function ApplySkin()
{
	local Pawn P;

	P = GetOwner();
	if ( P == none )
		return;
	P.Mass = 0.5 * P.default.Mass;
	P.DrawScale = 0.5 * P.default.DrawScale;
	P.SetCollisionSize(0.5 * P.default.CollisionRadius, 0.47 * P.default.CollisionHeight);

	AffectedWeapon = P.Weapon;
	if ( AffectedWeapon != none )
		AffectedWeapon.ThirdPersonScale = P.DrawScale;
}


function RemoveSkin()
{
	local pawn P;

	P = GetOwner();
	if ( P == none )
		return;
	P.Mass = P.Default.Mass;
	P.DrawScale = P.Default.DrawScale;
	P.SetCollisionSize( P.Default.CollisionRadius, P.Default.CollisionHeight);

	Instigator = none; //Make sure we don't repeat this call
	P.SetDefaultDisplayProperties();
}

defaultproperties
{
    PickupMessage="You found a Shrinker Suit"
}