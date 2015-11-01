//*************************************
// Supplier marker for AI controller
//*************************************

class sg_BOT_SupplyPoint expands sg_BOT_BuildingBase;

var sg_BOT_SupplyPoint SuperMarker; //For super supplier that diffs location


function bool AcceptBuild( sgBuilding Other)
{
	if ( !Other.IsA('sgSupplier') && !Other.IsA('sgSupplierXXL') )
		return false;
	if ( Building == none )
		return true;
	return Building.BuildCost <= Other.BuildCost;
}

//Multi supplier point support
function sg_BOT_SupplyPoint GlobalFindSupplier()
{
	local sg_BOT_SupplyPoint Other;

	if ( nextBuild != none )
		Other = nextBuild.GlobalFindSupplier();
	if ( Other != none && FRand() < 0.5 )
		return Other;
	return self;
}

//New supplier has level 5, remove old
function bool CheckPending()
{
	if ( (sgSupplier(PendingBuilding) != none) && (sgSupplier(PendingBuilding).Grade >= 5) )
		return true;
	if ( (sgSupplierXXL(PendingBuilding) != none) && (sgSupplierXXL(PendingBuilding).Grade >= 5) )
		return true;
}

//Local method
//Prioritize MAX if this supplier is the team's main supplier
function float RateUpgrade( sgBuilding Other)
{
	local float Factor;
	local int Project;

	if ( SiegeGI(Level.Game).BotControllers[Team].MainSupplier == Other )
		Factor = 10;
	else
		Factor = 2;
	Factor *= 1 + Other.BuildCost/1500;
	Factor *= Other.Energy / Other.MaxEnergy;
	return Factor;
}

defaultproperties
{
    EditClass=class'sgEB_Supplier'
}