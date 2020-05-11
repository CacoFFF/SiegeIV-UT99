//=============================================================================
// sgHUD.
// Revised by nOs*Badger
// Inventory handling recoded by Higor
// Fixed over 9000 log warnings
// ShowNukers rendering by banny
//=============================================================================
class sgHUD extends ChallengeTeamHUD config;

#exec Texture Import File=Graphics\HUD_ClockBg.pcx Name=HUD_ClockBg Mips=Off Group=HUD
#exec Texture Import File=Graphics\HUD_sgBoots.pcx Name=HUD_sgBoots Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_UDamT.pcx Name=HUD_UDamT Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_UDamM.pcx Name=HUD_UDamM Mips=Off Group=HUD Flags=64
#exec Texture Import File=Graphics\HUD_BersT.pcx Name=HUD_BersT Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_BersM.pcx Name=HUD_BersM Mips=Off Group=HUD Flags=64
#exec Texture Import File=Graphics\HUD_sgRubber.bmp Name=HUD_sgRubber Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_sgMetal.bmp Name=HUD_sgMetal Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_sgAsbestos.bmp Name=HUD_sgAsbestos Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_sgToxin.bmp Name=HUD_sgToxin Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_TNetworkT.pcx Name=HUD_TNetworkT Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_TNetworkM.pcx Name=HUD_TNetworkM Mips=Off Group=HUD Flags=64
#exec Texture Import File=Graphics\HUD_SpyT.pcx Name=HUD_SpyT Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_SpyM.pcx Name=HUD_SpyM Mips=Off Group=HUD Flags=64
#exec Texture Import File=Graphics\HUD_SpyEyes.pcx Name=HUD_SpyEyes Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_Invis.pcx Name=HUD_Invis Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_Scuba.pcx Name=HUD_Scuba Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_DampenerON.pcx Name=HUD_DampenerON Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_DampenerOFF.pcx Name=HUD_DampenerOFF Mips=Off Group=HUD Flags=2
#exec Texture Import File=Graphics\HUD_DampenerModu.pcx Name=HUD_DampenerModu Mips=Off Group=HUD Flags=2



var Pawn            IdentifyPawn;
var() color         GreyColor;
var int Glowing;
var int RedColour;
var color GlowColour;
var color GotoColour;
var() color TheWhiteStuff;
var int nHUDDecPlaces;
var float sCore;
var float GainedRU;
var float GainedRUExp;
var() config int NumBuildings;
//var() string sgRankDesc[8];
//var() int sgOldBuilt[41];
var() Texture TeamIcons[5];
var bool UseSpecialColor;
var int AmpCharge;

var float DecimalTimer;
var float HudItemSlotSpace;

var sgTeamNetworth NetworthStat[4];

// The message color variable
var Color SpecialMessageColor;

//Thermal Visor Variables
var() bool bSeeAllHeat, bSeeBehindWalls;
var() class<Actor> AffectedActorsClass;
var() name ExcludedClass;
const HeatInventoryClass = class'sgVisor';
var() class<Actor> HeatClass;
var() float HeatSensingRange;
struct HeatObj
{
	var Actor SavedHeat;
	var Actor HeatOwner;
};

var HeatObj HeatObjs[32];
var int globalint;
var bool bVisorDeActivated;
var config string VisorActMSG, VisorDeactMSG;
var bool bSiegeStats;
var bool bTeamRU;
var bool bEnforceHealth;
var bool bShowNukers;


const IC_Telenet      =  0;
const IC_Visor        =  1;
const IC_Dampener     =  2;
const IC_Scuba        =  3;
const IC_Suits        =  4;
const IC_Invisibility =  5;
const IC_Boots        =  6;
const IC_UDamage      =  7;
const IC_Speed        =  8;
const IC_Suit         =  9;
const IC_Berserk      = 10;
const IC_Constructor  = 11;

const IC_GENERIC      =  0;
const IC_GENERIC_MAX  =  2;
const IC_PICKUP       =  2;
const IC_PICKUP_MAX   =  5;
const IC_UTPICKUP     =  5;
const IC_UTPICKUP_MAX = 11;
const IC_WEAPON       = 11;
const IC_WEAPON_MAX   = 12;
const IC_MAX          = 12;


//Item caching for faster Inventory chain searches
var() int CachedArmor, CachedThighs, CachedShield, HiddenArmor;
var() Inventory I_Cache[12];
var() class<Inventory> I_Type[12];



//UTPure sets enemy health to random values
simulated function PostBeginPlay()
{
	local sgTeamNetworth TN;

	Super.PostBeginPlay();

	bEnforceHealth = (Owner != None) && Owner.IsA('bbPlayer');  //UTPure being gay as usual
	bShowNukers = Spectator(Owner) != None;

//	MyFonts.Destroy();
//	MyFonts = Spawn( class'FontInfoSiege');
		
	if ( SiegeGI(Level.Game) != None )
	{
		NetworthStat[0] = SiegeGI(Level.Game).NetworthStat[0];
		NetworthStat[1] = SiegeGI(Level.Game).NetworthStat[1];
		NetworthStat[2] = SiegeGI(Level.Game).NetworthStat[2];
		NetworthStat[3] = SiegeGI(Level.Game).NetworthStat[3];
	}
	else
	{
		ForEach AllActors( class'sgTeamNetworth', TN)
			if ( TN.Team < 4 )
				NetworthStat[TN.Team] = TN;
	}
}


//Weapon wasn't hooked in inventory chain
simulated final function FixInventoryChain( optional bool bOnlyBreak)
{
	local Inventory Inv, Last, Lone;
	local float fTag;

	//Do not run this routine on authoritary session
	if ( Level.NetMode != NM_Client || Pawn(Owner).Health <= 0 )
		return;

	//Setup - owned
	fTag = 1 + FRand() * 20;

	//Logic:
	// Chained to player		= 1
	// Chained out of player	-= 1 (bad chaining decrements even more)
	// Base of non-player chain	= 0
	// Items spawned more recently are last in actor list, first in inventory chain
	// Chain breaks when a new item is added, not when an existing item is removed (set Inventory before item spawn)

	For ( Inv=Owner.Inventory ; Inv!=none ; Inv=Inv.Inventory )
	{
		//Break the chain if it's looping
		if ( Inv.OddsOfAppearing == fTag )
		{
			if ( Last != none )
				Last.Inventory = none;
			break;
		}
		//Immediately remove bDeleteMe items from chain
		if ( Inv.bDeleteMe && (Last != none) )
			Last.Inventory = Inv.Inventory;
		Inv.OddsOfAppearing = fTag;
		Last = Inv;
	}

	if ( bOnlyBreak )
		return;

	//Setup chain weights, these are non-deleted actors
	ForEach Owner.ChildActors( class'Inventory', Inv)
		if ( (Inv.OddsOfAppearing != fTag) && (Inv.Inventory != none) )
		{
			if ( Inv.Inventory.OddsOfAppearing == fTag )
				Lone = Inv;
			else
				Inv.Inventory.OddsOfAppearing = -fTag;
		}

	//Fix lone inventory first, this is a priority (lone is always right, except when player says so)
	if ( Lone != none )
	{
		For ( Inv=Owner.Inventory ; Inv!=none ; Inv=Inv.Inventory )
			if ( Inv.Inventory == Lone.Inventory )
			{
				Inv.Inventory = Lone;
				return; //Try again on next frame
			}
	}

	//Find latest base of non-player chain and attach
	ForEach Owner.ChildActors( class'Inventory', Inv)
		if ( Abs(Inv.OddsOfAppearing) != fTag )
		{
			if ( Last == none )
				Owner.Inventory = Inv;
			else
				Last.Inventory = Inv;
			break;
		}
}

simulated function TryCacheItem( Inventory Inv, int Start, int Top)
{
	local int i;
	
	for ( i=Start ; i<Top ; i++ )
		if ( ClassIsChildOf( Inv.Class, I_Type[i]) )
		{
			I_Cache[i] = Inv;
			return;
		}
}

simulated function CacheInventory()
{
	local Inventory Inv;
	local int LoopCount, i;
	local Pawn P;
	local bool bNeedWeapon, bNeedAmmo;

	CachedArmor = 0;
	CachedThighs = 0;
	CachedShield = 0;
	HiddenArmor = 0;
	bNeedWeapon = (Pawn(Owner).Weapon != none);
	bNeedAmmo = bNeedWeapon && (Pawn(Owner).Weapon.AmmoType != none);
	P = Pawn(Owner);
	if ( PawnOwner != None )
		P = PawnOwner;

	for ( i=0 ; i<IC_MAX ; i++ )
		if ( (I_Cache[i] != None) && I_Cache[i].bDeleteMe )
			I_Cache[i] = None;

	For ( Inv=P.Inventory ; Inv!=none ; Inv=Inv.Inventory )
	{
		if ( ++LoopCount > 100 )
		{
			FixInventoryChain( true);
			return;
		}
		
		if ( Pickup(Inv) != None )
		{
			if ( Ammo(Inv) != None )
				bNeedAmmo = bNeedAmmo && (Pawn(Owner).Weapon.AmmoType != Inv);
			else
			{
				if ( Inv.bIsAnArmor )
				{
					if ( Inv.ArmorAbsorption >= 100 )
						CachedShield += Inv.Charge;
					else if ( ThighPads(Inv) != none )
						CachedThighs += Inv.Charge;
					else
						CachedArmor += Inv.Charge;
				}
				
				if ( TournamentPickup(Inv) != None )
					TryCacheItem( Inv, IC_UTPICKUP, IC_UTPICKUP_MAX);
				else
					TryCacheItem( Inv, IC_PICKUP, IC_PICKUP_MAX);
			}
		}
		else if ( Weapon(Inv) != None )
		{
			bNeedWeapon = bNeedWeapon && (Inv != Pawn(Owner).Weapon);
			TryCacheItem( Inv, IC_WEAPON, IC_WEAPON_MAX);
		}
		else
			TryCacheItem( Inv, IC_GENERIC, IC_GENERIC_MAX);
	}

	if ( I_Cache[IC_Suits] != none && I_Cache[IC_Suits].bIsAnArmor )
		HiddenArmor += I_Cache[IC_Suits].Charge;
	if ( I_Cache[IC_Suit] != none && I_Cache[IC_Suit].bIsAnArmor )
		HiddenArmor += I_Cache[IC_Suit].Charge;
	CachedArmor -= HiddenArmor;

	if ( bNeedWeapon || bNeedWeapon )
		FixInventoryChain();
}


simulated function DrawTeam(Canvas Canvas, TeamInfo TI)
{
	local float XL, YL, Spacing;
	local sgGameReplicationInfo sgGRI;

	if ( (TI != None) && (TI.Size > 0) )
	{
		Spacing = sqrt(Canvas.ClipY / 960f);
		sgGRI = sgGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
		Canvas.Font = MyFonts.GetHugeFont( Canvas.ClipX );
		Canvas.DrawColor = TeamColor[TI.TeamIndex];
		Canvas.SetPos(Canvas.ClipX - 72 * Spacing, Canvas.ClipY * 0.9 - (284 * Spacing + 60 * Spacing * TI.TeamIndex));

		//Canvas.DrawIcon(TeamIcon[TI.TeamIndex], 1.0);

		Canvas.DrawIcon(TeamIcons[TI.TeamIndex], Spacing );

		Canvas.StrLen(int(TI.Score) $ "  ", XL, YL);
		Canvas.SetPos(Canvas.ClipX - (128 * Spacing), Canvas.ClipY * 0.9 - (268 * Spacing + 60 * Spacing * TI.TeamIndex));
		Canvas.DrawText(int(TI.Score), false);
	}
	//60 > 72 IF FAILS
}

simulated function string GetPlural(int i, string sObject)
{
	if (i==1) return i@sObject;
	return i@sObject$"s";
}

simulated function DrawTeamRU(canvas C)
{
	local int i,y;
	local sgPRI PRI;
	local float widthtotal;
	local float width, height;
	local string s;

	C.Font = Font'SmallFont';
	C.Style = ERenderStyle.STY_Normal;
	for (i=0;i<32;i++)
	{
		PRI = sgPRI(PlayerPawn(Owner).GameReplicationInfo.PRIArray[i]);
		if (PRI != None)
		{
			if (PlayerPawn(Owner).PlayerReplicationInfo.Team == PRI.Team)
			{
				s = PRI.PlayerName @ int(PRI.RU) @ "RU";
				C.TextSize(s, width, height);
				if (width > widthtotal) widthtotal=width;
				y++;
			}
		}
	}


	C.DrawColor = TeamColor[Pawn(Owner).PlayerReplicationInfo.Team];
	y = C.ClipY/3 - ((y * height)/2);
	for (i=0;i<32;i++)
	{
		PRI = sgPRI(PlayerPawn(Owner).GameReplicationInfo.PRIArray[i]);
		if (PRI != None)
		{
			if (PlayerPawn(Owner).PlayerReplicationInfo.Team == PRI.Team)
			{
				C.SetPos(C.ClipX - widthtotal,y);
				C.DrawText(PRI.PlayerName, true);
				s = int(PRI.RU) @ "RU";
				C.TextSize(s, width, height);
				C.SetPos(C.ClipX - width,y);
				C.DrawText(s, True);
				y += height;
			}
		}
	}

}

simulated function DrawShowNukers( Canvas C)
{
	local string NukersList[4];
	local sgPRI PRI;
	local sgGameReplicationInfo GRI;
	local int yPos;					// if rendering all teams nukers, then need to keep track of Y position

	yPos = -1;
	PRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	GRI = sgGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	NukersList[0] = GRI.Nukers_Red;
	NukersList[1] = GRI.Nukers_Blue;
	NukersList[2] = GRI.Nukers_Green;
	NukersList[3] = GRI.Nukers_Yellow;

	if( PRI.Team == 255 )
	{										// spectators need nukers info from all teams
		RenderNukers(C, NukersList[0], 0, yPos);
		RenderNukers(C, NukersList[1], 1, yPos);
		RenderNukers(C, NukersList[2], 2, yPos);
		RenderNukers(C, NukersList[3], 3, yPos);
	}
	else
	{													// specific team
		RenderNukers(C, NukersList[PRI.Team], PRI.Team, yPos);
	}
}

simulated function RenderNukers( Canvas C, String Src, byte Team, out int yPos)
{
	local int i, x, y;
	local float width, height;
	local bool bDrawingName;
	local string S, S_CALC, S_RENDER;

	S_CALC = Src;
	S_RENDER = Src;
	x = 10;
	y = yPos;

	C.Font = Font'SmallFont';
	C.Style = ERenderStyle.STY_Normal;

	bDrawingName = true;
	CALC:									// this loop is just to calculate y
		i = InStr(S_CALC, ";");
		if ( i >= 0 )
		{
			S = Left(S_CALC, i);
			if ( bDrawingName )
			{
				C.TextSize(S, width, height);
				y++;
			}
			S_CALC = Mid(S_CALC, i+1);
  			bDrawingName = !bDrawingName;
   			Goto CALC;
		}

		// if first time, render the HEADING, skip for rest of the times
		if( yPos == -1 )
		{
			y = C.ClipY/3 - ((y * height)/2);
			C.DrawColor = WhiteColor;
			C.SetPos(x, y);
			C.TextSize("Nukers:", width, height);
			C.DrawText("Nukers:", True);
			y += height;
		}

	C.DrawColor = TeamColor[Team];

	bDrawingName = true;
	RENDER:
		i = InStr(S_RENDER, ";");
		if( i >= 0 )
		{
			S = Left(S_RENDER, i);
			if ( bDrawingName )
			{
				C.SetPos(x, y);
				C.DrawText(S, True);
				y += height;
			}
			else
			{
				// Draw Nuker Ammo? We can decide
				// C.SetPos(x + 5, y);
				// C.DrawText(S, True);
			}
			S_RENDER = Mid(S_RENDER, i+1);
			bDrawingName = !bDrawingName;
			Goto RENDER;
		}

	yPos = y;
}

simulated function DrawSiegeStats( Canvas C)
{
	local float FontSizeDirective;
	local float YL, Y1, Height, Width;
	local float TinyFontHeight, SmallFontHeight, BigFontHeight, HugeFontHeight;
	local int X, i;
	local string s1;
	local int MaxPerColumn;

	local string sInfo[8];

	local sgGameReplicationInfo GRI;
	local sgPRI PRI;

	GRI = sgGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	PRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	FontSizeDirective = C.ClipX * 0.6 + C.ClipY * 0.5;

	C.Style = ERenderStyle.STY_Normal;

	if ( PRI.Team < 5 ) //Higor: extra case for a fifth team
		C.DrawColor = TeamColor[PRI.Team];
	else
		C.DrawColor = TeamColor[3];

	C.Font = Font'SmallFont';
	C.TextSize("A", Width, TinyFontHeight);
	C.Font = MyFonts.GetSmallFont( FontSizeDirective );
	C.TextSize("A", Width, SmallFontHeight);
	C.Font = MyFonts.GetBigFont( FontSizeDirective );
	C.TextSize("A", Width, BigFontHeight);
	C.Font = MyFonts.GetHugeFont( FontSizeDirective );
	C.TextSize("A", Width, HugeFontHeight);
	BigFontHeight+=1;

	C.bCenter = true;
	C.SetPos(0, HugeFontHeight );
	C.DrawText("-= Siege IV Game Stats =-", True );
	C.Font = MyFonts.GetBigFont( FontSizeDirective );
	C.SetPos(0, YL + HugeFontHeight*2);

	if ( GRI != None )
	{
		C.DrawText("Top Player Rankings", True );
		YL+=HugeFontHeight*2;
		C.bCenter = false;

		YL += C.ClipY/2 - (5 * (BigFontHeight+TinyFontHeight)) - BigFontHeight;
		YL = int(YL * 0.5);


		if ( GRI.StatTop_Value[3] >= 1 ) sInfo[3] = GetPlural( GRI.StatTop_Value[3],"player")@"killed";
		if ( GRI.StatTop_Value[4] >= 1 ) sInfo[4] = GetPlural( GRI.StatTop_Value[4],"building")@"created";
		if ( GRI.StatTop_Value[5] >= 1 ) sInfo[5] = GetPlural( GRI.StatTop_Value[5],"Warhead")@"created";
		if ( GRI.StatTop_Value[6] >= 1 ) sInfo[6] = GetPlural( GRI.StatTop_Value[6],"Warhead")@"destroyed";

		X = C.ClipX / 4;
		if ( FontSizeDirective >= 800 )
			X -= 128;

		for ( i=0 ; i<8 ; i++ )
		{
			Y1 = YL + ((BigFontHeight+TinyFontHeight+1)*i);
			C.Font = MyFonts.GetBigFont( FontSizeDirective );
			C.DrawColor = WhiteColor;
			C.SetPos(X, Y1);
			C.DrawText( GRI.StatTop_Desc[i] );

			s1 = GRI.StatTop_Name[i];
			if ( s1 ~= PRI.PlayerName )
				C.DrawColor = GoldColor;
			else if ( s1 == "" )
			{
				s1 = "None"; //TODO: Localize
				C.DrawColor = GreyColor;
			}
			else if ( GRI.StatTop_Team[i] < 4 )
				C.DrawColor = TeamColor[GRI.StatTop_Team[i]];

			C.TextSize( s1, Width, Height);
			C.SetPos( X + (C.ClipX/2) - Width, Y1);
			C.DrawText( s1 );
			C.Font = Font'SmallFont';
			if ( sInfo[i] != "" )
			{
				C.DrawColor = GreyColor;
				C.TextSize(sInfo[i], Width, Height);
				C.SetPos( X + (C.ClipX/2) - Width, Y1 + BigFontHeight-2);
				C.DrawText(sInfo[i]);
			}
	//		C.SetPos(X, Y1 + BigFontHeight-3);
	//		C.DrawText(sgRankDesc[i]);
		}

	}

	//Draw Net Worth graph
	X += C.ClipX / 1.9;
	Y1 = YL;
	PRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	C.DrawColor = WhiteColor;
	C.Style = ERenderStyle.STY_Masked;
	For ( i=0 ; i<4 ; i++ )
		if ( (NetworthStat[i] != None) && ((Spectator(Owner) != None) || (PRI.Team == i)) )
		{
			C.SetPos( X, Y1);
			if ( NetworthStat[i].GraphTexture == None )
				NetworthStat[i].SetGraphTexture();
			NetworthStat[i].bGlobal = Spectator(Owner) != None;
			NetworthStat[i].bFirstGlobal = NetworthStat[i].bGlobal && (Y1 <= YL);
			C.DrawIcon( NetworthStat[i].GraphTexture, 1);
			Y1 += 128;
		}

	//HIGOR: Remove messages
	if ( PRI.Team < 4 )
		C.DrawColor = TeamColor[PRI.Team];
	Y1 = YL + ((BigFontHeight+TinyFontHeight+2)*9);
	Height = (C.ClipY - BigFontHeight*2) - Y1;
	MaxPerColumn = Clamp( Height / (SmallFontHeight + 2), 0, PRI.iHistory);
	Width = C.ClipX * 0.075;
	C.Font = MyFonts.GetSmallFont( FontSizeDirective );
	Y1 += int(BigFontHeight * 0.35);
	For ( i=MaxPerColumn-1 ; i>=0 ; i-- )
	{
		C.SetPos( Width, Y1 + (SmallFontHeight + 2) * (MaxPerColumn-i));
		if ( PRI.sColors[i] < 5 )
			C.DrawColor = TeamColor[PRI.sColors[i]];
		C.DrawText( PRI.sHistory[i]);
	}
}

//========================================
// Master HUD render function.

simulated function PostRender( canvas Canvas )
{
	local float XL, YL, YPos, FadeValue;
	local int M, i, j, k;
	local float OldOriginX;

	local bool bWatchingTV;

	local Actor A;

	///////////////////////
	//Thermal Visor Stuff//
	///////////////////////
	if (!bVisorDeActivated && (I_Cache[IC_Visor] != None) )
		{
			globalint=0;

			Canvas.SetPos(0, 0);
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.DrawRect(Texture'BlueSquare', Canvas.ClipX, Canvas.ClipY);

			if (bSeeBehindWalls)
				{
					foreach RadiusActors(AffectedActorsClass, A, HeatSensingRange, Owner.Location)
						{
							if (A != Owner && !A.IsA(ExcludedClass) && !A.bHidden && FMax(A.CollisionRadius, A.CollisionHeight) > 0
							&& A.DrawType == DT_Mesh && (A.bCollideActors || A.bProjTarget))
							HeatUp(A, globalint, Canvas);
						}
				}
			else
				{
					foreach VisibleCollidingActors(AffectedActorsClass, A, HeatSensingRange, Owner.Location)
						{
							if (A != Owner && !A.IsA(ExcludedClass) && A.DrawType == DT_Mesh)
							HeatUp(A, globalint, Canvas);
						}
				}
		}

	HUDSetup(canvas);

	if ( (PawnOwner == None) || (PlayerOwner.PlayerReplicationInfo == None) )
		return;

	if ( bShowInfo )
	{
		ServerInfo.RenderInfo( Canvas );
		return;
	}

	CacheInventory();

	Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
	OldOriginX = Canvas.OrgX;
	// Master message short queue control loop.
	Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
	Canvas.StrLen("TEST", XL, YL);
	Canvas.SetClip(768*Scale - 10, Canvas.ClipY);
	bDrawFaceArea = false;
	if ( !bHideFaces && !PlayerOwner.bShowScores && !bForceScores && !bHideHUD
			&& !PawnOwner.PlayerReplicationInfo.bIsSpectator && (Scale >= 0.4) )
	{
		DrawSpeechArea(Canvas, XL, YL);
		bDrawFaceArea = (FaceTexture != None) && (FaceTime > Level.TimeSeconds);
		if ( bDrawFaceArea )
		{
			if ( !bHideHUD && ((PawnOwner.PlayerReplicationInfo == None) || !PawnOwner.PlayerReplicationInfo.bIsSpectator) )
				Canvas.SetOrigin( FMax(YL*4 + 8, 70*Scale) + 7*Scale + 6 + FaceAreaOffset, Canvas.OrgY );
		}
	}

	for (i=0; i<4; i++)
	{
		if ( ShortMessageQueue[i].Message != None )
		{
			j++;

			if ( bResChanged || (ShortMessageQueue[i].XL == 0) )
			{
				if ( ShortMessageQueue[i].Message.Default.bComplexString )
					Canvas.StrLen(ShortMessageQueue[i].Message.Static.AssembleString(
											self,
											ShortMessageQueue[i].Switch,
											ShortMessageQueue[i].RelatedPRI,
											ShortMessageQueue[i].StringMessage),
								   ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
				else
					Canvas.StrLen(ShortMessageQueue[i].StringMessage, ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
				Canvas.StrLen("TEST", XL, YL);
				ShortMessageQueue[i].numLines = 1;
				if ( ShortMessageQueue[i].YL > YL )
				{
					ShortMessageQueue[i].numLines++;
					for (k=2; k<4-i; k++)
					{
						if (ShortMessageQueue[i].YL > YL*k)
							ShortMessageQueue[i].numLines++;
					}
				}
			}

			// Keep track of the amount of lines a message overflows, to offset the next message with.
			Canvas.SetPos(6, 2 + YL * YPos);
			YPos += ShortMessageQueue[i].numLines;
			if ( YPos > 4 )
				break;

			if ( ShortMessageQueue[i].Message.Default.bComplexString )
			{
				// Use this for string messages with multiple colors.
				ShortMessageQueue[i].Message.Static.RenderComplexMessage(
					Canvas,
					ShortMessageQueue[i].XL,  YL,
					ShortMessageQueue[i].StringMessage,
					ShortMessageQueue[i].Switch,
					ShortMessageQueue[i].RelatedPRI,
					None,
					ShortMessageQueue[i].OptionalObject
					);
			}
			else
			{
				Canvas.DrawColor = ShortMessageQueue[i].Message.Default.DrawColor;
				Canvas.DrawText(ShortMessageQueue[i].StringMessage, False);
			}
		}
	}

	Canvas.DrawColor = WhiteColor;
	Canvas.SetClip(OldClipX, Canvas.ClipY);
	Canvas.SetOrigin(OldOriginX, Canvas.OrgY);

	if ( PlayerOwner.bShowScores || bForceScores )
	{
		if ( (PlayerOwner.Scoring == None) && (PlayerOwner.ScoringType != None) )
			PlayerOwner.Scoring = Spawn(PlayerOwner.ScoringType, PlayerOwner);
		if ( PlayerOwner.Scoring != None )
		{
			PlayerOwner.Scoring.OwnerHUD = self;
			PlayerOwner.Scoring.ShowScores(Canvas);
			if ( PlayerOwner.Player.Console.bTyping )
				DrawTypingPrompt(Canvas, PlayerOwner.Player.Console);
			return;
		}
	}

	YPos = FMax(YL*4 + 8, 70*Scale);
	if ( bDrawFaceArea )
		DrawTalkFace( Canvas,0, YPos );
	if (j > 0)
	{
		bDrawMessageArea = True;
		MessageFadeCount = 2;
	}
	else
		bDrawMessageArea = False;

	if ( !bHideCenterMessages )
	{
		// Master localized message control loop.
		for (i=0; i<10; i++)
		{
			if (LocalMessages[i].Message != None)
			{
				if (LocalMessages[i].Message.Default.bFadeMessage && Level.bHighDetailMode)
				{
					Canvas.Style = ERenderStyle.STY_Translucent;
					FadeValue = (LocalMessages[i].EndOfLife - Level.TimeSeconds);
					if (FadeValue > 0.0)
					{
						if ( bResChanged || (LocalMessages[i].XL == 0) )
						{
							if ( LocalMessages[i].Message.Static.GetFontSize(LocalMessages[i].Switch) == 1 )
								LocalMessages[i].StringFont = MyFonts.GetBigFont( Canvas.ClipX );
							else // ==2
								LocalMessages[i].StringFont = MyFonts.GetHugeFont( Canvas.ClipX );
							Canvas.Font = LocalMessages[i].StringFont;
							Canvas.StrLen(LocalMessages[i].StringMessage, LocalMessages[i].XL, LocalMessages[i].YL);
							LocalMessages[i].YPos = LocalMessages[i].Message.Static.GetOffset(LocalMessages[i].Switch, LocalMessages[i].YL, Canvas.ClipY);
						}
						Canvas.Font = LocalMessages[i].StringFont;
						Canvas.DrawColor = LocalMessages[i].DrawColor * (FadeValue/LocalMessages[i].LifeTime);
						Canvas.SetPos( 0.5 * (Canvas.ClipX - LocalMessages[i].XL), LocalMessages[i].YPos );
						Canvas.DrawText( LocalMessages[i].StringMessage, False );
					}
				}
				else
				{
					if ( bResChanged || (LocalMessages[i].XL == 0) )
					{
						if ( LocalMessages[i].Message.Static.GetFontSize(LocalMessages[i].Switch) == 1 )
							LocalMessages[i].StringFont = MyFonts.GetBigFont( Canvas.ClipX );
						else // == 2
							LocalMessages[i].StringFont = MyFonts.GetHugeFont( Canvas.ClipX );
						Canvas.Font = LocalMessages[i].StringFont;
						Canvas.StrLen(LocalMessages[i].StringMessage, LocalMessages[i].XL, LocalMessages[i].YL);
						LocalMessages[i].YPos = LocalMessages[i].Message.Static.GetOffset(LocalMessages[i].Switch, LocalMessages[i].YL, Canvas.ClipY);
					}
					Canvas.Font = LocalMessages[i].StringFont;
					Canvas.Style = ERenderStyle.STY_Normal;
					Canvas.DrawColor = LocalMessages[i].DrawColor;
					Canvas.SetPos( 0.5 * (Canvas.ClipX - LocalMessages[i].XL), LocalMessages[i].YPos );
					Canvas.DrawText( LocalMessages[i].StringMessage, False );
				}
			}
		}
	}
	Canvas.Style = ERenderStyle.STY_Normal;

    if ( !bWatchingTV && !bSiegeStats) //OVERRIDE
	if ( !PlayerOwner.bBehindView && (PawnOwner.Weapon != None) && (Level.LevelAction == LEVACT_None) )
	{
		Canvas.DrawColor = WhiteColor;
		PawnOwner.Weapon.PostRender(Canvas);
		if ( !PawnOwner.Weapon.bOwnsCrossHair )
			DrawCrossHair(Canvas, 0,0 );
	}

    if ( !bWatchingTV && !bSiegeStats) //OVERRIDE
	if ( (PawnOwner != Owner) && PawnOwner.bIsPlayer )
	{
		Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
		Canvas.bCenter = true;
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = CyanColor * TutIconBlink;
		Canvas.SetPos(4, Canvas.ClipY - 96 * Scale);
		Canvas.DrawText( LiveFeed$PawnOwner.PlayerReplicationInfo.PlayerName, true );
		Canvas.bCenter = false;
		Canvas.DrawColor = WhiteColor;
		Canvas.Style = Style;
	}

	if ( bStartUpMessage && (Level.TimeSeconds < 5) )
	{
		bStartUpMessage = false;
		PlayerOwner.SetProgressTime(7);
	}
	if ( (PlayerOwner.ProgressTimeOut > Level.TimeSeconds) && !bHideCenterMessages )
		DisplayProgressMessage(Canvas);

	// Display MOTD
	if ( MOTDFadeOutTime > 0.0 )
		DrawMOTD(Canvas);

	if( !bHideHUD )
	{
		if ( (PawnOwner.PlayerReplicationInfo != none) && !PawnOwner.PlayerReplicationInfo.bIsSpectator )
		{
			Canvas.Style = Style;

			// Draw Ammo
			if ( !bWatchingTV && !bSiegeStats) //OVERRIDE
				if ( !bHideAmmo )
					DrawAmmo(Canvas);

			// Draw Health/Armor status
			if ( !bWatchingTV  && !bSiegeStats) //OVERRIDE
				DrawStatus(Canvas);

			// Display Weapons
			if ( !bWatchingTV  && !bSiegeStats) //OVERRIDE
			{
				if ( !bHideAllWeapons )
					DrawWeapons(Canvas);
				else if ( Level.bHighDetailMode
						&& (PawnOwner == PlayerOwner) && (PlayerOwner.Handedness == 2) )
				{
					// if weapon bar hidden and weapon hidden, draw weapon name when it changes
					if ( PawnOwner.PendingWeapon != None )
					{
						WeaponNameFade = 1.0;
						Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
						Canvas.DrawColor = PawnOwner.PendingWeapon.NameColor;
						Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
						Canvas.DrawText(PawnOwner.PendingWeapon.ItemName, False);
					}
					else if ( (Level.NetMode == NM_Client)
							&& PawnOwner.IsA('TournamentPlayer') && (TournamentPlayer(PawnOwner).ClientPending != None) )
					{
						WeaponNameFade = 1.0;
						Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
						Canvas.DrawColor = TournamentPlayer(PawnOwner).ClientPending.NameColor;
						Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
						Canvas.DrawText(TournamentPlayer(PawnOwner).ClientPending.ItemName, False);
					}
					else if ( (WeaponNameFade > 0) && (PawnOwner.Weapon != None) )
					{
						Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
						Canvas.DrawColor = PawnOwner.Weapon.NameColor;
						if ( WeaponNameFade < 1 )
							Canvas.DrawColor = Canvas.DrawColor * WeaponNameFade;
						Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
						Canvas.DrawText(PawnOwner.Weapon.ItemName, False);
					}
				}
			}

			// Display Frag count
			if ( !bWatchingTV  && !bSiegeStats) //OVERRIDE
				if ( !bAlwaysHideFrags && !bHideFrags )
					DrawFragCount(Canvas);
		}
		// Team Game Synopsis
		if ( !bWatchingTV  && !bSiegeStats) //OVERRIDE
			if ( !bHideTeamInfo )
				DrawGameSynopsis(Canvas);

		// Display Identification Info
		//if ( !bWatchingTV  && !bSiegeStats) //OVERRIDE
		if ( PawnOwner == PlayerOwner )
			DrawIdentifyInfo(Canvas);

		if ( HUDMutator != None )
			HUDMutator.PostRender(Canvas);

		if ( (PlayerOwner.GameReplicationInfo != None) && (PlayerPawn(Owner).GameReplicationInfo.RemainingTime > 0) )
		{
			if ( TimeMessageClass == None )
				TimeMessageClass = class<CriticalEventPlus>(DynamicLoadObject("Botpack.TimeMessage", class'Class'));

			if ( (PlayerOwner.GameReplicationInfo.RemainingTime <= 300)
			  && (PlayerOwner.GameReplicationInfo.RemainingTime != LastReportedTime) )
			{
				LastReportedTime = PlayerOwner.GameReplicationInfo.RemainingTime;
				if ( PlayerOwner.GameReplicationInfo.RemainingTime <= 30 )
				{
					bTimeValid = ( bTimeValid || (PlayerOwner.GameReplicationInfo.RemainingTime > 0) );
					if ( PlayerOwner.GameReplicationInfo.RemainingTime == 30 )
						TellTime(5);
					else if ( bTimeValid && PlayerOwner.GameReplicationInfo.RemainingTime <= 10 )
						TellTime(16 - PlayerOwner.GameReplicationInfo.RemainingTime);
				}
				else if ( PlayerOwner.GameReplicationInfo.RemainingTime % 60 == 0 )
				{
					M = PlayerOwner.GameReplicationInfo.RemainingTime/60;
					TellTime(5 - M);
				}
			}
		}
	}

	if ( PlayerOwner.Player.Console.bTyping )
		DrawTypingPrompt(Canvas, PlayerOwner.Player.Console);

	if ( PlayerOwner.bBadConnectionAlert && (PlayerOwner.Level.TimeSeconds > 5) )
	{
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = WhiteColor;
		Canvas.SetPos( Canvas.ClipX - (64*Scale), Canvas.ClipY / 2);
		Canvas.DrawIcon( Texture'DisconnectWarn', Scale);
	}

	if ( bSiegeStats )
		DrawSiegeStats( Canvas );
	else if ( bTeamRU )
		DrawTeamRU( Canvas );

	if( bShowNukers )
		DrawShowNukers( Canvas );
}

///////////////////////////////////////////
/////////MORE THERMAL VISOR STUFF//////////
///////////////////////////////////////////

simulated function HeatUp(Actor A, int i, canvas Canvas)
{

	if (HeatObjs[i].SavedHeat == None)
	{
		HeatObjs[i].HeatOwner = A;

		if (A.IsA('Bot') || A.IsA('PlayerPawn') )
		{
			Canvas.DrawColor.R = 0;
			Canvas.DrawColor.G = 0;
			Canvas.DrawColor.B = 0;
			if (Pawn(A).playerreplicationinfo.Team == 0)
			{
				Canvas.DrawColor.R=255;
				HeatObjs[i].SavedHeat = Spawn(Class'sgHeatRed', A,, A.Location, A.Rotation);
			}
			else if (Pawn(A).playerreplicationinfo.Team == 1)
			{
				Canvas.DrawColor.B=255;
				HeatObjs[i].SavedHeat = Spawn(Class'sgHeatBlue', A,, A.Location, A.Rotation);
			}
			else if (Pawn(A).playerreplicationinfo.Team == 2)
			{
				Canvas.DrawColor.G=255;
				HeatObjs[i].SavedHeat = Spawn(Class'sgHeatBlue', A,, A.Location, A.Rotation);
				HeatObjs[i].SavedHeat.Texture = Texture'GParticle';
			}
			else
			{
				Canvas.DrawColor.R=255;
				Canvas.DrawColor.G=255;
				HeatObjs[i].SavedHeat = Spawn(Class'sgHeatBlue', A,, A.Location, A.Rotation);
				HeatObjs[i].SavedHeat.Texture = Texture'YParticle';
			}
		}
	}

	if ( HeatObjs[i].SavedHeat == none )
	{
		GlobalInt++;
		return;
	}

	if (A.DrawScale == A.default.DrawScale)
	{
		HeatObjs[i].SavedHeat.Mesh = HeatObjs[i].HeatOwner.Mesh;
		HeatObjs[i].SavedHeat.AnimFrame = HeatObjs[i].HeatOwner.AnimFrame;
		HeatObjs[i].SavedHeat.AnimSequence = HeatObjs[i].HeatOwner.AnimSequence;
		HeatObjs[i].SavedHeat.PrePivot = HeatObjs[i].HeatOwner.PrePivot;
		HeatObjs[i].SavedHeat.SetLocation(HeatObjs[i].HeatOwner.Location);
		HeatObjs[i].SavedHeat.SetRotation(HeatObjs[i].HeatOwner.Rotation);
	}
	else
	{
		HeatObjs[i].SavedHeat.Mesh = LodMesh'UnrealShare.Candl2';
		HeatObjs[i].SavedHeat.SetLocation(HeatObjs[i].HeatOwner.Location);
		HeatObjs[i].SavedHeat.SetRotation(HeatObjs[i].HeatOwner.Rotation);
	}

	Canvas.DrawActor(HeatObjs[i].SavedHeat, false, bSeeAllHeat);
	globalint++;
}

exec function SiegeStats()
{
	bSiegeStats = !bSiegeStats;
}

exec function TeamRU()
{
	bTeamRU = !bTeamRU;
}

exec function ToggleVisor()
{
	local int i;

	if ( I_Cache[IC_Visor] != None)
	{
		if (!bVisorDeActivated)
		{
			bVisorDeActivated=True;
			Owner.PlaySound(Sound'UnrealShare.Menu.side1b', SLOT_Misc, Pawn(Owner).SoundDampening*2.5);
			Pawn(Owner).ClientMessage(VisorDeactMsg);

			for (i=0; i<32; i++)
			HeatObjs[i].SavedHeat.Destroy();
		}
		else
		{
			bVisorDeActivated=False;
			Owner.PlaySound(Sound'UnrealShare.Menu.side1b', SLOT_Misc, Pawn(Owner).SoundDampening*2.5);
			Pawn(Owner).ClientMessage(VisorActMSG);
		}
	}
}

exec function ShowNukers()
{
	bShowNukers = !bShowNukers;
}


//========================================
//Siege stuff.

simulated function bool TraceIdentify(canvas Canvas)
{
	local Actor         Other;
	local vector        hitLocation,
                        hitNormal,
                        startTrace,
                        endTrace;

	if ( I_Cache[IC_Constructor] != none )
		Other = sgConstructor(I_Cache[IC_Constructor]).HitPawn;

	if ( Other == None )
	{
		startTrace = Owner.Location;
		startTrace.Z += PawnOwner.BaseEyeHeight;
		endTrace = startTrace + vector(PawnOwner.ViewRotation) * 10000.0;
		Other = Trace(hitLocation, hitNormal, endTrace, startTrace, true);
	}

	if ( Pawn(Other) != None && !Other.bHidden )
	{
		IdentifyTarget = Pawn(Other).PlayerReplicationInfo;
		IdentifyPawn = Pawn(Other);
		IdentifyFadeTime = 3.0;
	}

	if ( IdentifyFadeTime == 0 || IdentifyPawn == None )
		return false;

	//Only deny if not same team
	if ( (IdentifyTarget != none) && (Pawn(Owner).PlayerReplicationInfo.Team != IdentifyTarget.Team) )
	{
		if ( IdentifyTarget.bFeigningDeath )
			return false;
		if ( (sgPRI(IdentifyTarget) != none) && sgPRI(IdentifyTarget).bHideIdentify )
			return false;
	}
	return true;
}

simulated function SetIDColor(canvas Canvas, int type)
{
    local int team;

    if ( sgBuilding(IdentifyPawn) != None )
        team = sgBuilding(IdentifyPawn).Team;
    else if ( IdentifyTarget != None )
        team = IdentifyTarget.Team;

    if ( type == 0 )
		Canvas.DrawColor = AltTeamColor[team] * 0.333 *
          IdentifyFadeTime;
	else
    	Canvas.DrawColor = TeamColor[team] * 0.333 *
          IdentifyFadeTime;
}

simulated function DrawTwoColorID(canvas Canvas, string TitleString,
  string ValueString, int YStart)
{
	local float XL, YL, XOffset, X1;

	Canvas.Style = ERenderStyle.STY_Masked;
	Canvas.StrLen(TitleString$": ", XL, YL);
	X1 = XL;
	Canvas.StrLen(ValueString, XL, YL);
	XOffset = Canvas.ClipX/2 - (X1+XL)/2;
	Canvas.SetPos(XOffset, YStart);
	SetIDColor(Canvas, 0);
	XOffset += X1;
	Canvas.DrawText(TitleString);
	Canvas.SetPos(XOffset, YStart);
	SetIDColor(Canvas, 1);
	Canvas.DrawText(ValueString);
	Canvas.DrawColor = WhiteColor;
	Canvas.Font = MyFonts.GetSmallFont(Canvas.ClipX);
}

//====================================================================================================
// HISTORY: The DrawIdentifyInfo() function use to SPAM the log file on clients with Acessed None
// Errors. Badger made some bad refrences to the building owner's PlayerReplicationInfo when the owner
// did not exist. Example: The core does not have an owner so when the player looks at the core the
// acessed none errors come cranking same could happen if a player left and all the ownership of the
// buildings they created were lost so those building have no owner so they behave like the core would
// Higor: And I had to rewrite all from scratch because the spam was still massive
//====================================================================================================

simulated function bool DrawIdentifyInfo(canvas Canvas)
{
	local sgPlayerData sgData;
	local string s, timeleft;
	local float YPos, buildTime;
	local Font BigFont;

	local PlayerReplicationInfo BuilderPRI;
	local sgBuilding Building;

	local float NextLVCost;

	if ( bSiegeStats || !TraceIdentify(Canvas) )
		return false;


	if( sgBuilding(IdentifyPawn) != None )
	{
		// We Are Looking at a building
		if ( IdentifyPawn.bDeleteMe )
		{
			IdentifyPawn = None;
			return false;
		}

		Building = sgBuilding(IdentifyPawn); //Higor, don't do a subclass lookup like 20 times.
		BuilderPRI = Building.OwnerPRI; //Higor: Now players don't need bAlwaysRelevant

		s = string(Building.Energy / Building.MaxEnergy * 100);

		s = left(s, InStr(s, ".")+nHUDDecPlaces+1);
		if (right(s,1)==".")
			s = left(s,len(s)-1);
		s = s  @ "%";
		BigFont = MyFonts.GetBigFont(Canvas.ClipX);
		Canvas.Font = BigFont;
		YPos = Canvas.ClipY - 216*Scale;
		DrawTwoColorID( Canvas, Building.BuildingName $ ": ", s, YPos);


		if( !Building.bNoUpgrade )
		{
			YPos += 36*Scale;
			Canvas.Font = BigFont;
			if ( sgEditBuilding(IdentifyPawn) != none )
			{
				s = string(int(Building.Grade));
				DrawTwoColorID(Canvas,"Priority:",s,Canvas.ClipY - 176 * Scale);
			}
			else
			{
				s = string(Building.Grade);
				s = left(s, InStr(s, ".")+nHUDDecPlaces+1);
				if (right(s,1)==".")
					s = left(s,len(s)-1);
				if( Building.Grade != 5 && ( Building.Team == PlayerPawn(Owner).PlayerReplicationInfo.Team || Spectator(Owner) != None ))
				{
					NextLVCost = int(Building.Grade + 1.001) - Building.Grade;
					if( NextLVCost == 0 )
						NextLVCost = 1;
	//				log(NextLVCost); //Higor: make this log only happen if we are on debug mode, maybe bDebugMode boolean? Log spamming every Tick is BAD
					NextLVCost *= ( Building.UpgradeCost * (int(Building.Grade)+1));
					s = s$"  [Next Level:"@Left( string(NextLVCost) ,InStr( string(NextLVCost), "."))$" RU]";
				}
				DrawTwoColorID(Canvas,"Level:",s, YPos);
			}
		}

		if ( BuilderPRI != None ) //Higor: only happens if looking at building, place it inside building status code block
		{
			YPos += 36*Scale;
			Canvas.Font = BigFont;
			DrawTwoColorID(Canvas,"Built by:", BuilderPRI.PlayerName, YPos);
		}
		
		if ( (sgBaseCore(Building) != None) && sgBaseCore(Building).bLimitRepair )
		{
			YPos += 36*Scale;
			Canvas.Font = BigFont;
			s = string(sgBaseCore(Building).RepairableEnergy * 100.0 / Building.MaxEnergy);
			s = Left( s, Len(s)-5);
			DrawTwoColorID( Canvas, "Repairable % left:", s, YPos);
		}

		if( !Building.DoneBuilding) //Higor: same here, placing it in this block ensures Building exists and preventes yet another log warning
		{
			buildTime = Building.SCount * 0.1 / Level.TimeDilation;
			if( buildTime > 0)
	  		{
				YPos += 36*Scale;
				timeleft = string(buildTime);
				timeleft = Left( timeleft, Len(timeleft) + nHUDDecPlaces - 6);
				Canvas.Font = BigFont;
				DrawTwoColorID(Canvas,"Time left:", timeleft @ "sec" , YPos);
			}
		}
		else if ( (Building.iRULeech > 0) && (PlayerOwner.PlayerReplicationInfo != none) )
		{
			if ( Spectator(Owner) != none )
			{
				YPos += 36*Scale;
				Canvas.Font = BigFont;
				DrawTwoColorID(Canvas,"RU Leeched:", string(Building.iRULeech), YPos);
			}
		}
	}
	else
	{
		// We are looking at a Player
		if ( (IdentifyTarget != None) && (IdentifyTarget.PlayerName != "") && (IdentifyPawn != none) )
		{
			if ( bEnforceHealth )
			{
				if ( sgPRI(IdentifyTarget) != none && sgPRI(IdentifyTarget).PlayerData != none )
					sgPRI(IdentifyTarget).PlayerData.SetHealth();
				else
				{	ForEach IdentifyPawn.ChildActors (class'sgPlayerData', sgData)
					{
						sgData.SetHealth();
						break;
					}
				}
			}
			Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
			DrawTwoColorID(Canvas,IdentifyTarget.PlayerName,string(IdentifyPawn.Health)	,Canvas.ClipY - 256 * Scale);
		}
	}
}

simulated function DrawTextCentered(Canvas canvas, coerce string text)
{
    local float width, height;
    canvas.TextSize(text, width, height);
    canvas.SetPos(Canvas.CurX - width/2, Canvas.CurY);
    canvas.DrawText(text, false);
}

simulated function DrawGameSynopsis(canvas Canvas)
{
    local sgGameReplicationInfo  GRI;
    local float         XL,XL2,
                        YL,YL2,
                        WeapScale,
                        YOffset,
                        Fade;
    local int           i, j,
                        AmpCharge;

	// Percents
    local float fuelPercent;

    local sgPRI		PRI;
    local Jetpack       pack;
    local string 	s;
    local color 	cCol;
    local sgBaseCore sgB;
    local byte aStyle;

	if (bSiegeStats) return;

	GRI = sgGameReplicationInfo(PlayerOwner.GameReplicationInfo);
	if ( GRI != None )
		for ( i = 0; i < 4; i++ )
			DrawTeam(Canvas, GRI.Teams[i]);

	if ( PawnOwner.PlayerReplicationInfo == None || PawnOwner.PlayerReplicationInfo.bIsSpectator )
		return;

	PRI = sgPRI(PawnOwner.PlayerReplicationInfo);
	sgB = GRI.Cores[PRI.Team];

	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.DrawColor = WhiteColor;

    Canvas.TextSize("RU: ", XL, YL);
    Canvas.TextSize("BaseCore:", XL2, YL2);

    if ( bHideAllWeapons )
	    YOffset = Canvas.ClipY;
	else if ( HudScale * WeaponScale * Canvas.ClipX <= Canvas.ClipX - 255 * Scale )
		YOffset = Canvas.ClipY - 63.9*Scale;
	else
		YOffset = Canvas.ClipY - 127.9*Scale;

	if ( PlayerPawn(Owner) != PawnOwner )
		Goto SKIP_ITEMS;

	///////////////////////////////////////////////////////////////
	// HUD ITEM SLOTS /////////////////////////////////////////////
	///////////////////////////////////////////////////////////////
	aStyle = Style;
	if ( aStyle == ERenderStyle.STY_Normal )
		aStyle = ERenderStyle.STY_Masked;
	Canvas.Style = Style;
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	WeapScale = (Scale + WeaponScale * Scale) / 2;


	//////////////////////// JUMPBOOTS ////////////////////////////////
	if ( I_Cache[IC_Boots] != None )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);
		Canvas.DrawIcon(Texture'HUD_sgBoots', WeapScale);
		Canvas.CurX = 5 * WeapScale;
		Canvas.CurY = YOffset + Canvas.CurX;
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(I_Cache[IC_Boots].Charge % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// INVISIBLE ////////////////////////////////
	if ( I_Cache[IC_Invisibility] != None )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);
		Canvas.DrawIcon(Texture'HUD_Invis', WeapScale);

		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		j = I_Cache[IC_Invisibility].Charge / 2;
		if ( j >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// AMPLIFIER /////////////////////////
	if ( I_Cache[IC_UDamage] != None )
	{
		AmpCharge = 0.1 * I_Cache[IC_UDamage].Charge;
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);
		Canvas.DrawIcon(Texture'HUD_UDamT', WeapScale);
		Canvas.SetPos(0,YOffset);
		Canvas.Style = ERenderStyle.STY_Modulated;
		Canvas.DrawIcon(Texture'HUD_UDamM', WeapScale);
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		if ( AmpCharge >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(AmpCharge / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(AmpCharge % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}
	
	//////////////////////// BERSERK /////////////////////////
	if ( I_Cache[IC_Berserk] != None )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor;
		Canvas.SetPos(0,YOffset);
		Canvas.DrawIcon(Texture'HUD_BersT', WeapScale);
		Canvas.SetPos(0,YOffset);
		Canvas.Style = ERenderStyle.STY_Modulated;
		Canvas.DrawIcon(Texture'HUD_BersM', WeapScale);
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		j = I_Cache[IC_Berserk].Charge;
		if ( j >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j/10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j%10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// DAMPENER ////////////////////////
	if ( I_Cache[IC_Dampener] != None )
	{
		AmpCharge = 0.1 * I_Cache[IC_Dampener].Charge;
		YOffset -= 63.9 * WeapScale;
		Canvas.SetPos(0,YOffset);
		Canvas.Style = ERenderStyle.STY_Modulated;
		Canvas.DrawColor = WhiteColor;
		Canvas.DrawIcon(Texture'HUD_DampenerModu', WeapScale);
		Canvas.SetPos(0,YOffset);
		Canvas.Style = ERenderStyle.STY_Translucent;
		Canvas.DrawColor = HUDColor;
		if ( I_Cache[IC_Dampener].bActive && (AmpCharge > 0) )
		{
			Canvas.DrawIcon(Texture'HUD_DampenerON', WeapScale);
			Canvas.DrawColor = GoldColor;
		}
		else
		{
			Canvas.DrawIcon(Texture'HUD_DampenerOFF', WeapScale);
			Canvas.DrawColor = RedColor;
		}
		Canvas.Style = ERenderStyle.STY_Normal;
		if ( AmpCharge >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(AmpCharge / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(AmpCharge % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// TELENETWORK /////////////////////////
	if ( I_Cache[IC_Telenet] != None )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		if ( Style != ERenderStyle.STY_Normal )
		{
			Canvas.SetPos(0,YOffset);
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.DrawIcon(Texture'HUD_TNetworkM', WeapScale);
		}
		Canvas.SetPos(0,YOffset);
		Canvas.Style = aStyle;
		Canvas.DrawIcon(Texture'HUD_TNetworkT', WeapScale);
	}

	//////////////////////// SCUBAGEAR /////////////////////////
	if ( I_Cache[IC_Scuba] != None )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor;
		Canvas.SetPos(0,YOffset);
		Canvas.DrawIcon(Texture'HUD_Scuba', WeapScale);
		j = I_Cache[IC_Scuba].Charge / 10;
		Canvas.DrawColor = GoldColor;
		Canvas.Style = ERenderStyle.STY_Normal;
		if ( j >= 10 )
		{
			if ( j >= 100 )
			{
				Canvas.SetPos( 62 * WeapScale, YOffset + 20 * WeapScale);
				Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j / 100), 0, 25.0, 64.0);
				j -= (j/100)*100;
			}
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// SUITS //////////////////////////////
	if ( I_Cache[IC_Suits] != none )
	{
		YOffset -= 63.9 * WeapScale;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);
		if ( ToxinSuit(I_Cache[IC_Suits]) != none )
			Canvas.DrawIcon(Texture'HUD_sgToxin', WeapScale);
		else if ( AsbestosSuit(I_Cache[IC_Suits]) != none ) //INCLUDE KEVLAR LATER!
			Canvas.DrawIcon(Texture'HUD_sgAsbestos', WeapScale);
	}

	//////////////////////// JETPACK / Super JETPACK //////////////
	if ( I_Cache[IC_Suit] != none )
	{
		if ( JetPack(I_Cache[IC_Suit]) != None )
		{
			YOffset -= HudItemSlotSpace;
			pack = JetPack(I_Cache[IC_Suit]);
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.DrawColor = GreyColor;
			Canvas.SetPos(4 * Scale,YOffset);
			if ( pack.MaxFuel == 999999999 )
			{
				Canvas.DrawTile(texture'IconSuperJetpackFuelBar', 128, 32, 0, 0, 128, 32);
				Canvas.SetPos(4 * Scale,YOffset);
				Canvas.DrawTile(texture'IconSuperJetpackFrame', 128, 32, 0, 0, 128, 32);
			}
			else
			{
				fuelPercent = FClamp(pack.Fuel / pack.MaxFuel,0, 1);
				Canvas.DrawTile(texture'IconJetpackFuelBar', 128 * fuelPercent, 32, 0, 0, 128 * fuelPercent, 32);
				Canvas.SetPos(4 * Scale,YOffset);
				Canvas.DrawTile(texture'IconJetpackFrame', 128, 32, 0, 0, 128, 32);
			}
		}
		else if ( SpySuit(I_Cache[IC_Suit]) != none )
		{
			YOffset -= 63.9 * WeapScale;
			Canvas.DrawColor = HUDColor; //SolidHUDcolor?
			Canvas.SetPos(0,YOffset);
			Canvas.DrawIcon( Texture'HUD_SpyT', WeapScale);
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.SetPos( 13*WeapScale, YOffset+14*WeapScale);
			Canvas.DrawIcon( Texture'HUD_SpyM', WeapScale);
			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.DrawColor = WhiteColor;
			Canvas.SetPos( 13*WeapScale, YOffset+14*WeapScale);
			Canvas.DrawTile( Texture'HUD_SpyEyes', 64*WeapScale,40*WeapScale,63*SpySuit(I_Cache[IC_Suit]).Spying,0,64,40);
		}
		else if ( sgSuit(I_Cache[IC_Suit]).HUD_Icon != none )
		{
			YOffset -= 63.9 * WeapScale;
			Canvas.DrawColor = HUDColor; //SolidHUDcolor?
			Canvas.SetPos(0,YOffset);
			Canvas.DrawIcon( sgSuit(I_Cache[IC_Suit]).HUD_Icon, WeapScale);
		}
		Canvas.Style = aStyle;
	}

	//////////////////////// SPEED ////////////////////////////////
	if ( I_Cache[IC_Speed] != None && I_Cache[IC_Speed].bActive )
	{
		YOffset -= HudItemSlotSpace;
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GreyColor;
		Canvas.SetPos(4 * Scale,YOffset);
		//Canvas.SetPos(4, YOffset - YL*2 + 26);
		Canvas.DrawTile( Texture'IconSpeed', 128, 32, 0, 0, 128, 32);
	}

	//////////////////////// HUD ITEM //////////////////////////////////////
		/*
		log("SiegeGI(Level.Game).MonsterMadness"@SiegeGI(Level.Game).MonsterMadness);
		log("SiegeGI(Level.Game).MonsterMadness"@SiegeGI(Level.Game).MonstersLeft);
		if ( SiegeGI(Level.Game).MonsterMadness == true )
			{
				XL = 20;
				YL = 384;
				Canvas.SetPos(XL,YL);
				Canvas.DrawColor = NewColor(128,128,128);

				Canvas.DrawText("Monster Left:"@SiegeGI(Level.Game).MonstersLeft, false);
			}
	*/
	SKIP_ITEMS:
	YOffset -= XL * 3;
    Canvas.SetPos(0, YOffset);
    Canvas.Style = ERenderStyle.STY_Masked;
    Canvas.DrawText("RU:", false);

	if (sgB != None)
	{
		Canvas.SetPos(0, YOffset+YL);
		Canvas.DrawText("BaseCore:", false);
	}

	if ( PRI != None )
	{
		Canvas.DrawColor = GreyColor;
		Canvas.SetPos(XL, YOffset);
		Canvas.DrawText( int(PRI.RU), false);
		Canvas.CurY = YOffset;
//		Canvas.DrawText( int(PRI.RU)@"/"@ int(PRI.MaxRU), false);
		if ( sgB != none )
		{
			j = sgB.StoredRU;
			if ( Abs(j) > 2 )
			{
				if ( j < 0 )
					Canvas.DrawColor = NewColor( 250, 20, 20);
				else
					Canvas.DrawColor = NewColor( 20, 200, 250);
				Canvas.DrawText( "[" $ int(Abs(j)) $ "]", false);
				Canvas.CurY = YOffset;
				Canvas.DrawColor = GreyColor;
			}
		}
		if ( GRI != none )
			Canvas.DrawText( " /"@ int(GRI.MaxRUs[PRI.Team]), false);

		if ( GainedRU != 0 )
		{
			Canvas.SetPos( Canvas.CurX + XL*0.3, YOffset);
			Fade = fClamp( GainedRUExp - Level.TimeSeconds, 0, 1);
			if ( GainedRU > 0 )
			{
				Canvas.DrawColor = NewColor( 10, 200*Fade, 10);
				Canvas.DrawText( "+"$int(GainedRU));
			}
			else
			{
				Canvas.DrawColor = NewColor( 250*Fade, 60*Fade, 10);
				Canvas.DrawText( int(GainedRU));
//				Canvas.DrawText( "-"$int(abs(GainedRU)));
			}
			if ( Fade <= 0 )
				GainedRU = 0;
			Canvas.DrawColor = GreyColor;
		}
		if (sgB != none)
		{
			Canvas.SetPos(XL2, YOffset+YL);
			s = string(sgB.Energy / sgB.MaxEnergy * 100);
			s = left(s, InStr(s, ".")+nHUDDecPlaces+1);
			if (right(s,1)==".")
				s = left(s,len(s)-1);

			fuelPercent = float(s);
			if (fuelPercent > sCore)
				RedColour=256;
			else if (fuelPercent < sCore)
				RedColour = 0;

			if (RedColour<128)
			{
				RedColour+=4;
				cCol = NewColor(255-RedColour,RedColour,RedColour);
			}
			else if (RedColour>128)
			{
				RedColour-=4;
				cCol = NewColor(RedColour,RedColour,RedColour);
			}
			else
				cCol=GreyColor;

			Canvas.DrawColor = cCol;
			sCore = fuelPercent;
			Canvas.DrawText(""@s, false);
		}
		Canvas.SetPos(XL, YOffset+20);
	}

}


simulated function DrawStatus(Canvas Canvas)
{
	local float StatScale, ChestAmount, ThighAmount, H1, H2, X, Y, DamageTime;
	Local int ArmorAmount,SuitAmount,CurAbs,i,OverTime;
//	Local inventory Inv,BestArmor;
	local bool bHasDoll;
	local Bot BotOwner;
	local TournamentPlayer TPOwner;
	local texture Doll, DollBelt;
	local float Amount, XL;

	ArmorAmount = 0;
	CurAbs = 0;
	i = 0;
//	BestArmor=None;

	ThighAmount = CachedThighs;
	SuitAmount = HiddenArmor;
	ChestAmount = CachedArmor;
	ArmorAmount = CachedThighs + HiddenArmor + CachedArmor + CachedShield;

	if ( !bHideStatus )
	{
		TPOwner = TournamentPlayer(PawnOwner);
		if ( Canvas.ClipX < 400 )
			bHasDoll = false;
		else if ( TPOwner != None)
		{
			Doll = TPOwner.StatusDoll;
			DollBelt = TPOwner.StatusBelt;
			bHasDoll = true;
		}
		else
		{
			BotOwner = Bot(PawnOwner);
			if ( BotOwner != None )
			{
				Doll = BotOwner.StatusDoll;
				DollBelt = BotOwner.StatusBelt;
				bHasDoll = true;
			}
		}
		if ( bHasDoll )
		{
			Canvas.Style = ERenderStyle.STY_Translucent;
			StatScale = Scale * StatusScale;
			X = Canvas.ClipX - 128 * StatScale;
			Canvas.SetPos(X, 0);
			if (PawnOwner.DamageScaling > 2.0)
				Canvas.DrawColor = PurpleColor;
			else
				Canvas.DrawColor = HUDColor;
			Canvas.DrawTile(Doll, 128*StatScale, 256*StatScale, 0, 0, 128.0, 256.0);
			if ( CachedShield > 0 )
			{
				Amount = fClamp( 195 - float(CachedShield) * 1.30, 0, 195);
				Canvas.DrawColor = BaseColor;
				Canvas.DrawColor.B = 0;
				Canvas.SetPos(X, Amount*StatScale);
				Canvas.DrawTile( DollBelt, 128.0 * StatScale, (256.0 - Amount)*StatScale, 0, Amount, 128, 256-Amount );
			}
			if ( CachedArmor > 0 )
			{
				ChestAmount = FMin(0.01 * ChestAmount,1);
				Canvas.DrawColor = HUDColor * ChestAmount;
				Canvas.SetPos(X, 0);
				Canvas.DrawTile( Doll, 128*StatScale, 64*StatScale, 128, 0, 128, 64);
			}
			if ( CachedThighs > 0 )
			{
				ThighAmount = FMin(0.02 * ThighAmount,1);
				Canvas.DrawColor = HUDColor * ThighAmount;
				Canvas.SetPos(X, 64*StatScale);
				Canvas.DrawTile( Doll, 128*StatScale, 64*StatScale, 128, 64, 128, 64);
			}
			if ( I_Cache[IC_Boots] != None )
			{
				Canvas.DrawColor = HUDColor;
				Canvas.SetPos(X, 128*StatScale);
				Canvas.DrawTile( Doll, 128*StatScale, 64*StatScale, 128, 128, 128, 64);
			}
			Canvas.Style = Style;
			if ( (PawnOwner == PlayerOwner) && Level.bHighDetailMode && !Level.bDropDetail )
			{
				for ( i=0; i<4; i++ )
				{
					DamageTime = Level.TimeSeconds - HitTime[i];
					if ( DamageTime < 1 )
					{
						Canvas.SetPos(X + HitPos[i].X * StatScale, HitPos[i].Y * StatScale);
						if ( (HUDColor.G > 100) || (HUDColor.B > 100) )
							Canvas.DrawColor = RedColor;
						else
							Canvas.DrawColor = (WhiteColor - HudColor) * FMin(1, 2 * DamageTime);
						Canvas.DrawColor.R = 255 * FMin(1, 2 * DamageTime);
						Canvas.DrawTile(Texture'BotPack.HudElements1', StatScale * HitDamage[i] * 25, StatScale * HitDamage[i] * 64, 0, 64, 25.0, 64.0);
					}
				}
			}
		}
	}
	Canvas.DrawColor = HUDColor;
	if ( bHideStatus && bHideAllWeapons )
	{
		X = 0.5 * Canvas.ClipX;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 64 * Scale;
	}
	Canvas.SetPos(X,Y);
	if ( PawnOwner.Health < 50 )
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = WhiteColor * H2 + (HUDColor - WhiteColor) * H1;
	}
	else
		Canvas.DrawColor = HUDColor;
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 128, 128, 128.0, 64.0);

	if ( PawnOwner.Health < 50 )
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = Canvas.DrawColor * H2 + (WhiteColor - Canvas.DrawColor) * H1;
	}
	else
		Canvas.DrawColor = WhiteColor;

	DrawBigNum(Canvas, Max(0, PawnOwner.Health), X + 4 * Scale, Y + 16 * Scale, 1);

	Canvas.DrawColor = HUDColor;
	if ( bHideStatus && bHideAllWeapons )
	{
		X = 0.5 * Canvas.ClipX - 128 * Scale;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 0;
	}
	Canvas.SetPos(X, Y);
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 0, 192, 128.0, 64.0);
	if ( bHideStatus && (CachedShield > 0) )
		Canvas.DrawColor = GoldColor;
	else
		Canvas.DrawColor = WhiteColor;
	if ( (ArmorAmount > 150) && (SuitAmount > 0) )
	{
		ArmorAmount -= SuitAmount;
		if ( ArmorAmount <= 150 )
			ArmorAmount = 150;
	}
	DrawBigNum(Canvas, Min(999,ArmorAmount), X + 4 * Scale, Y + 16 * Scale, 1);

	if ( true )
	{
		Canvas.DrawColor = HUDColor;

        i = PlayerOwner.GameReplicationInfo.RemainingTime;
        if (i == 0)
        {
            i = PlayerOwner.GameReplicationInfo.ElapsedTime;
            if (OverTime < 0)
                OverTime = i;
            if (OverTime > 0)
                i = OverTime - i;
        }
        else
            OverTime = -1;

		XL = 0;
		if ( i/60 > 199 )
			XL = 25;
		else if ( i/60 > 99 )
			XL = 15;

        // Draw in front of Frags
        if ( bHideStatus && bHideAllWeapons )
        {
            X = 0.5 * Canvas.ClipX - 384 * Scale - XL * Scale;
            Y = Canvas.ClipY - 64 * Scale;
        }
        else
        {
            X = Canvas.ClipX - 128 * StatScale - 140 * Scale - XL * Scale;
            Y = 128 * Scale;
        }

        Canvas.SetPos(X,Y);
        Canvas.DrawTile(Texture'HUD_ClockBg', 128*Scale + XL * Scale, 64*Scale, 0, 0, 128.0, 64.0);
        Canvas.Style = Style;
        Canvas.DrawColor = WhiteColor;
        DrawTime(Canvas, X, Y, i, XL);
	}
}


//*****************
//Higor:
// FUK PURE, I MAKE HUDE WITH TIMERR UHAHUAHUAHUA
// g0v woz ere
simulated function DrawTime(Canvas Canvas, float X, float Y, int Seconds, float ExtraSize)
{
	local int Min, Sec;
	local float FullSize;

	Min = Seconds / 60;
	Sec = Seconds % 60;
	X += ExtraSize * Scale;

	if ( Level.bHighDetailMode )
		Canvas.Style = ERenderStyle.STY_Translucent;

	FullSize = 25 * Scale * 4 + 16 * Scale; //At least 4 digits and : (extra size not counted)

	Canvas.SetPos( X + 64 * Scale, Y + 12 * Scale);
	Canvas.CurX -= (FullSize / 2);
	if ( Min >= 100 )
	{
		Canvas.CurX -= ExtraSize * Scale;
		Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*ExtraSize, 64*Scale, ((Min / 100)%10) * 25 + (25 - ExtraSize), 0, ExtraSize, 64.0);
	}
	Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*25, 64*Scale, ((Min/10)%10) *25, 0, 25.0, 64.0);
	Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*25, 64*Scale, (Min%10)*25, 0, 25.0, 64.0);
	Canvas.CurX -= 6 * Scale;
	Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*25, 64*Scale, 25, 64, 25.0, 64.0); //DOUBLE DOT HERE
	Canvas.CurX -= 6 * Scale;
	Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*25, 64*Scale, ((Sec/10)%10) *25, 0, 25.0, 64.0);
	Canvas.DrawTile(Texture'BotPack.HudElements1', Scale*25, 64*Scale, (Sec%10)*25, 0, 25.0, 64.0);
}


//=====================================================================
// Deal with a localized message.
// Modified By WILDCARD
// Contains a hack to FORCE it to allow non-hardcodded messages!

simulated function LocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject, optional String CriticalString )
{
	local int i;

	if ( ClassIsChildOf( Message, class'PickupMessagePlus' ) )
		PickupTime = Level.TimeSeconds;

	if ( !Message.Default.bIsSpecial )
	{
		if ( ClassIsChildOf(Message, class'SayMessagePlus') ||
						 ClassIsChildOf(Message, class'TeamSayMessagePlus') )
		{
			FaceTexture = RelatedPRI_1.TalkTexture;
			if ( FaceTexture != None )
				FaceTime = Level.TimeSeconds + 3;
		}
		// Find an empty slot.
		for (i=0; i<4; i++)
		{
			if ( ShortMessageQueue[i].Message == None )
			{
				ShortMessageQueue[i].Message = Message;
				ShortMessageQueue[i].Switch = Switch;
				ShortMessageQueue[i].RelatedPRI = RelatedPRI_1;
				ShortMessageQueue[i].OptionalObject = OptionalObject;
				ShortMessageQueue[i].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
				if ( Message.Default.bComplexString )
					ShortMessageQueue[i].StringMessage = CriticalString;
				else
					ShortMessageQueue[i].StringMessage = Message.Static.
					GetString(Switch,RelatedPRI_1, RelatedPRI_2, OptionalObject);
				return;
			}

		}
		// No empty slots.  Force a message out.
		for (i=0; i<3; i++)
			CopyMessage(ShortMessageQueue[i], ShortMessageQueue[i+1]);

		ShortMessageQueue[3].Message = Message;
		ShortMessageQueue[3].Switch = Switch;
		ShortMessageQueue[3].RelatedPRI = RelatedPRI_1;
		ShortMessageQueue[3].OptionalObject = OptionalObject;
		ShortMessageQueue[3].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
		if ( Message.Default.bComplexString )
			ShortMessageQueue[3].StringMessage = CriticalString;
		else
			ShortMessageQueue[3].StringMessage = Message.Static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
		return;
	}
	else
	{
		if ( CriticalString == "" )
			CriticalString = Message.Static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
		if ( Message.Default.bIsUnique )
		{
			for (i=0; i<10; i++)
			{
				if (LocalMessages[i].Message != None)
				{
					if ((LocalMessages[i].Message == Message)
						|| (LocalMessages[i].Message.Static.GetOffset(LocalMessages[i].Switch, 24, 640)
								== Message.Static.GetOffset(Switch, 24, 640)) )
					{
						LocalMessages[i].Message = Message;
						LocalMessages[i].Switch = Switch;
						LocalMessages[i].RelatedPRI = RelatedPRI_1;
						LocalMessages[i].OptionalObject = OptionalObject;
						LocalMessages[i].LifeTime = Message.Default.Lifetime;
						LocalMessages[i].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
						LocalMessages[i].StringMessage = CriticalString;

						// The Color Hack! :)
						if ( UseSpecialColor == true )
							{
								LocalMessages[i].DrawColor = SpecialMessageColor;
								//LocalMessages[i].DrawColor.R = 255;
//								log("SGX: This is a Siege Message Class");
							}
						else
							{
								LocalMessages[i].DrawColor = Message.Static.GetColor(Switch, RelatedPRI_1, RelatedPRI_2);
//								log("SGX: This NOT Siege Message Class");
							}

						LocalMessages[i].XL = 0;
						return;
					}
				}
			}
		}
		for (i=0; i<10; i++)
		{
			if (LocalMessages[i].Message == None)
			{
				LocalMessages[i].Message = Message;
				LocalMessages[i].Switch = Switch;
				LocalMessages[i].RelatedPRI = RelatedPRI_1;
				LocalMessages[i].OptionalObject = OptionalObject;
				LocalMessages[i].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
				LocalMessages[i].StringMessage = CriticalString;
				LocalMessages[i].DrawColor = Message.Static.GetColor(Switch, RelatedPRI_1, RelatedPRI_2);
				LocalMessages[i].LifeTime = Message.Default.Lifetime;
				LocalMessages[i].XL = 0;
				return;
			}
		}

		// No empty slots.  Force a message out.
		for (i=0; i<9; i++)
			CopyMessage(LocalMessages[i],LocalMessages[i+1]);

		LocalMessages[9].Message = Message;
		LocalMessages[9].Switch = Switch;
		LocalMessages[9].RelatedPRI = RelatedPRI_1;
		LocalMessages[9].OptionalObject = OptionalObject;
		LocalMessages[9].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
		LocalMessages[9].StringMessage = CriticalString;
		LocalMessages[9].DrawColor = Message.Static.GetColor(Switch, RelatedPRI_1, RelatedPRI_2);
		LocalMessages[9].LifeTime = Message.Default.Lifetime;
		LocalMessages[9].XL = 0;
		return;
	}
}

// ANOTHER Entry point for string messages.
simulated function SpecialMessage( PlayerReplicationInfo PRI, coerce string Msg, color SMC )
{
	SpecialMessageColor = SMC;
	LocalizedMessage( class'CriticalEventPlus', 0, None, None, None, Msg );
	return;
}

// Entry point for string messages.
simulated function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType )
{
	local int i;
	local Class<LocalMessage> MessageClass;

	switch (MsgType)
	{
		case 'Say':
			MessageClass = class'SayMessagePlus';
			break;
		case 'TeamSay':
			MessageClass = class'TeamSayMessagePlus';
			break;

		// Another step to defeat hardcoding
		case 'Custom':
			MessageClass = class'CriticalStringPlus';
			UseSpecialColor = true;
			LocalizedMessage( MessageClass, 0, None, None, None, Msg );
			return;

		case 'CriticalEvent':
			MessageClass = class'CriticalStringPlus';
			LocalizedMessage( MessageClass, 0, None, None, None, Msg );
			return;

		case 'DeathMessage':
			//MessageClass = class'RedSayMessagePlus';
			MessageClass = class'StringMessagePlus';
			break;
		case 'Pickup':
			PickupTime = Level.TimeSeconds;
		default:
			MessageClass = class'StringMessagePlus';
			break;
	}

	if ( ClassIsChildOf(MessageClass, class'SayMessagePlus') ||
				     ClassIsChildOf(MessageClass, class'TeamSayMessagePlus') )
	{
		FaceTexture = PRI.TalkTexture;
		if ( FaceTexture != None )
			FaceTime = Level.TimeSeconds + 3;
		if ( Msg == "" )
			return;
	}
	for (i=0; i<4; i++)
	{
		if ( ShortMessageQueue[i].Message == None )
		{
			// Add the message here.
			ShortMessageQueue[i].Message = MessageClass;
			ShortMessageQueue[i].Switch = 0;
			ShortMessageQueue[i].RelatedPRI = PRI;
			ShortMessageQueue[i].OptionalObject = None;
			ShortMessageQueue[i].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
			if ( MessageClass.Default.bComplexString )
				ShortMessageQueue[i].StringMessage = Msg;
			else
				ShortMessageQueue[i].StringMessage = MessageClass.Static.AssembleString(self,0,PRI,Msg);
			return;
		}
	}

	// No empty slots.  Force a message out.
	for (i=0; i<3; i++)
		CopyMessage(ShortMessageQueue[i], ShortMessageQueue[i+1]);

	ShortMessageQueue[3].Message = MessageClass;
	ShortMessageQueue[3].Switch = 0;
	ShortMessageQueue[3].RelatedPRI = PRI;
	ShortMessageQueue[3].OptionalObject = None;
	ShortMessageQueue[3].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
	if ( MessageClass.Default.bComplexString )
		ShortMessageQueue[3].StringMessage = Msg;
	else
		ShortMessageQueue[3].StringMessage = MessageClass.Static.AssembleString(self,0,PRI,Msg);
}

simulated function Tick( float DeltaTime)
{
	Super.Tick( DeltaTime);
	if ( (DecimalTimer += DeltaTime) >= 0.1 )
	{
		DecimalTimer -= 0.1;
		TimerDecimal();
	}
}

simulated function TimerDecimal()
{
	if ( Level.NetMode == NM_Client )
	{
		if ( (I_Cache[IC_Dampener] != None) && I_Cache[IC_Dampener].bActive && (I_Cache[IC_Dampener].Charge > 0) )
			I_Cache[IC_Dampener].Charge--;
		if ( (I_Cache[IC_UDamage] != None) && I_Cache[IC_UDamage].bActive && (I_Cache[IC_UDamage].Charge > 0) )
			I_Cache[IC_UDamage].Charge--;
	}
}

simulated function Color NewColor( byte r, byte g, byte b )
{
	local Color CreatedColor;
	CreatedColor.r = r;
	CreatedColor.g = g;
	CreatedColor.b = b;
	return CreatedColor;
}

/*     sgRankDesc(0)="The player who caused most BaseCore damage"
     sgRankDesc(1)="The player who repaired the BaseCore the most"
     sgRankDesc(2)="The player who caused the most building damage"
     sgRankDesc(3)="The player who killed more than any other"
     sgRankDesc(4)="The player who built the greatest number of buildings"
     sgRankDesc(5)="The player who built the greatest number of warheads"
     sgRankDesc(6)="The player who killed the greatest number of warheads"
     sgRankDesc(7)="The player who repaired and upgraded the most"*/

defaultproperties
{
	 HudItemSlotSpace=36
     GreyColor=(R=128,G=128,B=128)
     RedColour=128
     TheWhiteStuff=(R=255,G=255,B=255)
     nHUDDecPlaces=1
     I_Type(0)=Class'sgTeleNetwork'
     I_Type(1)=Class'sgVisor'
     I_Type(2)=Class'Dampener'
     I_Type(3)=Class'SCUBAGear'
     I_Type(4)=Class'Suits'
     I_Type(5)=Class'UT_Invisibility'
     I_Type(6)=Class'UT_JumpBoots'
     I_Type(7)=Class'UDamage'
     I_Type(8)=Class'sgSpeed'
     I_Type(9)=Class'sgSuit'
     I_Type(10)=Class'Berserk'
     I_Type(11)=Class'sgConstructor'
     TeamIcons(0)=Texture'IconCoreRed'
     TeamIcons(1)=Texture'IconCoreBlue'
     TeamIcons(2)=Texture'IconCoreGreen'
     TeamIcons(3)=Texture'IconCoreGold'
     bSeeAllHeat=True
     bSeeBehindWalls=True
     bVisorDeActivated=True
     AffectedActorsClass=Class'Pawn'
     ExcludedClass=StationaryPawn
     HeatClass=Class'sgHeatBlue'
     HeatSensingRange=16384.000000
}
