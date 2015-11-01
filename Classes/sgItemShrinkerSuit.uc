//=============================================================================
// sgItemShrinkerSuit
// by SK
//=============================================================================
class sgItemShrinkerSuit extends sgItem;

function bool GiveItems(Pawn Other)
{
	local Inventory OtherSuits;

	if ( Super.GiveItems( Other) )
	{
		OtherSuits = Other.FindInventoryType(class'sgSpeed');
		if ( OtherSuits != none )
		{
			OtherSuits.destroy();
			Other.GroundSpeed = Other.default.GroundSpeed;
		}
		return true;
	}
}


defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     InventoryClass=Class'sgShrinkerTimer'
     BuildingName="Shrinker Suit"
     BuildCost=800
	 UpgradeCost=0
     MaxEnergy=1000.000000
     Model=LodMesh'UnrealShare.Suit'
	 DSofMFX=0.4
	 SpriteScale=0.125
     SkinRedTeam=Texture'SuperProtectorSkinT0'
     SkinBlueTeam=Texture'SuperProtectorSkinT1'
     SpriteRedTeam=Texture'MotionAlarmSpriteT0'
     SpriteBlueTeam=Texture'MotionAlarmSpriteT1'
     SkinGreenTeam=Texture'SuperProtectorSkinT2'
     SkinYellowTeam=Texture'SuperProtectorSkinT3'
     SpriteGreenTeam=Texture'MotionAlarmSpriteT2'
     SpriteYellowTeam=Texture'MotionAlarmSpriteT3'
	 CollisionHeight=16
	 CollisionRadius=4
}