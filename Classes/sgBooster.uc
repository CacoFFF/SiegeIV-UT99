//=============================================================================
// sgBooster.
// * Revised by 7DS'Lust
//=============================================================================
class sgBooster extends sgBuilding;

var sound           BoostSound;
var float           RepairTimer;
var float LastSim;
var PlayerPawn LocalPlayer;

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	
	ForEach AllActors (class'PlayerPawn', LocalPlayer)
		if ( ViewPort(LocalPlayer.Player) != none )
			return;
	LocalPlayer = none;
}

function CompleteBuilding()
{
	if ( RepairTimer > 0 )
		RepairTimer -= 0.1;
	else
		Energy = FMin( Energy + 18, MaxEnergy);
}

event TakeDamage( int Damage, Pawn instigatedBy, vector HitLocation, Vector momentum, name DamageType)
{
	RepairTimer = 6;
	Super.TakeDamage(Damage * (1 - Grade*0.05), instigatedBy, HitLocation, momentum, DamageType);
}

simulated event Touch(Actor other)
{
	local bool bSim;

	if ( bDisabledByEMP || !DoneBuilding || !Other.bIsPawn )
		return;

	if ( Level.NetMode == NM_Client )
	{
		if ( Other != LocalPlayer )
			return;
		bSim = true; //Don't bother simulating other actors
	}

    if ( Pawn(other).bIsPlayer && Pawn(other).PlayerReplicationInfo != None && Pawn(other).PlayerReplicationInfo.Team == Team )
    {
		if ( bSim )
		{
//			Log("SimBoost: "$LocalPlayer.bUpdating @ LocalPlayer.bCanTeleport );
			if ( !LocalPlayer.bUpdating && LocalPlayer.bCanTeleport )
				LocalPlayer.PlaySound(BoostSound);
			if ( LocalPlayer.bCanTeleport )
			{
				PendingTouch = other.PendingTouch;
				other.PendingTouch = self;
			}
			return;
		}

        PendingTouch = other.PendingTouch;
        other.PendingTouch = self;
		if ( (PlayerPawn(Other) != none) && (NetConnection(PlayerPawn(Other).Player) != none) )
			ServerOwnedSound( Pawn(Other) );
		else
	        ServerSound();
    }
}

// Documentation:
// LocalPlayer: bUpdating && bCanTeleport >>> during AutonomousPhysics rounds, we can edit speed here
// LocalPlayer. !bUpdating && bCanTeleport >>> initial touch, should change physics here?
//
//
//
//



function ServerSound()
{
	PlaySound(BoostSound);
}

function ServerOwnedSound( pawn Other)
{
	Other.PlayOwnedSound(BoostSound);
}

//Serverside Touch
simulated event PostTouch(Actor other)
{
    if ( SCount > 0 || !Other.bIsPawn || bDisabledByEMP )
        return;
//	if ( SiegePlayer(Other) != none )
//		Log("PostTouch HERE");
	DoBoost( Pawn(Other) );
}

simulated function DoBoost( Pawn Other)
{
	local float boost;

	if ( Other.IsA('Bot') )
	{
		if ( Other.Physics == PHYS_Falling )
			Bot(Other).bJumpOffPawn = true;
		Bot(Other).SetFall();
	}
	boost = 115 * (Grade + 3);
	if ( Other.Velocity.Z < -1800 )
		Other.Velocity.Z += boost;
	else if ( Other.Velocity.Z < boost )
		Other.Velocity.Z = boost;

	if ( Other.Physics != PHYS_Swimming )
		Other.SetPhysics(PHYS_Falling);
		
//	if ( SiegePlayer(Other) != none )
//		Log("DoBoost ZVel should be "$Other.Velocity.Z);
}

defaultproperties
{
     BoostSound=Sound'UnrealI.Pickups.BootJmp'
     BuildingName="Booster"
     BuildCost=200
     UpgradeCost=25
     BuildTime=15.000000
     MaxEnergy=2000.000000
     Model=LodMesh'Botpack.Crystal'
     SkinRedTeam=Texture'BoosterSkinTeam0'
     SkinBlueTeam=Texture'BoosterSkinTeam1'
     SpriteRedTeam=Texture'BoosterSpriteTeam0'
     SpriteBlueTeam=Texture'BoosterSpriteTeam1'
     SkinGreenTeam=Texture'BoosterSkinTeam2'
     SkinYellowTeam=Texture'BoosterSkinTeam3'
     SpriteGreenTeam=Texture'BoosterSpriteTeam2'
     SpriteYellowTeam=Texture'BoosterSpriteTeam3'
	 SpriteScale=0.500000
     DSofMFX=0.950000
     MFXrotX=(Yaw=20000)
     MultiSkins(0)=Texture'BoosterSpriteTeam0'
     MultiSkins(1)=Texture'BoosterSpriteTeam1'
     MultiSkins(2)=Texture'BoosterSpriteTeam2'
     MultiSkins(3)=Texture'BoosterSpriteTeam3'
     CollisionHeight=30.000000
     bReplicateEMP=True
     GUI_Icon=Texture'GUI_Booster'
}
