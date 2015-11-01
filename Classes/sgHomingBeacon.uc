//=============================================================================
// sgHomingBeacon
//=============================================================================
class sgHomingBeacon extends sgBuilding;



simulated function FinishBuilding()
{
    local int i;
    local sgMeshFX newFX;
    local vector spawnLocation;

    if ( Role == ROLE_Authority )
        Spawn(class'sgFlash');

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    spawnLocation = Location;
    spawnLocation.Z -= 20;
    if ( myFX == None && Model != None )
        for ( i = 0; i < numOfMFX; i++ )
        {
            newFX = Spawn(class'sgMeshFX', Self,,spawnLocation,rotator(vect(0,0,0)));
            newFX.NextFX = myFX;
            myFX = newFX;
            myFX.Mesh = Model;
            myFX.DrawScale = DSofMFX;
            myFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
            myFX.RotationRate.Roll = MFXrotX.Roll*FRand();
            myFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();
        }
	TweenAnim('Open', 0.1);
	Self.AmbientSound=Sound'Botpack.Translocator.targethum';
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BuildingName="Homing Beacon"
     BuildCost=100
     UpgradeCost=25
     BuildTime=5.000000
     MaxEnergy=5000.000000
     SpriteScale=0.300000
     Model=LodMesh'Botpack.Module'
     SkinRedTeam=Texture'ProtectorSkinTeam0'
     SkinBlueTeam=Texture'ProtectorSkinTeam1'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SkinGreenTeam=Texture'ProtectorSkinTeam2'
     SkinYellowTeam=Texture'ProtectorSkinTeam3'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
     MFXrotX=(Yaw=20000)
     AmbientGlow=30
     MultiSkins(0)=Texture'ProtectorSpriteTeam0'
     MultiSkins(1)=Texture'ProtectorSpriteTeam1'
     MultiSkins(2)=Texture'ProtectorSpriteTeam2'
     MultiSkins(3)=Texture'ProtectorSpriteTeam3'
     CollisionHeight=32.000000
}
