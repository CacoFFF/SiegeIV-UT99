//=============================================================================
// sgPRI.
// * Revised by nOs*Badger
//
// HIGOR: Added tournament code and re-implemented spawn protection here
// HIGOR: Fingerprint and anti-supplier spam implemented
//=============================================================================
class sgPRI extends PlayerReplicationInfo;

var int		sgInfoKiller,
		sgInfoBuildingMaker,
		sgInfoWarheadMaker,
		sgInfoWarheadKiller,
		sgInfoSpreeCount,
		sgInfoWarheadFailCount,
		sgInfoMineFrags,
		sgInfoCoreDmg;

var string CountryPrefix;
var Texture CachedFlag; //Client takes care of this

var Actor IpToCountry;
var float ResolveWait;
var bool bIpToCountry;		

var float           RU;
var WildcardsOrbs Orb;
var sg_XC_Orb XC_Orb;
var sgPlayerData PlayerData;

//Server only
var float AccRU; //Accumulated addition
var float AccRUTimer; //Space out accumulation

Var bool bReadyToPlay;
var bool bGameStarted;
var bool bHideIdentify;
var bool bReplicateRU;		//Native c++ only
var bool bFlagCached; //Flag cache already attempted

//Spawn protection
var float ProtectCount;
var float SafeProtectTimer;
var Weapon LastWeapon;

var string VisibleMessage; //Always sHistory[0], for external mods
var int VisibleMessageNum;
var string sHistory[20];
var byte sColors[20];
var byte iHistory;

var Pawn PushedBy;
var SiegeStatPlayer Stat;

//Remove protection
var int RemoveTimer;

//Supplier anti-spam
var float SupplierTimer;
var bool bReachedSupplier;

//Fingerprint
var bool bRequestedFPTime;
var bool bReceivedFingerPrint;
var string PlayerFingerPrint;
var float NoFingerPrintTimer;
var int iNoFP;

//For use in AI modes
var name Orders;
var Actor OrderObject;
var sgAIqueuer AIQueuer;

replication
{
	reliable if ( Role == ROLE_Authority )
		RU, Orders, // SiegeNative: spectators and team only
		XC_Orb, Orb, sgInfoKiller, sgInfoBuildingMaker, sgInfoWarheadMaker, sgInfoWarheadKiller, sgInfoWarheadFailCount, sgInfoMineFrags, sgInfoCoreDmg, CountryPrefix, bReadyToPlay, bHideIdentify;
	reliable if ( Role == ROLE_Authority )
		ReceiveMessage, RequestFingerPrint, ClientReceiveRU;
	reliable if ( Role < ROLE_Authority )
		SendFingerPrint, RequestFPTime;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( SiegeGI(Level.Game) != None )
		RU = SiegeGI(Level.Game).StartingRU;
}

event Destroyed()
{
	Super.Destroyed();
	Stat = None;
}

simulated function ClientReceiveRU( float NewRU)
{
	local sgHUD HUD;
	if ( PlayerPawn(Owner) != none )
	{
		HUD = sgHUD(PlayerPawn(Owner).MyHUD);
		if ( HUD != none )
		{
			HUD.GainedRU += NewRU;
			HUD.GainedRUExp = Level.TimeSeconds + 3.5 * Level.TimeDilation;
		}
	}
}

function SendFingerPrint( string aFingerPrint)
{
	local sgPRI aPRI;
	local sgBuilding sgB;
	
	if ( bReceivedFingerPrint )
		return; //Cheat attempt?

	if ( (SiegeGI(Level.Game) != none) && !SiegeGI(Level.Game).bShareFingerPrints )
		ForEach AllActors (class'sgPRI', aPRI)
			if ( aPRI.PlayerFingerPrint == aFingerPrint )
			{
				RequestFingerPrint( true);
				return;
			}

	PlayerFingerPrint = aFingerPrint;
	ForEach AllActors ( class'sgBuilding', sgB)
		if ( (sgB.Owner == none) && (sgB.sPlayerIP == PlayerFingerPrint) )
		{
			sgB.SetOwner( Owner);
			sgB.SetOwnership();
		}

	if ( Spectator(Owner) == none )
		SiegeGI(Level.Game).StatPool.SetupPlayer(Pawn(Owner));
	bReceivedFingerPrint = true;
}

//sgClient is requesting more time to send the fingerprint
function RequestFPTime()
{
	if ( !bRequestedFPTime )
	{
		NoFingerPrintTimer += 5;
		bRequestedFPTime = True;
	}
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if ( Level.NetMode == NM_Client )
		GotoState('ClientOp');
	else if ( Spectator(Owner) != None )
		GotoState('ServerSpectatorOp');
	else
		GotoState('ServerOp');
}

simulated state ClientOp
{
	simulated function sgClientSetup()
	{
		local sgClient aClient;
		ForEach AllActors (class'sgClient', aClient)
			break;
		if ( aClient == none )
			Spawn( class'sgClient', Owner);
	}
Begin:
	while ( Owner == None )
		Sleep(0.2 * Level.TimeDilation);
	if ( (PlayerPawn(Owner) != none) && (Owner.Role == ROLE_AutonomousProxy) )
	{
		sgClientSetup();
		while ( true )
		{
			Sleep(1.98); //Ugly as hell
			RemoveTimer += 2;
		}
	}
}

//Procedural one-time actions in the server
state ServerOp
{
	function LocateIpToCountry()
	{
		ForEach AllActors(class'Actor', IpToCountry, 'IpToCountry')
			break;
		bIpToCountry = IpToCountry != none;
	}
	
	function LocalInit()
	{
		//Bots	
		if ( PlayerPawn(Owner) == none )
			SendFingerPrint("ARTIFICIAL_"$PlayerName);
		//Local Player
		else if ( ViewPort(PlayerPawn(Owner).Player) != None ) 
		{
			SendFingerPrint("LOCALPLAYER_"$PlayerID);
			Owner.Spawn(class'sgClient');
		}
	}
	
Begin:
	Sleep(0.0);
	LocalInit();
	PlayerData = Owner.Spawn(class'sgPlayerData',Owner);
	LocateIpToCountry();

	//Pre-Game, maybe use other checks?
	while ( Pawn(Owner).Weapon == None )
	{
		if ( SiegeGI(Level.Game).bTournament && PlayerPawn(Owner) != None )
			bReadyToPlay = PlayerPawn(Owner).bReadyToPlay;
		else
			bReadyToPlay = false;
		Sleep(0.0);
	}
	bReadyToPlay = false;
	bGameStarted = true;
}

//Spectators don't need to pass the fingerprint check
state ServerSpectatorOp
{
	ignores Tick;
	
	function LocalInit()
	{
	}
	
Begin:
	Sleep(0.0);
	LocalInit();
}


simulated function RequestFingerPrint( optional bool bRegen)
{
	local sgClient aClient;

	if ( (PlayerPawn(Owner) == none) || ViewPort(PlayerPawn(Owner).Player) == none )
		return;

	ForEach AllActors (class'sgClient', aClient )
		break;
	if ( aClient == none )
		return;
	if ( bRegen && aClient.bFPnoReplace )
	{
		PlayerPawn(Owner).ClientMessage("Your fingerprint is in use, if you timed out reconnect again in 5 seconds");
		PlayerPawn(Owner).ConsoleCommand("disconnect");
		return;
	}
	if ( bRegen )
	{
		PlayerPawn(Owner).ClientMessage("Your fingerprint is in use and will be regenerated");
		aClient.GenerateFingerPrint();
	}
	SendFingerPrint( aClient.FingerPrint);
}

simulated function ReceiveMessage( string sMsg, byte aTeam, bool bAnnounce)
{
	local int i, j;
	local PlayerPawn LocalPlayer;
	
	LocalPlayer = PlayerPawn(Owner);
	if ( (LocalPlayer == none) || (ViewPort(LocalPlayer.Player) == none) )
		return;

	//Duplicated messages merge now!
	i = Len( sMsg);
	if ( VisibleMessage == sMsg )
	{
		VisibleMessage = sMsg$" x2";
		sHistory[0] = VisibleMessage;
		VisibleMessageNum++;
	}
	else if ( (Left(VisibleMessage,i) == sMsg) && (Mid(VisibleMessage,i,2) == " x") )
	{
		j = int(Mid(VisibleMessage,i+2)) + 1;
		VisibleMessage = sMsg$" x"$ string(j);
		sHistory[0] = VisibleMessage;
		VisibleMessageNum++;
	}
	else
	{
		//Attempt merge Messages 0 and 1 into 1 (built)
		if ( iHistory > 1 && Len(sHistory[1]) < 75 )
		{
			j = InStr(sHistory[0]," ");
			if ( Left(sHistory[0],j) == Left(sHistory[1],j) ) //Pass 1a, same builder
			{
				if ( (Mid(sHistory[0],j,9) == " built a ") && (Mid(sHistory[1],j,9) == " built a ") ) //Pass 2a, build notification
				{
					j += 9;
					sHistory[1] = sHistory[1] $ "," @ Mid(sHistory[0],j);
					Goto SKIP_PUSH;
				}
			}
			i = InStr(sHistory[1]," ");
			if ( (Mid(sHistory[0],j,9) == " built a ") && (Mid(sHistory[1],i,9) == " built a ") ) //Pass 1b, build notifies from diff players
			{
				if ( Mid(sHistory[0],j) == Mid(sHistory[1],i) ) //Pass 2b, both built exactly the same stuff
				{
					sHistory[1] = Left(sHistory[1],i) $ "," @ Left(sHistory[0],j) $ Mid(sHistory[1],i) @ "each";
					Goto SKIP_PUSH;
				}
			}
		}
		
		if ( iHistory == ArrayCount(sHistory) )
			iHistory--;
		For ( i=iHistory ; i>0 ; i-- )
		{
			sHistory[i] = sHistory[i-1]; //Push up
			sColors[i] = sColors[i-1];
		}
		iHistory++;
	SKIP_PUSH:
		sHistory[0] = sMsg;
		sColors[0] = aTeam;
		VisibleMessage = sMsg;
		VisibleMessageNum++;
	}	
END_RECVM:
	if ( bAnnounce )
		LocalPlayer.ClientMessage("-== "$sMsg$" ==-");
}

function Timer()
{
	Super.Timer();
	RemoveTimer += 2;
}

simulated event PostNetBeginPlay()
{
	local sgClient aClient;

	Super.PostNetBeginPlay();

	if ( Level.NetMode == NM_Client )
	{
		ForEach AllActors (class'sgClient', aClient)
			break;
		if ( aClient == none )
			Spawn(class'sgClient');
		if ( (Owner != None) && (Owner.Role == ROLE_AutonomousProxy) )
			Role = ROLE_SimulatedProxy;
	}
}

simulated function AddRU( float Amount, optional bool bPassiveRU)
{
	local float TopRU;

	TopRU = MaxRU();
	if ( RU <= TopRU )
	{
		if ( (Level.NetMode != NM_Client) || bPassiveRU )
			RU = fClamp(RU + Amount, 0, TopRU);
	}
	else
	{
		if ( Amount > 0 )
			return;
		if ( (Level.NetMode != NM_Client) || bPassiveRU )
			RU = fMax(RU + Amount, 0);
	}

	if ( !bPassiveRU )
		AccRU += Amount;
}

function Tick(float deltaTime)
{
    local PlayerPawn P;
    local string temp;

	if ( Pawn(Owner) == none )
		return;
	
	if ( AccRU != 0 )
	{
		AccRUTimer += DeltaTime;
		NetPriority = default.NetPriority * 1.3;
	}
	if ( AccRUTimer > 0.5 * Level.TimeDilation )
	{
		ClientReceiveRU( AccRU);
		NetPriority = default.NetPriority;
		AccRU = 0;
		AccRUTimer = 0;
	}

	//Fingerprint requests
	if ( (PlayerFingerPrint == "") && (NoFingerPrintTimer > 0) )
	{
		NoFingerPrintTimer -= DeltaTime / Level.TimeDilation;
		if ( NoFingerPrintTimer <= 0 )
		{
			if ( (iNoFP == 0) && (PlayerPawn(Owner) != none) && (ViewPort(PlayerPawn(Owner).Player) == none) )
			{
				Pawn(Owner).ClientMessage("Fingerprint not received by server, disconnecting");
				Owner.Destroy();
			}
			else
			{
				RequestFingerPrint();
				iNoFP--;
			}
			NoFingerPrintTimer = 10;
		}
	}

	if ( PushedBy != none )
	{
		if ( PushedBy.bDeleteMe || (Owner.Physics == PHYS_Walking) )
			PushedBy = none;
	}
	if ( bReachedSupplier && SupplierTimer > 0 )
		SupplierTimer -= deltaTime;

	RU = fMax( RU, 0.f);

	if ( ProtectCount > 0 )
		ProtTimer( DeltaTime / Level.TimeDilation);

	if ( bIpToCountry )
	{
		if(CountryPrefix == "")
		{       
			CountryPrefix = "*2";
			P=PlayerPawn(Owner);
TRY_AGAIN:
			if( (P != none) && (NetConnection(P.Player) != None) )
			{
				ResolveWait = Level.TimeSeconds + 15*Level.TimeDilation;
				temp=P.GetPlayerNetworkAddress();
				temp=IpToCountry.GetItemName(Left(temp, InStr(temp, ":")));
				if(temp == "!Disabled") /* after this return, iptocountry won't resolve anything anyway */
					bIpToCountry=False;
				else if(Left(temp, 1) != "!") /* good response */
				{
					CountryPrefix=SelElem(temp, 5);
					if(CountryPrefix=="") /* the country is probably unknown(maybe LAN), so as the prefix */
						bIpToCountry=False;
				}
			}
			else
				bIpToCountry=False;
		}
		else if ( CountryPrefix == "*2" )
		{
			if ( Level.TimeSeconds > ResolveWait )
			{
				CountryPrefix = "*3";
				P=PlayerPawn(Owner);
				Goto TRY_AGAIN;
			}
		}
		else
			bIpToCountry=False;
	}

}

function ProtTimer( float DeltaTime)
{
	local bool bExpired;
	local Pawn P;

	P = Pawn(Owner);

	if ( LastWeapon == None )
		LastWeapon = P.Weapon;

	ProtectCount -= DeltaTime;
	SafeProtectTimer -= DeltaTime;

	bExpired = ProtectCount <= 0;
	if ( SafeProtectTimer < 0 ) //Additionally, expire after 1 sec if player fired or changed weapons.
		bExpired = bExpired || (P.Weapon != LastWeapon) || (P.bFire + P.bAltFire > 0);
	
	LastWeapon = P.Weapon;

	if ( bExpired )
	{
		Pawn(Owner).ClientMessage("Siege spawn protection off");
		ProtectCount = 0;
	}
	
	if ( PlayerData != None )
		PlayerData.bSpawnProtected = ProtectCount > 0.1;
}

function SetProtection( float NewProtectionTimer)
{
	Pawn(Owner).ClientMessage("Siege spawn protection on");
	ProtectCount = NewProtectionTimer;
	SafeProtectTimer = 1;
	bReachedSupplier = false;
	SupplierTimer = 3.3;
}

simulated function CacheFlag()
{
	if ( bFlagCached || (Asc(CountryPrefix) == 42) ) //* character
		return;
	
	CachedFlag = Texture(DynamicLoadObject("CountryFlags2."$CountryPrefix, class'Texture', true));
	if ( CachedFlag == None )
		CachedFlag = Texture(DynamicLoadObject("CountryFlags5."$CountryPrefix, class'Texture', true));
	if ( CachedFlag == None )
		CachedFlag = Texture(DynamicLoadObject("CountryFlags3."$CountryPrefix, class'Texture', true));
	bFlagCached = true;
}

static final function string SelElem(string Str, int Elem)
{
	local int pos;
	while(Elem-->1)
		Str=Mid(Str, InStr(Str,":")+1);
	pos=InStr(Str, ":");
	if(pos != -1)
    	Str=Left(Str, pos);
    return Str;
}

simulated final function float GetEff()
{
	return float(sgInfoKiller) / fMax(sgInfoKiller + Deaths, 1) * 100;
}

//Used for RU rewards
simulated final function float GetEff2()
{
	local float f;
	f = Max(sgInfoKiller + Deaths - 1, 1); //Max deviation
	return Clamp( 100 * sgInfoKiller / f, 50-2*f, 50+2*f);
}

simulated final function float MaxRU()
{
	if ( SiegeGI(Level.Game) != none )
		return SiegeGI(Level.Game).MaxRUs[Team];
	if ( PlayerPawn(Owner) != none && sgGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo) != none )
		return sgGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo).MaxRUs[Team];
}

defaultproperties
{
     iNoFP=3
	 NoFingerPrintTimer=10
}
