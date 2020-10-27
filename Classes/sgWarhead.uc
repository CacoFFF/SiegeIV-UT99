//=============================================================================
// sgWarhead.
// * Revised by 7DS'Lust
//=============================================================================
class sgWarhead extends sgItem;

//var bool Played;
var class<CriticalEventPlus> MessageClass;
var string sBuildMessage;



//Decrease nuke counter
function bool RemovedBy( Pawn Other, optional bool bWasLeech, optional float CheatMargin)
{
	local SiegeStatPlayer Stat;

	if ( Super.RemovedBy( Other, bWasLeech, CheatMargin) )
	{
		Stat = SGS.static.GetPlayerStat( Other);
		if ( Stat != None )
			Stat.WarheadBuildEvent( -1 );
		return true;
	}
}

function PostBuild()
{
	local TournamentPlayer P;
	local string sLocation;
	local SiegeStatPlayer Stat;

	Super.PostBuild();

	if ( bDeleteMe || (MessageClass == None) )
		return;

	ForEach AllActors (class'TournamentPlayer', P)
		if ( P.PlayerReplicationInfo != none && P.PlayerReplicationInfo.Team != Team )
			P.ReceiveLocalizedMessage(MessageClass, Team);

	if ( Pawn(Owner).PlayerReplicationInfo.PlayerLocation != None )
		sLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
	else if ( Pawn(Owner).PlayerReplicationInfo.PlayerZone != None )
		sLocation = Pawn(Owner).PlayerReplicationInfo.PlayerZone.ZoneName;
	if ( sLocation != "" && sLocation != " ")
		sLocation = "at"@sLocation;
		
	Stat = SGS.static.GetPlayerStat( Pawn(Owner) );
	if ( Stat != None )
		Stat.WarheadBuildEvent( 1 );

	AnnounceTeam(sBuildMessage@BuildingName@sLocation, Team);
}

function Destruct( optional pawn instigatedBy)
{
	local sgPRI aPRI;
	local SiegeGI Game;
	local byte KillerTeam;
	local SiegeStatPlayer Stat, VictimStat;
	
	Game = SiegeGI(Level.Game);
	KillerTeam = class'SiegeStatics'.static.GetTeam(instigatedBy, Team);
	
	if ( (Team < 4) && (Game.NetworthStat[Team] != None) )
		Game.NetworthStat[Team].AddEvent( 2 + Min(KillerTeam,3) );
	if ( (KillerTeam != Team) && (KillerTeam < 4) && (Game.NetworthStat[KillerTeam] != None) )
		Game.NetworthStat[KillerTeam].AddEvent( 1);
	
	if ( instigatedBy != none )
	{
		aPRI = sgPRI(instigatedBy.PlayerReplicationInfo);
		if ( aPRI != none )
		{
			aPRI.AddRu(200);
			aPRI.Score += 5;
		}
		
		Stat = SGS.static.GetPlayerStat( instigatedBy );
		VictimStat = SGS.static.GetPlayerStat(Pawn(Owner));
		if ( Stat != None )
			Stat.WarheadDestroyEvent( 1 );
		if (VictimStat != None)
			VictimStat.WarheadFailEvent(1);
	}
	Super.Destruct( instigatedBy);
}

function bool GiveItems( Pawn Other)
{
	local SiegeStatPlayer Stat;

	if ( Super.GiveItems(Other) )
	{
		Other.PlaySound(sound'sgMedia.sgGetNuke', SLOT_None, Other.SoundDampening * 3);
		if ( PlayerPawn(Other) != none )
			PlayerPawn(Other).GetWeapon( class<Weapon> (MyProduct.class) );
		Stat = SGS.static.GetPlayerStat( Other );
		if ( Stat != None )
			Stat.WarheadPickupEvent();
		return true;
	}
}


//	if ( (aItem != none) && (aItem.NukeDeco == none) && (aItem.AmmoType != none) && (aItem.AmmoType.AmmoAmount > 0) )
//		aItem.AddDeco();




defaultproperties
{
     bNoUpgrade=True
     bTakeProductVisual=True
     MaxEnergy=100
     DestructionAnnounce=ANN_Global
     MessageClass=Class'sgNukeBuildMsg'
     sBuildMessage="Your team has built a"
     FinishSound=Sound'sgMedia.SFX.sgWarAppear'
     InventoryClass=Class'sgNukeLauncher'
     SwitchToWeapon=True
     BuildingName="Warhead"
     BuildCost=1300
     UpgradeCost=200
     BuildTime=120.000000
     SpriteScale=0.400000
     Model=LodMesh'Botpack.missile'
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SpriteRedTeam=Texture'CoreSpriteTeam0'
     SpriteBlueTeam=Texture'CoreSpriteTeam1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteGreenTeam=Texture'CoreSpriteTeam2'
     SpriteYellowTeam=Texture'CoreSpriteTeam3'
     DSofMFX=1.500000
}
