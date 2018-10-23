//=============================================================================
// sgWarhead.
// * Revised by 7DS'Lust
//=============================================================================
class sgWarhead extends sgItem;

//var bool Played;
var class<CriticalEventPlus> MessageClass;
var string sBuildMessage;

//Decrease nuke counter
function bool RemovedBy( pawn Other, optional bool bWasLeech, optional float CheatMargin)
{
	if ( Super.RemovedBy( Other, bWasLeech, CheatMargin) )
	{
		if ( Other != none && sgPRI(Other.PlayerReplicationInfo) != none )
			sgPRI(Other.PlayerReplicationInfo).sgInfoWarheadMaker--;
		return true;
	}
}

function PostBuild()
{
	local TournamentPlayer P;
	local string sLocation;

	Super.PostBuild();

	if ( bDeleteMe || (MessageClass == None) )
		return;

	ForEach AllActors (class'TournamentPlayer', P)
		if ( P.PlayerReplicationInfo != none && P.PlayerReplicationInfo.Team != Team )
			P.ReceiveLocalizedMessage(MessageClass, Team);

	if ( Pawn(owner).PlayerReplicationInfo.PlayerLocation != None )
		sLocation = PlayerReplicationInfo.PlayerLocation.LocationName;
	else if ( Pawn(owner).PlayerReplicationInfo.PlayerZone != None )
		sLocation = Pawn(owner).PlayerReplicationInfo.PlayerZone.ZoneName;
	if ( sLocation != "" && sLocation != " ")
		sLocation = "at"@sLocation;
	sgPRI(Pawn(owner).PlayerReplicationInfo).sgInfoWarheadMaker++;

	AnnounceTeam(sBuildMessage@BuildingName@sLocation, Team);
}

function Destruct( optional pawn instigatedBy)
{
	local sgPRI aPRI;
	
	if ( instigatedBy != none )
	{
		aPRI = sgPRI(instigatedBy.PlayerReplicationInfo);
		if ( aPRI != none )
		{
			aPRI.sgInfoWarheadKiller++;
			aPRI.AddRu(200);
			aPRI.Score += 5;
		}
	}
	Super.Destruct( instigatedBy);
}

function bool GiveItems( Pawn Other)
{
	if ( Super.GiveItems(Other) )
	{
		Other.PlaySound(sound'sgMedia.sgGetNuke', SLOT_None, Other.SoundDampening * 3);
		if ( PlayerPawn(Other) != none )
			PlayerPawn(Other).GetWeapon( class<Weapon> (MyProduct.class) );
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
