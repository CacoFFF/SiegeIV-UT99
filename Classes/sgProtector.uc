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
//	if ( ShouldFire() && !bDisabledByEMP)
//		Shoot(FindEnemy());
	if ( !bDisabledByEMP )
		BufferAndShoot();
}

function BufferAndShoot()
{
	local byte TargetTeam;
	local Pawn P;
	local ScriptedPawn S;
	local float StartDist;
	
	ScanCycle = ((ScanCycle+1) % 4);
	TargetTeam = ScanCycle;
	if ( TargetTeam >= Team )
		TargetTeam++;

	if ( BufferedEnemies[ScanCycle] != none )
		StartDist = VSize( BufferedEnemies[ScanCycle].Location - Location);
	else
		StartDist = SightRadius;
	
	BufferedEnemies[ScanCycle] = FindTeamTarget( StartDist, TargetTeam);

	For ( TargetTeam=0 ; TargetTeam<4 ; TargetTeam++ )
	{
		if ( (BufferedEnemies[TargetTeam] == none) || BufferedEnemies[TargetTeam].bDeleteMe || (VSize(BufferedEnemies[TargetTeam].Location - Location) > SightRadius) )
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
	if ( Best == none )
		Best = BufferedEnemies[ScanCycle];
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
/*
function bool ShouldAttack(Pawn enemy)
{
    if ( ScriptedPawn(enemy) != None && (enemy.PlayerReplicationInfo == none || enemy.PlayerReplicationInfo.Team != Team) )
    {
        if ( enemy.Health <= 10 )
            return false;
        return FastTrace( enemy.Location);
    }
		
    if ( sgBuilding(enemy) != None )
    {
        if ( sgBuilding(enemy).Team == Team || sgBuilding(enemy).Energy < 0 )
            return false;
    }
    else if ( enemy.PlayerReplicationInfo == None || enemy.PlayerReplicationInfo.bIsSpectator ||
      enemy.PlayerReplicationInfo.Team == Team ||
      enemy.Health <= 10 || !enemy.bProjTarget || SuitProtects(enemy) )
        return false;
    return FastTrace(enemy.Location);
}

function Pawn FindEnemy()
{
	local Pawn p;
	local float eDist;

	//Should be applied during upgrade, does the function Upgraded() properly work?
//	SightRadius = 1000 + 1750*Grade;

	if ( Enemy != none )
	{
		eDist = VSize( Enemy.Location - Location);
		if ( (eDist > SightRadius) || !ShouldAttack(Enemy) )
			Enemy = none;
		else
		{
			eDist -= 1;
			foreach RadiusActors(class'Pawn', p, eDist)
				if ( (VSize(p.Location - Location) < VSize(Enemy.Location - Location)) && ShouldAttack(p) )
					Enemy = p;
			return Enemy;
		}
	}

	ForEach RadiusActors(class'Pawn', p, SightRadius)
		if ( (Enemy == None || VSize(p.Location - Location) < VSize(Enemy.Location - Location)) && ShouldAttack(p) )
			Enemy = p;

    return Enemy;
}
*/
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
	if ( Energy < MaxEnergy )
		NetUpdateFrequency = 15;
	else
		NetUpdateFrequency = 10;
}

//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aStorage, aCost;

	if ( Super.AI_Rate(CrtTeam, sgC, cSlot) < 0 ) //Forbidden
		return -1;

	aCost = sgC.BuildCost(cSlot);
	if ( (CrtTeam.AIList.TeamRU() * 1.0) < aCost ) //Too damn expensive
		return -1;
	return 0.75 + aCost / 300;
}

defaultproperties
{
     bOnlyOwnerRemove=True
     FireSound=Sound'sgMedia.SFX.sgProtShot'
     ProjectileType=Class'sgProtProj'
     BuildingName="Protector"
     BuildCost=100
     UpgradeCost=40
     MaxEnergy=1200.000000
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
