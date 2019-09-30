//=============================================================================
// sxMotionAlarm.
// Written By WILDCARD
//=============================================================================
class sxMotionAlarm expands sgBuilding;

var string AlarmLocation;
var() int DetectionRange;
var int BaseRange;
var float EmitWarningAgain;


simulated event PostBeginPlay()
{
	if ( SiegeGI(Level.Game) != none )
		DetectionRange = SiegeGI(Level.Game).BaseMotion;
	BaseRange = DetectionRange;

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

function CompleteBuilding()
{
	local Pawn P;

	if ( Level.TimeSeconds < EmitWarningAgain || bDisabledByEMP )
		return;
	
	if ( LightType != LT_None )
		AlertLight( false);
	
	ForEach RadiusActors(class'Pawn', P, DetectionRange)
		if ( P.bIsPlayer && (P.Health > 0) &&
			P.PlayerReplicationInfo != None &&
			P.PlayerReplicationInfo.Team != Team && !P.PlayerReplicationInfo.bIsSpectator)
			{
				EmitWarningAgain = Level.TimeSeconds + 3.5 * Level.TimeDilation;
				TeamAlarm();
				break;
			}
}

function TeamAlarm()
{
	local PlayerPawn P;

	AnnounceTeam("ENEMY INTRUSION DETECTED!!"@AlarmLocation, Team);
	AlertLight(true);
	PlaySound( Sound'IntrusionAlarm',, 4.0);
	ForEach AllActors( class'PlayerPawn', P)
		if ( (P.PlayerReplicationInfo != None) && (P.PlayerReplicationInfo.Team == Team) && !P.PlayerReplicationInfo.bIsSpectator )
	        P.ReceiveLocalizedMessage(Class'TeamMotionAlarmAlert');
}

function AlertLight( bool bEnable)
{
	if ( bEnable && !bDisabledByEMP )
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
	DetectionRange = (BaseRange*(1+Grade));
}

simulated function FinishBuilding()
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
     SkinRedTeam=Texture'MotionAlarmSkinT0'
     SkinBlueTeam=Texture'MotionAlarmSkinT1'
     SkinGreenTeam=Texture'MotionAlarmSkinT2'
     SkinYellowTeam=Texture'MotionAlarmSkinT3'
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
