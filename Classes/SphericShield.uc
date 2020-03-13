//=============================================================================
// SphericShield.
//
// Generic sphere shield.
//=============================================================================
class SphericShield expands sgBuilding;

simulated function FinishBuilding()
{
	local sgMeshFX newFX;

	Super.FinishBuilding();
	
	if ( WildcardsMeshFX(myFX) != None ) //Generic MeshFX created, add HQ version now
	{
		newFX = Spawn(class'sgMeshFX_MiniShieldHQ', Self);
		newFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
		newFX.RotationRate.Roll = MFXrotX.Roll*FRand();
		newFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();
		newFX.DrawScale = CollisionRadius / 50;
		newFX.NextFX = myFX;
		myFX = newFX;
	}
}

simulated function bool AdjustHitLocation(out vector HitLocation, vector TraceDir)
{
	local float OffsetDist, discr;

	Super.AdjustHitLocation( HitLocation, TraceDir);
	
	OffsetDist = 3 + CollisionRadius * 0.15;
	if ( VSize(Location - HitLocation) < CollisionRadius * 0.88)
	{
		HitLocation += Normal(TraceDir) * OffsetDist;
		return false;
	}

	TraceDir = Normal(TraceDir);
	HitLocation -= Location;

	discr = (square(TraceDir dot HitLocation) - HitLocation dot HitLocation) + square(CollisionRadius);
	if ( discr < 0 )
	{
		HitLocation += Location;
		HitLocation += Normal(TraceDir) * OffsetDist; //This should help prevent infinite recursions
		return false;
	}

	HitLocation += TraceDir * ( -(HitLocation dot TraceDir) - sqrt(discr)) + Location;
	return true;
}

event TakeDamage( int Damage, Pawn instigatedBy, Vector HitLocation, Vector Momentum, name damageType )
{
	local float Factor;
	if ( damagetype == 'jolted' || damagetype == 'shot' || damagetype == 'shredded' || damagetype == 'sgSpecial' )
	{
		Factor = 1 + fClamp( Normal(Location - HitLocation) dot Normal(Momentum), 0, 1) * 0.8;
		Damage *= Factor;
	}
	Super.TakeDamage( Damage, instigatedBy, HitLocation, Momentum, damageType);

	if ( !bDeleteMe && !bIsOnFire )
	{
		Spawn(class'ForceFieldFlash',,,HitLocation).DrawScale *= 0.1 + float(Damage) / 250;
		PlaySound(Sound'UnrealShare.General.Expla02',,7.0);
	}
}


defaultproperties
{
     bDragable=True
     bNoUpgrade=True
     RuRewardScale=0.75
     BuildingName="Spheric Shield"
     BuildCost=1000
     UpgradeCost=0
     BuildTime=15.000000
     MaxEnergy=20000.000000
     Model=LodMesh'Botpack.ShockWavem'
     SkinRedTeam=Texture'FORCEFIELDT0'
     SkinBlueTeam=Texture'FORCEFIELDT1'
     SkinGreenTeam=Texture'FORCEFIELDT2'
     SkinYellowTeam=Texture'FORCEFIELDT3'
     SpriteRedTeam=Texture'ContainerSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerSpriteTeam1'
     SpriteGreenTeam=Texture'ContainerSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerSpriteTeam3'
     SpriteScale=0.8
     DSofMFX=2.04
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     CollisionRadius=60.000000
     CollisionHeight=60.000000
     GUI_Icon=Texture'GUI_MiniShield'
}