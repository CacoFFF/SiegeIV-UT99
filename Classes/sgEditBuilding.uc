//****************
// Edit mode class
//****************

class sgEditBuilding expands sgBuilding
	abstract;

var class<sg_BOT_BuildingBase> BBaseClass;
var sg_BOT_BuildingBase BMarker;
var bool bOffensive;

function PostBuild()
{
	Super.PostBuild();
	//Create the marker if we have none
	if ( BMarker == none )
	{
		BMarker = Spawn( BBaseClass, Owner,,,Pawn(Owner).ViewRotation);
		if ( Owner.Physics == PHYS_Falling )
			BMarker.GotoState('AirInsert','Begin');
		else
			BMarker.SetLocation( Owner.Location);
		BMarker.FinalPos = Location;
		BMarker.nextBuild = SiegeGI(Level.Game).BuildMarkers[Pawn(Owner).PlayerReplicationInfo.Team];
		BMarker.bHidden = false;
		SiegeGI(Level.Game).BuildMarkers[Pawn(Owner).PlayerReplicationInfo.Team] = BMarker;
	}
}

function Upgraded()
{
	if ( Grade >= 5 )
		Grade = 0;
	BMarker.Priority = Grade;
}

event Destroyed()
{
	local sg_BOT_BuildingBase aM;
	Super.Destroyed();
	if ( BMarker != none )
	{
		aM = SiegeGI(Level.Game).BuildMarkers[Team];
		if ( aM == BMarker )
		{
			SiegeGI(Level.Game).BuildMarkers[Team] = aM.nextBuild;
			aM.Destroy();
		}
		else
		{
			while (aM.nextBuild != none)
			{
				if ( aM.nextBuild == BMarker )
				{
					aM.nextBuild = BMarker.nextBuild;
					BMarker.Destroy();
					break;
				}
				aM = aM.nextBuild;
			}
		}
	}
}

//Do not take damage
event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType )
{
}

defaultproperties
{
    BBaseClass=class'sg_BOT_BuildingBase'
    BuildCost=1
    UpgradeCost=0
    BuildTime=1
    BuildDistance=60
    bNoFractionUpgrade=True
}