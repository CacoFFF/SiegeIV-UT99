// ORB INFO ACTOR, MADE BY HIGOR

class sg_XC_Orb expands Actor;

var byte OrbTeam;

var bool bIsDropped;
var Pawn Holder;
var name ScriptedHold;

var sg_XC_OrbGFX_1 MyGFX;

var() config int DestructionTime;
var int iDest;

replication
{
	reliable if ( Role==ROLE_Authority )
		bIsDropped, OrbTeam, Holder;
	reliable if ( Role==ROLE_Authority )
 		LocalPickSound;
}

state Carried
{
	event BeginState()
	{
		SetCollision(false,false,false);
		SetPhysics( PHYS_None);
		SetLocation( Holder.Location);
		SetBase( Holder);
	}
Begin:
	if ( (Holder == none) || Holder.bDeleteMe || (Holder.Health <= 0) )
		DropAt();
	else
	{
		SetLocation( Holder.Location);
		Sleep(0.01);
		Goto('Begin');
	}
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if ( Level.NetMode != NM_Client )
		GotoState( 'Dropped','StaticDrop' );
}

state Dropped
{
	event BeginState()
	{
		SetOwner(none);
		bIsDropped = True;
		SetCollision( true, false, false);
		SetPhysics( PHYS_Falling);
		if ( Holder != none )
		{
			if ( sgPRI(Holder.PlayerReplicationInfo) != none )
				sgPRI(Holder.PlayerReplicationInfo).XC_Orb = none;
			else if ( sgBuilding(Holder) != none )
			{
				sgBuilding(Holder).OrbRemoved( none);
				sgBuilding(Holder).XC_Orb = none;
			}
			Holder = none;
		}
	}
	event EndState()
	{
		bIsDropped = false;
	}
	function InsertScript()
	{
		local sgBuilding sgB;
		ForEach AllActors (class'sgBuilding',sgB,ScriptedHold)
		{
			InsertOn( sgB);
			return;
		}
	}
Begin:
	Goto('StaticDrop');
TimedDrop:
	Sleep(0.98);
	if ( --iDest > 0 )
		Goto('TimedDrop');
	else
		Destroy();
StaticDrop:
	Sleep(0.01);
	//Wait one frame before spawning server graphics, this way we set correct TEAM
	if ( Level.NetMode != NM_DedicatedServer )
	{
		MyGFX = Spawn( class'sg_XC_OrbGFX_1', self, 'OrbGFX', location + vect(0,0,20));
		MyGFX.Slave = Spawn( class'sg_XC_OrbGFX_2', self, 'OrgGFX', location + vect(0,0,20));
		MyGFX.MyOrb = self;
		MyGFX.SetTeamTexture( OrbTeam);
	}
	//Preset scripted state!!! This works for Siege-Assault gametypes
	if ( ScriptedHold != '' )
		InsertScript();
}

event PostBeginPlay()
{
	SetTimer( 0.5, True);
}

simulated event PostNetBeginPlay()
{
	MyGFX = Spawn( class'sg_XC_OrbGFX_1', self, 'OrbGFX', location + vect(0,0,20));
	MyGFX.Slave = Spawn( class'sg_XC_OrbGFX_2', self, 'OrgGFX', location + vect(0,0,20));
	MyGFX.MyOrb = self;
	MyGFX.SetTeamTexture( OrbTeam);
}

event Timer()
{
}

event Touch( actor Other)
{
	local pawn P;
	local sgPRI aPRI;
	
	if ( !bIsDropped )
		return;

	P = Pawn(Other);
	if ( P != none)
		aPRI = sgPRI( P.PlayerReplicationInfo );

	if ( (aPRI != none) && (aPRI.XC_Orb == none) && P.bIsPlayer && (P.Health > 0) )
	{
		//Handle orb aquisition
		aPRI.XC_Orb = self;
		Holder = P;
		SetOwner(Holder);
		PlayerPawn(P).ClientPlaySound( sound'XC_OrbPick');
//		LocalPickSound( PlayerPawn(P) );
		GotoState('Carried');
	}
}

function DropAt()
{
	iDest = DestructionTime;
	GotoState('Dropped','TimedDrop');
}

function bool InsertOn( sgBuilding sgB)
{
	local sgPRI aPRI;

	if ( !sgB.bCanTakeOrb )
		return false;
	if ( sgB.XC_Orb != none )
		return false;

	SetOwner(none);
	if ( Holder != none )
	{
		aPRI = sgPRI( Holder.PlayerReplicationInfo);
		if ( aPRI != none )
		{
			if ( sgB.Team != aPRI.Team )
				return false;
			if ( OrbTeam == 255 )
				aPRI.Score += 5;
			else if ( OrbTeam != sgB.Team )
				return false;

			aPRI.XC_Orb = none;
			PlaySound( sound'XC_OrbInsert');
		}
	}
	sgB.XC_Orb = self;
	sgB.OrbReceived( Holder);
	Holder = sgB;
	SetCollision(false,false,false);
	SetPhysics( PHYS_None);
	SetBase( none);
	GotoState('');
	return true;
}

function bool RetrieveFrom( Pawn Retriever)
{
	local sgPRI aPRI;

	aPRI = sgPRI(Retriever.PlayerReplicationInfo);
	if ( (aPRI == none) || (aPRI.XC_Orb != none) )
		return false;

	if ( sgBuilding(Holder) != none )
	{
		sgBuilding(Holder).OrbRemoved( Retriever);
		sgBuilding(Holder).XC_Orb = none;
		SetOwner(Retriever);
		Holder = Retriever;
		aPRI.Score -= 5;
		aPRI.XC_Orb = self;
		GotoState('Carried');
		return true;
	}
	return false;
}

simulated function LocalPickSound( PlayerPawn P)
{
//	if ( (P != none) && ViewPort(P.Player) != none )
//		P.PlaySound( sound'XC_OrbPick', SLOT_Interface, 4);
}

defaultproperties
{
     OrbTeam=255
     DestructionTime=20
     bAlwaysRelevant=True
     DrawType=DT_None
     CollisionRadius=15.000000
     CollisionHeight=20.000000
     bCollideWorld=True
     NetUpdateFrequency=8.000000
}
