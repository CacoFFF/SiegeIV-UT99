//=============================================================================
// sgContainer
//
// Higor: now with faster healing method
// Higor: now radius and storage fully scalable
//=============================================================================
class sgContainer extends sgBuilding;

var int StorageAmount, BaseStorage;
var native sgBuilding sgRelated[48];
var int iRelated;
var float BaseEnergy; //Used for upgrade health scaling
var float HealAmount; //Base (non-upgraded)

simulated function CompleteBuilding()
{
	local int i;
	local float MaxHeal;

	if ( Role != ROLE_Authority  || bDisabledByEMP )
		return;
	if ( FRand() < 0.05 ) //Container can move around, just in case...
		RebuildRelated();

	if ( iRelated < 1 )
		return;

	MaxHeal = HealAmount + Grade*0.2;
	if ( SiegeGI(Level.Game) != none && SiegeGI(Level.Game).bOverTime )
		MaxHeal *= 0.5;

	While ( i < iRelated ) //Self always gets healing, so iRelated is always above 0
	{
		if ( (sgRelated[i] != none) && !sgRelated[i].bDisabledByEMP && (sgRelated[i].Energy < sgRelated[i].MaxEnergy) && (FRand() <= 0.5 + Grade*0.2 ))
			sgRelated[i].Energy = FMin(sgRelated[i].Energy + MaxHeal, sgRelated[i].MaxEnergy);
		++i;
	}
}

simulated function FinishBuilding()
{
    Super.FinishBuilding();

	SetCollision(true, true, true);
	bProjTarget = true;
	if ( BaseEnergy == 0 )
		BaseEnergy = MaxEnergy;
	if ( BaseStorage == 0 )
		BaseStorage = StorageAmount;

	if ( SiegeGI(Level.Game) != None )
	{
		SiegeGI(Level.Game).MaxRus[Team] += StorageAmount;
		SiegeGI(Level.Game).MaxRus[Team] = FMax(SiegeGI(Level.Game).MaxRUs[Team], 300);
	}
}

function PostBuild()
{
	Super.PostBuild();
	if ( SiegeGI(Level.Game) != None )
		SiegeGI(Level.Game).MaxFutureRUs[Team] += (StorageAmount + 250);
}

//Variable healing radius
function RebuildRelated()
{
	local sgBuilding sgB;

	iRelated = 0;
	foreach RadiusActors(class'sgBuilding', sgB, ScanRadius() )
		if ( (sgBaseCore(sgB) == None) && (sgB.Team == Team) && (iRelated < 48) )
			sgRelated[iRelated++] = sgB;
}

function float ScanRadius()
{
	return 150 + CollisionRadius + CollisionHeight + CollisionRadius * Grade * 0.5;
}

event Destroyed()
{
	Super.Destroyed();
	if ( SiegeGI(Level.Game) == none )
		return;
	
	if ( DoneBuilding )
		SiegeGI(Level.Game).MaxRUs[Team] -= StorageAmount;

	if ( bBuildInitialized )
	{
		if ( BaseStorage == 0 )
			SiegeGI(Level.Game).MaxFutureRUs[Team] -= (StorageAmount + 250);
		else
			SiegeGI(Level.Game).MaxFutureRUs[Team] -= (BaseStorage + 250);
	}
}

//Container notifications
function BuildingCreated( sgBuilding sgNew)
{
	local float InRadius;
	
	if ( bBuildInitialized && (sgNew.Team == Team) && (sgBaseCore(sgNew) == None) && (iRelated < ArrayCount(sgRelated)) )
	{
		InRadius = ScanRadius();
		if ( VSize(Location - sgNew.Location) <= InRadius + sgNew.CollisionRadius )
			sgRelated[iRelated++] = sgNew;
	}
}

function BuildingDestroyed( sgBuilding sgOld)
{
	local int i;

	Super.BuildingDestroyed( sgOld);
	if ( sgOld.Team != Team || (VSize(Location-sgOld.Location) < ScanRadius() + sgOld.CollisionRadius) )
		return;

	For ( i=iRelated-1 ; i>=0 ; i-- )
	{
		if ( sgRelated[i] == sgOld )
		{
			sgRelated[i] = sgRelated[--iRelated];
			sgRelated[iRelated] = none;
			break;
		}
	}
}

function Upgraded()
{
	local float percent, scale;

	if ( SiegeGI(Level.Game) != None )
	{
		scale = Clamp( Grade, 0, 5);
		SiegeGI(Level.Game).MaxRus[Team] -= StorageAmount;
		StorageAmount = BaseStorage + 50 * scale;
		SiegeGI(Level.Game).MaxRus[Team] += StorageAmount;
	}
	percent = Energy/MaxEnergy;
	MaxEnergy = BaseEnergy * (1 + Grade/2);
	Energy = percent * MaxEnergy;
	RebuildRelated();
}


//Rate self on AI teams, using category variations
static function float AI_Rate( sgBotController CrtTeam, sgCategoryInfo sgC, int cSlot)
{
	local float aStorage, aCost;

	if ( Super.AI_Rate(CrtTeam, sgC, cSlot) < 0 )
		return -1;

	if ( cSlot < 0 )
		aCost = default.BuildCost;
	else
		aCost = sgC.BuildCost(cSlot);
	if ( CrtTeam.AIList.MaxRU() < aCost ) //Containers can't wait for other containers to break the MaxRU boundary
		return -1;
	if ( (CrtTeam.AIList.TeamRU() * 1.3) < aCost ) //Too damn expensive
		return -1;

	//Container is needed, rating is (300 = 0.5) + 0.25
	aStorage = float(sgC.ParseProp(cSlot, "StorageAmount"));
	if ( aStorage == 0 )
		aStorage = Default.StorageAmount;
	aStorage = 0.25 + (aStorage+250) / 600;
	return aStorage;
}

defaultproperties
{
     StorageAmount=50
	 HealAmount=0.95
     BuildingName="Container"
     BuildCost=125
     UpgradeCost=25
     MaxEnergy=2000.000000
     Model=LodMesh'Botpack.CubeGem'
     SkinRedTeam=Texture'ContainerSkinTeam0'
     SkinBlueTeam=Texture'ContainerSkinTeam1'
     SpriteRedTeam=Texture'ContainerSpriteTeam0'
     SpriteBlueTeam=Texture'ContainerSpriteTeam1'
	 SpriteScale=0.800000
     SkinGreenTeam=Texture'ContainerSkinTeam2'
     SkinYellowTeam=Texture'ContainerSkinTeam3'
     SpriteGreenTeam=Texture'ContainerSpriteTeam2'
     SpriteYellowTeam=Texture'ContainerSpriteTeam3'
     DSofMFX=2.812500
     MFXrotX=(Pitch=2500,Yaw=2500,Roll=2500)
     MultiSkins(0)=Texture'ContainerSpriteTeam0'
     MultiSkins(1)=Texture'ContainerSpriteTeam1'
     MultiSkins(2)=Texture'ContainerSpriteTeam2'
     MultiSkins(3)=Texture'ContainerSpriteTeam3'
     CollisionRadius=36.000000
     CollisionHeight=36.000000
	 bCollideWhenPlacing=True
	 bBlocksPath=True
	 bNotifyDestroyed=True
	 bNotifyCreated=True
	 GUI_Icon=Texture'GUI_Container'
}
