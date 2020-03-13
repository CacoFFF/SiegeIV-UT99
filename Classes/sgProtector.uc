//=============================================================================
// sgProtector.
// * Revised by 7DS'Lust
// Revised for Monster Madness by nOs*Wildcard
// Team-colored projectiles by SK
// Pooled projectile system by Higor
//=============================================================================
class sgProtector extends sgBuilding;

var() sound         FireSound;
var() class<Projectile> ProjectileType;
var XC_ProtProjStorage Store;

var native Pawn BufferedEnemies[4];
var byte ScanCycle;


function CompleteBuilding()
{
	if ( !bDisabledByEMP )
		BufferAndShoot();
}

function BufferAndShoot()
{
	local byte TargetTeam;
	local float StartDist;
	
	ScanCycle = ((ScanCycle+1) % 4);
	TargetTeam = ScanCycle;
	if ( TargetTeam >= Team )
		TargetTeam++;

	if ( BufferedEnemies[ScanCycle] != none )
		StartDist = VSize( BufferedEnemies[ScanCycle].Location - Location) + 1;
	else
		StartDist = SightRadius;
	BufferedEnemies[ScanCycle] = FindTeamTarget( StartDist, TargetTeam);

	For ( TargetTeam=0 ; TargetTeam<4 ; TargetTeam++ )
	{
		//Fast rejects, the main loop should take care of cleaning these up
		if ( (BufferedEnemies[TargetTeam] == none) || BufferedEnemies[TargetTeam].bDeleteMe || !BufferedEnemies[TargetTeam].bCollideActors )
			continue;
		if ( ShouldFire() )
			Shoot( BufferedEnemies[TargetTeam] );
	}
}

//OVERRIDE USING NATIVE PLUGIN
final function Pawn FindTeamTarget( float Dist, byte aTeam)
{
	local Pawn P, Best;
	local ScriptedPawn SP;
	local float BestDist, CurDist;
	
	BestDist = Dist;
	
	if ( ScanCycle == 3 ) //Monsters
	{
		ForEach RadiusActors( class'ScriptedPawn', SP, Dist)
			if ( SP.bCollideActors && (SP.Health > 10) && (SP.PlayerReplicationInfo == none || SP.PlayerReplicationInfo.Team != Team) )
			{
				CurDist = VSize( SP.Location - Location);
				if ( CurDist < BestDist )
				{
					BestDist = CurDist;
					Best = SP;
				}
			}
	}
	else //Players
	{
		if ( (SiegeGI(Level.Game) != none) && (SiegeGI(Level.Game).Cores[aTeam] == none) )
			return none;
		ForEach RadiusActors( class'Pawn', P, Dist)
			if ( P.bCollideActors && ShouldAttackTeamPawn(P, aTeam) )
			{
				CurDist = VSize( P.Location - Location);
				if ( CurDist < BestDist )
				{
					BestDist = CurDist;
					Best = P;
				}
			}
	}
	return Best;
}

//XC_Engine v19 variant
final function Pawn XCGE_FindTeamTarget( float Dist, byte aTeam)
{
	local Pawn P, Best;
	local sgBuilding sgB;
	local ScriptedPawn SP;
	local float BestDist, CurDist;
	
	BestDist = Dist;
	
	if ( ScanCycle == 3 ) //Monsters
	{
		ForEach PawnActors( class'ScriptedPawn', SP, Dist)
			if ( SP.bCollideActors && (SP.Health > 10) && (SP.PlayerReplicationInfo == none || SP.PlayerReplicationInfo.Team != Team) )
			{
				CurDist = VSize( SP.Location - Location);
				if ( CurDist < BestDist )
				{
					BestDist = CurDist;
					Best = SP;
				}
			}
	}
	else //Players
	{
		if ( (SiegeGI(Level.Game) != none) && (SiegeGI(Level.Game).Cores[aTeam] == none) )
			return none;
		//Scan players first for quick reject
		ForEach PawnActors( class'Pawn', P, Dist, Location, true)
			if ( P.bCollideActors && ShouldAttackTeamPawn(P, aTeam) )
			{
				CurDist = VSize( P.Location - Location);
				if ( CurDist < BestDist )
				{
					BestDist = CurDist;
					Best = P;
				}
			}
		//Scan sgBuildings in shorter range
		ForEach PawnActors( class'sgBuilding', sgB, BestDist)
			if ( sgB.bCollideActors && (sgB.Team == aTeam) && ShouldAttackTeamPawn(sgB, aTeam) )
			{
				CurDist = VSize( sgB.Location - Location);
				if ( CurDist < BestDist )
				{
					BestDist = CurDist;
					Best = sgB;
				}
			}
	}
	return Best;
}

function PostBuild()
{
	local XC_ProtProjStorage ST;
	local sgBuilding sgB;
	local int FriendlySplash;

	Super.PostBuild();
	
	if (Team == 0)
		ProjectileType=Class'sgProtProjRed';
	else if (Team == 1)
		ProjectileType=Class'sgProtProjBlue';
	else if (Team == 2)
		ProjectileType=Class'sgProtProjGreen';
	else if (Team == 3)
		ProjectileType=Class'sgProtProjYellow';
	else
		ProjectileType=Class'sgProtProj';

	ForEach AllActors (class'XC_ProtProjStorage', ST)
		if ( ST.Team == Team )
		{
			Store = ST;
			break;
		}

	//Protectors splashing other buildings can be removed
	ForEach VisibleCollidingActors (class'sgBuilding', sgB, 135)
	{
		if ( Mine(sgB) != none || sgB.RuRewardScale < 0.9 || sgProtector(sgB) != none )
			continue;
		if ( ++FriendlySplash >= 2 )
		{
			bOnlyOwnerRemove = false;
			break;
		}
	}

	if ( Store == none )
	{
		Store = Spawn(class'XC_ProtProjStorage',none);
		Store.Team = Team;
	}
}

function Shoot(Pawn target)
{
	local vector FireSpot;
    local rotator ShootDirection;

//	if ( target == None || VSize(target.Location - Location) > SightRadius )
//       return;
    ShootDirection = rotator(target.Location - Location);

	PlaySound(FireSound, SLOT_None, 0.75);
	if ( Grade > 2 )
	{
	    FireSpot = target.Location + FMin(1, 1.1 + 0.6 * FRand()) *
          target.Velocity * VSize(target.Location - Location) /
          ProjectileType.default.Speed;

		if ( !FastTrace(FireSpot) )
			FireSpot = 0.5 * (FireSpot + target.Location);

		ShootDirection = Rotator(FireSpot - Location);
	}
	ShootDirection.Pitch += RandRange(-300,300) * FRand();
	ShootDirection.Yaw += RandRange(-300,300) * FRand();
	Store.FireProj( Location, ShootDirection);

//	Spawn(ProjectileType, Self,, Location, shootDirection);
}

function bool ShouldFire()
{
    return ( FRand() < 0.05 + Grade*0.05 );
}

function bool ShouldAttackTeamPawn( Pawn aPawn, byte aTeam)
{
	if ( sgBuilding(aPawn) != none )
		return (sgBuilding(aPawn).Team == aTeam) && (sgBuilding(aPawn).Energy >= 0) && FastTrace(aPawn.Location);
	return (aPawn.PlayerReplicationInfo != none) 
		&&	(aPawn.PlayerReplicationInfo.Team == aTeam)
		&& !aPawn.PlayerReplicationInfo.bIsSpectator
		&& (aPawn.Health > 10)
		&& !SuitProtects(aPawn)
		&& FastTrace(aPawn.Location);
}

function bool SuitProtects( pawn Other)
{
	local Inventory I;
	
	For ( I=Other.Inventory ; I!=none ; I=I.inventory )
		if ( sgSuit(I) != none )
			return sgSuit(I).bNoProtectors;
	return false;
}

simulated function Upgraded()
{
	SightRadius = 1000 + 1750*Grade;
}

//Higor, use this function to alter the NetUpdateFrequency on net games
function AlterNetRate()
{
	if ( Class'SiegeMutator'.default.bDropNetRate  )
		NetUpdateFrequency = 8;
	else
		NetUpdateFrequency = 12;
}

//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aCost;

	if ( Super.AI_Rate(CrtTeam, sgC, cSlot) < 0 ) //Forbidden
		return -1;

	aCost = sgC.BuildCost(cSlot);
	if ( (CrtTeam.AIList.TeamRU() * 1.0) < aCost ) //Too damn expensive
		return -1;
	return 0.75 + aCost / 300;
}

defaultproperties
{
     bDragable=true
     bOnlyOwnerRemove=True
     bExpandsTeamSpawn=True
     FireSound=Sound'sgMedia.SFX.sgProtShot'
     ProjectileType=Class'sgProtProj'
     BuildingName="Protector"
     BuildCost=100
     UpgradeCost=20
     MaxEnergy=1300.000000
     SpriteScale=0.850000
     Model=LodMesh'Botpack.Crystal'
     SkinRedTeam=Texture'ProtectorSkinTeam0'
     SkinBlueTeam=Texture'ProtectorSkinTeam1'
     SpriteRedTeam=Texture'ProtectorSpriteTeam0'
     SpriteBlueTeam=Texture'ProtectorSpriteTeam1'
     SkinGreenTeam=Texture'ProtectorSkinTeam2'
     SkinYellowTeam=Texture'ProtectorSkinTeam3'
     SpriteGreenTeam=Texture'ProtectorSpriteTeam2'
     SpriteYellowTeam=Texture'ProtectorSpriteTeam3'
     DSofMFX=1.200000
     NumOfMFX=3
     MFXrotX=(Pitch=20000,Yaw=20000,Roll=20000)
     SightRadius=1000.000000
     MultiSkins(0)=Texture'ProtectorSpriteTeam0'
     MultiSkins(1)=Texture'ProtectorSpriteTeam1'
     MultiSkins(2)=Texture'ProtectorSpriteTeam3'
     MultiSkins(3)=Texture'ProtectorSpriteTeam4'
     SightRadius=1000
     GUI_Icon=Texture'GUI_Protector'
}
