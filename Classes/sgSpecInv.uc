class sgSpecInv expands Inventory;

var float GivenAt;
var string ViewingFrom;
var bool bCheckedRights;
var bool bSpecialRights;

replication
{
	Reliable if ( Role < ROLE_Authority )
		Chase, FindFlamer, FindNuker, ToWall, JumpOutOfPlayer, TeamName;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Spectator(Owner) != none )
		ViewingFrom = Spectator(Owner).ViewingFrom;
}

function GiveTo( Pawn Other )
{
	Super.GiveTo( Other);
	GivenAt = Level.TimeSeconds; //Nexgen hasn't loaded yet!

}

function bool SpecialRights()
{
	local Info NX;

	if ( ViewPort(PlayerPawn(Owner).Player) != None )
	{
		bSpecialRights = true;
		bCheckedRights = true;
	}
	
	if ( !bCheckedRights && (Level.TimeSeconds - GivenAt > 10*Level.TimeDilation) )
	{
		bCheckedRights = true;
		//We gotta see what gives a player impunity...
		NX = class'SiegeStatics'.static.FindNexgenClient( PlayerPawn(Owner) );
		if ( NX != none && ((InStr(NX.GetPropertyText("rights"),"G") >= 0) || (InStr(NX.GetPropertyText("rights"),"F") >= 0)) )
			bSpecialRights = true;
	}
	return bSpecialRights;
}

function SetViewTarget( Actor Other)
{
	if ( Other == None )
		PlayerPawn(Owner).ViewSelf();
	else
	{
		PlayerPawn(Owner).ViewTarget = Other;
		PlayerPawn(Owner).bBehindView = true;
		if ( (Pawn(Other) != None) && (Pawn(Other).PlayerReplicationInfo != None) )
			PlayerPawn(Owner).ClientMessage(ViewingFrom@Pawn(Other).PlayerReplicationInfo.PlayerName, 'Event', true);
	}
}

exec function Chase( string aPlayer)
{
	local PlayerReplicationInfo PRI;

	if ( aPlayer == "" || ( PlayerPawn(Owner) == none ) )
		return;

	ForEach AllActors ( class'PlayerReplicationInfo', PRI)
		if ( (Spectator(PRI.Owner) == none) && (PRI.PlayerName != "Player") && (InStr(Caps(PRI.PlayerName), Caps(aPlayer)) >= 0) )
		{
			SetViewTarget( PRI.Owner);
			return;
		}
}

exec function FindFlamer( optional int Skip)
{
	local FlameThrower F;

	if ( PlayerPawn(Owner) == none )
		return;

	ForEach AllActors ( class'Flamethrower', F)
		if ( F.AmmoType != none && F.AmmoType.AmmoAmount > 0 && F.Owner != none )
		{
			if ( Skip-- > 0 )
				continue;
			SetViewTarget( F.Owner);
			return;
		}
}

exec function FindNuker()
{
	local WarheadAmmo W, WCur, WFirst;
	local bool bNext;

	if ( PlayerPawn(Owner) == none )
		return;

	if ( Pawn(PlayerPawn(Owner).ViewTarget) != None )
		WCur = WarheadAmmo(Pawn(PlayerPawn(Owner).ViewTarget).FindInventoryType( class'WarheadAmmo'));

	bNext = (WCur == None) || (WCur.Owner == None) || (WCur.AmmoAmount <= 0);
	ForEach AllActors ( class'WarheadAmmo', W)
		if ( (W.AmmoAmount > 0) && (W.Owner != None) )
		{
			if ( bNext )
			{
				SetViewTarget( W.Owner);
				return;
			}
			bNext = (WCur == W);
			if ( WFirst == None )
				WFirst = W;
		}
	if ( (WFirst != None) && (WFirst != WCur) )
		SetViewTarget( WFirst.Owner);
}



exec function ToWall()
{
	local vector HitLocation, HitNormal;

	if ( Pawn(Owner) == none )
		return;

	Owner.Trace( HitLocation, HitNormal, Owner.Location + vector(Pawn(Owner).ViewRotation) * 20000);
	if ( HitLocation != vect(0,0,0) )
		Owner.SetLocation( HitLocation + HitNormal * 5);
}

exec function JumpOutOfPlayer()
{
	if ( PlayerPawn(Owner) == none )
		return;
	if ( Pawn(PlayerPawn(Owner).ViewTarget) != none )
	{
		PlayerPawn(Owner).SetLocation( PlayerPawn(Owner).ViewTarget.Location);
		PlayerPawn(Owner).ViewTarget = none;
		PlayerPawn(Owner).bBehindView = false;
	}
}

exec function TeamName( name aTeam, string aName)
{
	local byte TheTeam;

	if ( (PlayerPawn(Owner) == none) || (!SpecialRights() && !PlayerPawn(Owner).bAdmin) )
	{
		if ( Pawn(Owner) != None )
			Pawn(Owner).ClientMessage( "You're not allowed to use this command");
		return;
	}

	if ( aTeam == 'Red' )
		TheTeam = 0;
	else if ( aTeam == 'Blue' )
		TheTeam = 1;
	else if ( aTeam == 'Green' )
		TheTeam = 2;
	else if ( (aTeam == 'Gold') || (aTeam == 'Yellow') )
		TheTeam = 3;
	else
	{
		Pawn(Owner).ClientMessage( "Invalid team, use [RED][BLUE][GREEN][YELLOW/GOLD]");
		return;
	}
	SiegeGI(Level.Game).Teams[TheTeam].TeamName = aName;
	class'SiegeStatics'.static.AnnounceAll( Pawn(Owner), Pawn(Owner).PlayerReplicationInfo.PlayerName@"changed"@aTeam@"team name to"@aName);
}
