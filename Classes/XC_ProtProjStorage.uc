//Projectile effects maker
//This exists because SuperProtector projectiles are spawned in thousands
//And that will delay garbage collection massively in long games
//Made by Higor

class XC_ProtProjStorage expands SiegeActor;


var sgProtProj ProjPool;
var sgProjImp ImpPool;
var byte Team;

struct ProjInfo
{
	var() vector Start;
	var() int Rot;
	var() int Id;
};

var ProjInfo Projs[32];
var byte CurPos; //Array pos
var int CurId;

var class<sgProtProj> TeamProjs[5];
var class<sgProjImp> TeamImps[5];

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		CurPos;
	reliable if ( Role == ROLE_Authority )
		Team, Projs;
}

simulated event PostNetBeginPlay()
{
	CurId = Projs[CurPos].Id;
	GotoState('Client');
	CurPos = (CurPos+1) % 32;
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if ( Level.NetMode == NM_Client )
		SetTimer( 2, false);
}

state Client
{
	simulated event Tick( float DeltaTime)
	{
		while ( Projs[CurPos].Id > CurId )
		{
			SetupProj( CurPos);
			CurId = Projs[CurPos].Id;
			CurPos = (CurPos+1) % 32;
		}
	}
	simulated event Timer();
}



simulated function SetupProj( byte Idx)
{
	local sgProtProj Result;

	if ( ProjPool != none )
		Result = ProjPool;
	else
	{
		Result = Spawn( TeamProjs[ Clamp(Team,0,4)]);
		Result.Store = self;
	}
	Result.SetCollision( True);
	Result.SetLocation( Projs[Idx].Start );
	Result.SetRotation( class'SiegeStatics'.static.DecompressRotator( Projs[Idx].Rot) );
	Result.MultiSkins[1] = TeamProjs[Team].default.MultiSkins[1];
	Result.GotoState('Flying');
}

simulated function SetupImpact( vector MoveAt)
{
	local sgProjImp Result;

	if ( ImpPool != none )
		Result = ImpPool;
	else
	{
		Result = Spawn( TeamImps[ Clamp(Team,0,4)] );
		Result.Store = self;
	}
	Result.SetLocation( MoveAt);
	Result.GotoState('Active');
}

function FireProj( vector Start, rotator Rot)
{
	NetUpdateFrequency = Default.NetUpdateFrequency;
	Projs[CurPos].Id = ++CurId;
	Projs[CurPos].Start = Start;
	Projs[CurPos].Rot = class'SiegeStatics'.static.CompressRotator( Rot);
	SetupProj( CurPos);
	CurPos = (CurPos+1) % 32;
	SetTimer( 1, false);
}

simulated event Timer()
{
	if ( Level.NetMode == NM_Client )
		GotoState( 'Client');
	else
		NetUpdateFrequency = Default.NetUpdateFrequency * 0.2;
}


defaultproperties
{
     bAlwaysRelevant=True
     NetUpdateFrequency=50
     RemoteRole=ROLE_SimulatedProxy
     NetPriority=1.4
     TeamProjs(0)=Class'sgProtProjRed'
     TeamProjs(1)=Class'sgProtProjBlue'
     TeamProjs(2)=Class'sgProtProjGreen'
     TeamProjs(3)=Class'sgProtProjYellow'
     TeamProjs(4)=Class'sgProtProj'
     TeamImps(0)=Class'sgProjImpRed'
     TeamImps(1)=Class'sgProjImpBlue'
     TeamImps(2)=Class'sgProjImpGreen'
     TeamImps(3)=Class'sgProjImpYellow'
     TeamImps(4)=Class'sgProjImp'
}