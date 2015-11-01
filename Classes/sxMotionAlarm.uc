//=============================================================================
// sxMotionAlarm.
// Written By WILDCARD
//=============================================================================
class sxMotionAlarm expands sgBuilding;

var bool bOwnsCrossHair;
var sgHUD AlarHud;
var() texture TextureRed;
var() texture TextureBlue;
var() texture TextureGreen;
var() texture TextureYellow;
var String AlarmLocation;
var() int DetectionRange;
var int ShortestRange;
var bool StopSpamming;
var bool EnemyIsStillPresent;
var int AccSpam; //Accumulated spam, HIGOR: Accumulate 8 units and sound again, prevents exploits

function AnnounceTeam(string sMessage, int iTeam)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( (p.bIsPlayer || p.IsA('MessagingSpectator')) &&
          p.PlayerReplicationInfo != None && p.playerreplicationinfo.Team == iTeam )
		    p.ClientMessage(sMessage);
}

simulated event PostBeginPlay()
{
	local Pawn p;

	if ( SiegeGI(Level.Game) != none )
		DetectionRange = SiegeGI(Level.Game).BaseMotion;
	ShortestRange = DetectionRange;
	StopSpamming = false;
	EnemyIsStillPresent = false;

	if ( Level.NetMode != NM_Client )
	{
		if ( Pawn(owner).PlayerReplicationInfo.PlayerLocation != None )
			AlarmLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
		else if ( Pawn(owner).PlayerReplicationInfo.PlayerZone != None )
			AlarmLocation = Pawn(owner).PlayerReplicationInfo.PlayerZone.ZoneName;
		if ( AlarmLocation != "" && AlarmLocation != " ")
			AlarmLocation = "at the "@AlarmLocation;
		Super.PostBeginPlay();
	}
}

simulated event Timer()
{
	local Pawn p;
	Super.Timer();

	if ( SCount > 0 || Role != ROLE_Authority )
        	return;

	if ( AccSpam > 50)
	{
		StopSpamming = False;
		AccSpam = 0;
	}

	foreach RadiusActors(class'Pawn', p,DetectionRange)
		if ( p.bIsPlayer && p.Health > 0 &&
			p.PlayerReplicationInfo != None &&
			p.PlayerReplicationInfo.Team != Team && !p.PlayerReplicationInfo.bIsSpectator)
			{
				if (p != None) // if an enemy is present.
				{
					EnemyIsStillPresent = true;
					if ( !StopSpamming )
					{
						StopSpamming = true;
						TeamAlarm();
					}
					AccSpam++;
					break;
				}
			}

	if ( p == none )
	{
		AccSpam = 0;
		if ( !EnemyIsStillPresent )
		{
			StopSpamming = false;
			AlertLight(false);
		}
	}

	EnemyIsStillPresent = false;
}

function TeamAlarm()
{

	local pawn p;

	if (!bDisabledByEMP)
	{
		AnnounceTeam("ENEMY INTRUSION DETECTED!!"@AlarmLocation, Team);
		AlertLight(true);
		Self.PlaySound(Sound'IntrusionAlarm',, 4.0);
		for ( p = Level.PawnList; p != None; p = p.nextPawn )
			if ( p.IsA('TournamentPlayer' ) && p.PlayerReplicationInfo.Team == Team && !p.PlayerReplicationInfo.bIsSpectator )
		        TournamentPlayer(P).ReceiveLocalizedMessage(Class'TeamMotionAlarmAlert');
	}
}

function AlertLight(bool on)
{
	if ( on == true && !bDisabledByEMP)
		{
			LightEffect=LE_SearchLight;
			LightBrightness=255;
			LightPeriod=1;

			if ( Team == 0 )
				LightHue=0;
			else
				LightHue=170;

			LightRadius=32;
			LightSaturation=0;
			LightType=LT_Steady;
		}
    else
		LightType=LT_None;
}

function Upgraded()
{
//	if ( SiegeGI(Level.Game) != None )
		DetectionRange = (ShortestRange*(1+Grade));
}

simulated function FinishBuilding()
{
	MultiSkins[4] = TextureRed;
	MultiSkins[5] = TextureBlue;
	MultiSkins[6] = TextureGreen;
	MultiSkins[7] = TextureYellow;
    JustFinishBuilding();
}

simulated function JustFinishBuilding()
{
    local int i;
    local WildcardsMeshFX newFX;

	AnnounceTeam("Your team has setup a motion alarm "@AlarmLocation, Team);

    DrawScale = SpriteScale;

    if ( Role == ROLE_Authority )
        Spawn(class'sgFlash');

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    if ( myFX == None && Model != None )
        for ( i = 0; i < numOfMFX; i++ )
        {
            newFX = Spawn(class'WildcardsMeshFX', Self,,,
              rotator(vect(0,0,0)));
            //newFX.WcNextFX = myFX;
            myFX = newFX;
            myFX.Mesh = Model;
            myFX.DrawScale = DSofMFX;
            myFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
            myFX.RotationRate.Roll = MFXrotX.Roll*FRand();
            myFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();

        }
}

defaultproperties
{
     bOnlyOwnerRemove=True
     TextureRed=Texture'MotionAlarmSkinT0'
     TextureBlue=Texture'MotionAlarmSkinT1'
     TextureGreen=Texture'MotionAlarmSkinT2'
     TextureYellow=Texture'MotionAlarmSkinT3'
     DetectionRange=64
     BuildingName="Motion Alarm"
     BuildCost=400
     UpgradeCost=30
     BuildTime=20.000000
     MaxEnergy=8000.000000
     Energy=8000.000000
     SpriteScale=1.000000
     Model=LodMesh'UnrealShare.UrnM'
     SpriteRedTeam=Texture'MotionAlarmSpriteT0'
     SpriteBlueTeam=Texture'MotionAlarmSpriteT1'
     SpriteGreenTeam=Texture'MotionAlarmSpriteT2'
     SpriteYellowTeam=Texture'MotionAlarmSpriteT3'
     DSofMFX=2.200000
     NumOfMFX=3
     MFXrotX=(Pitch=9000,Yaw=9000,Roll=9000)
     Fatness=183
     MultiSkins(0)=Texture'MotionAlarmSpriteT0'
     MultiSkins(1)=Texture'MotionAlarmSpriteT1'
     MultiSkins(2)=Texture'MotionAlarmSpriteT2'
     MultiSkins(3)=Texture'MotionAlarmSpriteT3'
     CollisionRadius=32.000000
     CollisionHeight=32.000000
}
