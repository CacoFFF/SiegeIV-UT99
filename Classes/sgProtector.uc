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

//XC_GameEngine interface
native(3552) final iterator function CollidingActors( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc);

function CompleteBuilding()
{
	if ( ShouldFire() && !bDisabledByEMP)
		Shoot(FindEnemy());
}

function PostBuild()
{
	local XC_ProtProjStorage ST;
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
	if ( Store == none )
	{
		Store = Spawn(class'XC_ProtProjStorage',none);
		Store.Team = Team;
	}
}

function Shoot(Pawn target)
{
	local vector    fireSpot,
                    projStart;
	local Projectile
                    proj;
    local rotator   shootDirection;

	if ( target == None || VSize(target.Location - Location) > SightRadius )
        return;

    shootDirection = rotator(target.Location - Location);

	PlaySound(FireSound, SLOT_None, 0.75);

	if ( Grade > 2 )
	{
	    fireSpot = target.Location + FMin(1, 1.1 + 0.6 * FRand()) *
          target.Velocity * VSize(target.Location - Location) /
          ProjectileType.default.Speed;

		if ( !FastTrace(fireSpot, ProjStart) )
			fireSpot = 0.5 * (fireSpot + target.Location);

		shootDirection = Rotator(fireSpot - Location);
	}
	shootDirection.Pitch += RandRange(-300,300) * FRand();
	shootDirection.Yaw += RandRange(-300,300) * FRand();
	Store.FireProj( Location, shootDirection);

//	Spawn(ProjectileType, Self,, Location, shootDirection);
}

function bool ShouldFire()
{
    return ( FRand() < 0.05 + Grade/20 );
}

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
