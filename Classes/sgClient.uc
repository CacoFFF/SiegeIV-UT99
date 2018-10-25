///////////////////////////////////////
// Client settings and exchange class

//The test mode will spawn one per server, should be one per client at some point

class sgClient expands ReplicationInfo
	config(SiegeClient);

var PlayerPawn LocalPlayer;
var weapon LocalWeapon;

var FV_sgConstructorPanel ConstructorPanel;
var FV_ConstructorWheel ConstructorWheel;

//LOCALE LOADING IS AUTOMATIC
var() bool bUseSmallGui;
var() bool bNoConstructorScreen;
var() bool bBuildingLights;
var() float GuiSensitivity; //0-1
var() float SirenVol; //0-1
var() string FingerPrint;
var() float ScoreboardBrightness;
var() bool bFPnoReplace; //Never replace fingerprint
var() bool bUseNewDeco;
var() bool bBuildInfo; //Alternative build interface
var() bool bClientIGDropFix;
var() bool bHighPerformance;

var bool bSendFingerPrint;
var bool bTimeoutSafety;
var bool bTriggerSave;
var int iChance;
var IntFileWriter Writer;
var EffectsPool EffectsPool;

var Object TmpOuter;
var sgClientSettings sgSet;

//Fix erroneous settings and initialize fingerprint system
simulated event PostBeginPlay()
{
	local sgScore ScoreBoard;
	
	LocalPlayer = class'SiegeStatics'.static.FindLocalPlayer( Self);
	if ( LocalPlayer == none )
	{
		Destroy();
		return;
	}
	if ( Owner == none )
		SetOwner(LocalPlayer);
	bSendFingerPrint = true;
	iChance = 2;
	SetTimer(2.5 * Level.TimeDilation, false);
	TmpOuter = new(self,'SiegeClient') class'Object';
	sgSet = new(TmpOuter,'Settings') class'sgClientSettings';
	LoadSettings();
	GuiSensitivity = fClamp( GuiSensitivity, 0, 1);
	SirenVol = fClamp( SirenVol, 0.1, 1);

	if ( FingerPrint == "" )
		GenerateFingerPrint();
	ClientSetBind();
	
	ForEach AllActors (class'sgScore', ScoreBoard)
	{
		ScoreBoard.ClientActor = self;
		break;
	}

	ForEach AllActors (class'EffectsPool', EffectsPool)
		break;
	if ( EffectsPool == None )
		EffectsPool = Spawn(class'EffectsPool');
	
	ConstructorPanel = new( self, 'sgConstructorPanel') class'FV_sgConstructorPanel';
	ConstructorPanel.LocalPlayer = LocalPlayer;

	ConstructorWheel = new( self, 'sgConstructorWheel') class'FV_ConstructorWheel';
	ConstructorWheel.LocalPlayer = LocalPlayer;

	EnforcePerformance();
}

//Execute timed actions here
simulated event Timer()
{
	if ( bSendFingerPrint )
	{
		if ( LocalPlayer.PlayerReplicationInfo == none )
		{
			ForEach LocalPlayer.ChildActors (class'PlayerReplicationInfo', LocalPlayer.PlayerReplicationInfo )
			{
				SetTimer( 1 * Level.TimeDilation, false);
				return;
			}
			if ( iChance-- > 0 )
			{
				SetTimer(3 * Level.TimeDilation, false);
				return;
			}
			LocalPlayer.ClientMessage("Own PRI actor not received, this is a network problem and you're being disconnected");
			LocalPlayer.ConsoleCommand("disconnect");
			return;
		}
		if ( !bTimeoutSafety && (InStr(LocalPlayer.PlayerReplicationInfo.PlayerName, "Player") != -1) )
		{
			bTimeoutSafety = true;
			sgPRI(LocalPlayer.PlayerReplicationInfo).RequestFPTime();
			SetTimer(5 * Level.TimeDilation, false);
			return;
		}
		//Do not request FingerPrint if already has one (autoset)
		if ( sgPRI(LocalPlayer.PlayerReplicationInfo).PlayerFingerPrint == "" )
			sgPRI(LocalPlayer.PlayerReplicationInfo).SendFingerPrint( FingerPrint);
		bSendFingerPrint = false;
	}
}

simulated function AdjustSensitivity( int i)
{
	GuiSensitivity = fClamp( GuiSensitivity + 0.1 * float(i), 0, 1);
	sgSet.GuiSensitivity = GuiSensitivity;
	SaveSettings();
}

simulated function AdjustSirenVol( int i)
{
	SirenVol = fClamp( SirenVol + 0.1 * float(i), 0.1, 1);
	sgSet.SirenVol = SirenVol;
	SaveSettings();
}

simulated function SlideSensitivity( float aF)
{
	GuiSensitivity = fClamp( aF, 0, 1);
	sgSet.GuiSensitivity = GuiSensitivity;
	SaveSettings();
}

simulated function AdjustScoreBright( int i)
{
	ScoreboardBrightness = fClamp( ScoreboardBrightness + 0.1 * float(i), 0, 1);
	sgSet.ScoreboardBrightness = ScoreboardBrightness;
	SaveSettings();
}

simulated function ToggleSize()
{
	bUseSmallGui = !bUseSmallGui;
	sgSet.bUseSmallGui = bUseSmallGui;
	SaveSettings();
}

simulated function ToggleConstructor()
{
	bNoConstructorScreen = !bNoConstructorScreen;
	sgSet.bNoConstructorScreen = bNoConstructorScreen;
	SaveSettings();
}

simulated function ToggleKeepFP()
{
	bFPnoReplace = !bFPnoReplace;
	sgSet.bFPnoReplace = bFPnoReplace;
	SaveSettings();
}

simulated function ToggleBInterface()
{
	bBuildInfo = !bBuildInfo;
	sgSet.bBuildInfo = bBuildInfo;
	SaveSettings();
}

simulated function TogglePerformance()
{
	local string Msg;
	bHighPerformance = !bHighPerformance;
	default.bHighPerformance = bHighPerformance;
	sgSet.bHighPerformance = bHighPerformance;
	Msg = "Siege high performance mode";
	if ( bHighPerformance )
		LocalPlayer.ClientMessage( Msg@"enabled");
	else
		LocalPlayer.ClientMessage( Msg@"disabled");
	EnforcePerformance();
	SaveSettings();
}

simulated function EnforcePerformance()
{
	local WildcardsResources WRU;
	if ( Level.NetMode != NM_ListenServer )
	{
		if ( bHighPerformance )
			ForEach AllActors (class'WildcardsResources', WRU)
				WRU.LightType = LT_None;
		else
			ForEach AllActors (class'WildcardsResources', WRU)
				WRU.LightType = LT_Steady;
	}
}

simulated function GenerateFingerprint()
{
	local string aStr;
	local int aInt;
	
	aStr = string(Rand(100)) $ "_" $ string(Level.Year) $ "." $ string( Level.Month) $ "." $ string(Level.Day);
	if ( LocalPlayer.PlayerReplicationInfo != none )
		aStr = aStr $ "_" $ LocalPlayer.PlayerReplicationInfo.PlayerName;
	FingerPrint = aStr;
	sgSet.FingerPrint = FingerPrint;
	SaveSettings();
}

simulated event Tick( float DeltaTime)
{
	if ( LocalPlayer == none ) //WTF?, IS THIS A DEMO?
		return;
	
	if ( Level.Pauser != "" )
	{
		//Hack to prevent client's timers from going bad after a pause
		if ( (Level.NetMode == NM_Client) && (LocalPlayer.GameReplicationInfo != None) )
			LocalPlayer.GameReplicationInfo.SecondCount += DeltaTime * 2;
		//This is an owned actor and the engine has a bug when ticking stuff during pause!!!
		//This actor will only tick half the times!!!
		return;
	}
	
	if ( LocalWeapon != LocalPlayer.Weapon )
	{
		if ( sgConstructor(LocalWeapon) != none )
		{
			ConstructorPanel.ConstructorDown();
			ConstructorWheel.ConstructorDown();
		}
		LocalWeapon = LocalPlayer.Weapon;
	}
	if ( sgConstructor(LocalWeapon) != none )
	{
		ConstructorPanel.Tick( DeltaTime);
		ConstructorWheel.Tick( DeltaTime / Level.TimeDilation); //Real time render
	}
}

//Load strings from custom INI
simulated function LoadSettings()
{
	bUseSmallGui = sgSet.bUseSmallGui;
	bNoConstructorScreen = sgSet.bNoConstructorScreen;
	bBuildingLights = sgSet.bBuildingLights;
	GuiSensitivity = sgSet.GuiSensitivity;
	SirenVol = sgSet.SirenVol;
	FingerPrint = sgSet.FingerPrint;
	bFPnoReplace  = sgSet.bFPnoReplace;
	ScoreboardBrightness  = sgSet.ScoreboardBrightness;
	bClientIGDropFix = sgSet.bClientIGDropFix;
	bHighPerformance = sgSet.bHighPerformance;
	default.bHighPerformance = bHighPerformance;
	sgSet.SaveConfig();
}

//Save this class' settings into the SiegeClient localized file
simulated function SaveSettings()
{
	sgSet.SaveConfig();
}

simulated function CheckWriter()
{
	if ( Writer == none )
		Writer = Spawn(class'IntFileWriter');
}

simulated function LoadAndSet( string PropName)
{
	local string Value;
	Value = Locale(PropName);
	Log( Value);
	if ( Value != "" )
		SetPropertyText( PropName, Value);
	else
		bTriggerSave = true;
}
simulated function string Locale( string PropName)
{
	local string S;
	S = Localize ( "SiegeClient", PropName, "SiegeClient");
	Log( S);
	if ( Left( S, 2) == "<?" )
		return "";
	return S;
}

simulated function ClientSetBind()
{
	local int key;
	local string keyName, bind, bindCaps;
	local PlayerPawn playerOwner;

	bind = LocalPlayer.ConsoleCommand("KEYBINDING F3");
	if ( InStr(Caps(Bind),"SIEGESTATS") < 0 )
		LocalPlayer.ConsoleCommand("SET INPUT F3"@Bind$"|SiegeStats");
	LocalPlayer.ConsoleCommand("SET INPUT F7 TeamRU");

	for ( key = 1; key < 255; key++ )
	{
		keyName = LocalPlayer.ConsoleCommand("KEYNAME"@key);
		bind = LocalPlayer.ConsoleCommand("KEYBINDING"@keyName);
		bindCaps = Caps(bind);
        if ( Left(bindCaps, 4) == "JUMP" || InStr(bindCaps, " JUMP") != -1 || InStr(bindCaps, "|JUMP") != -1 )
		{
			if ( Left(bindCaps, 10) != "SETJETPACK" &&
              InStr(bindCaps, " SETJETPACK") == -1 &&
              InStr(bindCaps, "|SETJETPACK") == -1 )
			{
				bind = "SetJetpack 1|"$bind$"|OnRelease SetJetpack 0";
				LocalPlayer.ConsoleCommand("SET INPUT"@keyName@bind);
			}
		}
	}
}

defaultproperties
{
     SirenVol=1
     bAlwaysRelevant=False
     bAlwaysTick=True
     GuiSensitivity=0.4
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
     bNoConstructorScreen=True
     bUseNewDeco=True
     bClientIGDropFix=True
}
