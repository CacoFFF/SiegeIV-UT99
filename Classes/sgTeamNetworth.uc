class sgTeamNetworth expands ReplicationInfo;

var ScriptedTexture GraphTexture;

var byte Team;
var float BuildingNetworth[120];
var float CarriedNetworth[120];
var float ItemNetworth[120];
var int EventCodes[120];
var int CurrentIndex;
var float MaxTotalNetworth; //Max of all teams, not this one
var float MaxTeamNetworth;

var Color TextColor[4];
var Color ShadeColor;
var Color GreyColor;
var bool bGlobal;
var bool bFirstGlobal;

// Event codes (4,4,4,4,4,4,3 bits):
// 0 - Nuke Blast (on us)
// 1 - Nuke Deny  (on enemy)
// 2 - Nuke Deny  (red)
// 3 - Nuke Deny  (blue)
// 4 - Nuke Deny  (green)
// 5 - Nuke Deny  (yellow)
// 6 - Nuke Blast (on enemy)
// 7 - Nuke Blast (on enemy, amp)
// 8 - reserved bit

replication
{
	reliable if ( bNetInitial && ROLE==ROLE_Authority )
		Team;
	reliable if ( !bNetInitial && Role==ROLE_Authority )
		BuildingNetworth, CarriedNetworth, ItemNetworth, EventCodes, CurrentIndex, MaxTotalNetworth, MaxTeamNetworth;
}


function SetTeam( byte InTeam)
{
	Team = InTeam;
	SetGraphTexture();
}

simulated event PostNetBeginPlay()
{
	local sgHUD HUD;
	
	SetGraphTexture();

	ForEach AllActors( class'sgHUD', HUD)
		HUD.NetworthStat[Team] = self;
	
}

simulated function SetGraphTexture()
{
	GraphTexture = ScriptedTexture(default.MultiSkins[Team]);
	GraphTexture.NotifyActor = self;
}

simulated event RenderTexture( ScriptedTexture T)
{
	local int i, j, Row, RowCount, E_Blast, E_Deny, E_Nuke, E_NukeA, E_NukeD[4];
	local int EventSum, RowAccumulate;
	local float MaxNetworth;
	local float Scale;
	local float Y1, Y2;
	local float X, XE;
	local float V;
	local Color HeaderColor;
	
	if ( bGlobal )
		MaxNetworth = MaxTotalNetworth;
	else
		MaxNetworth = MaxTeamNetworth;
	
	RowAccumulate = 4; //Accumulate every 4 rows (8 pixels)
	
	V = 1 + Team * 2;
	MaxNetworth = fMax( int(MaxNetworth / 1000 + 0.99) * 1000, 1000.0);
	Scale = 120.0 / MaxNetworth;
	RowCount = Min( CurrentIndex+1, 120);
	Row = CurrentIndex - RowCount; //Starts at -1
	X = 244 - RowCount * 2; //Down to 4
	XE = X - 1.0;
	while ( i < RowCount )
	{
		Row = (Row + 1) % 120;
		
		Y2 = BuildingNetworth[Row] * Scale;
		Y1 = 126 - Y2;
		T.DrawTile( X, Y1, 2, Y2, 31, V, 1, 1, Texture'SiegeStats.STATS_Networth', false);
		Y2 = CarriedNetworth[Row] * Scale;
		Y1 -= Y2;
		T.DrawTile( X, Y1, 2, Y2, 30, V, 1, 1, Texture'SiegeStats.STATS_Networth', false);
		Y2 = ItemNetworth[Row] * Scale;
		Y1 -= Y2;
		T.DrawTile( X, Y1, 2, Y2, 29, V, 1, 1, Texture'SiegeStats.STATS_Networth', false);

		//Count events (accumulate every 2 rows)
		if ( EventCodes[Row] != 0 )
		{
			E_Blast    += (EventCodes[Row])        & 0x0F;
			E_Deny     += (EventCodes[Row] >>> 4)  & 0x0F;
			E_NukeD[0] += (EventCodes[Row] >>> 8)  & 0x0F;
			E_NukeD[1] += (EventCodes[Row] >>> 12) & 0x0F;
			E_NukeD[2] += (EventCodes[Row] >>> 16) & 0x0F;
			E_NukeD[3] += (EventCodes[Row] >>> 20) & 0x0F;
			E_Nuke     += (EventCodes[Row] >>> 24) & 0x0F;
			E_NukeA    += (EventCodes[Row] >>> 28) & 0x07;
			EventSum++;
		}
		
		i++;
		X += 2.0;
		if ( (i % RowAccumulate == 0) || (i == RowCount) ) //Events advance by Accumulator
		{
			if ( EventSum > 0 )
			{
				EventSum = 0;
				Y1 = 124;
				while ( E_Blast > 0 )
				{
					Y1 -= 12.0;
					T.DrawTile( XE-1, Y1, 12, 13, 0, 0, 12, 13, Texture'SiegeStats.STATS_Networth', true);
					E_Blast--;
				}
				while ( E_Deny > 0 )
				{
					Y1 -= 12.0;
					T.DrawTile( XE-2, Y1, 12, 13, 0, 0, 12, 13, Texture'SiegeStats.STATS_Networth', true);
					T.DrawTile( XE-1, Y1+2, 9, 9, 0 + (Team & 1) * 9, 14 + (Team / 2) * 9, 9, 9, Texture'SiegeStats.STATS_Networth', true);
					E_Deny--;
				}
				if ( E_Nuke + E_NukeA > 0 )
					Y1 -= 4.0;
				while ( E_Nuke > 0 )
				{
					Y1 -= 8.0;
					T.DrawTile( XE, Y1, 8, 13, 12, 0, 8, 13, Texture'SiegeStats.STATS_Networth', true);
					E_Nuke--;
				}
				while ( E_NukeA > 0 )
				{
					Y1 -= 8.0;
					T.DrawTile( XE, Y1, 8, 13, 20, 0, 8, 13, Texture'SiegeStats.STATS_Networth', true);
					E_NukeA--;
				}
				if ( E_NukeD[0] + E_NukeD[1] + E_NukeD[2] + E_NukeD[3] > 0 )
					Y1 -= 6.0;
				For ( j=0 ; j<4 ; j++ )
					while ( E_NukeD[j] > 0 )
					{
						Y1 -= 8.0;
						T.DrawTile( XE, Y1, 8, 13, 12, 0, 8, 13, Texture'SiegeStats.STATS_Networth', true);
						T.DrawTile( XE, Y1+2, 9, 9, 0 + (j & 1) * 9, 14 + (j / 2) * 9, 9, 9, Texture'SiegeStats.STATS_Networth', true);
						E_NukeD[j]--;
					}
			}
			XE += 2.0 * RowAccumulate;
		}
	}
	T.DrawTile( 4, 126, 241, 1, 31, 11, 1, 1, Texture'SiegeStats.STATS_Networth', false);
	T.DrawTile( 244, 5, 1, 121, 31, 11, 1, 1, Texture'SiegeStats.STATS_Networth', false);

	if ( bGlobal && !bFirstGlobal )
		return;

	if ( bGlobal )
		HeaderColor = class'sgHUD'.default.WhiteColor;
	else
		HeaderColor = TextColor[Team];
		
	T.DrawColoredText( 2, 2, "Net worth [30 min]", Font'Engine.SmallFont', ShadeColor );
	T.DrawColoredText( 1, 1, "Net worth [30 min]", Font'Engine.SmallFont', HeaderColor );
	T.TextSize( "% of "$string(int(MaxNetworth)), X, Y1, Font'Engine.SmallFont');
	T.DrawColoredText( 247 - X, 2, "% of "$string(int(MaxNetworth)), Font'Engine.SmallFont', ShadeColor );
	T.DrawColoredText( 246 - X, 1, "% of "$string(int(MaxNetworth)), Font'Engine.SmallFont', HeaderColor );
}

//Player already passed sgPRI and Team check
function EvaluatePlayer( Pawn P)
{
	local Ammo Ammo;
	local int i;
	
	i = CurrentIndex % 120;
	CarriedNetworth[i] += sgPRI(P.PlayerReplicationInfo).RU;
	Ammo = Ammo(P.FindInventoryType( class'WarheadAmmo'));
	if ( Ammo != None )
		ItemNetworth[i] += 600 * Min(Ammo.AmmoAmount,2);
	Ammo = Ammo(P.FindInventoryType( class'BlueGunAmmo'));
	if ( Ammo != None )
		ItemNetworth[i] += 3 * Min(Ammo.AmmoAmount,200);
}

//Building already passed Team check
function EvaluateBuilding( sgBuilding B)
{
	if ( sgItem(B) != None )
		ItemNetworth[CurrentIndex % 120] += B.RUInvested;
	else
		BuildingNetworth[CurrentIndex % 120] += B.RUInvested;
}

function AddEvent( int Code)
{
	local int i, Shift, Mask, Value;
	
	i = CurrentIndex % 120;
	Shift = Code*4;
	if ( Code < 7 )
		Mask = 0x0F;
	else if ( Code < 8 )
		Mask = 0x07;
	else
	{
		Shift--;
		Mask = 0x01;
	}

	Value = (EventCodes[i] >>> Shift) & Mask;
	if ( Value != Mask )
	{
		Value++;
		EventCodes[i] = EventCodes[i] & (~(Mask << Shift)) | (Value << Shift);
	}
}

function float TotalNetworth( int i)
{
	i = i % 120;
	return BuildingNetworth[i] + CarriedNetworth[i] + ItemNetworth[i];
}

function ResetNetworth( int i)
{
	i = i % 120;
	BuildingNetworth[i] = 0;
	CarriedNetworth[i] = 0;
	ItemNetworth[i] = 0;
	EventCodes[i] = 0;
}

function float MaximumNetworth()
{
	local int i;
	local float Maximum;
	
	For ( i=0 ; i<120 ; i++ )
		Maximum = fMax( TotalNetworth(i), Maximum);
		
	return Maximum;
}



defaultproperties
{
	NetPriority=0.5
	NetUpdateFrequency=0.5
	MultiSkins(0)=ScriptedTexture'SiegeStats.STATS_NetworthRed'
	MultiSkins(1)=ScriptedTexture'SiegeStats.STATS_NetworthBlue'
	MultiSkins(2)=ScriptedTexture'SiegeStats.STATS_NetworthGreen'
	MultiSkins(3)=ScriptedTexture'SiegeStats.STATS_NetworthYellow'
	TextColor(0)=(R=255,G=100,B=100)
	TextColor(1)=(R=120,G=120,B=255)
	TextColor(2)=(R=100,G=200,B=100)
	TextColor(3)=(R=255,G=255,B=100)
	ShadeColor=(R=26,G=26,B=26)
}
