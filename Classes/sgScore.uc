// sgScore
// by Sektor
//=============================================================================
class sgScore extends UnrealCTFScoreBoard;


struct FlagData
{
	var string Prefix;
	var texture Tex;
};

var FlagData FD[64];
var sgPRI PRI[64];
var int iPRI;
var int counter, tableWidth, tableHeaderHeight, cellHeight, countTeams, saveindex, TeamPlayers[4], 
		ShowMaxPlayer1, ShowMaxPlayer2, NotShownPlayers[4], LastSortTime, tableLine1,
		tableLine2, paddingInfo, avgEff[4], avgPi[4], avgPl[4], avgY;
var Color White, Pink, Orange, getHeaderColor[4], getTeamColor[4];
var Font PtsFont26,PtsFont24,PtsFont22, PtsFont20, PtsFont18, PtsFont16, PtsFont14, PtsFont12;
var Texture getIconTexture[4], getTeamIcon[4], getHeaderTexture[4];
var string teamNames[4];
var float TeamX[4], TeamY[4];
var sgGameReplicationInfo sgGRI;
var sgClient ClientActor;

var TeamInfo TInfo[4];
var bool bAllowDraw;
 
function PostBeginPlay()
{
  super.PostBeginPlay();
  LastSortTime = -100;
  
  sgGRI = sgGameReplicationInfo( PlayerPawn(Owner).GameReplicationInfo);
  
  PtsFont26 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
  PtsFont24 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
  PtsFont22 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
  PtsFont20 = Font( DynamicLoadObject( "LadderFonts.UTLadder20", class'Font' ) );
  PtsFont18 = Font( DynamicLoadObject( "LadderFonts.UTLadder18", class'Font' ) );
  PtsFont16 = Font( DynamicLoadObject( "LadderFonts.UTLadder16", class'Font' ) );
  PtsFont14 = Font( DynamicLoadObject( "LadderFonts.UTLadder14", class'Font' ) );
  PtsFont12 = Font( DynamicLoadObject( "LadderFonts.UTLadder12", class'Font' ) );
	Timer();
}

event Timer()
{
	local TeamInfo T;
	local int Count;
	ForEach AllActors (class'TeamInfo', T)
	{
		if ( T.TeamIndex < 4 )
		{
			TInfo[ T.TeamIndex] = T;
			Count++;
		}
	}
	
	if ( ClientActor != none )
		Count++;
	else
	{	ForEach Owner.ChildActors (class'sgClient', ClientActor)
		{
			Count++;
			break;
		}
	}
	
	if ( (Count >= 5) || (Level.TimeSeconds > 3 * Level.TimeDilation) )
		bAllowDraw = true;
	else
		SetTimer( 0.2 * Level.TimeDilation, false);
}

function ShowScores(Canvas Canvas)
{
	local int i, Time, eff, Lightness;
	local float X,Y, xLen,yLen, pnx,pny, paddingInfo, ruX;
	local string s;
	local int TeamExist[4];
	local sgPRI aPRI;

	if ( !bAllowDraw )
		return;

	if ( ClientActor != none )
		Lightness = 140 * ClientActor.ScoreboardBrightness;

	if(Canvas.ClipX < 900){
		tableWidth = 370;
		paddingInfo = 160;
	}
	else{
		tableWidth = Self.default.tableWidth;
		paddingInfo = Self.default.paddingInfo;
	}

	//Reserve space: 7.5% top, 5% mid (centered), 7.5% bottom
	tableLine1 = (Canvas.ClipY / 40) * 3;
	tableLine2 = Canvas.ClipY / 2 + tableLine1 / 3;
	tableLine1 += 5; //Because we need to see messages
	ShowMaxPlayer1 = (Canvas.ClipY - (tableLine1*1.7 + 80)) / 40;
	ShowMaxPlayer2 = (Canvas.ClipY / 2 - (tableLine1*0.8 + 80)) / 40;
	tableLine1 += 5;

/*
	if(Canvas.ClipY<750){
		tableLine2 = 300;
		ShowMaxPlayer1=9;
		ShowMaxPlayer2=3;
	}
	else{
		tableLine2 = Self.default.tableLine2;
		ShowMaxPlayer1 = Self.default.ShowMaxPlayer1;
		ShowMaxPlayer2 = Self.default.ShowMaxPlayer2;
	}
	*/
	if( Level.TimeSeconds - LastSortTime > 0.5 )
	{
	  sortPRI();
	  LastSortTime = Level.TimeSeconds;
	}

	//I should handle this in Sort
	For(i=0; i<4; i++)
		if( (sgGRI.Cores[i] != None) && !sgGRI.Cores[i].bDeleteMe )
			TeamExist[i] = 1;
	For ( i = 0; i < iPRI; i++ )
		TeamExist[PRI[i].Team] = 1;
	
	countTeams = 0;
	for(i = 0; i < 4; i++ )
	{
		TeamPlayers[i] = 0;
		NotShownPlayers[i] = 0;

		if( TeamExist[i] > 0)
		{
			X = getXHeader(Canvas.ClipX);
			Y = getYHeader();
			TeamX[i] = X;
			TeamY[i] = Y; 
			
			////////
			//Header
			////////
			Canvas.bNoSmooth = False;
			//Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.DrawColor = Lighten(getHeaderColor[i], Lightness);
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.SetPos( X, Y );
			Canvas.DrawRect( texture'shade2', tableWidth , tableHeaderHeight );

			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.SetPos( X, Y );
			if ( getHeaderTexture[i] != none )
				Canvas.DrawPattern( getHeaderTexture[i], tableWidth , tableHeaderHeight , 1 );


			//Header core icons
			Canvas.DrawColor = Lighten(getTeamColor[i], Lightness);

			if ( (TInfo[i] != none) && (TInfo[i].TeamName != "") )
				s = TInfo[i].TeamName;
			else
				s = teamNames[i];

			Canvas.Font = PtsFont26;
			Canvas.SetPos( X+5, Y+5 );
			Canvas.StrLen( s,xLen,yLen);
			if ( xLen < 180 )
			{
				Canvas.DrawIcon(getTeamIcon[i], 0.5 );
				Canvas.SetPos( X+50, Y + 10);
			}
			else
			{
				Canvas.SetPos( X+5, Y + 10);
				xLen -= 50;
			}
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.DrawText( s);

			//avgInfo
			Canvas.Font = Font'SmallFont';
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.StrLen("AVG",pnx,pny);
			avgY = (tableHeaderHeight - (3*pny))/4;
			Canvas.SetPos(X+70+xLen, Y + avgY);
			Canvas.DrawText("PI:"@avgPi[i]@"ms");
			Canvas.SetPos(X+70+xLen, Y + 2*avgY + pny);
			Canvas.DrawText("PL:"@avgPl[i]$"%");
			Canvas.SetPos(X+70+xLen, Y + 3*avgY + 2*pny );
			Canvas.DrawText("EFF:"@avgEff[i]$"%");

			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.Font = Font'LEDFont2';
			if ( sgGRI.Cores[i] != none )
				s = ""$int(sgGRI.Cores[i].Energy / sgGRI.Cores[i].MaxEnergy * 100);
			else
				s = "0";
			Canvas.StrLen(s,xLen,yLen);
			
			Canvas.SetPos(X+tableWidth-xLen-42, Y+5 );
			Canvas.DrawIcon(getIconTexture[i], 0.5 );
			
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.SetPos( X+tableWidth-xLen-5, Y + 5);
			Canvas.DrawText(s);
			
			avgEff[i] = 0;
			avgPi[i] = 0;
			avgPl[i] = 0;
			
			countTeams++;
		}
	}
	
	for ( i = 0; i < iPRI; i++)
	{
		aPRI = PRI[i];
		if ( aPRI == none )
			continue;
		if(countTeams>2 && TeamPlayers[aPRI.Team] >= ShowMaxPlayer2)
			NotShownPlayers[aPRI.Team]++;
		else if(countTeams<=2 && TeamPlayers[aPRI.Team] >= ShowMaxPlayer1)
			NotShownPlayers[aPRI.Team]++;
		else
		{
			X = TeamX[aPRI.Team]; 
			Y = TeamY[aPRI.Team] + tableHeaderHeight + TeamPlayers[aPRI.Team] * cellHeight;
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.SetPos( X,Y);  
			Canvas.DrawRect( texture'shade2', tableWidth , cellHeight );		 
  
			//face
			Canvas.DrawColor = White;
			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.SetPos( X+5,Y+5);
			if ( (aPRI != none) && aPRI.bReadyToPlay )
				Canvas.DrawIcon( texture'IconCoreGreen', 0.5);
			else if( aPRI.TalkTexture != None ) Canvas.DrawIcon( aPRI.TalkTexture, 0.5 * 64.0 / aPRI.TalkTexture.VSize );
			else Canvas.DrawIcon( texture'shade', 0.5 );	  
	  
			//name
			Canvas.Font = PtsFont20;
			if(aPRI.bAdmin)
				Canvas.DrawColor = White;
			else if(aPRI.PlayerID == PlayerPawn(Owner).PlayerReplicationInfo.PlayerID)
				Canvas.DrawColor = Pink;
			else
				Canvas.DrawColor = Lighten(getTeamColor[aPRI.Team], Lightness);
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.SetPos( X + 45, Y + 7);
			Canvas.StrLen(aPRI.PlayerName,pnx,pny);
			Canvas.DrawText(aPRI.PlayerName);
			
			//ping-packetloss-bot
			Canvas.Font = Font'SmallFont';
			Canvas.SetPos( X + 45, Y + pny + 7);
			if(aPRI.bIsABot)
				Canvas.DrawText("BOT");
			else
			{
				Canvas.StrLen("PI:"@aPRI.Ping@"ms | PL:"@aPRI.PacketLoss$"%",xLen,yLen);
				Canvas.DrawText("PI:"@aPRI.Ping@"ms | PL:"@aPRI.PacketLoss$"%");
				//country flag
				if ( aPRI.CountryPrefix != "" )
				{
					Canvas.SetPos(X+xLen+90, Y + pny + 7);
					Canvas.DrawColor = WhiteColor;
					Canvas.DrawIcon(FD[GetFlagIndex(aPRI.CountryPrefix)].Tex, 1.0);
				}
			}
		  
			// Draw Nukes
	  		Canvas.DrawColor=Lighten(getTeamColor[3], Lightness);
			Canvas.SetPos(X+ paddingInfo+40, Y + 7);
			Canvas.StrLen("Ping:     ", xLen, yLen);
			Canvas.DrawText("Nukes:"@aPRI.sgInfoWarheadMaker, false);
		  
			// Draw Time
			Canvas.DrawColor=White;
			Time = Max(1, (Level.TimeSeconds + PlayerPawn(Owner).PlayerReplicationInfo.StartTime - aPRI.StartTime)/60);
			Canvas.SetPos(X+xLen+paddingInfo+40, Y + 7);
			Canvas.DrawText(TimeString$":"@Time, false);
		  
		  
			// Draw Nuke Takedowns
	  		Canvas.DrawColor=Lighten(getTeamColor[1], Lightness);
			Canvas.SetPos(X+paddingInfo+40, Y + yLen + 9);
			Canvas.StrLen("Ping:     ", xLen, yLen);
			Canvas.DrawText("NkKls:"@aPRI.sgInfoWarheadKiller, false);
	  	
			// Deaths && Eff
			eff = aPRI.GetEff();
				
			 // Draw Deaths
			Canvas.DrawColor=Lighten(getTeamColor[0], Lightness);
			Canvas.SetPos(X+xLen+paddingInfo+40, Y + yLen + 9);
			Canvas.DrawText("Dths:"@int(aPRI.Deaths), false); //@sgPRI(PRI).sgInfoKiller
			
			
	  		  // Draw Buildings
	  		Canvas.DrawColor=Lighten(getTeamColor[2], Lightness);
			Canvas.SetPos(X+paddingInfo+40, Y + 2 * yLen + 11);
			Canvas.StrLen("Ping:     ", xLen, yLen);
			Canvas.DrawText("Build:"@aPRI.sgInfoBuildingMaker, false);
		  
			// Draw Effective
			Canvas.DrawColor=Orange;
			Canvas.SetPos(X+xLen+paddingInfo+40, Y + 2 * yLen + 11);
			Canvas.DrawText("Eff:"@eff$"%", false);
	  	
			// Kills && Points
			Canvas.Font = PtsFont16;
			Canvas.DrawColor = Lighten(getTeamColor[aPRI.Team], Lightness);
			Canvas.StrLen(""@aPRI.sgInfoKiller@"/"@int(aPRI.Score),xLen,yLen);
			Canvas.SetPos(X+tableWidth-xLen-5, Y + 7);
			Canvas.DrawText(""@aPRI.sgInfoKiller@"/"@int(aPRI.Score), false);
			
			//RU
			ruX = 0;
			if(aPRI.Team == Pawn(Owner).PlayerReplicationInfo.Team)
			{
				Canvas.Font = Font'SmallFont';
				Canvas.StrLen("RU:"$int(aPRI.RU),xLen,yLen);
				ruX = xLen;
				Canvas.SetPos(X+tableWidth-xLen-5, Y + pny + 7);
				Canvas.DrawText("RU:"$int(aPRI.RU), false);
			}
			
		
			if ( aPRI.Team < 4 )
			{
				TeamPlayers[aPRI.Team]++;
				avgEff[aPRI.Team] += eff;
				avgPi[aPRI.Team] += aPRI.Ping;
				avgPl[aPRI.Team] += aPRI.PacketLoss;
			}
		}
	}

	for(i=0;i<4;i++)
	{
		avgEff[i] = avgEff[i] / TeamPlayers[i];
		avgPi[i] = avgPi[i] / TeamPlayers[i];
		avgPl[i] = avgPl[i] / TeamPlayers[i];
		
		if(NotShownPlayers[i]>0)
		{
			if(countTeams <= 2)
			{
				X = TeamX[i];
				Y = TeamY[i] + tableHeaderHeight + ShowMaxPlayer1 * cellHeight;				
			}
			else
			{
				X = TeamX[i];
				Y = TeamY[i] + tableHeaderHeight + ShowMaxPlayer2 * cellHeight; 
			}
			
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.SetPos( X,Y);
			Canvas.DrawRect( texture'shade2', tableWidth , cellHeight-10 );
			
			Canvas.DrawColor = Lighten(getTeamColor[i], Lightness);
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.Font = PtsFont16;
			Canvas.SetPos( X+5,Y+5);
			Canvas.DrawText(NotShownPlayers[i]@"Player not shown!", false);
		}
	}
	DrawFooters(Canvas);
}

function DrawFooters( Canvas C )
{
  local float DummyX, DummyY, Nil, X1, Y1;
  local string TextStr;
  local string TimeStr, HeaderText;
  local int Hours, Minutes, Seconds, i;
  local PlayerReplicationInfo PRI;
  local color specColor;
  local int baseX, baseY;

  C.bCenter = True;
  C.Font = MyFonts.GetSmallFont( C.ClipX );

  // Display server info in bottom center
  C.DrawColor = White;
  C.StrLen( "Test", DummyX, DummyY );
  C.SetPos( 0, C.ClipY - DummyY );
  TextStr = "Playing" @ Level.Title @ "on" @ sgGRI.ServerName;
  C.DrawText( TextStr );

  // Draw Time
  if( ( PlayerPawn(Owner).GameReplicationInfo.RemainingTime > 0 ) )
  {

	if( PlayerPawn(Owner).GameReplicationInfo.RemainingTime <= 0 )
	{
	  TimeStr = RemainingTime $ "00:00";
	}
	else
	{
	  Minutes = PlayerPawn(Owner).GameReplicationInfo.RemainingTime / 60;
	  Seconds = PlayerPawn(Owner).GameReplicationInfo.RemainingTime % 60;
	  TimeStr = RemainingTime $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
	}
  }
  else
  {
	Seconds = PlayerPawn(Owner).GameReplicationInfo.ElapsedTime;
	Minutes = Seconds / 60;
	Hours = Minutes / 60;
	Seconds = Seconds - ( Minutes * 60 );
	Minutes = Minutes - ( Hours * 60 );
	TimeStr = ElapsedTime $ TwoDigitString( Hours ) $ ":" $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
  }

	//Higor: this should help us break the 32 player limit barrier
	ForEach AllActors (class'PlayerReplicationInfo', PRI)
	{
		if ( PRI.bIsSpectator && !PRI.bWaitingPlayer && PRI.StartTime > 0)
		{
			if(HeaderText=="") HeaderText = pri.Playername;
			else HeaderText = HeaderText$", "$pri.Playername;
		}
	}
	if (HeaderText=="") HeaderText = "there is currently no one spectating this match."; else HeaderText = HeaderText$"."; // I'm sorry about this, it's really stupid																													 //  but I'm to lazy rewrite it :P
																														 // Atleast it's working..
  C.SetPos( 0, C.ClipY - 2 * DummyY );
  C.DrawText( "Current Time:" @ GetTimeStr() @ "|" @ TimeStr );

  // Draw Spectators
  C.StrLen( HeaderText, DummyX, Nil );
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( 0, C.ClipY - 3 * DummyY );
  
  C.Font = MyFonts.GetSmallestFont(C.ClipX);
  C.DrawColor = White;	  // Added in 4E
  C.DrawText("Spectators:"@HeaderText);
  
  C.SetPos( 0, C.ClipY - 4 * DummyY );
  C.DrawText(PlayerPawn(Owner).GameReplicationInfo.GameName);
  
  HeaderText=""; // This is declared as a global var, so we reset it to start with a clean slate.

  
   
  C.bCenter = False;
}

function sortPRI()
{
	local int i,j, maxIndex;
	local int oPRI;
	local sgPRI aPRI, maxValue;

	oPRI = iPRI;
	iPRI = 0;
	foreach AllActors(class'sgPRI', aPRI)
		if( (!aPRI.bIsSpectator || aPRI.bWaitingPlayer) && (aPRI.Team < 5) )
			PRI[iPRI++] = aPRI;

	For ( i=iPRI ; i<oPRI ; i++ )
		PRI[i] = none;

	For ( i=0 ; i<iPRI; i++)
	{
		maxIndex = i;
		maxValue = PRI[i];
		For( j=i+1; j<iPRI; j++)
		{
			if(PRI[j].Score > maxValue.Score)
			{
				maxValue = PRI[j];
				maxIndex = j;
			}
		}
		PRI[maxIndex] = PRI[i];
		PRI[i] = maxValue;
	}
}

function float getXHeader(int screenWidth){
	local float x;
	x = (screenWidth-2*tableWidth)/3; 
	switch(countTeams){
		case 0: 
		case 2: return x;
		case 1: 
		case 3: return 2*x+tableWidth;
		default: return 0;
	}
}

function float getYHeader(){
	
	switch(countTeams){
		case 0: 
		case 1: return tableLine1;
		case 2: 
		case 3: return tableLine2;
		default: return 0;
	}
}




function int GetFlagIndex(string Prefix)
{
	local int i;
	for(i=0;i<32;i++)
		if(FD[i].Prefix == Prefix)
			return i;
	FD[saveindex].Prefix=Prefix;
	FD[saveindex].Tex=texture(DynamicLoadObject("CountryFlags2."$Prefix, class'Texture'));
	i=saveindex;
	saveindex = (saveindex+1) % 256;
	return i;
}

function string GetTimeStr()
{
  local string Mon, Day, Hour, Min;

  Hour = string( PlayerPawn( Owner ).Level.Hour );
  if( int( Hour ) < 10 ) Hour = "0" $ Hour;
  
  Min = string( PlayerPawn( Owner ).Level.Minute );
  if( int( Min ) < 10 ) Min = "0" $ Min;

  switch( PlayerPawn( Owner ).Level.month )
  {
	case  1: Mon = "Jan"; break;
	case  2: Mon = "Feb"; break;
	case  3: Mon = "Mar"; break;
	case  4: Mon = "Apr"; break;
	case  5: Mon = "May"; break;
	case  6: Mon = "Jun"; break;
	case  7: Mon = "Jul"; break;
	case  8: Mon = "Aug"; break;
	case  9: Mon = "Sep"; break;
	case 10: Mon = "Oct"; break;
	case 11: Mon = "Nov"; break;
	case 12: Mon = "Dec"; break;
  }

  switch( PlayerPawn( Owner ).Level.dayOfWeek )
  {
	case 0: Day = "Sunday";	break;
	case 1: Day = "Monday";	break;
	case 2: Day = "Tuesday";   break;
	case 3: Day = "Wednesday"; break;
	case 4: Day = "Thursday";  break;
	case 5: Day = "Friday";	break;
	case 6: Day = "Saturday";  break;
  }

  return Day @ PlayerPawn( Owner ).Level.Day @ Mon @ PlayerPawn( Owner ).Level.Year $ "," @ Hour $ ":" $Min;
}

final function Color Lighten( Color C, int Amount)
{
	C.R = Min(255, C.R + Amount);
	C.G = Min(255, C.G + Amount);
	C.B = Min(255, C.B + Amount);
	return C;
}

defaultproperties
{
	 tableWidth=450
	 tableHeaderHeight=40
	 cellHeight=40
	 ShowMaxPlayer1=12
	 ShowMaxPlayer2=5
	 tableLine1=100
	 tableLine2=410
	 paddingInfo=200
	 White=(R=255,G=255,B=255)
	 Pink=(R=242,G=128,B=249)
	 Orange=(R=255,G=128)
	 getHeaderColor(0)=(R=32)
	 getHeaderColor(1)=(B=16)
	 getHeaderColor(2)=(G=32)
	 getHeaderColor(3)=(R=64,G=64)
	 getTeamColor(0)=(R=255)
	 getTeamColor(1)=(B=255)
	 getTeamColor(2)=(G=255)
	 getTeamColor(3)=(R=255,G=255)
	 getIconTexture(0)=Texture'IconCoreRed'
	 getIconTexture(1)=Texture'IconCoreBlue'
	 getIconTexture(2)=Texture'IconCoreGreen'
	 getIconTexture(3)=Texture'IconCoreGold'
	 getTeamIcon(0)=Texture'Botpack.Icons.I_TeamR'
	 getTeamIcon(1)=Texture'Botpack.Icons.I_TeamB'
	 getTeamIcon(2)=Texture'Botpack.Icons.I_TeamG'
	 getTeamIcon(3)=Texture'Botpack.Icons.I_TeamY'
	 TeamNames(0)="Red Team"
	 TeamNames(1)="Blue Team"
	 TeamNames(2)="Green Team"
	 TeamNames(3)="Gold Team"
	 FragGoal="Crystal Damage Limit:"
}
