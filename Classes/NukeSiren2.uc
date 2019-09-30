//=============================================================================
// NukeSiren2
// HIGOR: League version
//=============================================================================
class NukeSiren2 expands NukeSiren;

//Called on server
function CheckForNukers()
{
	local PlayerPawn p;
	local sgNukeLauncher aNuke;


	SirenRange = 900*(3+Grade);
	TurnOffRange = SirenRange + 768;
	SpamAgain--;

	if (!bAlreadySounding)
	{
		foreach RadiusActors(Class'PlayerPawn', p, SirenRange)
			if ( p.PlayerReplicationInfo.Team != Team )
			{
				aNuke = sgNukeLauncher(p.FindInventoryType(class'sgNukeLauncher'));
				if ( (aNuke != none) && (aNuke.AmmoType.AmmoAmount > 0) )
				{
					SoundTheAlarm();
					aNuker = p;
					return;
				}
			}
	}
	else
	{
		if ( (aNuker != none) && !aNuker.bDeleteMe )
		{
			if ( VSize(aNuker.Location - Location) < TurnOffRange + aNuker.CollisionRadius)
				aNuke = sgNukeLauncher(aNuker.FindInventoryType(class'sgNukeLauncher'));
			if ( (aNuke != none) && (aNuke.AmmoType.AmmoAmount > 0) )
			{
				SoundTheAlarm();
				return;
			}
			aNuker = none;
		}
		else
			aNuker = none;

		foreach RadiusActors(Class'PlayerPawn', p, TurnOffRange)
			if ( p.PlayerReplicationInfo.Team != Team )
			{
				aNuke = sgNukeLauncher(p.FindInventoryType(class'sgNukeLauncher'));
				if ( (aNuke != none) && (aNuke.AmmoType.AmmoAmount > 0) )
				{
					SoundTheAlarm();
					aNuker = p;
					return;
				}
			}
		TurnOffAlarm();
	}
}

defaultproperties
{
     bAlwaysRelevant=True
     bOnlyOwnerRemove=True
     SkinRedTeam=Texture'MotionAlarmSkinT0'
     SkinBlueTeam=Texture'MotionAlarmSkinT1'
     SkinGreenTeam=Texture'MotionAlarmSkinT2'
     SkinYellowTeam=Texture'MotionAlarmSkinT3'
     BuildingName="Mini Nuke Siren"
     BuildCost=1200
     UpgradeCost=100
     BuildTime=20.000000
     MaxEnergy=12000.000000
     Energy=12000.000000
     SpriteScale=0.500000
     Model=Mesh'SirenIcon'
     SpriteRedTeam=Texture'MotionAlarmSpriteT0'
     SpriteBlueTeam=Texture'MotionAlarmSpriteT1'
     SpriteGreenTeam=Texture'MotionAlarmSpriteT2'
     SpriteYellowTeam=Texture'MotionAlarmSpriteT3'
     DSofMFX=1.00000
     NumOfMFX=1
     MFXrotX=(Pitch=0,Yaw=4096,Roll=4096)
     Fatness=183
     MultiSkins(0)=Texture'MotionAlarmSpriteT0'
     MultiSkins(1)=Texture'MotionAlarmSpriteT1'
     MultiSkins(2)=Texture'MotionAlarmSpriteT2'
     MultiSkins(3)=Texture'MotionAlarmSpriteT3'
     CollisionRadius=48.000000
     CollisionHeight=48.000000
}
