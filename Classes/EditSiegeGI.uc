//=============================================================================
// Edit mode, for Bot stuff and scenarios?
//=============================================================================

class EditSiegeGI extends FreeSiegeGI;

function InitGame(string options, out string error)
{
	local int i;
	local sg_BOT_BuildingBase aMarker;
	local sgEditBuilding EB;

	GameProfile='SiegeEditMode';
	Super.InitGame( Options, Error);

	For ( i=0 ; i<4 ; i++ )
	{
		For ( aMarker=BuildMarkers[i] ; aMarker!=none ; aMarker=aMarker.nextBuild )
		{
			EB = Spawn(aMarker.EditClass,,,aMarker.FinalPos,aMarker.Rotation);
			EB.Destination = aMarker.Location;
			EB.BMarker = aMarker;
			EB.Team = aMarker.Team;
			EB.Grade = aMarker.Priority;
			EB.DoneBuilding = true;
			EB.SCount = 0;
			EB.Energy = EB.MaxEnergy;
			aMarker.bHidden = false;
		}
	}
}


defaultproperties
{
    GameName="Siege IV - Edit Mode"
    GameProfile=SiegeEditMode
}
