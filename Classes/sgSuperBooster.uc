//=============================================================================
// sgBooster.
// * Revised by 7DS'Lust
//=============================================================================
class sgSuperBooster extends sgBuilding;

var Sound BoostSound;
var float RepairTimer;

function CompleteBuilding()
{
	if ( RepairTimer > 0 )
		RepairTimer -= 0.1;
	else
		Energy = FMin( Energy + 18, MaxEnergy);
}

event TakeDamage( int Damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType)
{
    RepairTimer = 6;
    Super.TakeDamage(Damage * (1 - Grade*0.05), instigatedBy, hitLocation, momentum, damageType);
}

event Touch(Actor other)
{
    if ( DoneBuilding && Pawn(other) != None && Pawn(other).bIsPlayer &&
      Pawn(other).PlayerReplicationInfo != None &&
      Pawn(other).PlayerReplicationInfo.Team == Team && !bDisabledByEMP)
    {
        PendingTouch = other.PendingTouch;
        other.PendingTouch = self;
        PlaySound(BoostSound);
        PlaySound(BoostSound);
    }
}

event PostTouch(Actor other)
{
    local Pawn target;
    local float boost;
    local float Zboost;

    if ( DoneBuilding || Pawn(other) == None )
        return;

    target = Pawn(other);

	if (!bDisabledByEMP)
	{
    if ( target.IsA('Bot') )
    {
        if ( target.Physics == PHYS_Falling )
            Bot(target).bJumpOffPawn = true;
        Bot(target).SetFall();
    }
    if ( target.Physics != PHYS_Swimming )
        target.SetPhysics(PHYS_Falling);
    Zboost = 120 * (Grade + 5);
    boost = Grade;

        target.Velocity.X *= boost;
        target.Velocity.Y *= boost;
        target.Velocity.Z += Zboost;
	}
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BoostSound=Sound'UnrealI.Pickups.BootJmp'
     BuildingName="Super Booster"
     BuildCost=1200
     UpgradeCost=75
     BuildTime=15.000000
     MaxEnergy=2500.000000
     Model=LodMesh'Botpack.Crystal'
     SkinRedTeam=Texture'SuperBoosterSkinT0'
     SkinBlueTeam=Texture'SuperBoosterSkinT1'
     SpriteRedTeam=Texture'SuperBoosterSpriteT0'
     SpriteBlueTeam=Texture'SuperBoosterSpriteT1'
     SkinGreenTeam=Texture'SuperBoosterSkinT2'
     SkinYellowTeam=Texture'SuperBoosterSkinT3'
     SpriteGreenTeam=Texture'SuperBoosterSpriteT2'
     SpriteYellowTeam=Texture'SuperBoosterSpriteT3'
	 SpriteScale=0.500000
     DSofMFX=1.250000
     MFXrotX=(Pitch=50000,Yaw=50000,Roll=50000)
     MultiSkins(0)=Texture'SuperBoosterSpriteT0'
     MultiSkins(1)=Texture'SuperBoosterSpriteT1'
     MultiSkins(2)=Texture'SuperBoosterSpriteT2'
     MultiSkins(3)=Texture'SuperBoosterSpriteT3'
     CollisionHeight=30.000000
     GUI_Icon=Texture'GUI_SBooster'
}
