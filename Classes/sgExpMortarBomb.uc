//=============================================================================
// sgExpMortarBomb.
// HIGOR: No more building in invincible suppliers
//=============================================================================
class sgExpMortarBomb extends sgItemSpawner;


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
     ItemClass=Class'Botpack.flakslug'
     ItemCount=40
     SpawnRate=2
     RateVariance=1
     SpawnChance=0.200000
     speed=650.000000
     SpeedVariance=250.000000
     VerticalVel=1.000000
     Spread=0.500000
     SpawnRadius=30.000000
     BuildingName="Mortar Bomb"
     BuildCost=500
     BuildTime=5.000000
     MaxEnergy=1000.000000
     SpriteRedTeam=Texture'CoreSpriteTeam0'
     SpriteBlueTeam=Texture'CoreSpriteTeam1'
     SpriteGreenTeam=Texture'CoreSpriteTeam2'
     SpriteYellowTeam=Texture'CoreSpriteTeam3'
     BuildDistance=20
}
