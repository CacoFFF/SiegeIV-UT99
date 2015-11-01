//=============================================================================
// NukeSiren
// by SK
// HIGOR: Major rewrite, now messages shouldn't play the sound, but the siren
// itself, with a loop point on the sound and all
// HIGOR: Made a halfassed model for it
//=============================================================================
class NukeSiren expands sgBuilding;


#exec mesh import mesh=SirenIcon anivfile=Models\SirenIcon_a.3d datafile=Models\SirenIcon_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=SirenIcon x=0 y=0 z=0
#exec mesh sequence mesh=SirenIcon seq=All startframe=0 numframes=1

#exec meshmap new meshmap=SirenIcon mesh=SirenIcon
#exec meshmap scale meshmap=SirenIcon x=0.30000 y=0.30000 z=0.60000


var float SirenRange;
var float TurnOffRange;
var bool bAlreadySounding;
var Pawn aNuker;

var int SpamAgain;
var PlayerPawn LocalPlayer;
var NukeClientSound ClientEffect;

const SecsBeforeSpam = 5;

replication
{
	reliable if ( Role == ROLE_Authority )
		bAlreadySounding;
}

simulated event Timer()
{
	CheckForNukers();
	Super.Timer();	

	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( LocalPlayer == none )
			LocalPlayer = FindLocalPlayer();
		else if ( LocalPlayer.PlayerReplicationInfo != none )
			ClientEffects();
	}
}

//Visual and audible effects
simulated function ClientEffects()
{
	if ( LocalPlayer.PlayerReplicationInfo.Team != Team )
	{
		if ( ClientEffect != none )
		{
			ClientEffect.Destroy();
			ClientEffect = none;
		}
		return;
	}

	if ( bAlreadySounding && (ClientEffect == none) )
	{
		ClientEffect = Spawn( class'NukeClientSound', LocalPlayer,'NukeSounder',Location);
		ClientEffect.OriginSiren = self;
	}
	else if ( !bAlreadySounding && (ClientEffect != none) )
	{
		ClientEffect.Destroy();
		ClientEffect = none;
	}
}

simulated function FinishBuilding()
{
Super.FinishBuilding();
SetTimer(1.0, True);
}

//Called on server
function CheckForNukers()
{
	local PlayerPawn p;
	local sgNukeLauncher aNuke;


	SirenRange = 2048*(1+Grade);
	TurnOffRange = SirenRange + 1024;
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

function SoundTheAlarm()
{
	local TournamentPlayer p;

	if ( !bDisabledByEMP )
	{
		AlertLight(true);
		bAlreadySounding=True;
		if ( SpamAgain <= 0 )
		{
			SpamAgain = SecsBeforeSpam;
			ForEach AllActors (class'TournamentPlayer',P)
				if ( (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team == Team) )
		        	p.ReceiveLocalizedMessage(Class'NukeAlert');
		}
	}
}

function TurnOffAlarm()
{

	AlertLight(false);
	bAlreadySounding=False;

}

function AlertLight(bool on)
{
	if ( on == true && !bDisabledByEMP)
		{
			LightEffect=LE_Cylinder;
			LightBrightness=255;
			LightSaturation=1;
			LightPeriod=8;

			if ( Team == 0 )
				LightHue=2;
			else
				LightHue=150;

			LightRadius=32;
			LightSaturation=0;
			LightType=LT_Pulse;
		}
    else
		LightType=LT_None;
}

simulated function PlayerPawn FindLocalPlayer()
{
	local PlayerPawn P;
	ForEach AllActors (class'PlayerPawn', P)
	{
		if ( (P.Player != none) && (ViewPort(P.Player) != none) )
			return P;
	}
	return none;
}

defaultproperties
{
     bAlwaysRelevant=True
     bOnlyOwnerRemove=True
     SkinRedTeam=Texture'MotionAlarmSkinT0'
     SkinBlueTeam=Texture'MotionAlarmSkinT1'
     SkinGreenTeam=Texture'MotionAlarmSkinT2'
     SkinYellowTeam=Texture'MotionAlarmSkinT3'
     BuildingName="Nuke Siren"
     BuildCost=4000
     UpgradeCost=350
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
