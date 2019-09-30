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
	local int i, cc, iBest;
	local float fCur, fBest;

	sgC = SiegeGI(Level.Game).CategoryInfo[Team];
	if ( CatBStart == -1 ) //Cache builds
	{
		CatBStart = sgC.NextTypedBuild( class'sgProtector', 0);
		CatBCount = sgC.CountTypedBuilds( class'sgProtector', CatBStart);
	}

	iBest = -1;
	if ( CatBStart >= 0 )
	{
		i = CatBStart;
		while ( cc < CatBCount )
		{
			i = sgC.NextTypedBuild( class'sgProtector', i);
			if ( i >= 0 )
			{
				fCur = sgC.GetBuild(i).static.AI_Rate( SiegeGI(Level.Game).BotControllers[Team], sgC, i);
				if ( fCur > fBest )
				{
					fBest = fCur;
					iBest = i;
				}
			}
			i++; //Lookup from next index
			cc++;
		}
	}
	return iBest;
}



//Local method
//Protectors need to be safe for upgrade
//Highly prioritize protectors with low grades
function float RateUpgrade( sgBuilding Other)
{
	local float Factor;

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