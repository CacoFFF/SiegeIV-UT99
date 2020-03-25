//=============================================================================
// Mine 
// Written by nOs*Badger
// Revised for Monster Madness by nOs*Wildcard
// Revised by SK
// Optimized and de-exploited by Higor
//=============================================================================
class Mine extends sgBuilding;

var Viewport LocalPlayer;
var Pawn CheckOn[8];
var int iCheckOn;
var sgMineTrigger MyTrigger;
var() float DetRadius; //Base detonation radius
var() float ExpRadiusLevel; //Increase explosion radius per level
var() float SelfDamageDet;
var() float RULevelMult; //Additional RU given per damage instance scaler

//First event in creation order?
event Spawned()
{
	local PlayerStart P;
	local sgEquipmentSupplier ES;
	local byte aTeam;

	Super.Spawned();

	if ( (Pawn(Owner) == none) || (Pawn(Owner).PlayerReplicationInfo == none) )
		return;

	aTeam = Pawn(Owner).PlayerReplicationInfo.Team;
	ForEach RadiusActors (class'PlayerStart', P, 105)
		if ( P.TeamNumber != aTeam )
		{
			if ( PlayerPawn(Owner) != none )
				Pawn(Owner).ClientMessage("Cannot mine enemy spawn points.");
			Destroy();
			return;
		}
	ForEach RadiusActors (class'sgEquipmentSupplier', ES, 100)
	{
		if ( ES.bProtected && (ES.Team != aTeam) )
		{
			if ( PlayerPawn(Owner) != none )
				Pawn(Owner).ClientMessage("Cannot mine enemy main suppliers.");
			Destroy();
			return;
		}
	}
}

function CheckThis( Pawn Other)
{
	if ( iCheckOn >= 8 || bDeleteMe || (Energy <= 0) ) //Multi-explode bug here?
		return; //8 pawns on mine!!??

	CheckOn[iCheckOn++] = Other;

	if ( DoneBuilding && FastTrace(Other.Location) )
		CompleteBuilding();
}

function bool ShouldDetonate()
{
	local int i;
	local bool bSuccess;

	if ( bDeleteMe || (Energy <= 0) ) //Bugfixes
		return false;
	For ( i=iCheckOn-1 ; i>=0 ; i-- )
	{
		if ( !MyTrigger.IsTouching( CheckOn[i]) ) //Clean up the whole list before returning
		{
			CheckOn[i] = CheckOn[--iCheckOn];
			CheckOn[iCheckOn] = none;
			continue;
		}

		if ( !bSuccess && (CheckOn[i].Health > 0) && (VSize( CheckOn[i].Location - Location) < (DetRadius + CheckOn[i].CollisionRadius)) && FastTrace(CheckOn[i].Location) )
		{
			if ( sgPRI(CheckOn[i].PlayerReplicationInfo) != none && sgPRI(CheckOn[i].PlayerReplicationInfo).ProtectCount > 2 )
				continue;
			bSuccess = true;
		}
	}
	return bSuccess;
}

event Destroyed()
{
	if ( MyTrigger != none )
		MyTrigger.Destroy();
	Super.Destroyed();
}

function PostBuild()
{
	Super.PostBuild();
	Texture = Texture'SKFlare';
}


simulated function string KillMessage( name damageType, pawn Other )
{
	local int i, WarheadCount;
	local string s;
	local string sWarhead;
	local Pawn P;
	local PlayerReplicationInfo PRI;
	local SiegeGI Game;
	local byte VictimTeam;
	local SiegeStatPlayer Stat;
	
	WarheadCount = Min( SGS.static.GetAmmoAmount( Other, class'WarheadAmmo'), 2);

	P = Pawn(Owner);
	if ( (P != none) && P.PlayerReplicationInfo != none )
	{
		PRI = P.PlayerReplicationInfo;
		PRI.Score += 1 + WarheadCount * 3;

		s = " built by" @ PRI.PlayerName;
	}

	if ( WarheadCount > 0 )
	{
		Stat = SGS.static.GetPlayerStat( P );
		if ( Stat != None )
			Stat.WarheadDestroyEvent( WarheadCount);

		if ( Other.PlayerReplicationInfo != None )
		{
			if ( WarheadCount == 1 )
				sWarhead = ". " $ Other.PlayerReplicationInfo.PlayerName@"was carrying a WARHEAD!!!";
			else
				sWarhead = ". " $ Other.PlayerReplicationInfo.PlayerName@"was carrying TWO WARHEADS!!!";
		}
		Game = SiegeGI(Level.Game);
		if ( Game != none )
		{
			Game.SharedReward( sgPRI(PRI), Team, 500 * WarheadCount );
			VictimTeam = class'SiegeStatics'.static.GetTeam( Other);
			if ( Team < 4 && VictimTeam < 4 )
			{
				For ( i=0 ; i<WarheadCount ; i++ )
				{
					if ( Game.NetworthStat[Team] != None )
						Game.NetworthStat[Team].AddEvent( 1);
					if ( Game.NetworthStat[VictimTeam] != None )
						Game.NetworthStat[VictimTeam].AddEvent( 2 + Team);
				}
			}
		}
	}
	else
		sWarhead = ".";

    return ( Other.GetHumanName() @ "was killed by a" @ BuildingName $ s $ sWarhead);
}

function bool ShouldAttack(Pawn enemy)
{
	if ( ScriptedPawn(enemy) != None )
		return true;
	if ( sgBuilding(enemy) != None )
		return (sgBuilding(enemy).Team != Team) && (sgBuilding(enemy).Energy > 0);
	if ( enemy.PlayerReplicationInfo == None ||	enemy.PlayerReplicationInfo.Team == Team || !enemy.bProjTarget )
		return false;
	return true;
}


function Damage( optional bool bNoReward)
{
	local int i, j, iP;
	local Pawn p, pList[16];
	local float Award;

	PlaySound(Sound'SharpExplosion',, 4.0);

	//Hack fix, This iterator doesn't include CollisionRadius, use 25 extra for max detection (for monster support)!!
	ForEach VisibleCollidingActors (class'Pawn', p, DetRadius+(int(Grade)*ExpRadiusLevel)+25,,true) 
	{
		if ( (p.Health > 0) && ShouldAttack(P) )
		{
			pList[iP++] = p;
			if ( iP >= arraycount(pList) )
				break;
		}
	}

	i=Grade;	
	While ( i-- >= 0 )
		Spawn (class'MineExplosion',,, Location + VRand() * 40);

	Award = 50;
	While ( j < iP )
	{
		i = 0;
		While ( VSize( Location - pList[j].Location ) > DetRadius+17+(i*ExpRadiusLevel) )
			i++;
		if ( i > Grade )
		{
			j++;
			continue;
		}
		i = 1 + int(Grade) - i;

		pList[j].TakeDamage( (Grade+1) * i * 15, instigator, normal( Location - pList[j].Location) * 0.5 * (pList[j].CollisionHeight + pList[j].CollisionRadius), vect(0,0,0), 'mine');
		Award += (Grade+1) * i * RULevelMult;
		j++;
	}

	if ( !bNoReward && (SiegeGI(Level.Game) != none) )
	{
		if ( Pawn(Owner) == none )
			SiegeGI(Level.Game).SharedReward( none, Team, Award );
		else
			SiegeGI(Level.Game).SharedReward( sgPRI(Pawn(Owner).PlayerReplicationInfo), Team, Award );
	}

	Energy -= SelfDamageDet;
	if ( Energy <= 0 )
		Destruct();
}


simulated function CompleteBuilding()
{
	if ( Level.NetMode == NM_Client )
		Assert( LocalPlayer != none );

	Assert( (LocalPlayer == None) == (MyFX == none) );
	if ( LocalPlayer != none )
	{
		if ( LocalPlayer.Actor.PlayerReplicationInfo.Team == Team )
			MyFX.AmbientGlow = 240;
		else
		{
			MyFX.AmbientGlow = 1;
			MyFX.ScaleGlow = 0.2;
		}
		Assert( sgMeshFX_MineModu(MyFX.NextFX) != None );
	}

	if ( Role != ROLE_Authority )
		return;

	if ( VSize( Location - MyTrigger.Location) > 5)
		MyTrigger.SetLocation( Location - vect(0,0,1) );
	if ( ShouldDetonate() && !bDisabledByEMP )
		Damage();
}

simulated function FinishBuilding()
{
	local PlayerPawn P;
	local rotator R;
	
	Texture=Texture'Botpack.FLAKAMMOLEDbase';

	if ( Role == ROLE_Authority )
	{
		Spawn(class'sgFlash');
		MyTrigger = Spawn(class'sgMineTrigger', none, 'sgMineTrigger');
		MyTrigger.Master = self;
		MyTrigger.SetCollisionSize( DetRadius, DetRadius);
		MyTrigger.SetLocation( Location - vect(0,0,1) );
		if ( OwnerPRI != none )
			OwnerPRI.sgInfoSpreeCount += 3;
		if ( (DeathMatchPlus(Level.Game) != None) && DeathMatchPlus(Level.Game).bTournament )
			bOnlyOwnerRemove = false;
	}

	if ( Level.NetMode == NM_DedicatedServer )
		return;

	ForEach AllActors (class'PlayerPawn', P)
		if ( Viewport(P.Player) != none )
		{
			LocalPlayer = Viewport(P.Player);
			break;
		}
	if ( LocalPlayer == none )
		return;

	R = Rotation;
	R.Pitch = 0;
	R.Roll = 0;
	SetRotation(R);
	Assert( Model == LodMesh'Botpack.DiscStud' );
	if ( myFX == None && Model != None )
	{
		myFX = Spawn(class'WildcardsMeshFX', Self);
		myFX.Mesh = Model;
		myFX.DrawScale = DSofMFX;
		myFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
		myFX.RotationRate.Roll = MFXrotX.Roll*FRand();
		myFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();
		myFX.AmbientGlow=1;
		myFX.Style = STY_Translucent;
		myFX.ScaleGlow = 0.2;
		
		myFX.NextFX = Spawn(class'sgMeshFX_MineModu', Self);
		myFX.NextFX.Mesh = Model;
		myFX.NextFX.DrawScale = DSofMFX;
		myFX.NextFX.RotationRate = myFX.RotationRate;
	}
}

//Higor, use this function to alter the NetUpdateFrequency on net games
function AlterNetRate()
{
	if ( Class'SiegeMutator'.default.bDropNetRate  )
		NetUpdateFrequency = 12;
	else
		NetUpdateFrequency = 16;
//Enemies must see them earlier, hp update freq doesn't mean much
}


defaultproperties
{
     bDragable=true
     bOnlyOwnerRemove=True
     BurnPerSecond=5
     BuildingName="Mine"
     BuildCost=125
     UpgradeCost=15
     BuildTime=1.000000
     MaxEnergy=2000.000000
     SpriteScale=0.250000
     Model=LodMesh'Botpack.DiscStud'
     SpriteRedTeam=Texture'Botpack.FLAKAMMOLEDbase'
     SpriteBlueTeam=Texture'Botpack.FLAKAMMOLEDbase'
     SpriteGreenTeam=Texture'Botpack.FLAKAMMOLEDbase'
     SpriteYellowTeam=Texture'Botpack.FLAKAMMOLEDbase'
     MFXrotX=(Yaw=10000)
     AmbientGlow=0
     CollisionHeight=10.000000
     LightBrightness=1
     Visibility=15
     DetRadius=75
     ExpRadiusLevel=25
     SelfDamageDet=4000
     RULevelMult=4
     BuildDistance=37
	 RuRewardScale=1.1
     GUI_Icon=Texture'GUI_Mine'
}
