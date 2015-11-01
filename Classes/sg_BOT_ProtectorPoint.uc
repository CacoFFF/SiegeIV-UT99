//*************************************
// Protector marker for AI controller
//*************************************

class sg_BOT_ProtectorPoint expands sg_BOT_BuildingBase;


function bool AcceptBuild( sgBuilding Other)
{
	if ( !Other.IsA('sgProtector') )
		return false;
	if ( Building == none )
		return true;
	return Building.BuildCost <= Other.BuildCost;
}


//New protector is more expensive, replace (change later!)
function bool CheckPending()
{
	if ( (PendingBuilding != none) && (PendingBuilding.BuildCost >= Building.BuildCost) )
		return true;
}

//Returns the best building index this team can build
function int SelectBuilding()
{
	local sgCategoryInfo sgC;
	local int i, iBest;
	local float fCur, fBest;

	sgC = SiegeGI(Level.Game).CategoryInfo[Team];
	if ( (CatBStart == -1) || (CatBCount != sgC.iBuilds) )
		ScanOptCat( sgC);

	iBest = -1;
	For ( i=CatBStart ; i<CatBCount ; i++ )
	{
		if ( ClassIsChildOf(sgC.GetBuild(i),class'sgProtector') )
		{
			fCur = sgC.GetBuild(i).static.AI_Rate( SiegeGI(Level.Game).BotControllers[Team], sgC, i);
			if ( fCur > fBest )
			{
				fBest = fCur;
				iBest = i;
			}
		}
	}
	return iBest;
}


//If no build, return iBuild
//If something edits the iBuild, we'll check again
function ScanOptCat( sgCategoryInfo sgC)
{
	local int i;

	CatBCount = sgC.iBuilds;
	For ( i=0 ; i<CatBCount ; i++ )
	{
		if ( ClassIsChildOf(sgC.GetBuild(i),class'sgProtector') )
		{
			CatBStart = i;
			return;
		}
	}
	CatBStart = CatBCount;
}


//Local method
//Protectors need to be safe for upgrade
//Highly prioritize protectors with low grades
function float RateUpgrade( sgBuilding Other)
{
	local float Factor;
	local int Project;

	if ( Other.Energy < Other.MaxEnergy ) //No risks
		return -1;
	Factor = 0.7 + Other.BuildCost / 1500;
	Factor *= (6-Other.Grade)/2; //Can triple priority if level 0
	return Factor;
}

defaultproperties
{
    EditClass=class'sgEB_Protector'
}