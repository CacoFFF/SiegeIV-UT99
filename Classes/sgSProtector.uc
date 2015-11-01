//=============================================================================
// sgSProtector.
// * Revised by 7DS'Lust
// Revised for Monster Madness by nOs*Wildcard
//=============================================================================
class sgSProtector extends sgProtector;

function bool ShouldFire()
{
    return ( FRand() < 0.05 + Grade/10 );
}

//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aStorage, aCost;

	if ( Super.AI_Rate(CrtTeam, sgC, cSlot) < 0 ) //Forbidden
		return -1;

	aCost = sgC.BuildCost(cSlot);
	if ( (CrtTeam.AIList.TeamRU() * 1.0) < aCost ) //Too damn expensive
		return -1;
	return 0.9 + aCost / 200;
}

defaultproperties
{
     ProjectileType=Class'sgSProtProj'
     BuildingName="Super Protector"
     BuildCost=500
     MaxEnergy=5000.000000
     SpriteScale=0.800000
     Model=LodMesh'Botpack.OctGem'
     SkinRedTeam=Texture'SuperProtectorSkinT0'
     SkinBlueTeam=Texture'SuperProtectorSkinT1'
     SpriteRedTeam=Texture'SuperProtectorSpriteT0'
     SpriteBlueTeam=Texture'SuperProtectorSpriteT1'
     SkinGreenTeam=Texture'SuperProtectorSkinT2'
     SkinYellowTeam=Texture'SuperProtectorSkinT3'
     SpriteGreenTeam=Texture'SuperProtectorSpriteT2'
     SpriteYellowTeam=Texture'SuperProtectorSpriteT3'
     DSofMFX=3.000000
     GUI_Icon=Texture'GUI_SProtector'
}
