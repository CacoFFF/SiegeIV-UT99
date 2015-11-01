//=============================================================================
// sgSupplier.
// nOs*Badger
//=============================================================================
class sgShield extends sgBuilding;

simulated event Timer()
{
	Super.Timer();
}

simulated event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType )
{
	
	Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BuildingName="Shield"
     BuildCost=300
     BuildTime=45.000000
     MaxEnergy=1500.000000
     SpriteScale=0.900000
     Model=LodMesh'Botpack.ShockWavem'
     SkinRedTeam=None
     SkinBlueTeam=None
     DSofMFX=10.000000
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     AmbientGlow=0
     MultiSkins(0)=Texture'sgMedia.GFX.sgSupSpriteT0'
     MultiSkins(1)=Texture'sgMedia.GFX.sgSupSpriteT1'
     MultiSkins(2)=Texture'sgMedia2.GFX.sgSupSpriteT2'
     MultiSkins(3)=Texture'sgMedia2.GFX.sgSupSpriteT3'
}
