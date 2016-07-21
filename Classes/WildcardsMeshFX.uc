//=============================================================================
// WildcardsMeshFX.
// Because I want some of the buildings look cool other then a bland blur
// of fuzzy lens flares.... yawn.....
//=============================================================================
class WildcardsMeshFX expands sgMeshFX;

function PostBeginPlay()
{
	if ( sgBuilding(Owner) == none )
		return;

	if ( sgBuilding(Owner).Team == 0 )
		Texture = sgBuilding(Owner).SkinRedTeam;	
	else if ( sgBuilding(Owner).Team == 1 )
		Texture = sgBuilding(Owner).SkinBlueTeam;
	else if ( sgBuilding(Owner).Team == 2 )
		Texture = sgBuilding(Owner).SkinGreenTeam;
	else if ( sgBuilding(Owner).Team == 3 )
		Texture = sgBuilding(Owner).SkinYellowTeam;
	else
		return; //HIGOR: ADD EXTRA CASE FOR SPECTATOR MOCK BUILDINGS
}

function Tick(float deltaTime)
{
	if ( sgBuilding(Owner) == None )
        Destroy();
}

