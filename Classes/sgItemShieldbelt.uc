//=============================================================================
// sgItemShieldbelt.
//=============================================================================
class sgItemShieldbelt extends sgItem;

var int BaseCharge;

function Upgraded()
{
	local float RUScale;
	local int j;

	Super.Upgraded();
	if ( MyProduct == none )
	{
		MyProduct = Inventory;
		if ( MyProduct == none )
			return;
	}
	if ( BaseCharge == 0 )
		BaseCharge = MyProduct.Charge;
	RUScale = BuildCost;
	For ( j=0 ; j<int(Grade) ; j++ ) //Add levels
		RUScale += UpgradeCost * (j+1);
	if ( float(j) < Grade ) //Add fraction
		RUScale += UpgradeCost * (j+1) * (Grade - int(Grade));
	MyProduct.Charge = (BaseCharge * RUScale) / (BuildCost + UpgradeCost * 15);
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();
	Upgraded();
}

defaultproperties
{
     bNoUpgrade=False
     UpgradeCost=10
     InventoryClass=Class'sg_XC_ShieldBelt'
     BuildingName="Shieldbelt"
     BuildCost=250
     bTakeProductVisual=True
     Model=LodMesh'Botpack.ShieldBeltMeshM'
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SpriteRedTeam=Texture'PlatformSpriteT0'
     SpriteBlueTeam=Texture'PlatformSpriteT1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     SpriteGreenTeam=Texture'PlatformSpriteT2'
     SpriteYellowTeam=Texture'PlatformSpriteT3'
     SpriteScale=0.250000
     SpriteProjForward=-1
     CollisionRadius=24.000000
     CollisionHeight=14.000000

}
