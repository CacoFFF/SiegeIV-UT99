//=============================================================================
//=============================================================================
class sgItemMeshFX expands WildcardsMeshFX;

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

function PostNetBeginPlay()
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
	if ( Owner == none || Owner.bDeleteMe || Owner.bHidden || Inventory(Owner).Owner != none )
	{
		SetOwner( none);
		Destroy();
	}
}

function Destroyed()
{
    Super.Destroyed();
    if ( NextFX != None )
    {
        NextFX.Destroy();
        NextFX = None;
    }
}

function SetSize(float size)
{
    DrawScale = size;
    if ( NextFX != None )
        NextFX.SetSize(size);
}

defaultproperties
{
    Style=STY_Normal
    bTrailerSameRotation=True
}
