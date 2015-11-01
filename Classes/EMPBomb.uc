//=============================================================================
// EMPBomb
// by SK
//=============================================================================
class EMPBomb extends sgBuilding;

function PostBuild()
{
	local Pawn p;
	Super.PostBuild();
	for ( p = Level.PawnList; p != None; p = p.nextPawn )
		if ( p.IsA('TournamentPlayer' ) && p.PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team)
			TournamentPlayer(P).ReceiveLocalizedMessage(Class'EMPMsg');
}

simulated function FinishBuilding()
{
	Super.FinishBuilding();	
	Explode();
}

function DisableEnemyBuildings()
{
	local sgBuilding building;
	local sgPRI PRIowner;

	if (Pawn(Owner) != none)
		PRIowner = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	foreach RadiusActors(class'sgBuilding', building, 2560)
		if (building.Team != Team)
		{
			building.Electrify();
			if ( PRIowner != none )
				PRIowner.Score += 0.5;
		}
}

function Explode()
{
	if ( Role < ROLE_Authority )
		return;
			
	DisableEnemyBuildings();
	 	
	PlaySound(Sound'emp2', SLOT_None, 20,,11000,1+(FRand()*0.3-0.15));
	PlaySound(Sound'emp1', SLOT_None, 20,,10000, 1.2 + FRand() * 0.1);
	spawn(class'EMPRings');
	spawn(class'EMPBall');
 	spawn(class'EMPFlash');
	spawn(class'LongFlash');
	RemoteRole = ROLE_SimulatedProxy;		
 	Destroy();
}

defaultproperties
{
     bOnlyOwnerRemove=True
     DestructionAnnounce=ANN_Global
     BuildingName="EMP Bomb"
     BuildCost=1500
     MaxEnergy=500.000000
	 BuildTime=10
     Model=LodMesh'Botpack.Module'
     SkinRedTeam=Texture'ContainerSkinTeam0'
     SkinBlueTeam=Texture'ContainerSkinTeam1'
     SpriteRedTeam=Texture'ContainerSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerSpriteTeam1'
     SkinGreenTeam=Texture'ContainerSkinTeam2'
     SkinYellowTeam=Texture'ContainerSkinTeam3'
     SpriteGreenTeam=Texture'ContainerSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerSpriteTeam3'
	 SpriteScale=0.800000
     DSofMFX=2.812500
     MFXrotX=(Pitch=2500,Yaw=2500,Roll=2500)
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     CollisionRadius=16.000000
     CollisionHeight=16.000000
}