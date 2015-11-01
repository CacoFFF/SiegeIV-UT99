//=============================================================================
// MiniShield
// by SK
// Replaces SupplierX since that's only used as a forcefield anyway!
// Higor: Spheric hitbox
// Higor: Balance changes for single target weapons
//=============================================================================

class MiniShield extends sgBuilding;

simulated function FinishBuilding()
{
	if ( Role == ROLE_Authority )
		SetCollisionSize(50,50);
	super.FinishBuilding();
}

simulated event TakeDamage( int damage, Pawn instigatedBy, Vector HitLocation, 
  Vector momentum, name damageType )
{
	local float Factor;
	if ( damagetype == 'jolted' || damagetype == 'shot' || damagetype == 'shredded' || damagetype == 'sgSpecial' )
	{
		Factor = 1 + fClamp( Normal(Location - HitLocation) dot Normal(momentum), 0, 1);
		damage *= Factor;
	}
	Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
	Spawn(class'ForceFieldFlash',,,hitlocation);
	Self.PlaySound(Sound'UnrealShare.General.Expla02',,7.0);
}

simulated function bool AdjustHitLocation(out vector HitLocation, vector TraceDir)
{
	local float hitDist, discr;

	if ( VSize(Location - HitLocation) < CollisionRadius * 0.88)
		return false;

	TraceDir = Normal(TraceDir);
	HitLocation -= Location;

	discr = (square(TraceDir dot HitLocation) - HitLocation dot HitLocation) + square(CollisionRadius);
	if ( discr < 0 )
	{
		HitLocation += Location;
		HitLocation += Normal(TraceDir); //This should help prevent infinite recursions
		return false;
	}

	HitLocation += TraceDir * ( -(HitLocation dot TraceDir) - sqrt(discr)) + Location;
	return true;
}

defaultproperties
{
     bNoUpgrade=True
     RuRewardScale=0.75
     BuildingName="Mini Shield"
     BuildCost=800
     UpgradeCost=0
     BuildTime=30.000000
     MaxEnergy=14000.000000
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
     DSofMFX=1.700000
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     CollisionRadius=28.000000
     CollisionHeight=28.000000
     GUI_Icon=Texture'GUI_MiniShield'
}