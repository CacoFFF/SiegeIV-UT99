//=============================================================================
// sgExpBioBomb.
//=============================================================================
class sgExpBioBomb extends sgItemSpawner;

//First event in creation order
event Spawned()
{
	local sgBuilding sgB, best;
	local byte aTeam;
	local float Dist;

	Super.Spawned();

	if ( (Pawn(Owner) == none) || (Pawn(Owner).PlayerReplicationInfo == none) )
		return;
	aTeam = Pawn(Owner).PlayerReplicationInfo.Team;
	Team = aTeam;

	Dist = 201;
	ForEach RadiusActors (class'sgBuilding', sgB, 200)
	{
		if ( sgB.Team == aTeam )
			continue;

		if ( VSize(sgB.Location - Location) < Dist )
		{
			best = sgB;
			Dist = VSize(sgB.Location - Location);
		}
	}

	if ( (sgEquipmentSupplier(best) != none) && sgEquipmentSupplier(best).bProtected )
		Destroy();
}

defaultproperties
{
     ItemClass=Class'sgBioGel'
     ItemCount=60
     SpawnRate=8
     RateVariance=5
     SpawnChance=0.600000
     speed=350.000000
     SpeedVariance=150.000000
     VerticalVel=1.000000
     Spread=1.000000
     SpawnRadius=55.000000
     BuildingName="Bio Bomb"
     BuildCost=150
     BuildTime=4.000000
     SpriteRedTeam=Texture'ContainerXSkinTeam0'
     SpriteBlueTeam=Texture'ContainerXSkinTeam1'
     SpriteGreenTeam=Texture'ContainerXSkinTeam2'
     SpriteYellowTeam=Texture'ContainerXSkinTeam3'
     BuildDistance=20
}
