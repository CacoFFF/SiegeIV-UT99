// sgScore
// by Sektor
// Greatly optimized by Higor
//=============================================================================
class sgScore extends UnrealCTFScoreBoard;

var sgPRI PRI[64];
var byte Eff[64];
var byte Show[64];

var int iPRI;
var int counter, tableWidth, tableHeaderHeight, cellHeight, CountTeams, saveindex, TeamPlayers[4], 
		ShowMaxPlayer1, ShowMaxPlayer2, NotShownPlayers[4], LastSortTime, tableLine1,
		tableLine2, paddingInfo, avgEff[4], avgPi[4], avgPl[4], avgY;
var Color White, Pink, Orange, Peach, Purple, Brown, getHeaderColor[4], getTeamColor[4];
var Font PtsFont26,PtsFont24,PtsFont22, PtsFont20, PtsFont18, PtsFont16, PtsFont14, PtsFont12;
var Texture getIconTexture[4], getTeamIcon[4], getHeaderTexture[4];
var string TeamNames[4];
var float TeamX[4], TeamY[4];
var sgGameReplicationInfo sgGRI;
var sgClient ClientActor;

 
function PostBeginPlay()
{
	Super.PostBeginPlay();
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
}

//Disable on release build for now...
//native (3559) static final function int AppCycles();
final function int GetCycles()
{
//	if ( (Level.NetMode != NM_Client) && class'SiegeStatics'.default.XCGE_Version >= 19 )
//		return AppCycles();
	return 0;
}


function ShowScores(Canvas Canvas)
{
	local int i, Time, iTeam[4];
	local float X,Y, xLen,yLen, pnx,pny, paddingInfo, ruX;
	local string s;
	local sgPRI aPRI;
	local int Cycles;
	local byte MyTeam;

	if ( sgGRI == None )
	{
		if ( PlayerPawn(Owner) != None )
			sgGRI = sgGameReplicationInfo( PlayerPawn(Owner).GameReplicationInfo);
		return;
	}

	MyTeam = 255;
	if ( (PlayerPawn(Owner) != None) && (PlayerPawn(Owner).PlayerReplicationInfo != None) )
		MyTeam = PlayerPawn(Owner).PlayerReplicationInfo.Team;
	
	Cycles = GetCycles();

	if(Canvas.ClipX < 900)
	{
		tableWidth = 370;
		paddingInfo = 160;
	}
	else
	{
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

	if( Level.TimeSeconds - LastSortTime > 0.5 )
	{
		sortPRI();
		LastSortTime = Level.TimeSeconds;
	}

	for( i=0; i<4; i++ )
	{
		if( (TeamPlayers[i] > 0) || (sgGRI.Cores[i] != None) )
		{
			iTeam[0]++;
			X = getXHeader( iTeam[0], Canvas.ClipX);
			Y = getYHeader( iTeam[0]);
			TeamX[i] = X;
			TeamY[i] = Y; 
			
			ruX = TeamPlayers[i] - NotShownPlayers[i];
			if( NotShownPlayers[i] > 0) //Not shown players need extra shade space (3/4 of player cell)
				ruX += 0.75; //HACK
			
			
			////////
			//Header
			////////
			Canvas.bNoSmooth = False;
			//Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.DrawColor = getHeaderColor[i]; //Do we need this?
			Canvas.Style = ERenderStyle.STY_Modulated;
			Canvas.SetPos( X, Y );
			Canvas.DrawRect( texture'shade2', tableWidth , tableHeaderHeight + cellHeight * ruX );

			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.SetPos( X, Y );
			if ( getHeaderTexture[i] != none )
				Canvas.DrawPattern( getHeaderTexture[i], tableWidth , tableHeaderHeight , 1 );


			//Header core icons
			Canvas.DrawColor = getTeamColor[i];

			if ( (sgGRI.Teams[i] != none) && (sgGRI.Teams[i].TeamName != "") )
				s = sgGRI.Teams[i].TeamName;
			else
				s = TeamNames[i];

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
				s = string( int(sgGRI.Cores[i].Energy / sgGRI.Cores[i].MaxEnergy * 100));
			else
				s = "0";
			Canvas.StrLen(s,xLen,yLen);
			
			Canvas.SetPos(X+tableWidth-xLen-42, Y+5 );
			Canvas.DrawIcon(getIconTexture[i], 0.5 );
			
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.SetPos( X+tableWidth-xLen-5, Y + 5);
			Canvas.DrawText(s);
			
		}
	}
	iTeam[0] = 0;
	
	for ( i = 0; i < iPRI; i++)
	{
		aPRI = PRI[i];
		if ( aPRI == none )
		{
			LastSortTime -= 0.5; //Force sort on next frame
			continue;
		}

		if ( Show[i] > 0 )
		{
			X = TeamX[aPRI.Team]; 
			Y = TeamY[aPRI.Team] + tableHeaderHeight + iTeam[aPRI.Team] * cellHeight;
			iTeam[aPRI.Team]++;
  
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
				Canvas.DrawColor = getTeamColor[aPRI.Team];
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
				Canvas.CurYL = 0;
				Canvas.DrawText("PI:"@aPRI.Ping@"ms | PL:"@aPRI.PacketLoss$"%", false); //Clear line = false, saves a StrLen call
				//country flag
				if ( aPRI.CountryPrefix != "" )
				{
					if ( aPRI.CachedFlag == None )
						aPRI.CacheFlag();
					else
					{
						Canvas.CurX += 45;
						Canvas.CurY -= Canvas.CurYL;
						Canvas.DrawColor = WhiteColor;
						Canvas.DrawIcon( aPRI.CachedFlag, 1.0);
					}
				}
			}
		  
			// Draw Nukes
	  		Canvas.DrawColor=getTeamColor[3];
			Canvas.SetPos(X+ paddingInfo+15, Y + 7);
//			Canvas.StrLen("Ping:     ", xLen, yLen);
			xLen = 60; //Font is fixed, this should be faster here
			yLen = 8;
			Canvas.DrawText("Nukes:"@aPRI.sgInfoWarheadMaker, false);
		  
			// Draw Time
			Canvas.DrawColor=White;
			Time = Max(1, (Level.TimeSeconds + PlayerPawn(Owner).PlayerReplicationInfo.StartTime - aPRI.StartTime)/60);
			Canvas.SetPos(X+xLen+paddingInfo+20, Y + 7);
			Canvas.DrawText(TimeString$":"@Time, false);
			
			 // Draw Core Dmg
			 Canvas.DrawColor=Purple;
			 Canvas.SetPos(X + (2 * xLen) + paddingInfo + 15, Y + 7);
			 Canvas.DrawText("CrDmg:"@aPRI.sgInfoCoreDmg, false);
		  
			// Draw Nuke Fails
	  		Canvas.DrawColor=Peach;
			Canvas.SetPos(X+paddingInfo+15, Y + yLen + 9);
			Canvas.DrawText("NkFls:"@aPRI.sgInfoWarheadFailCount, false);

			// Draw Deaths
			Canvas.DrawColor=getTeamColor[0];
			Canvas.SetPos(X+xLen+paddingInfo+20, Y + yLen + 9);
			Canvas.DrawText("Dths:"@int(aPRI.Deaths), false); //@sgPRI(PRI).sgInfoKiller

			// Draw Mine Frags
			Canvas.DrawColor=Brown;
			Canvas.SetPos(X + (2 * xLen) + paddingInfo + 15, Y + yLen+ 9);
			Canvas.DrawText("MnFrg:"@aPRI.sgInfoMineFrags, false);

	  		// Draw Nuke Kills
	  		Canvas.DrawColor=getTeamColor[1];
			Canvas.SetPos(X+paddingInfo+15, Y + 2 * yLen + 11);
			Canvas.DrawText("NkKls:"@aPRI.sgInfoWarheadKiller, false);
		  
			// Draw Effective
			Canvas.DrawColor=Orange;
			Canvas.SetPos(X+xLen+paddingInfo+20, Y + 2 * yLen + 11);
			Canvas.DrawText("Effn:"@Eff[i]$"%", false);

			if ( !sgGRI.bHideEnemyBuilds || (MyTeam == aPRI.Team) || (MyTeam == 255) )
			{
				// Draw Buildings
				Canvas.DrawColor=getTeamColor[2];
				Canvas.SetPos(X + (2 * xLen) + paddingInfo + 15, Y + 2 * yLen+ 11);
				Canvas.DrawText("Build:"@aPRI.sgInfoBuildingMaker, false);
			}
	  	
			// Kills && Points
			Canvas.Font = PtsFont16;
			Canvas.DrawColor = getTeamColor[aPRI.Team];
			Canvas.StrLen(aPRI.sgInfoKiller@"/"@int(aPRI.Score),xLen,yLen);
			Canvas.SetPos(X+tableWidth-xLen-5, Y + 7);
			Canvas.DrawText(aPRI.sgInfoKiller@"/"@int(aPRI.Score), false);
			
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
			
		}
	}

	for(i=0;i<4;i++)
	{
		if(NotShownPlayers[i]>0)
		{
			if( CountTeams <= 2)
			{
				X = TeamX[i];
				Y = TeamY[i] + tableHeaderHeight + ShowMaxPlayer1 * cellHeight;				
			}
			else
			{
				X = TeamX[i];
				Y = TeamY[i] + tableHeaderHeight + ShowMaxPlayer2 * cellHeight; 
			}

			Canvas.DrawColor = getTeamColor[i];
			Canvas.Style = ERenderStyle.STY_Normal;
			Canvas.Font = PtsFont16;
			Canvas.SetPos( X+5,Y+5);
			Canvas.DrawText(NotShownPlayers[i]@"Player not shown!", false);
		}
	}
	DrawFooters(Canvas);
	
	Cycles = GetCycles() - Cycles;
	if ( Cycles > 0 )
	{
		Canvas.SetPos( 5, 100);
		Canvas.DrawText( "Render cycles: "$Cycles);
	}
}

function DrawFooters( Canvas C )
{
	local float DummyX, DummyY, Nil;
	local string TextStr;
	local string TimeStr, HeaderText;
	local int Hours, Minutes, Seconds;
	local PlayerReplicationInfo PRI;

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
		Minutes = PlayerPawn(Owner).GameReplicationInfo.RemainingTime / 60;
		Seconds = PlayerPawn(Owner).GameReplicationInfo.RemainingTime % 60;
		TimeStr = RemainingTime $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
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
		if ( PRI.bIsSpectator && !PRI.bWaitingPlayer && PRI.StartTime > 0)
		{
			if(HeaderText=="") HeaderText = pri.Playername;
			else HeaderText = HeaderText$", "$pri.Playername;
		}
	if ( HeaderText == "" )
		HeaderText = "there is currently no one spectating this match.";
	else
		HeaderText = HeaderText$".";

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
   
	C.bCenter = False;
}

function sortPRI()
{
	local int i,j,k, maxIndex, sorted;
	local int oPRI;
	local sgPRI aPRI;
	local int TeamPlayersToShow;

	For ( i=0 ; i<4 ; i++ )
	{
		avgEff[i] = 0;
		avgPi[i] = 0;
		avgPl[i] = 0;
		TeamPlayers[i] = 0;
		NotShownPlayers[i] = 0;
	}
	
	oPRI = iPRI;
	iPRI = 0;
	CountTeams = 0;
	//Cache significant stuff
	ForEach AllActors(class'sgPRI', aPRI)
		if( (!aPRI.bIsSpectator || aPRI.bWaitingPlayer) && (aPRI.Team < 4) )
		{
			Show[iPRI] = 1;
			PRI[iPRI] = aPRI;
			avgEff[aPRI.Team] += Eff[iPRI];
			avgPi[aPRI.Team] += aPRI.Ping;
			avgPl[aPRI.Team] += aPRI.PacketLoss;
			TeamPlayers[aPRI.Team]++;
			iPRI++;
		}

	//Calculate averages
	maxIndex = 0;
	For ( i=0 ; i<4 ; i++ )
	{
		if ( TeamPlayers[i] > 0 )
		{
			avgEff[i] /= TeamPlayers[i];
			avgPi[i] /= TeamPlayers[i];
			avgPl[i] /= TeamPlayers[i];
			maxIndex = i; //This team appears to be the last one with players
			CountTeams++;
		}
		else if ( sgGRI.Cores[i] != None )
			CountTeams++;
	}

	//How many can we show
	if ( CountTeams > 2 )	TeamPlayersToShow = ShowMaxPlayer2;
	else					TeamPlayersToShow = ShowMaxPlayer1;

	For ( i=0 ; i<4 ; i++ )
		if( TeamPlayers[i] > TeamPlayersToShow)
		{
			NotShownPlayers[i] = TeamPlayers[i]-TeamPlayersToShow;
			if ( NotShownPlayers[i] == 1 )
				NotShownPlayers[i] = 0;
		}

	For ( i=iPRI ; i<oPRI ; i++ )
		PRI[i] = none;

	//Group team players
//	sorted = 0;
	For ( k=0 ; k<maxIndex ; k++ ) //No need to run a pass on the last team with players
	{
		i = sorted; //Start
		sorted += TeamPlayers[k]; //End
		while ( i<sorted )
		{
			if ( PRI[i].Team != k ) //Not in group
			{
				For ( j=i+1 ; j<iPRI ; j++ )
					if ( PRI[j].Team == k ) //Swap
					{
						aPRI = PRI[i];
						PRI[i] = PRI[j];
						PRI[j] = aPRI;
						break;
					}
			}
			i++;
		}
	}
	
	//Now that team players are grouped, QSort each team block by score
	sorted = 0; //Top index
	j = 0; //Bottom index
	For ( k=0 ; k<4 ; k++ )
		if ( TeamPlayers[k] > 0 )
		{
			sorted += TeamPlayers[k];
			Assert( sorted <= iPRI );
			For ( i=j+1 ; i<sorted ; i++ )
			{
				aPRI = PRI[i-1];
				if ( aPRI.Score < PRI[i].Score )
				{
					PRI[i-1] = PRI[i];
					PRI[i] = aPRI;
					if ( i > j+1 ) //If we just swapped, we may need to downswap again
						i -= 2;
				}
			}
			For ( i=j+(TeamPlayers[k]-NotShownPlayers[k]) ; i<sorted ; i++ )
				Show[i] = 0;
			j = sorted;
		}
	
	//Bugfix
	For ( i=0 ; i<iPRI ; i++ )
		Eff[i] = PRI[i].GetEff();
}

function float getXHeader( int CurTeam, int screenWidth)
{
	local float x;
	x = (screenWidth-2*tableWidth)/3; 
	switch(CurTeam)
	{
		case 1: 
		case 3: return x;
		case 2: 
		case 4: return 2*x+tableWidth;
		default: return 0;
	}
}

function float getYHeader( int CurTeam)
{
	if ( CurTeam <= 2 )
		return tableLine1;
	return tableLine2;
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
	 Peach=(R=248,G=184,B=179)
	 Purple=(R=177,G=156,B=217)
	 Brown=(R=152,G=118,B=84)
	 getHeaderColor(0)=(R=32)
	 getHeaderColor(1)=(B=16)
	 getHeaderColor(2)=(G=32)
	 getHeaderColor(3)=(R=64,G=64)
	 getTeamColor(0)=(R=255,G=50,B=50)
	 getTeamColor(1)=(R=80,B=255,G=120)
	 getTeamColor(2)=(R=20,G=255,B=20)
	 getTeamColor(3)=(R=255,G=255,B=20)
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
