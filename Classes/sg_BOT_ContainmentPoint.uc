//*************************************
// Container marker for AI controller
//*************************************

class sg_BOT_ContainmentPoint expands sg_BOT_BuildingBase;


function bool AcceptBuild( sgBuilding Other)
{
	if ( !Other.IsA('sgContainer') )
		return false;
	if ( Building == none )
		return true;
	return Building.BuildCost <= Other.BuildCost;
}


//New container has more storage than old, allow removal of old one
function bool CheckPending()
{
	if ( (PendingBuilding != none) && (sgContainer(PendingBuilding).StorageAmount >= sgContainer(Building).StorageAmount) )
		return true;
	return false;
}

//Local method
//Prioritize containers with low grade, super prioritize if we can reach the RU needed for project by simply upgrading
//Don't upgrade harmed containers
function float RateUpgrade( sgBuilding Other)
{
	local float Factor;
	local int Project;

	Factor = Other.Energy / Other.MaxEnergy;
	if ( Other.Grade < 3 )
		Factor *= (6-Other.Grade)/3; //Can double priority if level 0
	Project = SiegeGI(Level.Game).BotControllers[Team].NextBProject;
	if ( (Project >= 0) && SiegeGI(Level.Game).MaxFutureRUs[Team] >= SiegeGI(Level.Game).CategoryInfo[Team].BuildCost(Project) )
	{
		Factor *= 1.2;
		if ( SiegeGI(Level.Game).MaxRUs[Team] < SiegeGI(Level.Game).CategoryInfo[Team].BuildCost(Project) )
			Factor *= 1.5;
	}
	return Factor;
}

function sg_BOT_ContainmentPoint FindPriorityCont( bool bCrowded, float Rating, optional int Pri, optional float Factor, optional sg_BOT_ContainmentPoint Best)
{
	local float CurF;
	local sgBuilding sgB;

	if ( PendingBuilding != none )
		Goto ENDE;

	//MODIFY FOR BUILD REPLACEMENT USING AI RATE INSTEAD!!!!
	if ( (Building == none) || (Building.AI_Rate(SiegeGI(Level.Game).BotControllers[Team], SiegeGI(Level.Game).CategoryInfo[Team], Building.iCatTag) < Rating) )
	{
		if ( Priority > Pri )
		{
			Pri = Priority;
			Best = none;
			Factor = 0;
		}
		else if ( Priority < Pri )
			Goto ENDE;

		CurF = FRand();
		if ( bCrowded )
		{
			ForEach RadiusActors( class'sgBuilding', sgB, 350) //DYNAMIZE BY HEAL RADIUS!
				CurF += 0.5 + FRand() * 0.5;
		}
		if ( Building != none )
			CurF *= 0.1;
		if ( CurF > Factor )
		{
			Best = self;
			Factor = CurF;
		}
	}
	ENDE:
	if ( NextBuild != none )
		return NextBuild.FindPriorityCont( bCrowded, Rating, Pri, Factor, Best);
	return Best;
}

function bool OnlyContainersInPriority( int Pri, optional bool bFoundContainer)
{
	if ( Building == none && (Pri == Priority) )
		bFoundContainer = true;
	if ( NextBuild != none )
		return NextBuild.OnlyContainersInPriority( Pri, bFoundContainer);
	Log("PRI "$Pri$", RESULT "$bFoundContainer);
	return bFoundContainer;
}


defaultproperties
{
    EditClass=class'sgEB_Container'
    bNoProject=True
}