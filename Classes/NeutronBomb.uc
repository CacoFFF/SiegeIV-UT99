//=============================================================================
// NeutronBomb
// by SK
//=============================================================================
class NeutronBomb extends sgItemSpawner;

function PostBuild()
{
	local pawn p;
	Super.PostBuild();
	for ( p = Level.PawnList; p != None; p = p.nextPawn )
		if ( p.IsA('TournamentPlayer' ) && p.PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team)
			TournamentPlayer(P).ReceiveLocalizedMessage(Class'NeutronBombMsg');	
}

defaultproperties
{
     ItemClass=Class'NeutronExplosion'
     ItemCount=1
     SpawnRate=100
     RateVariance=0
     SpawnChance=1.000000
     speed=0.000000
     SpeedVariance=0.000000
     VerticalVel=-2048.000000
     Spread=1.000000
     SpawnRadius=4.000000
     DestructionAnnounce=ANN_Global
     BuildingName="Neutron Bomb"
     BuildCost=4000
     BuildTime=10.000000
     MaxEnergy=800.000000
     SpriteScale=2.000000
     Model=LodMesh'Botpack.Module'
     SkinRedTeam=None
     SkinBlueTeam=None
     DSofMFX=3.800000
     NumOfMFX=3
     MFXrotX=(Pitch=20000,Yaw=20000,Roll=20000)
     AmbientGlow=40
     MultiSkins(0)=Texture'Botpack.UTFlare3'
     MultiSkins(1)=Texture'Botpack.UTFlare3'
     MultiSkins(2)=Texture'Botpack.UTFlare3'
     MultiSkins(3)=Texture'Botpack.UTFlare3'
     CollisionHeight=32.000000
     SpriteRedTeam=Texture'Botpack.UTFlare3'
     SpriteBlueTeam=Texture'Botpack.UTFlare3'
     SpriteGreenTeam=Texture'Botpack.UTFlare3'
     SpriteYellowTeam=Texture'Botpack.UTFlare3'
}