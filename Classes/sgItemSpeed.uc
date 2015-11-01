//=============================================================================
// sgItemSpeed
// nOs*Badger
//=============================================================================

class sgItemSpeed extends sgItem;

function bool GiveItems(Pawn Other)
{
	local Inventory OtherSuits;

	if ( Super.GiveItems( Other) )
	{
		OtherSuits = Other.FindInventoryType(class'sgShrinkerTimer');
		if ( OtherSuits != none )
			OtherSuits.destroy();
		return true;
	}
}


simulated function FinishBuilding()
{
	SpriteScale=0.2;
 	Super.FinishBuilding();
}

defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     InventoryClass=Class'sgSpeed'
     BuildingName="Speed"
     BuildCost=650
     MaxEnergy=1000.000000
     SpriteScale=0.300000
     Model=LodMesh'Botpack.ArrowStud'
     SkinRedTeam=Texture'SuperProtectorSkinT0'
     SkinBlueTeam=Texture'SuperProtectorSkinT1'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SkinGreenTeam=Texture'SuperProtectorSkinT2'
     SkinYellowTeam=Texture'SuperProtectorSkinT3'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
     GUI_Icon=Texture'GUI_ItemSpeed'
     MFXrotX=(Yaw=90000)
}
