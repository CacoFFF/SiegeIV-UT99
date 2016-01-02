//=============================================================================
// sgPRI.
// * Revised by nOs*Badger
//
// HIGOR: Added tournament code and re-implemented spawn protection here
// HIGOR: Fingerprint and anti-supplier spam implemented
//=============================================================================
class sgPRI extends PlayerReplicationInfo;

var int choice;

var float	sgInfoCoreKiller, 
		sgInfoCoreRepair, 
		sgInfoBuildingHurt,
		sgInfoUpgradeRepair;
var int		sgInfoKiller,
		sgInfoBuildingMaker,
		sgInfoWarheadMaker,
		sgInfoWarheadKiller,
		sgInfoSpreeCount;

var string CountryPrefix;

var Actor IpToCountry;
var bool bIpToCountry;		

var float           RU,
                    MaxRU;
var sgBaseCore      Cores[4];
var WildcardsOrbs Orb;
var sg_XC_Orb XC_Orb;

//Server only
var float AccRU; //Accumulated addition
var float AccRUTimer; //Space out accumulation

Var bool bReadyToPlay;
var bool bGameStarted;
var bool bHideIdentify;

//Spawn protection
var float ProtectCount;
var Weapon WhosGun;
var int WhosAmmoCount;

var string VisibleMessage; //Always sHistory[0], for external mods
var int VisibleMessageNum;
var string sHistory[16];
var byte sColors[16];
var byte iHistory;

var pawn PushedBy;

//Remove protection
var int RemoveTimer;

//Supplier anti-spam
var bool bReachedSupplier;
var float SupplierTimer;

//Fingerprint
var bool bReceivedFingerPrint;
var string PlayerFingerPrint;
var float NoFingerPrintTimer;
var int iNoFP;
var bool bRequestedFPTime;

//For use in AI modes
var name Orders;
var actor OrderObject;
var sgAIqueuer AIQueuer;

replication
{
	reliable if ( Role == ROLE_Authority )
		RU, MaxRU, Cores, XC_Orb, Orb, sgInfoCoreKiller, sgInfoBuildingHurt, sgInfoCoreRepair, sgInfoUpgradeRepair, sgInfoKiller, sgInfoBuildingMaker,sgInfoWarheadMaker, sgInfoWarheadKiller, CountryPrefix, bReadyToPlay, bHideIdentify, Orders;
	reliable if ( Role == ROLE_Authority )
		ReceiveMessage, RequestFingerPrint, ClientReceiveRU;
	reliable if ( Role < ROLE_Authority )
		SendFingerPrint, RequestFPTime;
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
	{
		if ( (sgB.Owner == none) && (sgB.sPlayerIP == PlayerFingerPrint) )
			sgB.SetOwner( Owner);
	}
	if ( Spectator(Owner) == none )
		SiegeGI(Level.Game).RURecovery.RecoverRU(Pawn(Owner));
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
	else
		GotoState('ServerOp');
}

simulated state ClientOp
{
	function sgClientSetup()
	{
		local sgClient aClient;
		ForEach AllActors (class'sgClient', aClient)
			break;
		if ( aClient == none )
			Spawn(class'sgClient');
	}
Begin:
	Sleep(0.1);
	if ( (PlayerPawn(Owner) != none) && (ViewPort(PlayerPawn(Owner).Player) != none) )
		sgClientSetup();
}

state ServerOp
{
	function LocateIpToCountry()
	{
		ForEach AllActors(class'Actor', IpToCountry, 'IpToCountry')
			break;
		bIpToCountry = IpToCountry != none;
	}
Begin:
	Sleep(0.0);
	if ( SiegeGI(Level.Game) != none )
		RU = SiegeGI(Level.Game).StartingRU;
	if ( Spectator(Owner) == none )
		Owner.Spawn(class'sgPlayerData',Owner);
	if ( PlayerPawn(Owner) == none )
		PlayerFingerPrint = "BOT_"$PlayerName;
	else if ( ViewPort(PlayerPawn(Owner).Player) != none ) //Local player found
	{
		PlayerFingerPrint = "LocalPlayer";
		Owner.Spawn(class'sgClient');
	}
	LocateIpToCountry();
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
		For ( i=ArrayCount(sHistory)-1 ; i>0 ; i-- )
		{
			sHistory[i] = sHistory[i-1]; //Push up
			sColors[i] = sColors[i-1];
		}
		sHistory[0] = sMsg;
		sColors[0] = aTeam;
		VisibleMessage = sMsg;
		VisibleMessageNum++;
		iHistory = Min(16,iHistory+1);
	}	
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
	}
}

simulated function AddRU( float Amount, optional bool bPassiveRU)
{
	if ( RU <= MaxRU )
		RU = fClamp(RU + Amount, 0, MaxRU);
	else
	{
		if ( Amount > 0 )
			return;
		RU = fMax(RU + Amount, 0);
	}

	if ( !bPassiveRU )
		AccRU += Amount;
}

function Tick(float deltaTime)
{
    local sgBaseCore core;
    local int I;
    local PlayerPawn P;
    local string temp;

	if ( Spectator(Owner) != none )
	{
		Disable('Tick');
		return;
	}
	if ( Pawn(Owner) == none )
		return;
	
	if ( AccRU != 0 )
		AccRUTimer += DeltaTime;
	if ( AccRUTimer > 0.5 * Level.TimeDilation )
	{
		ClientReceiveRU( AccRU);
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
			else if ( !Owner.IsA('PlayerPawn') )
			{
				SendFingerPrint("ARTIFICIAL_"$PlayerName);
				AIQueuer = Spawn(class'sgAIqueuer',Owner,'sgAIqueuer');
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

	if ( !bGameStarted && (Pawn(Owner).Weapon != none) )
		bGameStarted = true;
	if ( !bGameStarted && !bReadyToPlay )
	{
		if ( PlayerPawn(Owner) == none )
			bReadyToPlay = true;
		else if ( DeathMatchPlus(Level.Game).bTournament && (PlayerPawn(Owner) != none) )
			bReadyToPlay = PlayerPawn(Owner).bReadyToPlay;
	}
	else if ( bReadyToPlay && bGameStarted )
		bReadyToPlay = false;

	if ( SiegeGI(Level.Game) != None )
	{
		RU = FMax(FMin(RU, SiegeGI(Level.Game).MaxRUs[Team]), 0);
		MaxRU = SiegeGI(Level.Game).MaxRUs[Team];
		for (I=0;I<4;I++)
			Cores[I] = SiegeGI(Level.Game).Cores[I];
	}

	if ( ProtectCount > 0 )
	{
		if ( (ProtectCount -= DeltaTime) <= 0 )
			ClearProt();
		else
			ProtTimer();
	}

    if(bIpToCountry)
  {
     if(CountryPrefix == "")
     {       
        
	   /*if(Owner.Owner.IsA('PlayerPawn'))
	   {*/
          CountryPrefix = "*2";  
          P=PlayerPawn(Owner);
	      if(NetConnection(P.Player) != None)
	      {
             temp=P.GetPlayerNetworkAddress();
             temp=Left(temp, InStr(temp, ":"));
             
             temp=IpToCountry.GetItemName(temp);
             
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
	    /*}
	    else
	       bIpToCountry=False;*/
      }
      else
         bIpToCountry=False;
    
  }

}

function ProtTimer()
{
	local Pawn P;

	P = Pawn(Owner);
	if ( sgConstructor(P.Weapon) != none )
		return;
	if ( WhosGun == None )
	{
		WhosGun = P.Weapon;
		if ( (WhosGun != none) && (WhosGun.AmmoType != none) )
			WhosAmmoCount = P.Weapon.AmmoType.AmmoAmount;
		return;
	}
	if ( P.Weapon != WhosGun ) //Weapon changed
		ClearProt();
	else if ( WhosGun.AmmoType != none ) 
	{
		if ( P.Weapon.AmmoType.AmmoAmount < WhosAmmoCount ) //Ammo was fired
			ClearProt();
		else if ( P.Weapon.AmmoType.AmmoAmount > WhosAmmoCount ) //Ammo was gained
		{
			WhosAmmoCount = P.Weapon.AmmoType.AmmoAmount;
			if ( P.bFire + P.bAltFire > 0 ) //Disallow firing from suppliers
				ClearProt();
		}
	}
}

function ClearProt()
{
	WhosGun = none;
	WhosAmmoCount = 0;
	ProtectCount = 0;
	Pawn(Owner).ClientMessage("Siege spawn protection off");
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

simulated final function float GetEff( optional bool bJustKilled)
{
	return float(sgInfoKiller) / Max(sgInfoKiller + Deaths - int(bJustKilled), 1) * 100;
}

defaultproperties
{
     iNoFP=3
	 NoFingerPrintTimer=10
}
