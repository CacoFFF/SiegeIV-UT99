//=============================================================================
// WildcardsSuperContainer.
// When a Container is not good enough...
// Besides ContainerX's are generally Useless!
//
// Faster healing iterations made by Higor
// Path node handler done as well
// Higor: now radius and storage fully scalable
//=============================================================================
class WildcardsSuperContainer expands sgBuilding;

var int StorageAmount, BaseStorage;
var byte HealRadius;
var int HealAmount;
var sgBuilding sgRelated[48];
var int iRelated;
var float BaseEnergy; //Used for upgrade health scaling

simulated event CompleteBuilding()
{
	local int i;

	if ( Role != ROLE_Authority  || bDisabledByEMP )
		return;

	if ( FRand() < 0.05 ) //Container can move around, just in case...
		RebuildRelated();

	While ( i < iRelated )
	{
		if ( !sgRelated[i].bDisabledByEMP && (sgRelated[i].Energy < sgRelated[i].MaxEnergy) && (FRand() <= 0.5 + Grade*0.2 ))
		{
			if ( SiegeGI(Level.Game).bOverTime )
				sgRelated[i].Energy = FMin(sgRelated[i].Energy + (HealAmount + Grade*0.2)*0.5, sgRelated[i].MaxEnergy);
			else
				sgRelated[i].Energy = FMin(sgRelated[i].Energy + HealAmount + Grade*0.2, sgRelated[i].MaxEnergy);
		}
		++i;
	}
}

simulated function FinishBuilding()
{
	SetCollisionSize( 80, 80);
	SetCollision(true, true, true);
	Super.FinishBuilding();
	bProjTarget = true;
	if ( BaseEnergy == 0 )
		BaseEnergy = MaxEnergy;
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

event Destroyed()
{
	Super.Destroyed();

	if ( DoneBuilding && SiegeGI(Level.Game) != None )
		SiegeGI(Level.Game).MaxRUs[Team] -= StorageAmount;

	if ( bBuildInitialized && (SiegeGI(Level.Game) != None) )
	{
		if ( BaseStorage == 0 )
			SiegeGI(Level.Game).MaxFutureRUs[Team] -= (StorageAmount + 250);
		else
			SiegeGI(Level.Game).MaxFutureRUs[Team] -= (BaseStorage + 250);
	}
}

function RebuildRelated()
{
	local sgBuilding sgB;

	iRelated = 0;
	foreach RadiusActors(class'sgBuilding', sgB, 240+(HealRadius*0.25)*Grade)
		if ( (sgBaseCore(sgB) == None) && (sgB.Team == Team) && (iRelated < 48) )
			sgRelated[iRelated++] = sgB;
}

function Upgraded()
{
	local float percent, scale;

	if ( SiegeGI(Level.Game) != None )
	{
		if ( BaseStorage == 0 )
			BaseStorage = StorageAmount;
		scale = Clamp( Grade, 0, 5);
		SiegeGI(Level.Game).MaxRus[Team] -= StorageAmount;
		StorageAmount = BaseStorage + 50 * scale;
		SiegeGI(Level.Game).MaxRus[Team] += StorageAmount;
	}
	if ( BaseEnergy == 0 )
		BaseEnergy = MaxEnergy;
	percent = Energy/MaxEnergy;
	MaxEnergy = BaseEnergy * (1 + Grade/2);
	Energy = percent * MaxEnergy;
	RebuildRelated();
}

//Super container notifications
function BuildingCreated( sgBuilding sgNew)
{
	local float InRadius;

	if ( (sgNew.Team == Team) && (sgBaseCore(sgNew) == None) && (iRelated < ArrayCount(sgRelated)) )
	{
		InRadius = 240+(HealRadius*0.25)*Grade + sgNew.CollisionRadius;
		if ( VSize(Location - sgNew.Location) <= InRadius )
			sgRelated[iRelated++] = sgNew;
	}
}

function BuildingDestroyed( sgBuilding sgOld)
{
	local int i;

	Super.BuildingDestroyed( sgOld);
	if ( sgOld.Team == Team )
	{
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
}


defaultproperties
{
     StorageAmount=1600
     HealRadius=240
     HealAmount=6
     BuildingName="Super Container"
     BuildCost=1600
     UpgradeCost=60
     BuildTime=45.000000
     MaxEnergy=7000.000000
     SpriteScale=1.350000
     Model=LodMesh'Botpack.CubeGem'
     SkinRedTeam=Texture'SuperContainerSkinT0'
     SkinBlueTeam=Texture'SuperContainerSkinT1'
     SpriteRedTeam=Texture'SuperContainerSpriteT0'
     SpriteBlueTeam=Texture'SuperContainerSpriteT1'
     SkinGreenTeam=Texture'SuperContainerSkinT2'
     SkinYellowTeam=Texture'SuperContainerSkinT3'
     SpriteGreenTeam=Texture'SuperContainerSpriteT2'
     SpriteYellowTeam=Texture'SuperContainerSpriteT3'
     DSofMFX=5.000000
     MFXrotX=(Pitch=5000,Yaw=5000,Roll=5000)
     MultiSkins(0)=Texture'SuperContainerSpriteT0'
     MultiSkins(1)=Texture'SuperContainerSpriteT1'
     MultiSkins(2)=Texture'SuperContainerSpriteT2'
     MultiSkins(3)=Texture'SuperContainerSpriteT3'
     CollisionRadius=40.000000
     CollisionHeight=40.000000
     bCollideWhenPlacing=True
     bBlocksPath=True
     BuildDistance=55
     GUI_Icon=Texture'GUI_SContainer'
}
