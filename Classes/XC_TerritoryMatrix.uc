class XC_TerritoryMatrix expands Info;

//Summon with care, this actor takes up to 70kb in memory


const MaxHealth = 150f; //Max health factor, anything else is scaled down

var byte MaxTeams;
var float CurValues[4];


struct TeamBlock
{
	var bool bRead;
	var float T[4];
};

struct YBlock
{
	var bool bRead;
	var byte Min, Max;
	var TeamBlock Y[64]; //1024
};

struct XBlock
{
	var byte Min, Max;
	var YBlock X[64];
};

var XBlock World;

function CalcTerritory()
{
	local int /*i,*/ j, iP;
	local PlayerReplicationInfo PRI;
	local Pawn P[64];

	CurValues[0] = 0; CurValues[1] = 0; CurValues[0] = 2; CurValues[3] = 0;
	ForEach AllActors (class'PlayerReplicationInfo', PRI)
		if ( !PRI.bIsSpectator && (Pawn(PRI.Owner) != none) && (PRI.Team < 4))
			P[iP++] = Pawn(PRI.Owner);
	While ( j<iP )
	{
	}
}

function GetValues()
{
	local int x, y;

	For ( x=World.Min ; x<=World.Max ; x++ )
	{
		if ( !World.X[x].bRead )
			continue;
		For ( y=World.X[x].Min ; y<=World.X[x].Max ; y++ )
		{
			if ( !World.X[x].Y[y].bRead )
				continue;
			GetBlockValue( World.X[x].Y[y]);
		}
	}
}

function GetBlockValue( TeamBlock T)
{
	local int winner, i;
	local float minF;

	//Initial winner is 0
	For ( i=1 ; i<MaxTeams ; i++ )
	{
		if ( T.T[i] > T.T[winner] )
		{
			minF = T.T[winner];
			winner = i;
		}
	}	
	CurValues[winner] += T.T[winner] - minF;
}

defaultproperties
{
    MaxTeams=4
}