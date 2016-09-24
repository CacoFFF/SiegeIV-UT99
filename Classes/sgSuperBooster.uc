//=============================================================================
// sgSuperBooster.
// * Higor: now it's a sgBooster derivate
//=============================================================================
class sgSuperBooster extends sgBooster;

function ServerSound()
{
	PlaySound(BoostSound,,2);
}

function ServerOwnedSound( pawn Other)
{
	Other.PlayOwnedSound(BoostSound,,2);
}

simulated function DoBoost( Pawn Other)
{
	local float boost;
	local float Zboost;

	if ( Other.IsA('Bot') )
	{
		if ( Other.Physics == PHYS_Falling )
			Bot(Other).bJumpOffPawn = true;
		Bot(Other).SetFall();
	}
    Zboost = 120 * (Grade + 5);
	boost = Grade;

	Other.Velocity.X *= boost;
	Other.Velocity.Y *= boost;
	Other.Velocity.Z += Zboost;

	if ( Other.IsA('PlayerPawn') && Other.Physics == PHYS_Walking ) //Adjust boost angle
	{
		if ( PlayerPawn(Other).bDuck > 0 ) //Ducking
			Other.Velocity = Normal(Other.Velocity * vect( 1.0, 1.0, 0.25)) * (VSize(Other.Velocity) * 1.5);
		else if ( PlayerPawn(Other).bRun > 0 ) //Walking
			Other.Velocity = Normal(Other.Velocity) * (VSize(Other.Velocity) * 1.5);
	}

	if ( Other.Physics != PHYS_Swimming )
		Other.SetPhysics(PHYS_Falling);
}

defaultproperties
{
     bOnlyOwnerRemove=True
     BuildingName="Super Booster"
     BuildCost=1200
     UpgradeCost=75
     BuildTime=15.000000
     MaxEnergy=2500.000000
     SkinRedTeam=Texture'SuperBoosterSkinT0'
     SkinBlueTeam=Texture'SuperBoosterSkinT1'
     SpriteRedTeam=Texture'SuperBoosterSpriteT0'
     SpriteBlueTeam=Texture'SuperBoosterSpriteT1'
     SkinGreenTeam=Texture'SuperBoosterSkinT2'
     SkinYellowTeam=Texture'SuperBoosterSkinT3'
     SpriteGreenTeam=Texture'SuperBoosterSpriteT2'
     SpriteYellowTeam=Texture'SuperBoosterSpriteT3'
     DSofMFX=1.250000
     MFXrotX=(Pitch=50000,Yaw=50000,Roll=50000)
     MultiSkins(0)=Texture'SuperBoosterSpriteT0'
     MultiSkins(1)=Texture'SuperBoosterSpriteT1'
     MultiSkins(2)=Texture'SuperBoosterSpriteT2'
     MultiSkins(3)=Texture'SuperBoosterSpriteT3'
     GUI_Icon=Texture'GUI_SBooster'
}
