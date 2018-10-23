class sgSpecInv expands Inventory;

var string ViewingFrom;
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

function GiveTo( pawn Other )
{
	local Info NX;

	Super.GiveTo( Other);
	//We gotta see what gives a player impunity...
	NX = class'SiegeStatics'.static.FindNexgenClient( PlayerPawn(Other) );
	if ( NX != none && (InStr(NX.GetPropertyText("rights"),"G") >= 0) )
		bSpecialRights = true;
}

exec function Chase( string aPlayer)
{
	local PlayerReplicationInfo PRI;

	if ( aPlayer == "" || ( PlayerPawn(Owner) == none ) )
		return;

	ForEach AllActors ( class'PlayerReplicationInfo', PRI)
	{
		if ( (Spectator(PRI.Owner) == none) && (PRI.PlayerName != "Player") && (InStr(Caps(PRI.PlayerName), Caps(aPlayer)) >= 0) )
		{
			PlayerPawn(Owner).ViewTarget = PRI.Owner;
			PlayerPawn(Owner).ClientMessage(ViewingFrom@Pawn(PRI.Owner).PlayerReplicationInfo.PlayerName, 'Event', true);
			PlayerPawn(Owner).bBehindView = true;
			return;
		}
	}
}

exec function FindFlamer( optional int Skip)
{
	local FlameThrower F;

	if ( PlayerPawn(Owner) == none )
		return;

	ForEach AllActors ( class'Flamethrower', F)
	{
		if ( F.AmmoType != none && F.AmmoType.AmmoAmount > 0 && F.Owner != none )
		{
			if ( Skip-- > 0 )
				continue;
			PlayerPawn(Owner).ViewTarget = F.Owner;
			PlayerPawn(Owner).ClientMessage(ViewingFrom@Pawn(F.Owner).PlayerReplicationInfo.PlayerName, 'Event', true);
			PlayerPawn(Owner).bBehindView = true;
			return;
		}
	}
}

exec function FindNuker( optional int Skip)
{
	local WarheadAmmo W;

	if ( PlayerPawn(Owner) == none )
		return;

	ForEach AllActors ( class'WarheadAmmo', W)
	{
		if ( W.AmmoAmount > 0 && W.Owner != none )
		{
			if ( Skip-- > 0 )
				continue;
			PlayerPawn(Owner).ViewTarget = W.Owner;
			PlayerPawn(Owner).ClientMessage(ViewingFrom@Pawn(W.Owner).PlayerReplicationInfo.PlayerName, 'Event', true);
			PlayerPawn(Owner).bBehindView = true;
			return;
		}
	}
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
	local TeamInfo T;

	if ( (PlayerPawn(Owner) == none) || (!bSpecialRights && !PlayerPawn(Owner).bAdmin) )
		return;

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

	Pawn(Owner).ClientMessage( "Changed"@aTeam@"team name to"@aName);
	SiegeGI(Level.Game).Teams[TheTeam].TeamName = aName;
}
